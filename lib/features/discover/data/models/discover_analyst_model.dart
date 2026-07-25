class DiscoverAnalystModel {
  const DiscoverAnalystModel({
    required this.userId,
    required this.name,
    this.sebiLicenseNumber,
    this.specialization = const [],
    this.segmentsCovered = const [],
    this.winRate = 0,
    this.avgPnlPercent = 0,
    this.totalSubscribers = 0,
  });

  final String userId;
  final String name;
  final String? sebiLicenseNumber;
  final List<String> specialization;
  final List<String> segmentsCovered;
  final double winRate;
  final double avgPnlPercent;
  final int totalSubscribers;

  factory DiscoverAnalystModel.fromJson(Map<String, dynamic> json) {
    final perf = (json['performance'] as Map?)?.cast<String, dynamic>() ?? const {};
    return DiscoverAnalystModel(
      userId: json['user_id'] as String,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : 'Analyst',
      sebiLicenseNumber: json['sebi_license_number'] as String?,
      specialization: _stringList(json['specialization']),
      segmentsCovered: _stringList(json['segments_covered']),
      winRate: (json['win_rate'] as num?)?.toDouble() ?? 0,
      avgPnlPercent: (perf['average_pnl_percent'] as num?)?.toDouble() ?? 0,
      totalSubscribers: (perf['total_subscribers'] as num?)?.toInt() ?? 0,
    );
  }

  static List<String> _stringList(dynamic v) =>
      (v as List?)?.whereType<String>().toList() ?? const [];
}
