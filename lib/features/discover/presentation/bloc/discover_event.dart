abstract class DiscoverEvent {
  const DiscoverEvent();
}

class DiscoverLoadRequested extends DiscoverEvent {
  const DiscoverLoadRequested({
    this.search,
    this.segment,
    this.sort,
  });

  final String? search;
  final String? segment;
  final String? sort;
}

class DiscoverBatchesLoadRequested extends DiscoverEvent {
  const DiscoverBatchesLoadRequested({
    this.search,
    this.segment,
    this.sort,
  });

  final String? search;
  final String? segment;
  final String? sort;
}
