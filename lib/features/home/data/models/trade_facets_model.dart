class TradeFacetOption {
  const TradeFacetOption({required this.value, required this.count});

  final String value;
  final int count;

  factory TradeFacetOption.fromJson(Map<String, dynamic> json) {
    return TradeFacetOption(
      value: (json['value'] as String? ?? '').trim(),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Facets from `GET /trades/facets` used by the home feed filter dialog.
class TradeFacets {
  const TradeFacets({
    this.segments = const <TradeFacetOption>[],
    this.statuses = const <TradeFacetOption>[],
    this.categories = const <TradeFacetOption>[],
  });

  final List<TradeFacetOption> segments;
  final List<TradeFacetOption> statuses;
  final List<TradeFacetOption> categories;

  factory TradeFacets.fromJson(Map<String, dynamic> json) {
    List<TradeFacetOption> parse(dynamic raw) {
      return (raw as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (item) => TradeFacetOption.fromJson(item.cast<String, dynamic>()),
          )
          .where((item) => item.value.isNotEmpty)
          .toList();
    }

    return TradeFacets(
      segments: parse(json['segments']),
      statuses: parse(json['statuses']),
      categories: parse(json['categories']),
    );
  }
}
