abstract class DiscoverEvent {
  const DiscoverEvent();
}

class DiscoverLoadRequested extends DiscoverEvent {
  const DiscoverLoadRequested({
    this.search,
    this.segment,
    this.horizon,
    this.sort,
    this.isRefresh = false,
  });

  final String? search;
  final String? segment;
  final String? horizon;
  final String? sort;
  final bool isRefresh;
}

class DiscoverBatchesLoadRequested extends DiscoverEvent {
  const DiscoverBatchesLoadRequested({
    this.search,
    this.segment,
    this.horizon,
    this.riskLevel,
    this.sort,
    this.isRefresh = false,
  });

  final String? search;
  final String? segment;
  final String? horizon;
  final String? riskLevel;
  final String? sort;
  final bool isRefresh;
}
