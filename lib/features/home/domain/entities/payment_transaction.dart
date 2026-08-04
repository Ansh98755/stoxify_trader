class PaymentTransaction {
  const PaymentTransaction({
    required this.id,
    required this.type,
    required this.status,
    required this.planName,
    required this.analystName,
    required this.amount,
    required this.currency,
    this.discountAmount = 0,
    this.createdAt,
  });

  final String id;
  final String type;
  final String status;
  final String planName;
  final String? analystName;
  final double amount;
  final String currency;
  final double discountAmount;
  final DateTime? createdAt;

  bool get isSuccessful => status.toUpperCase() == 'SUCCESS';
}
