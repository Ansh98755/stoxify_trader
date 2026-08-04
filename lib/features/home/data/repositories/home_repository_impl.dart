import '../../../../core/cache/in_memory_cache.dart';
import '../../domain/entities/home_subscription.dart';
import '../../domain/entities/home_trade.dart';
import '../../domain/entities/payment_transaction.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';

// ── TTL constants ─────────────────────────────────────────────────────────────
// Subscriptions change only on purchase / cancellation — 5 min is generous.
// Saved trade IDs change on user action — updated locally after mutations.
// Analyst-specific feed (LIVE,CLOSED trades for a given analyst) — 5 min.
// These trades don't change in real-time like the home feed does.

const _ttlSubscriptions = Duration(minutes: 5);
const _ttlSavedIds = Duration(minutes: 5);
const _ttlAnalystFeed = Duration(minutes: 5);

// Keyed by analystId + page + status so different callers don't collide.
String _analystFeedKey(String analystId, int page, String status) =>
    'feed|$analystId|p$page|$status';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._remote);

  final HomeRemoteDataSource _remote;

  final _subscriptionsCache =
      InMemoryCache<String, List<HomeSubscription>>();
  final _savedIdsCache = InMemoryCache<String, Set<String>>();

  // Only analyst-scoped feed pages are cached. The main home feed (no
  // analystId) is always live and must never be cached.
  final _analystFeedCache = InMemoryCache<String, HomeFeedPage>();

  static const _kSubscriptions = 'subscriptions';
  static const _kSavedIds = 'saved_ids';

  // ── Feed ──────────────────────────────────────────────────────────────────

  @override
  Future<HomeFeedPage> fetchFeed({
    required int page,
    String? segment,
    String status = 'LIVE',
    String? analystId,
  }) {
    // Only cache analyst-scoped requests (detail screens).
    // The main home feed has no analystId and must always be fresh.
    if (analystId != null && analystId.isNotEmpty) {
      final key = _analystFeedKey(analystId, page, status);
      return _analystFeedCache.get(
        key: key,
        ttl: _ttlAnalystFeed,
        fetch: () => _remote.fetchFeed(
          page: page,
          segment: segment,
          status: status,
          analystId: analystId,
        ),
      );
    }

    // No analystId — home feed, always live.
    return _remote.fetchFeed(
      page: page,
      segment: segment,
      status: status,
    );
  }

  @override
  Future<HomeTrade> fetchTrade(String tradeId) {
    // Individual trade detail — always fresh (price/status change frequently).
    return _remote.fetchTrade(tradeId);
  }

  // ── Subscriptions — cached ────────────────────────────────────────────────

  @override
  Future<List<HomeSubscription>> fetchSubscriptions() {
    return _subscriptionsCache.get(
      key: _kSubscriptions,
      ttl: _ttlSubscriptions,
      fetch: _remote.fetchSubscriptions,
    );
  }

  @override
  Future<List<PaymentTransaction>> fetchPaymentTransactions() =>
      _remote.fetchPaymentTransactions();

  // ── Saved trades — cached with local mutation ─────────────────────────────

  @override
  Future<Set<String>> fetchSavedTradeIds() {
    return _savedIdsCache.get(
      key: _kSavedIds,
      ttl: _ttlSavedIds,
      fetch: _remote.fetchSavedTradeIds,
    );
  }

  @override
  Future<bool> saveTrade(String tradeId) async {
    final result = await _remote.saveTrade(tradeId);
    if (result) {
      final current = _savedIdsCache.contains(_kSavedIds)
          ? await fetchSavedTradeIds()
          : <String>{};
      _savedIdsCache.write(
        _kSavedIds,
        {...current, tradeId},
        ttl: _ttlSavedIds,
      );
    }
    return result;
  }

  @override
  Future<bool> unsaveTrade(String tradeId) async {
    final result = await _remote.unsaveTrade(tradeId);
    if (result) {
      final current = _savedIdsCache.contains(_kSavedIds)
          ? await fetchSavedTradeIds()
          : <String>{};
      _savedIdsCache.write(
        _kSavedIds,
        current.where((id) => id != tradeId).toSet(),
        ttl: _ttlSavedIds,
      );
    }
    return result;
  }

  @override
  Future<List<HomeTrade>> fetchSavedTrades() {
    return _remote.fetchSavedTrades();
  }

  // ── Cache management ──────────────────────────────────────────────────────

  @override
  void invalidateSubscriptions() {
    _subscriptionsCache.invalidate(_kSubscriptions);
  }

  @override
  void invalidateSavedIds() {
    _savedIdsCache.invalidate(_kSavedIds);
  }

  /// Invalidates all cached feed pages for a specific analyst — call when a
  /// new trade is published by that analyst via WebSocket.
  void invalidateAnalystFeed(String analystId) {
    _analystFeedCache.invalidateWhere(
      (key) => key.startsWith('feed|$analystId|'),
    );
  }

  @override
  void clearAll() {
    _subscriptionsCache.clear();
    _savedIdsCache.clear();
    _analystFeedCache.clear();
  }
}
