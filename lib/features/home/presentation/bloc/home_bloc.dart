import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/live_prices_service.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/home_subscription.dart';
import '../../../../../shared/models/trading_card_data.dart';
import '../../domain/entities/home_trade.dart';
import '../../domain/repositories/home_repository.dart';
import '../mappers/home_ui_mapper.dart';
import '../widgets/home_subscriptions_strip.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required HomeRepository repository,
    required AuthRepository authRepository,
    required LivePricesService livePrices,
    required WebSocketService webSocket,
  })  : _repository = repository,
        _authRepository = authRepository,
        _livePrices = livePrices,
        _webSocket = webSocket,
        super(const HomeState()) {
    on<HomeStarted>(_onStarted);
    on<HomeRefreshed>(_onRefreshed);
    on<HomeLoadMoreRequested>(_onLoadMore);
    on<HomeSearchChanged>(_onSearchChanged);
    on<HomeFiltersChanged>(_onFiltersChanged);
    on<HomeLivePricesUpdated>(_onLivePricesUpdated);
    on<HomeNotificationReceived>(_onNotificationReceived);
    on<HomeNotificationsOpened>(_onNotificationsOpened);
    on<HomeTradeToggleSaved>(_onToggleSaved);
    on<HomeClearSaveFeedback>(_onClearSaveFeedback);
  }

  final HomeRepository _repository;
  final AuthRepository _authRepository;
  final LivePricesService _livePrices;
  final WebSocketService _webSocket;

  StreamSubscription<Map<String, double>>? _pricesSub;
  StreamSubscription<Map<String, dynamic>>? _notifSub;

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.loading, clearError: true));
    unawaited(_webSocket.connect());
    await _loadInitial(emit, includeProfile: true);
    _livePrices.start();
    _bindLiveStreams();
  }

  Future<void> _onRefreshed(
    HomeRefreshed event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, clearError: true));
    unawaited(_webSocket.connect());
    await _loadInitial(emit, includeProfile: false);
    _bindLiveStreams();
  }

  void _bindLiveStreams() {
    _pricesSub ??= _livePrices.pricesStream.listen((prices) {
      if (!isClosed) add(HomeLivePricesUpdated(prices));
    });
    _notifSub ??= _webSocket.notificationUpdates.listen((data) {
      if (!isClosed) add(HomeNotificationReceived(data));
    });
  }

  Future<void> _loadInitial(
    Emitter<HomeState> emit, {
    required bool includeProfile,
  }) async {
    try {
      final apiSegment = mapFilterSegmentToApi(state.filterSegment);
      final feedFuture = _repository.fetchFeed(page: 1, segment: apiSegment);
      final subsFuture = _repository.fetchSubscriptions();
      final savedIdsFuture = _repository.fetchSavedTradeIds();
      final profileFuture =
          includeProfile ? _authRepository.getMe() : null;

      final feed = await feedFuture;
      final subs = await subsFuture;
      final savedIds = await savedIdsFuture;
      final profile = profileFuture == null ? null : await profileFuture;

      var activeTrades =
          feed.trades.where((HomeTrade t) => t.state.isLive).toList();
      if (activeTrades.isEmpty && feed.trades.isNotEmpty) {
        activeTrades = feed.trades;
      }
      activeTrades = _mergeLivePrices(activeTrades, _livePrices.current);
      _trackSymbols(activeTrades);

      emit(
        state.copyWith(
          status: HomeStatus.success,
          greetingName: profile?.firstName ?? state.greetingName,
          trades: activeTrades,
          cards: _applyLocalFilters(
            activeTrades,
            query: state.query,
            segment: state.filterSegment,
            sort: state.sort,
            savedIds: savedIds,
          ),
          subscriptions: _mapSubscriptions(subs),
          rawSubscriptions: subs,
          page: feed.page,
          hasMore: feed.hasMore,
          isRefreshing: false,
          clearError: true,
          savedTradeIds: savedIds,
        ),
      );
    } catch (e) {
      final keepData = state.cards.isNotEmpty;
      emit(
        state.copyWith(
          status: keepData ? HomeStatus.success : HomeStatus.failure,
          isRefreshing: false,
          errorMessage: _messageOf(e),
        ),
      );
    }
  }

  Future<void> _onLoadMore(
    HomeLoadMoreRequested event,
    Emitter<HomeState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final nextPage = state.page + 1;
      final apiSegment = mapFilterSegmentToApi(state.filterSegment);
      final feed = await _repository.fetchFeed(
        page: nextPage,
        segment: apiSegment,
      );
      var incomingTrades =
          feed.trades.where((HomeTrade t) => t.state.isLive).toList();
      if (incomingTrades.isEmpty && feed.trades.isNotEmpty) {
        incomingTrades = feed.trades;
      }
      final merged = _mergeLivePrices(
        <HomeTrade>[...state.trades, ...incomingTrades],
        _livePrices.current,
      );
      _trackSymbols(merged);
      emit(
        state.copyWith(
          trades: merged,
          cards: _applyLocalFilters(
            merged,
            query: state.query,
            segment: state.filterSegment,
            sort: state.sort,
            savedIds: state.savedTradeIds,
          ),
          page: feed.page,
          hasMore: feed.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingMore: false,
          errorMessage: _messageOf(e),
        ),
      );
    }
  }

  void _onSearchChanged(HomeSearchChanged event, Emitter<HomeState> emit) {
    emit(
      state.copyWith(
        query: event.query,
        cards: _applyLocalFilters(
          state.trades,
          query: event.query,
          segment: state.filterSegment,
          sort: state.sort,
          savedIds: state.savedTradeIds,
        ),
      ),
    );
  }

  Future<void> _onFiltersChanged(
    HomeFiltersChanged event,
    Emitter<HomeState> emit,
  ) async {
    final previousApi = mapFilterSegmentToApi(state.filterSegment);
    final nextApi = mapFilterSegmentToApi(event.segment);

    emit(
      state.copyWith(
        filterSegment: event.segment,
        sort: event.sort,
      ),
    );

    if (previousApi != nextApi) {
      emit(state.copyWith(status: HomeStatus.loading, clearError: true));
      await _loadInitial(emit, includeProfile: false);
      return;
    }

    emit(
      state.copyWith(
        cards: _applyLocalFilters(
          state.trades,
          query: state.query,
          segment: event.segment,
          sort: event.sort,
          savedIds: state.savedTradeIds,
        ),
      ),
    );
  }

  void _onLivePricesUpdated(
    HomeLivePricesUpdated event,
    Emitter<HomeState> emit,
  ) {
    if (state.trades.isEmpty) return;
    final merged = _mergeLivePrices(state.trades, event.prices);
    emit(
      state.copyWith(
        trades: merged,
        cards: _applyLocalFilters(
          merged,
          query: state.query,
          segment: state.filterSegment,
          sort: state.sort,
          savedIds: state.savedTradeIds,
        ),
      ),
    );
  }

  Future<void> _onNotificationReceived(
    HomeNotificationReceived event,
    Emitter<HomeState> emit,
  ) async {
    emit(
      state.copyWith(unreadNotifications: state.unreadNotifications + 1),
    );
    final type = (event.payload['type'] as String?) ?? '';
    if (type.startsWith('TRADE_')) {
      await _loadInitial(emit, includeProfile: false);
    }
  }

  void _onNotificationsOpened(
    HomeNotificationsOpened event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(unreadNotifications: 0));
  }

  Future<void> _onToggleSaved(
    HomeTradeToggleSaved event,
    Emitter<HomeState> emit,
  ) async {
    final wasSaved = state.savedTradeIds.contains(event.tradeId);

    // Optimistic update — flip UI immediately.
    final optimistic = Set<String>.from(state.savedTradeIds);
    if (wasSaved) {
      optimistic.remove(event.tradeId);
    } else {
      optimistic.add(event.tradeId);
    }
    emit(state.copyWith(
      savedTradeIds: optimistic,
      cards: _applyLocalFilters(
        state.trades,
        query: state.query,
        segment: state.filterSegment,
        sort: state.sort,
        savedIds: optimistic,
      ),
    ));

    try {
      if (wasSaved) {
        await _repository.unsaveTrade(event.tradeId);
      } else {
        await _repository.saveTrade(event.tradeId);
      }
      emit(state.copyWith(
        saveTradeSuccess: !wasSaved,
        saveTradeError: null,
      ));
    } catch (_) {
      // Rollback optimistic update on failure.
      final rolledBack = Set<String>.from(state.savedTradeIds);
      if (wasSaved) {
        rolledBack.add(event.tradeId);
      } else {
        rolledBack.remove(event.tradeId);
      }
      emit(state.copyWith(
        savedTradeIds: rolledBack,
        cards: _applyLocalFilters(
          state.trades,
          query: state.query,
          segment: state.filterSegment,
          sort: state.sort,
          savedIds: rolledBack,
        ),
        saveTradeError: wasSaved
            ? 'Failed to remove trade. Please try again.'
            : 'Failed to save trade. Please try again.',
      ));
    }
  }

  void _onClearSaveFeedback(
    HomeClearSaveFeedback event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(
      clearSaveTradeSuccess: true,
      clearSaveTradeError: true,
    ));
  }

  void _trackSymbols(List<HomeTrade> trades) {
    final symbols = <String>{};
    for (final t in trades) {
      if (!t.state.isLive) continue;
      if (t.symbol.contains(' / ')) {
        for (final part in t.symbol.split(' / ')) {
          final s = part.trim();
          if (s.isNotEmpty) symbols.add(s);
        }
      } else {
        symbols.add(t.symbol);
      }
    }
    _livePrices.track(symbols);
  }

  List<HomeTrade> _mergeLivePrices(
    List<HomeTrade> trades,
    Map<String, double> prices,
  ) {
    if (prices.isEmpty) return trades;
    return trades.map((t) {
      if (!t.state.isLive) return t;
      double? price = prices[t.symbol];
      if (price == null && t.symbol.contains(' / ')) {
        price = prices[t.symbol.split(' / ').first.trim()];
      }
      return price == null ? t : t.copyWith(ltp: price);
    }).toList();
  }

  List<HomeSubscriptionItem> _mapSubscriptions(List<HomeSubscription> subs) {
    final active = subs.where((s) => s.isActive).toList();
    final source = active.isNotEmpty ? active : subs;
    return source.map(mapHomeSubscriptionToItem).toList();
  }

  String _messageOf(Object e) {
    final raw = e.toString();
    return raw.replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  @override
  Future<void> close() {
    _pricesSub?.cancel();
    _notifSub?.cancel();
    return super.close();
  }
}

List<TradingCardData> _applyLocalFilters(
  List<HomeTrade> trades, {
  required String query,
  required String segment,
  required String sort,
  Set<String> savedIds = const <String>{},
}) {
  final q = query.trim().toLowerCase();
  final cards = trades
      .map((t) => mapHomeTradeToCard(t, savedIds: savedIds))
      .toList();
  final filtered = <TradingCardData>[];

  for (var i = 0; i < trades.length; i++) {
    final trade = trades[i];
    final card = cards[i];

    final matchesQuery = q.isEmpty ||
        card.symbol.toLowerCase().contains(q) ||
        (card.batchName?.toLowerCase().contains(q) ?? false) ||
        (card.segment?.toLowerCase().contains(q) ?? false) ||
        (card.asset?.toLowerCase().contains(q) ?? false);

    final matchesSegment = segment == 'All' ||
        card.segment == segment ||
        card.asset == segment ||
        trade.categoryLabel == segment ||
        trade.segmentLabel == segment;

    if (matchesQuery && matchesSegment) {
      filtered.add(card);
    }
  }

  switch (sort) {
    case 'In profit':
      filtered.sort((a, b) {
        final aProfit =
            a.tradeStatus?.toLowerCase().contains('profit') == true;
        final bProfit =
            b.tradeStatus?.toLowerCase().contains('profit') == true;
        if (aProfit == bProfit) return 0;
        return aProfit ? -1 : 1;
      });
    case 'Symbol A–Z':
      filtered.sort(
        (a, b) => a.symbol.toLowerCase().compareTo(b.symbol.toLowerCase()),
      );
    default:
      break;
  }

  return filtered;
}
