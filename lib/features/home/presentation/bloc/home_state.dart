import 'package:equatable/equatable.dart';

import '../../../../../shared/models/trading_card_data.dart';
import '../../domain/entities/home_subscription.dart';
import '../../domain/entities/home_trade.dart';
import '../widgets/home_subscriptions_strip.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.greetingName = 'there',
    this.trades = const <HomeTrade>[],
    this.cards = const <TradingCardData>[],
    this.subscriptions = const <HomeSubscriptionItem>[],
    this.rawSubscriptions = const <HomeSubscription>[],
    this.page = 1,
    this.hasMore = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.unreadNotifications = 0,
    this.errorMessage,
    this.query = '',
    this.filterSegment = 'All',
    this.sort = 'Newest',
    this.savedTradeIds = const <String>{},
    this.saveTradeSuccess,
    this.saveTradeError,
    this.savingTradeId,
    this.isNewUser = false,
  });

  final HomeStatus status;
  final String greetingName;
  final List<HomeTrade> trades;
  final List<TradingCardData> cards;
  final List<HomeSubscriptionItem> subscriptions;
  final List<HomeSubscription> rawSubscriptions;
  final int page;
  final bool hasMore;
  final bool isRefreshing;
  final bool isLoadingMore;
  final int unreadNotifications;
  final String? errorMessage;
  final String query;
  final String filterSegment;
  final String sort;
  final Set<String> savedTradeIds;

  /// Non-null after a successful save (true) or unsave (false) API call.
  /// The page listens for this to show a flushbar, then clears it.
  final bool? saveTradeSuccess;

  /// Non-null when the save/unsave API call fails. Contains the error message.
  final String? saveTradeError;

  /// Non-null while the save/unsave API call is in flight for a specific trade.
  final String? savingTradeId;

  /// True for the current signed-in new-user session.
  final bool isNewUser;

  bool get isLoading => status == HomeStatus.loading && cards.isEmpty;
  bool get hasUnreadNotifications => unreadNotifications > 0;

  HomeState copyWith({
    HomeStatus? status,
    String? greetingName,
    List<HomeTrade>? trades,
    List<TradingCardData>? cards,
    List<HomeSubscriptionItem>? subscriptions,
    List<HomeSubscription>? rawSubscriptions,
    int? page,
    bool? hasMore,
    bool? isRefreshing,
    bool? isLoadingMore,
    int? unreadNotifications,
    String? errorMessage,
    bool clearError = false,
    String? query,
    String? filterSegment,
    String? sort,
    Set<String>? savedTradeIds,
    bool? saveTradeSuccess,
    bool clearSaveTradeSuccess = false,
    String? saveTradeError,
    bool clearSaveTradeError = false,
    String? savingTradeId,
    bool clearSavingTradeId = false,
    bool? isNewUser,
  }) {
    return HomeState(
      status: status ?? this.status,
      greetingName: greetingName ?? this.greetingName,
      trades: trades ?? this.trades,
      cards: cards ?? this.cards,
      subscriptions: subscriptions ?? this.subscriptions,
      rawSubscriptions: rawSubscriptions ?? this.rawSubscriptions,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      query: query ?? this.query,
      filterSegment: filterSegment ?? this.filterSegment,
      sort: sort ?? this.sort,
      savedTradeIds: savedTradeIds ?? this.savedTradeIds,
      saveTradeSuccess: clearSaveTradeSuccess
          ? null
          : (saveTradeSuccess ?? this.saveTradeSuccess),
      saveTradeError: clearSaveTradeError
          ? null
          : (saveTradeError ?? this.saveTradeError),
      savingTradeId: clearSavingTradeId
          ? null
          : (savingTradeId ?? this.savingTradeId),
      isNewUser: isNewUser ?? this.isNewUser,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        greetingName,
        trades,
        cards,
        subscriptions,
        rawSubscriptions,
        page,
        hasMore,
        isRefreshing,
        isLoadingMore,
        unreadNotifications,
        errorMessage,
        query,
        filterSegment,
        sort,
        savedTradeIds,
        saveTradeSuccess,
        saveTradeError,
        savingTradeId,
        isNewUser,
      ];
}
