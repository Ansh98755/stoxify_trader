import 'package:equatable/equatable.dart';

sealed class SavedTradesEvent extends Equatable {
  const SavedTradesEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Initial load or manual refresh.
final class SavedTradesStarted extends SavedTradesEvent {
  const SavedTradesStarted();
}

/// Pull-to-refresh.
final class SavedTradesRefreshed extends SavedTradesEvent {
  const SavedTradesRefreshed();
}

/// Remove a trade from saved list.
final class SavedTradeRemoved extends SavedTradesEvent {
  const SavedTradeRemoved(this.tradeId);

  final String tradeId;

  @override
  List<Object?> get props => <Object?>[tradeId];
}

/// Clears removeSuccess / removeError after page shows the flushbar.
final class SavedTradesClearFeedback extends SavedTradesEvent {
  const SavedTradesClearFeedback();
}
