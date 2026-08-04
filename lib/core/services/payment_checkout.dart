import 'package:flutter/foundation.dart' show kIsWeb;

import 'payment_checkout_stub.dart'
    if (dart.library.html) 'payment_checkout_web.dart'
    if (dart.library.io) 'payment_checkout_io.dart' as impl;

/// Unified Razorpay launcher for mobile (plugin) and web (checkout.js).
class PaymentCheckout {
  PaymentCheckout();

  void open({
    required Map<String, dynamic> options,
    required void Function(Map<String, dynamic> response) onSuccess,
    required void Function(String code, String message) onError,
  }) {
    impl.openPaymentCheckout(
      options: options,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  void dispose() {
    impl.disposePaymentCheckout();
  }

  static bool get isWeb => kIsWeb;
}
