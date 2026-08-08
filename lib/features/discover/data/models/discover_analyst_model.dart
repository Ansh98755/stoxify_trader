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
    this.totalTrades,
    this.winningTrades,
    this.avgReturnPercent,
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
  /// Null when discover API omits `performance.total_trades`.
  final int? totalTrades;
  /// Null when discover API omits `performance.winning_trades`.
  final int? winningTrades;
  /// Null when discover API omits avg-return fields.
  final double? avgReturnPercent;
  final int experienceYears;

  factory DiscoverAnalystModel.fromJson(Map<String, dynamic> json) {
    final perf =
        (json['performance'] as Map?)?.cast<String, dynamic>() ?? const {};
    final name = (json['name'] as String?)?.trim() ?? '';
    final companyName = (json['company_name'] as String?)?.trim() ?? '';
    final totalTrades = _optionalInt(perf, 'total_trades');
    final winningTrades = _optionalInt(perf, 'winning_trades');
    final winRate =
        (json['win_rate'] as num?)?.toDouble() ??
        (perf['win_rate'] as num?)?.toDouble() ??
        ((totalTrades != null &&
                winningTrades != null &&
                totalTrades > 0)
            ? winningTrades / totalTrades
            : 0);
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
      winningTrades: winningTrades,
      avgReturnPercent: _optionalDouble(perf, 'average_return') ??
          _optionalDouble(perf, 'avg_return') ??
          _optionalDouble(perf, 'average_return_percent') ??
          _optionalDouble(json, 'average_return') ??
          _optionalDouble(json, 'avg_return'),
      experienceYears: (json['experience_years'] as num?)?.toInt() ?? 0,
    );
  }

  static List<String> _stringList(dynamic v) =>
      (v as List?)?.whereType<String>().toList() ?? const [];

  static String? _nonEmptyString(dynamic value) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? null : text;
  }

  static int? _optionalInt(Map<String, dynamic> map, String key) {
    if (!map.containsKey(key) || map[key] == null) return null;
    final value = map[key];
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _optionalDouble(Map<String, dynamic> map, String key) {
    if (!map.containsKey(key) || map[key] == null) return null;
    final value = map[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
