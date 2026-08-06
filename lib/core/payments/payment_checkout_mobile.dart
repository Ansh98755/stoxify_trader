import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'payment_checkout.dart';

PaymentCheckout createPlatformPaymentCheckout() => _MobilePaymentCheckout();

/// Thin wrapper over [Razorpay] so mobile path is unchanged.
class _MobilePaymentCheckout implements PaymentCheckout {
  final Razorpay _razorpay = Razorpay();

  @override
  void on({
    required void Function(PaymentSuccessResult response) success,
    required void Function(PaymentFailureResult response) error,
    void Function(String walletName)? externalWallet,
  }) {
    _razorpay
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
        success(
          PaymentSuccessResult(
            orderId: r.orderId,
            paymentId: r.paymentId,
            signature: r.signature,
          ),
        );
      })
      ..on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
        error(
          PaymentFailureResult(
            code: r.code,
            message: r.message,
          ),
        );
      })
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse r) {
        externalWallet?.call(r.walletName ?? '');
      });
  }

  @override
  void open(Map<String, dynamic> options) => _razorpay.open(options);

  @override
  void clear() => _razorpay.clear();
}
