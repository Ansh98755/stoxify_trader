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
  int _requestEpoch = 0;

  Future<void> _onLoadRequested(
    DiscoverLoadRequested event,
    Emitter<DiscoverState> emit,
  ) async {
    final request = ++_requestEpoch;
    // Guard — skip network call if data is already loaded and this is not
    // a manual refresh. The repository cache (SWR) handles background
    // revalidation on subsequent fetches.
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
        forceRefresh: event.isRefresh,
      );
      final facetsFuture = state.analystFacets == null || event.isRefresh
          ? _repository.fetchAnalystFacets(forceRefresh: event.isRefresh)
          : Future.value(state.analystFacets!);

      final analysts = await analystsFuture;
      DiscoverAnalystFacets? facets;
      try {
        facets = await facetsFuture;
      } catch (_) {
        facets = state.analystFacets;
      }
      if (request != _requestEpoch) return;
      emit(
        state.copyWith(
          status: DiscoverStatus.success,
          analysts: analysts,
          analystFacets: facets,
        ),
      );
    } catch (e) {
      if (request != _requestEpoch) return;
      emit(state.copyWith(status: DiscoverStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onBatchesLoadRequested(
    DiscoverBatchesLoadRequested event,
    Emitter<DiscoverState> emit,
  ) async {
    final request = ++_requestEpoch;
    // Guard — skip network call if data is already loaded and this is not
    // a manual refresh.
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
        forceRefresh: event.isRefresh,
      );
      final facetsFuture = state.planFacets == null || event.isRefresh
          ? _repository.fetchPlanFacets(forceRefresh: event.isRefresh)
          : Future.value(state.planFacets!);
      final batches = await batchesFuture;
      DiscoverPlanFacets? facets;
      try {
        facets = await facetsFuture;
      } catch (_) {
        facets = state.planFacets;
      }
      if (request != _requestEpoch) return;
      emit(
        state.copyWith(
          status: DiscoverStatus.success,
          batches: batches,
          planFacets: facets,
        ),
      );
    } catch (e) {
      if (request != _requestEpoch) return;
      emit(state.copyWith(status: DiscoverStatus.failure, error: e.toString()));
    }
  }
}
