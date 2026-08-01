import '../../data/models/discover_analyst_model.dart';
import '../../data/models/discover_batch_model.dart';
import '../../data/models/discover_facets_model.dart';

enum DiscoverStatus { initial, loading, success, failure }

class DiscoverState {
  const DiscoverState({
    this.status = DiscoverStatus.initial,
    this.analysts = const [],
    this.batches = const [],
    this.analystFacets,
    this.planFacets,
    this.error,
  });

  final DiscoverStatus status;
  final List<DiscoverAnalystModel> analysts;
  final List<DiscoverBatchModel> batches;
  final DiscoverAnalystFacets? analystFacets;
  final DiscoverPlanFacets? planFacets;
  final String? error;

  DiscoverState copyWith({
    DiscoverStatus? status,
    List<DiscoverAnalystModel>? analysts,
    List<DiscoverBatchModel>? batches,
    DiscoverAnalystFacets? analystFacets,
    DiscoverPlanFacets? planFacets,
    String? error,
  }) {
    return DiscoverState(
      status: status ?? this.status,
      analysts: analysts ?? this.analysts,
      batches: batches ?? this.batches,
      analystFacets: analystFacets ?? this.analystFacets,
      planFacets: planFacets ?? this.planFacets,
      error: error,
    );
  }
}
