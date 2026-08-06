import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';

import 'payment_checkout.dart';

PaymentCheckout createPlatformPaymentCheckout() => _WebPaymentCheckout();

/// Razorpay Checkout.js bridge (script loaded from `web/index.html`).
class _WebPaymentCheckout implements PaymentCheckout {
  void Function(PaymentSuccessResult response)? _onSuccess;
  void Function(PaymentFailureResult response)? _onError;

  @override
  void on({
    required void Function(PaymentSuccessResult response) success,
    required void Function(PaymentFailureResult response) error,
    void Function(String walletName)? externalWallet,
  }) {
    _onSuccess = success;
    _onError = error;
  }

  @override
  void open(Map<String, dynamic> options) {
    try {
      final ctor = globalContext.getProperty('Razorpay'.toJS);
      if (ctor == null || ctor.isUndefinedOrNull) {
        _onError?.call(
          const PaymentFailureResult(
            code: 1,
            message: 'Razorpay Checkout.js is not loaded',
          ),
        );
        return;
      }

      final jsOptions = _mapToJs(options);

      jsOptions.setProperty(
        'handler'.toJS,
        ((JSObject response) {
          _onSuccess?.call(
            PaymentSuccessResult(
              orderId: _jsProp(response, 'razorpay_order_id'),
              paymentId: _jsProp(response, 'razorpay_payment_id'),
              signature: _jsProp(response, 'razorpay_signature'),
            ),
          );
        }).toJS,
      );

      final modal = JSObject();
      modal.setProperty(
        'ondismiss'.toJS,
        (() {
          _onError?.call(
            const PaymentFailureResult(
              code: 2,
              message: 'Payment cancelled',
            ),
          );
        }).toJS,
      );
      jsOptions.setProperty('modal'.toJS, modal);

      final instance =
          (ctor as JSFunction).callAsConstructorVarArgs(<JSAny?>[jsOptions]);
      instance.callMethod('open'.toJS);
    } catch (e, st) {
      debugPrint('[Razorpay web] open failed: $e\n$st');
      _onError?.call(
        PaymentFailureResult(code: 100, message: e.toString()),
      );
    }
  }

  @override
  void clear() {
    _onSuccess = null;
    _onError = null;
  }

  static String? _jsProp(JSObject obj, String key) {
    final v = obj.getProperty(key.toJS);
    if (v == null || v.isUndefinedOrNull) return null;
    final dart = v.dartify();
    if (dart == null) return null;
    final s = dart.toString();
    return s.isEmpty ? null : s;
  }

  static JSObject _mapToJs(Map<String, dynamic> map) {
    final obj = JSObject();
    map.forEach((key, value) {
      final jsVal = _valueToJs(value);
      if (jsVal != null) {
        obj.setProperty(key.toJS, jsVal);
      }
    });
    return obj;
  }

  static JSAny? _valueToJs(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.toJS;
    if (value is int) return value.toJS;
    if (value is double) return value.toJS;
    if (value is num) return value.toDouble().toJS;
    if (value is bool) return value.toJS;
    if (value is Map) {
      final m = <String, dynamic>{};
      value.forEach((k, v) => m[k.toString()] = v);
      return _mapToJs(m);
    }
    if (value is List) {
      final arr = JSArray();
      for (var i = 0; i < value.length; i++) {
        final item = _valueToJs(value[i]);
        if (item != null) {
          arr.setProperty(i.toJS, item);
        }
      }
      return arr;
    }
    return value.toString().toJS;
  }
}
