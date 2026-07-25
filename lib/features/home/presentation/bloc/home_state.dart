import 'package:equatable/equatable.dart';

import '../../../../core/widgets/common_trading_card.dart';
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
  });

  final HomeStatus status;
  final String greetingName;
  final List<HomeTrade> trades;
  final List<TradingCardData> cards;
  final List<HomeSubscriptionItem> subscriptions;
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

  bool get isLoading => status == HomeStatus.loading && cards.isEmpty;
  bool get hasUnreadNotifications => unreadNotifications > 0;

  HomeState copyWith({
    HomeStatus? status,
    String? greetingName,
    List<HomeTrade>? trades,
    List<TradingCardData>? cards,
    List<HomeSubscriptionItem>? subscriptions,
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
  }) {
    return HomeState(
      status: status ?? this.status,
      greetingName: greetingName ?? this.greetingName,
      trades: trades ?? this.trades,
      cards: cards ?? this.cards,
      subscriptions: subscriptions ?? this.subscriptions,
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
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        greetingName,
        trades,
        cards,
        subscriptions,
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
      ];
}
