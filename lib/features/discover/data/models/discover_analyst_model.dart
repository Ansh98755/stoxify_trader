class DiscoverAnalystModel {
  const DiscoverAnalystModel({
    required this.userId,
    required this.name,
    this.registrationType,
    this.sebiLicenseNumber,
    this.profilePicUrl,
    this.specialization = const [],
    this.segmentsCovered = const [],
    this.horizonsCovered = const [],
    this.winRate = 0,
    this.avgPnlPercent = 0,
    this.totalSubscribers = 0,
    this.totalTrades = 0,
    this.experienceYears = 0,
  });

  final String userId;
  final String name;
  final String? registrationType;
  final String? sebiLicenseNumber;
  final String? profilePicUrl;
  final List<String> specialization;
  final List<String> segmentsCovered;
  final List<String> horizonsCovered;
  final double winRate;
  final double avgPnlPercent;
  final int totalSubscribers;
  final int totalTrades;
  final int experienceYears;

  factory DiscoverAnalystModel.fromJson(Map<String, dynamic> json) {
    final perf =
        (json['performance'] as Map?)?.cast<String, dynamic>() ?? const {};
    final name = (json['name'] as String?)?.trim() ?? '';
    final companyName = (json['company_name'] as String?)?.trim() ?? '';
    final totalTrades = (perf['total_trades'] as num?)?.toInt() ?? 0;
    final winningTrades = (perf['winning_trades'] as num?)?.toInt() ?? 0;
    final winRate =
        (json['win_rate'] as num?)?.toDouble() ??
        (perf['win_rate'] as num?)?.toDouble() ??
        (totalTrades > 0 ? winningTrades / totalTrades : 0);
    return DiscoverAnalystModel(
      userId: json['user_id'] as String? ?? '',
      name: name.isNotEmpty ? name : companyName,
      registrationType: _nonEmptyString(json['registration_type']),
      sebiLicenseNumber: _nonEmptyString(json['sebi_license_number']),
      profilePicUrl: _nonEmptyString(json['profile_pic_url']),
      specialization: _stringList(json['specialization']),
      segmentsCovered: _stringList(json['segments_covered']),
      horizonsCovered: _stringList(json['horizons_covered']),
      winRate: winRate,
      avgPnlPercent: (perf['average_pnl_percent'] as num?)?.toDouble() ?? 0,
      totalSubscribers: (perf['total_subscribers'] as num?)?.toInt() ?? 0,
      totalTrades: totalTrades,
      experienceYears: (json['experience_years'] as num?)?.toInt() ?? 0,
    );
  }

  static List<String> _stringList(dynamic v) =>
      (v as List?)?.whereType<String>().toList() ?? const [];

  static String? _nonEmptyString(dynamic value) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? null : text;
  }
}
