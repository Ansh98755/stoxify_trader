import 'dart:async';

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
    required this.segments,
    required this.categories,
    required this.statuses,
    required this.sort,
  });

  final Set<String> segments;
  final Set<String> categories;
  final Set<String> statuses;
  final String sort;

  @override
  List<Object?> get props =>
      <Object?>[segments, categories, statuses, sort];
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

/// Syncs bookmark state from another screen (e.g. Trades) without re-calling the API.
final class HomeSavedTradeIdsUpdated extends HomeEvent {
  const HomeSavedTradeIdsUpdated(this.savedTradeIds);

  final Set<String> savedTradeIds;

  @override
  List<Object?> get props => <Object?>[savedTradeIds];
}

/// Clears saveTradeSuccess / saveTradeError after the page has shown the flushbar.
final class HomeClearSaveFeedback extends HomeEvent {
  const HomeClearSaveFeedback();
}

/// Resets all HomeBloc state back to its initial value.
/// Must be dispatched on logout so the next user session starts clean.
final class HomeLoggedOut extends HomeEvent {
  const HomeLoggedOut([this.completer]);

  final Completer<void>? completer;
}
