import 'package:flutter_bloc/flutter_bloc.dart';
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
    emit(state.copyWith(status: DiscoverStatus.loading));
    try {
      final analysts = await _repository.fetchAnalysts(
        page: 1,
        search: event.search,
        segment: event.segment,
        sort: event.sort,
      );
      emit(state.copyWith(
        status: DiscoverStatus.success,
        analysts: analysts,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DiscoverStatus.failure,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onBatchesLoadRequested(
    DiscoverBatchesLoadRequested event,
    Emitter<DiscoverState> emit,
  ) async {
    emit(state.copyWith(status: DiscoverStatus.loading));
    try {
      final batches = await _repository.fetchBatches(
        page: 1,
        search: event.search,
        segment: event.segment,
        sort: event.sort,
      );
      emit(state.copyWith(
        status: DiscoverStatus.success,
        batches: batches,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DiscoverStatus.failure,
        error: e.toString(),
      ));
    }
  }
}
