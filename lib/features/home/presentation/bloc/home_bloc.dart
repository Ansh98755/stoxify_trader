import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/live_prices_service.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../notifications/domain/repositories/notifications_repository.dart';
import '../../domain/entities/home_subscription.dart';
import '../../../../../shared/models/trading_card_data.dart';
import '../../data/models/trade_facets_model.dart';
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
    required NotificationsRepository notificationsRepository,
    required SecureStorage storage,
  })  : _repository = repository,
        _authRepository = authRepository,
        _livePrices = livePrices,
        _webSocket = webSocket,
        _notificationsRepository = notificationsRepository,
        _storage = storage,
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
    on<HomeSavedTradeIdsUpdated>(_onSavedTradeIdsUpdated);
    on<HomeClearSaveFeedback>(_onClearSaveFeedback);
    on<HomeLoggedOut>(_onLoggedOut);
  }

  final HomeRepository _repository;
  final AuthRepository _authRepository;
  final LivePricesService _livePrices;
  final WebSocketService _webSocket;
  final NotificationsRepository _notificationsRepository;
  final SecureStorage _storage;

  StreamSubscription<Map<String, double>>? _pricesSub;
  StreamSubscription<Map<String, dynamic>>? _notifSub;

  Future<void> resetForLogout() {
    final completer = Completer<void>();
    add(HomeLoggedOut(completer));
    return completer.future;
  }

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    if (state.status == HomeStatus.loading) return;
    // Keep this flag for the complete signed-in session. The HomeBloc can be
    // started again after visiting Profile, so consuming it once would make
    // the empty state change mid-session.
    final isNewUser = state.isNewUser ||
        (await _storage.read(SecureStorage.isNewUser)) == 'true';

    // Never retain a previous account's values while the next account loads.
    emit(const HomeState());
    emit(state.copyWith(
      status: HomeStatus.loading,
      clearError: true,
      isNewUser: isNewUser,
    ));
    unawaited(_webSocket.connect());
    await _loadInitial(emit, includeProfile: true, loadFacets: true);
    _livePrices.start();
    _bindLiveStreams();
  }

  Future<void> _onRefreshed(
    HomeRefreshed event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, clearError: true));
    // Bust cached data so pull-to-refresh always hits the network.
    _repository.invalidateSubscriptions();
    unawaited(_webSocket.connect());
    await _loadInitial(emit, includeProfile: false, loadFacets: true);
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
    bool loadFacets = false,
  }) async {
    try {
      final segment = joinFilterValues(state.filterSegments);
      final category = joinFilterValues(state.filterCategories);
      final status = resolveFeedStatus(state.filterStatuses);
      final feedFuture = _repository.fetchFeed(
        page: 1,
        segment: segment,
        category: category,
        status: status,
      );
      final subsFuture = _repository.fetchSubscriptions();
      final savedIdsFuture = _repository.fetchSavedTradeIds();
      final unreadCountFuture = _notificationsRepository.fetchUnreadCount();
      final profileFuture =
          includeProfile ? _authRepository.getMe() : null;
      final facetsFuture = loadFacets || state.facets == null
          ? _repository.fetchTradeFacets()
          : null;

      final feed = await feedFuture;
      final subs = await subsFuture;
      final savedIds = await savedIdsFuture;
      final unreadCount = await unreadCountFuture;
      final profile = profileFuture == null ? null : await profileFuture;
      TradeFacets? facets = state.facets;
      if (facetsFuture != null) {
        try {
          facets = await facetsFuture;
        } catch (_) {
          // Facets are optional — keep previously loaded options if any.
        }
      }

      var trades = _normalizeFeedTrades(feed.trades, state.filterStatuses);
      trades = _mergeLivePrices(trades, _livePrices.current);
      _trackSymbols(trades);

      emit(
        state.copyWith(
          status: HomeStatus.success,
          greetingName: profile?.firstName ?? state.greetingName,
          trades: trades,
          cards: _applyLocalFilters(
            trades,
            query: state.query,
            segments: state.filterSegments,
            categories: state.filterCategories,
            statuses: state.filterStatuses,
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
          unreadNotifications: unreadCount,
          isNewUser: state.isNewUser,
          facets: facets,
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
      final feed = await _repository.fetchFeed(
        page: nextPage,
        segment: joinFilterValues(state.filterSegments),
        category: joinFilterValues(state.filterCategories),
        status: resolveFeedStatus(state.filterStatuses),
      );
      final incoming =
          _normalizeFeedTrades(feed.trades, state.filterStatuses);
      final merged = _mergeLivePrices(
        <HomeTrade>[...state.trades, ...incoming],
        _livePrices.current,
      );
      _trackSymbols(merged);
      emit(
        state.copyWith(
          trades: merged,
          cards: _applyLocalFilters(
            merged,
            query: state.query,
            segments: state.filterSegments,
            categories: state.filterCategories,
            statuses: state.filterStatuses,
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
          segments: state.filterSegments,
          categories: state.filterCategories,
          statuses: state.filterStatuses,
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
    final previousKey = _filterKey(
      segments: state.filterSegments,
      categories: state.filterCategories,
      statuses: state.filterStatuses,
    );
    final nextKey = _filterKey(
      segments: event.segments,
      categories: event.categories,
      statuses: event.statuses,
    );

    emit(
      state.copyWith(
        filterSegments: event.segments,
        filterCategories: event.categories,
        filterStatuses: event.statuses,
        sort: event.sort,
      ),
    );

    // Refetch whenever server-side filters change.
    if (previousKey != nextKey) {
      emit(state.copyWith(status: HomeStatus.loading, clearError: true));
      await _loadInitial(emit, includeProfile: false);
      return;
    }

    // Sort-only / local change.
    emit(
      state.copyWith(
        cards: _applyLocalFilters(
          state.trades,
          query: state.query,
          segments: event.segments,
          categories: event.categories,
          statuses: event.statuses,
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
          segments: state.filterSegments,
          categories: state.filterCategories,
          statuses: state.filterStatuses,
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
    // Bust list cache; red-dot only updates from the `read=false` API.
    _notificationsRepository.invalidateOnNewNotification();
    try {
      final unreadCount = await _notificationsRepository.fetchUnreadCount();
      if (!isClosed) {
        emit(state.copyWith(unreadNotifications: unreadCount));
      }
    } catch (_) {
      // Keep previous API-backed value; never invent an unread mark.
    }
    final type = (event.payload['type'] as String?) ?? '';
    if (type.startsWith('TRADE_')) {
      await _loadInitial(emit, includeProfile: false);
    }
  }

  Future<void> _onNotificationsOpened(
    HomeNotificationsOpened event,
    Emitter<HomeState> emit,
  ) async {
    // Red-dot is solely from the unread (`read=false`) API — refresh it.
    // Do not force-clear on navigation, or a stale local 0/1 drifts from truth.
    try {
      final unreadCount = await _notificationsRepository.fetchUnreadCount();
      if (!isClosed) {
        emit(state.copyWith(unreadNotifications: unreadCount));
      }
    } catch (_) {}
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
      savingTradeId: event.tradeId,
      cards: _applyLocalFilters(
        state.trades,
        query: state.query,
        segments: state.filterSegments,
        categories: state.filterCategories,
        statuses: state.filterStatuses,
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
        clearSavingTradeId: true,
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
        clearSavingTradeId: true,
        cards: _applyLocalFilters(
          state.trades,
          query: state.query,
          segments: state.filterSegments,
          categories: state.filterCategories,
          statuses: state.filterStatuses,
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

  void _onSavedTradeIdsUpdated(
    HomeSavedTradeIdsUpdated event,
    Emitter<HomeState> emit,
  ) {
    emit(
      state.copyWith(
        savedTradeIds: event.savedTradeIds,
        cards: _applyLocalFilters(
          state.trades,
          query: state.query,
          segments: state.filterSegments,
          categories: state.filterCategories,
          statuses: state.filterStatuses,
          sort: state.sort,
          savedIds: event.savedTradeIds,
        ),
      ),
    );
  }

  Future<void> _onLoggedOut(
    HomeLoggedOut event,
    Emitter<HomeState> emit,
  ) async {
    await _pricesSub?.cancel();
    _pricesSub = null;
    await _notifSub?.cancel();
    _notifSub = null;
    _repository.invalidateSubscriptions();
    await _livePrices.resetSession();
    _webSocket.disconnect();
    emit(const HomeState());
    event.completer?.complete();
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

String _filterKey({
  required Set<String> segments,
  required Set<String> categories,
  required Set<String> statuses,
}) {
  String pack(Set<String> values) {
    final list = values.map((v) => v.trim().toUpperCase()).toList()..sort();
    return list.join('|');
  }

  return '${pack(segments)}::${pack(categories)}::${pack(statuses)}';
}

/// Prefer server-filtered rows; only tighten to live trades on the default
/// home filter (no status multi-select / live-only).
List<HomeTrade> _normalizeFeedTrades(
  List<HomeTrade> trades,
  Set<String> statuses,
) {
  if (!isLiveOnlyStatusFilter(statuses)) return trades;
  final live = trades.where((HomeTrade t) => t.state.isLive).toList();
  if (live.isEmpty && trades.isNotEmpty) return trades;
  return live;
}

List<TradingCardData> _applyLocalFilters(
  List<HomeTrade> trades, {
  required String query,
  required Set<String> segments,
  required Set<String> categories,
  required Set<String> statuses,
  required String sort,
  Set<String> savedIds = const <String>{},
}) {
  final q = query.trim().toLowerCase();
  final cards = trades
      .map((t) => mapHomeTradeToCard(t, savedIds: savedIds))
      .toList();
  final filtered = <TradingCardData>[];

  final segmentApi = segments
      .map((s) => s.trim().toUpperCase().replaceAll('&', '').replaceAll(' ', ''))
      .where((s) => s.isNotEmpty && s != 'ALL')
      .toSet();
  // Normalize FNO / FO variants.
  if (segmentApi.contains('FO') || segmentApi.contains('F&O')) {
    segmentApi.add('FNO');
  }

  final categoryApi = categories
      .map((s) => s.trim().toUpperCase().replaceAll('-', '_').replaceAll(' ', '_'))
      .where((s) => s.isNotEmpty && s != 'ALL')
      .toSet();

  final statusApi = statuses
      .map((s) => s.trim().toUpperCase())
      .where((s) => s.isNotEmpty && s != 'ALL')
      .toSet();

  for (var i = 0; i < trades.length; i++) {
    final trade = trades[i];
    final card = cards[i];

    final matchesQuery = q.isEmpty ||
        trade.symbol.toLowerCase().contains(q) ||
        (trade.companyName?.toLowerCase().contains(q) ?? false) ||
        card.symbol.toLowerCase().contains(q) ||
        (card.company?.toLowerCase().contains(q) ?? false);

    // Within a group: OR. Across groups: AND.
    final matchesSegment =
        segmentApi.isEmpty || _tradeMatchesSegments(trade, segmentApi);
    final matchesCategory =
        categoryApi.isEmpty || _tradeMatchesCategories(trade, categoryApi);
    final matchesStatus =
        statusApi.isEmpty || _tradeMatchesStatuses(trade, statusApi);

    if (matchesQuery && matchesSegment && matchesCategory && matchesStatus) {
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

bool _tradeMatchesSegments(HomeTrade trade, Set<String> segmentApi) {
  final codes = <String>{
    _tradeSegmentApi(trade),
    trade.segmentLabel.toUpperCase().replaceAll('&', '').replaceAll(' ', ''),
  };
  if (trade.segment == HomeTradeSegment.fno) {
    codes.addAll(<String>{'FNO', 'FO', 'F&O'});
  }
  return segmentApi.any(codes.contains);
}

bool _tradeMatchesCategories(HomeTrade trade, Set<String> categoryApi) {
  final codes = <String>{
    _tradeCategoryApi(trade),
    trade.categoryLabel
        .toUpperCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_'),
  };
  switch (trade.category) {
    case HomeTradeCategory.positional:
      codes.addAll(<String>{'POSITIONAL', 'LONG_TERM', 'LONGTERM'});
    case HomeTradeCategory.swing:
      codes.addAll(<String>{'SWING', 'SHORT_TERM'});
    case HomeTradeCategory.intraday:
      codes.add('INTRADAY');
    case HomeTradeCategory.btst:
      codes.add('BTST');
  }
  return categoryApi.any(codes.contains);
}

bool _tradeMatchesStatuses(HomeTrade trade, Set<String> statusApi) {
  final codes = _tradeStatusCodes(trade);
  return statusApi.any(codes.contains);
}

Set<String> _tradeStatusCodes(HomeTrade trade) {
  return switch (trade.state) {
    HomeTradeState.live => const <String>{
        'LIVE',
        'ACTIVE',
        'OPEN',
        'PUBLISHED',
        'RUNNING',
      },
    HomeTradeState.t1Hit => const <String>{'T1_HIT', 'LIVE'},
    HomeTradeState.t2Hit => const <String>{'T2_HIT', 'LIVE'},
    HomeTradeState.allTargetsHit => const <String>{
        'CLOSED_BY_TARGET',
        'TARGET_HIT',
        'CLOSED',
      },
    HomeTradeState.slHit => const <String>{
        'CLOSED_BY_SL',
        'SL_HIT',
        'CLOSED',
      },
    HomeTradeState.manuallyClosed => const <String>{
        'MANUALLY_CLOSED',
        'CLOSED',
      },
    HomeTradeState.expired => const <String>{'EXPIRED', 'CLOSED'},
  };
}

String _tradeSegmentApi(HomeTrade trade) {
  return switch (trade.segment) {
    HomeTradeSegment.equity => 'EQUITY',
    HomeTradeSegment.fno => 'FNO',
    HomeTradeSegment.commodity => 'COMMODITY',
  };
}

String _tradeCategoryApi(HomeTrade trade) {
  return switch (trade.category) {
    HomeTradeCategory.intraday => 'INTRADAY',
    HomeTradeCategory.swing => 'SWING',
    HomeTradeCategory.positional => 'POSITIONAL',
    HomeTradeCategory.btst => 'BTST',
  };
}
