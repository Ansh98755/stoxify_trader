import 'package:equatable/equatable.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

final class HomeRefreshed extends HomeEvent {
  const HomeRefreshed();
}

final class HomeLoadMoreRequested extends HomeEvent {
  const HomeLoadMoreRequested();
}

final class HomeSearchChanged extends HomeEvent {
  const HomeSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => <Object?>[query];
}

final class HomeFiltersChanged extends HomeEvent {
  const HomeFiltersChanged({
    required this.segment,
    required this.sort,
  });

  final String segment;
  final String sort;

  @override
  List<Object?> get props => <Object?>[segment, sort];
}

final class HomeLivePricesUpdated extends HomeEvent {
  const HomeLivePricesUpdated(this.prices);

  final Map<String, double> prices;

  @override
  List<Object?> get props => <Object?>[prices];
}

final class HomeNotificationReceived extends HomeEvent {
  const HomeNotificationReceived(this.payload);

  final Map<String, dynamic> payload;

  @override
  List<Object?> get props => <Object?>[payload];
}

final class HomeNotificationsOpened extends HomeEvent {
  const HomeNotificationsOpened();
}

final class HomeTradeToggleSaved extends HomeEvent {
  const HomeTradeToggleSaved(this.tradeId);

  final String tradeId;

  @override
  List<Object?> get props => <Object?>[tradeId];
}

/// Clears saveTradeSuccess / saveTradeError after the page has shown the flushbar.
final class HomeClearSaveFeedback extends HomeEvent {
  const HomeClearSaveFeedback();
}
