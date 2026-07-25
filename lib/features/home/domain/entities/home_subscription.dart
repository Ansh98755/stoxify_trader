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
    required this.batchName,
    this.analystName,
    required this.status,
    this.endDate,
  });

  final String id;
  final String batchName;
  final String? analystName;
  final HomeSubscriptionStatus status;
  final DateTime? endDate;

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
