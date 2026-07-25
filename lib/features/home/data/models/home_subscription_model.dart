import '../../domain/entities/home_subscription.dart';

class HomeSubscriptionModel {
  const HomeSubscriptionModel._();

  static HomeSubscription fromJson(Map<String, dynamic> json) {
    return HomeSubscription(
      id: json['subscription_id'] as String? ?? '',
      batchName: json['batch_name'] as String? ?? 'Subscription',
      analystName: json['analyst_name'] as String?,
      status: _status(json['status'] as String?),
      endDate: _date(json['end_date']),
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
