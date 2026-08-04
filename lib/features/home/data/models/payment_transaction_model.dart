import '../../domain/entities/payment_transaction.dart';

class PaymentTransactionModel {
  const PaymentTransactionModel._();

  static PaymentTransaction fromJson(Map<String, dynamic> json) =>
      PaymentTransaction(
        id: json['transaction_id'] as String? ?? json['_id'] as String? ?? '',
        type: json['type'] as String? ?? 'PAYMENT',
        status: json['status'] as String? ?? 'PENDING',
        planName: json['plan_name'] as String? ?? 'Plan subscription',
        analystName: json['analyst_name'] as String?,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        currency: json['currency'] as String? ?? 'INR',
        discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
        createdAt: _date(json['created_at']),
      );

  static DateTime? _date(dynamic value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;
}
