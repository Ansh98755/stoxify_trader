import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/home/domain/repositories/home_repository.dart';
import '../../../../features/home/presentation/mappers/home_ui_mapper.dart';
import '../../../../shared/models/trading_card_data.dart';
import 'saved_trades_event.dart';
import 'saved_trades_state.dart';

class SavedTradesBloc extends Bloc<SavedTradesEvent, SavedTradesState> {
  SavedTradesBloc({required HomeRepository repository})
      : _repository = repository,
        super(const SavedTradesState()) {
    on<SavedTradesStarted>(_onStarted);
    on<SavedTradesRefreshed>(_onRefreshed);
    on<SavedTradeRemoved>(_onRemoved);
    on<SavedTradesClearFeedback>(_onClearFeedback);
  }

  final HomeRepository _repository;

  Future<void> _onStarted(
    SavedTradesStarted event,
    Emitter<SavedTradesState> emit,
  ) async {
    emit(state.copyWith(status: SavedTradesStatus.loading, clearError: true));
    await _load(emit);
  }

  Future<void> _onRefreshed(
    SavedTradesRefreshed event,
    Emitter<SavedTradesState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, clearError: true));
    await _load(emit);
  }

  Future<void> _load(Emitter<SavedTradesState> emit) async {
    try {
      final trades = await _repository.fetchSavedTrades();
      final cards = trades
          .map((t) => mapHomeTradeToCard(t, savedIds: <String>{t.id}))
          .toList();
      emit(state.copyWith(
        status: SavedTradesStatus.success,
        trades: trades,
        cards: cards,
        isRefreshing: false,
        clearError: true,
      ));
    } catch (e) {
      final keepData = state.cards.isNotEmpty;
      emit(state.copyWith(
        status: keepData
            ? SavedTradesStatus.success
            : SavedTradesStatus.failure,
        isRefreshing: false,
        errorMessage: _messageOf(e),
      ));
    }
  }

  Future<void> _onRemoved(
    SavedTradeRemoved event,
    Emitter<SavedTradesState> emit,
  ) async {
    // Optimistic remove from both lists.
    final optimisticTrades = state.trades
        .where((t) => t.id != event.tradeId)
        .toList();
    final optimisticCards = state.cards
        .where((c) => c.tradeId != event.tradeId)
        .toList();
    emit(state.copyWith(trades: optimisticTrades, cards: optimisticCards));

    try {
      await _repository.unsaveTrade(event.tradeId);
      emit(state.copyWith(removeSuccess: true));
    } catch (_) {
      // Rollback — reload the full list from backend.
      await _load(emit);
      emit(state.copyWith(
        removeError: 'Failed to remove trade. Please try again.',
      ));
    }
  }

  void _onClearFeedback(
    SavedTradesClearFeedback event,
    Emitter<SavedTradesState> emit,
  ) {
    emit(state.copyWith(
      clearRemoveSuccess: true,
      clearRemoveError: true,
    ));
  }

  String _messageOf(Object e) {
    final raw = e.toString();
    return raw.replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}
