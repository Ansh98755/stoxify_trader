import 'payment_checkout_stub.dart'
    if (dart.library.html) 'payment_checkout_web.dart'
    if (dart.library.io) 'payment_checkout_mobile.dart';

/// Shared payment result when Razorpay checkout succeeds.
class PaymentSuccessResult {
  const PaymentSuccessResult({
    this.orderId,
    this.paymentId,
    this.signature,
  });

  final String? orderId;
  final String? paymentId;
  final String? signature;
}

/// Shared payment failure.
class PaymentFailureResult {
  const PaymentFailureResult({this.code, this.message});

  final int? code;
  final String? message;
}

/// Cross-platform Razorpay checkout. Mobile uses plugin; web uses Checkout.js.
abstract class PaymentCheckout {
  void on({
    required void Function(PaymentSuccessResult response) success,
    required void Function(PaymentFailureResult response) error,
    void Function(String walletName)? externalWallet,
  });

  void open(Map<String, dynamic> options);

  void clear();
}

/// Platform-selected factory (mobile plugin vs web Checkout.js).
PaymentCheckout createPaymentCheckout() => createPlatformPaymentCheckout();
