import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Browser global (`window` / `globalThis`) without `package:web`.
@JS()
external JSObject get globalThis;

JSAny? _toJs(Object? value) {
  if (value == null) return null;
  if (value is String) return value.toJS;
  if (value is int) return value.toJS;
  if (value is double) return value.toJS;
  if (value is bool) return value.toJS;
  if (value is Map) {
    final obj = JSObject();
    value.forEach((Object? k, Object? v) {
      obj.setProperty(k.toString().toJS, _toJs(v));
    });
    return obj;
  }
  if (value is List) {
    return value.map(_toJs).toList().toJS;
  }
  return value.toString().toJS;
}

void openPaymentCheckout({
  required Map<String, dynamic> options,
  required void Function(Map<String, dynamic> response) onSuccess,
  required void Function(String code, String message) onError,
}) {
  final razorpayCtor = globalThis.getProperty('Razorpay'.toJS);
  if (razorpayCtor == null || razorpayCtor.isUndefinedOrNull) {
    onError(
      'NO_RAZORPAY_JS',
      'Razorpay checkout script is not loaded. Rebuild with checkout.js in index.html.',
    );
    return;
  }

  // Strip non-JSON fields we attach as real JS functions below.
  final data = Map<String, dynamic>.from(options)
    ..remove('handler')
    ..remove('modal');

  final opts = _toJs(data) as JSObject;

  final handler = (JSAny response) {
    final result = <String, dynamic>{};
    try {
      final decoded = jsonDecode(jsonEncode(response.dartify()));
      if (decoded is Map) {
        result.addAll(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      try {
        final o = response as JSObject;
        result['razorpay_order_id'] = o
            .getProperty('razorpay_order_id'.toJS)
            ?.dartify()
            ?.toString();
        result['razorpay_payment_id'] = o
            .getProperty('razorpay_payment_id'.toJS)
            ?.dartify()
            ?.toString();
        result['razorpay_signature'] = o
            .getProperty('razorpay_signature'.toJS)
            ?.dartify()
            ?.toString();
      } catch (_) {}
    }
    onSuccess(result);
  };
  opts.setProperty('handler'.toJS, handler.toJS);

  final modal = JSObject();
  final onDismiss = () {
    onError('DISMISSED', 'Payment cancelled');
  };
  modal.setProperty('ondismiss'.toJS, onDismiss.toJS);
  final existingModal = options['modal'];
  if (existingModal is Map) {
    existingModal.forEach((Object? k, Object? v) {
      if (k.toString() == 'ondismiss') return;
      modal.setProperty(k.toString().toJS, _toJs(v));
    });
  }
  opts.setProperty('modal'.toJS, modal);

  try {
    final ctor = razorpayCtor as JSFunction;
    final instance = ctor.callAsConstructor(opts) as JSObject;
    final onFailed = (JSAny response) {
      String code = 'FAILED';
      String message = 'Payment failed';
      try {
        final decoded = response.dartify();
        if (decoded is Map && decoded['error'] is Map) {
          final err = Map<String, dynamic>.from(decoded['error'] as Map);
          code = err['code']?.toString() ?? code;
          message = err['description']?.toString() ?? message;
        }
      } catch (_) {}
      onError(code, message);
    };
    instance.callMethod('on'.toJS, 'payment.failed'.toJS, onFailed.toJS);
    instance.callMethod('open'.toJS);
  } catch (e) {
    onError('OPEN_FAILED', e.toString());
  }
}

void disposePaymentCheckout() {}
