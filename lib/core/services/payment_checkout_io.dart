import 'package:razorpay_flutter/razorpay_flutter.dart';

Razorpay? _instance;

void openPaymentCheckout({
  required Map<String, dynamic> options,
  required void Function(Map<String, dynamic> response) onSuccess,
  required void Function(String code, String message) onError,
}) {
  _instance?.clear();
  final razorpay = Razorpay();
  _instance = razorpay;

  razorpay
    ..on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
      onSuccess(<String, dynamic>{
        'razorpay_order_id': r.orderId,
        'razorpay_payment_id': r.paymentId,
        'razorpay_signature': r.signature,
      });
    })
    ..on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      onError(
        r.code?.toString() ?? 'FAILED',
        r.message ?? 'Payment failed',
      );
    })
    ..on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {})
    ..open(options);
}

void disposePaymentCheckout() {
  _instance?.clear();
  _instance = null;
}
