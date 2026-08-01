class DiscoverFacetOption {
  const DiscoverFacetOption({required this.value, required this.count});

  final String value;
  final int count;

  factory DiscoverFacetOption.fromJson(Map<String, dynamic> json) {
    return DiscoverFacetOption(
      value: json['value'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class DiscoverAnalystFacets {
  const DiscoverAnalystFacets({
    this.segments = const <DiscoverFacetOption>[],
    this.horizons = const <DiscoverFacetOption>[],
  });

  final List<DiscoverFacetOption> segments;
  final List<DiscoverFacetOption> horizons;

  factory DiscoverAnalystFacets.fromJson(Map<String, dynamic> json) {
    List<DiscoverFacetOption> parse(dynamic raw) {
      return (raw as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (item) =>
                DiscoverFacetOption.fromJson(item.cast<String, dynamic>()),
          )
          .where((item) => item.value.isNotEmpty)
          .toList();
    }

    return DiscoverAnalystFacets(
      segments: parse(json['segments']),
      horizons: parse(json['horizons']),
    );
  }
}

class DiscoverPlanFacets {
  const DiscoverPlanFacets({
    this.segments = const <DiscoverFacetOption>[],
    this.riskLevels = const <DiscoverFacetOption>[],
    this.horizons = const <DiscoverFacetOption>[],
  });

  final List<DiscoverFacetOption> segments;
  final List<DiscoverFacetOption> riskLevels;
  final List<DiscoverFacetOption> horizons;

  factory DiscoverPlanFacets.fromJson(Map<String, dynamic> json) {
    List<DiscoverFacetOption> parse(dynamic raw) {
      return (raw as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (item) =>
                DiscoverFacetOption.fromJson(item.cast<String, dynamic>()),
          )
          .where((item) => item.value.isNotEmpty)
          .toList();
    }

    return DiscoverPlanFacets(
      segments: parse(json['segments']),
      riskLevels: parse(json['risk_levels']),
      horizons: parse(json['horizons']),
    );
  }
}
