void openPaymentCheckout({
  required Map<String, dynamic> options,
  required void Function(Map<String, dynamic> response) onSuccess,
  required void Function(String code, String message) onError,
}) {
  throw UnsupportedError('Payment checkout is not supported on this platform.');
}

void disposePaymentCheckout() {}
