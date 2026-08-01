import '../../domain/entities/home_subscription.dart';

class HomeSubscriptionModel {
  const HomeSubscriptionModel._();

  static HomeSubscription fromJson(Map<String, dynamic> json) {
    final payment =
        (json['payment'] as Map?)?.cast<String, dynamic>() ?? const {};
    return HomeSubscription(
      id: json['subscription_id'] as String? ?? '',
      planId: json['plan_id'] as String?,
      planName: json['plan_name'] as String?,
      batchId: json['batch_id'] as String?,
      batchName: json['batch_name'] as String? ?? 'Subscription',
      analystId: json['analyst_id'] as String?,
      analystName: json['analyst_name'] as String?,
      status: _status(json['status'] as String?),
      startDate: _date(json['start_date']),
      endDate: _date(json['end_date']),
      autoRenew: json['auto_renew'] as bool? ?? false,
      couponApplied: json['coupon_applied'] as String?,
      discountAmount:
          (json['discount_amount'] as num?)?.toDouble() ?? 0,
      paymentAmount: (payment['amount'] as num?)?.toDouble() ?? 0,
      paymentCurrency: payment['currency'] as String? ?? 'INR',
      transactionId: payment['transaction_id'] as String?,
    );
  }

  static HomeSubscriptionStatus _status(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'ACTIVE':
        return HomeSubscriptionStatus.active;
      case 'CANCELLED':
        return HomeSubscriptionStatus.cancelled;
      case 'PAYMENT_FAILED':
        return HomeSubscriptionStatus.paymentFailed;
      case 'PENDING':
        return HomeSubscriptionStatus.pending;
      default:
        return HomeSubscriptionStatus.expired;
    }
  }

  static DateTime? _date(dynamic v) {
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal();
    return null;
  }
}
