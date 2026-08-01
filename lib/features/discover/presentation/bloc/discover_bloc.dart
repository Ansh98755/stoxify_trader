import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/discover_facets_model.dart';
import '../../domain/repositories/discover_repository.dart';
import 'discover_event.dart';
import 'discover_state.dart';

class DiscoverBloc extends Bloc<DiscoverEvent, DiscoverState> {
  DiscoverBloc({required DiscoverRepository repository})
    : _repository = repository,
      super(const DiscoverState()) {
    on<DiscoverLoadRequested>(_onLoadRequested);
    on<DiscoverBatchesLoadRequested>(_onBatchesLoadRequested);
  }

  final DiscoverRepository _repository;

  Future<void> _onLoadRequested(
    DiscoverLoadRequested event,
    Emitter<DiscoverState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(state.copyWith(status: DiscoverStatus.loading));
    }
    try {
      final analystsFuture = _repository.fetchAnalysts(
        page: 1,
        search: event.search,
        segment: event.segment,
        horizon: event.horizon,
        sort: event.sort,
      );
      final facetsFuture = state.analystFacets == null
          ? _repository.fetchAnalystFacets()
          : Future.value(state.analystFacets!);

      final analysts = await analystsFuture;
      DiscoverAnalystFacets? facets;
      try {
        facets = await facetsFuture;
      } catch (_) {
        facets = state.analystFacets;
      }
      emit(
        state.copyWith(
          status: DiscoverStatus.success,
          analysts: analysts,
          analystFacets: facets,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: DiscoverStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onBatchesLoadRequested(
    DiscoverBatchesLoadRequested event,
    Emitter<DiscoverState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(state.copyWith(status: DiscoverStatus.loading));
    }
    try {
      final batchesFuture = _repository.fetchBatches(
        page: 1,
        search: event.search,
        segment: event.segment,
        horizon: event.horizon,
        riskLevel: event.riskLevel,
        sort: event.sort,
      );
      final facetsFuture = state.planFacets == null
          ? _repository.fetchPlanFacets()
          : Future.value(state.planFacets!);
      final batches = await batchesFuture;
      DiscoverPlanFacets? facets;
      try {
        facets = await facetsFuture;
      } catch (_) {
        facets = state.planFacets;
      }
      emit(
        state.copyWith(
          status: DiscoverStatus.success,
          batches: batches,
          planFacets: facets,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: DiscoverStatus.failure, error: e.toString()));
    }
  }
}
