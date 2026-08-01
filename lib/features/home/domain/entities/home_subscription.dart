enum HomeSubscriptionStatus {
  active,
  expired,
  cancelled,
  paymentFailed,
  pending,
}

class HomeSubscription {
  const HomeSubscription({
    required this.id,
    this.planId,
    this.planName,
    this.batchId,
    required this.batchName,
    this.analystId,
    this.analystName,
    required this.status,
    this.startDate,
    this.endDate,
    this.autoRenew = false,
    this.couponApplied,
    this.discountAmount = 0,
    this.paymentAmount = 0,
    this.paymentCurrency = 'INR',
    this.transactionId,
  });

  final String id;
  final String? planId;
  final String? planName;
  final String? batchId;
  final String batchName;
  final String? analystId;
  final String? analystName;
  final HomeSubscriptionStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool autoRenew;
  final String? couponApplied;
  final double discountAmount;
  final double paymentAmount;
  final String paymentCurrency;
  final String? transactionId;

  bool get isActive => status == HomeSubscriptionStatus.active;

  String get displayName =>
      (analystName != null && analystName!.trim().isNotEmpty)
          ? analystName!.trim()
          : batchName;

  String get initials {
    final parts = displayName
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.first;
      return s.substring(0, s.length >= 2 ? 2 : 1).toUpperCase();
    }
    return ('${parts[0][0]}${parts[1][0]}').toUpperCase();
  }
}
