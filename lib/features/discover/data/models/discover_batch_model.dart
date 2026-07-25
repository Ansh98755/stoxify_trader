class DiscoverBatchTierModel {
  const DiscoverBatchTierModel({
    required this.id,
    required this.price,
    this.discountedPrice,
    this.isActive = true,
  });

  final String id;
  final double price;
  final double? discountedPrice;
  final bool isActive;

  double get effectivePrice => discountedPrice ?? price;

  factory DiscoverBatchTierModel.fromJson(Map<String, dynamic> json) =>
      DiscoverBatchTierModel(
        id: json['batch_id'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        discountedPrice: (json['discounted_price'] as num?)?.toDouble(),
        isActive: json['is_active'] as bool? ?? true,
      );
}

class DiscoverBatchModel {
  const DiscoverBatchModel({
    required this.planId,
    required this.analystId,
    required this.analystName,
    required this.name,
    this.description,
    this.price = 0,
    this.riskLevel,
    this.segments = const [],
    this.tiers = const [],
    this.subscriberCount,
    this.analystSebiNumber,
  });

  final String planId;
  final String analystId;
  final String analystName;
  final String name;
  final String? description;
  final String? analystSebiNumber;
  final double price;
  final String? riskLevel;
  final List<String> segments;
  final List<DiscoverBatchTierModel> tiers;
  final int? subscriberCount;

  DiscoverBatchTierModel? get cheapestTier {
    final active = tiers.where((t) => t.isActive).toList();
    if (active.isEmpty) return null;
    active.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
    return active.first;
  }

  double get startingPrice => cheapestTier?.effectivePrice ?? price;

  factory DiscoverBatchModel.fromJson(Map<String, dynamic> json) =>
      DiscoverBatchModel(
        planId: json['plan_id'] as String,
        analystId: json['analyst_id'] as String? ?? '',
        analystName: json['analyst_name'] as String? ?? 'Analyst',
        name: json['name'] as String? ?? 'Plan',
        description: json['description'] as String?,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        riskLevel: json['risk_level'] as String?,
        segments: _stringList(json['segments']),
        tiers: (json['batches'] as List?)
                ?.whereType<Map>()
                .map((e) => DiscoverBatchTierModel.fromJson(e.cast<String, dynamic>()))
                .toList() ??
            const [],
        subscriberCount: (json['subscriber_count'] as num?)?.toInt(),
        analystSebiNumber: json['sebi_license_number'] as String?,
      );

  static List<String> _stringList(dynamic v) =>
      (v as List?)?.whereType<String>().toList() ?? const [];
}
