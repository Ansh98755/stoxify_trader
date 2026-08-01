import 'package:equatable/equatable.dart';

import '../../../../features/home/domain/entities/home_trade.dart';
import '../../../../shared/models/trading_card_data.dart';

enum SavedTradesStatus { initial, loading, success, failure }

class SavedTradesState extends Equatable {
  const SavedTradesState({
    this.status = SavedTradesStatus.initial,
    this.trades = const <HomeTrade>[],
    this.cards = const <TradingCardData>[],
    this.isRefreshing = false,
    this.errorMessage,
    this.removeSuccess = false,
    this.removeError,
  });

  final SavedTradesStatus status;
  final List<HomeTrade> trades;
  final List<TradingCardData> cards;
  final bool isRefreshing;
  final String? errorMessage;

  /// True after a successful unsave — page shows success flushbar.
  final bool removeSuccess;

  /// Non-null after a failed unsave — page shows error flushbar.
  final String? removeError;

  bool get isLoading =>
      status == SavedTradesStatus.loading && cards.isEmpty;

  SavedTradesState copyWith({
    SavedTradesStatus? status,
    List<HomeTrade>? trades,
    List<TradingCardData>? cards,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
    bool? removeSuccess,
    bool clearRemoveSuccess = false,
    String? removeError,
    bool clearRemoveError = false,
  }) {
    return SavedTradesState(
      status: status ?? this.status,
      trades: trades ?? this.trades,
      cards: cards ?? this.cards,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
      removeSuccess: clearRemoveSuccess
          ? false
          : (removeSuccess ?? this.removeSuccess),
      removeError:
          clearRemoveError ? null : (removeError ?? this.removeError),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        trades,
        cards,
        isRefreshing,
        errorMessage,
        removeSuccess,
        removeError,
      ];
}
