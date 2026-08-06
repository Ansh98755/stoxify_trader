import '../../../../core/cache/in_memory_cache.dart';
import '../../domain/repositories/discover_repository.dart';
import '../datasources/discover_remote_data_source.dart';
import '../models/discover_analyst_model.dart';
import '../models/discover_batch_model.dart';
import '../models/discover_facets_model.dart';

// ── TTL constants ────────────────────────────────────────────────────────────
// Facets (segments, horizons) barely change — 30 min is safe.
// Analyst/plan lists change when analysts publish new content — 10 min.
// Individual profiles and plans are fetched per-ID — 10 min.
// Analyst batches list is linked to a specific analyst — 10 min.

const _ttlFacets = Duration(minutes: 30);
const _ttlList = Duration(minutes: 10);
const _ttlDetail = Duration(minutes: 10);

// ── Cache key helpers ────────────────────────────────────────────────────────

String _analystListKey(
  int page,
  String? search,
  String? segment,
  String? horizon,
  String? sort,
) =>
    'analysts|p$page|q${search ?? ''}|seg${segment ?? ''}|hor${horizon ?? ''}|s${sort ?? ''}';

String _batchListKey(
  int page,
  String? search,
  String? segment,
  String? horizon,
  String? riskLevel,
  String? sort,
) =>
    'batches|p$page|q${search ?? ''}|seg${segment ?? ''}|hor${horizon ?? ''}|r${riskLevel ?? ''}|s${sort ?? ''}';

class DiscoverRepositoryImpl implements DiscoverRepository {
  DiscoverRepositoryImpl(this._remote);

  final DiscoverRemoteDataSource _remote;

  // Separate typed caches per data shape — avoids accidental key collisions.
  final _analystListCache =
      InMemoryCache<String, List<DiscoverAnalystModel>>();
  final _batchListCache =
      InMemoryCache<String, List<DiscoverBatchModel>>();
  final _analystProfileCache =
      InMemoryCache<String, DiscoverAnalystModel>();
  final _analystBatchesCache =
      InMemoryCache<String, List<DiscoverBatchModel>>();
  final _planCache =
      InMemoryCache<String, DiscoverBatchModel>();
  final _analystFacetsCache =
      InMemoryCache<String, DiscoverAnalystFacets>();
  final _planFacetsCache =
      InMemoryCache<String, DiscoverPlanFacets>();

  // ── List endpoints ──────────────────────────────────────────────────────────

  @override
  Future<List<DiscoverAnalystModel>> fetchAnalysts({
    required int page,
    String? search,
    String? segment,
    String? horizon,
    String? sort,
    bool forceRefresh = false,
  }) {
    final key = _analystListKey(page, search, segment, horizon, sort);
    Future<List<DiscoverAnalystModel>> doFetch() => _remote.fetchAnalysts(
          page: page,
          search: search,
          segment: segment,
          horizon: horizon,
          sort: sort,
        );
    if (forceRefresh) {
      return _analystListCache.refresh(key: key, ttl: _ttlList, fetch: doFetch);
    }
    return _analystListCache.get(key: key, ttl: _ttlList, fetch: doFetch);
  }

  @override
  Future<List<DiscoverBatchModel>> fetchBatches({
    required int page,
    String? search,
    String? segment,
    String? horizon,
    String? riskLevel,
    String? sort,
    bool forceRefresh = false,
  }) {
    final key = _batchListKey(page, search, segment, horizon, riskLevel, sort);
    Future<List<DiscoverBatchModel>> doFetch() => _remote.fetchBatches(
          page: page,
          search: search,
          segment: segment,
          horizon: horizon,
          riskLevel: riskLevel,
          sort: sort,
        );
    if (forceRefresh) {
      return _batchListCache.refresh(key: key, ttl: _ttlList, fetch: doFetch);
    }
    return _batchListCache.get(key: key, ttl: _ttlList, fetch: doFetch);
  }

  // ── Detail endpoints ────────────────────────────────────────────────────────

  @override
  Future<DiscoverAnalystModel> fetchAnalystProfile(String analystId) {
    return _analystProfileCache.get(
      key: analystId,
      ttl: _ttlDetail,
      fetch: () => _remote.fetchAnalystProfile(analystId),
    );
  }

  @override
  Future<List<DiscoverBatchModel>> fetchAnalystBatches(String analystId) {
    return _analystBatchesCache.get(
      key: analystId,
      ttl: _ttlDetail,
      fetch: () => _remote.fetchAnalystBatches(analystId),
    );
  }

  @override
  Future<DiscoverBatchModel> fetchPlan(String planId) {
    return _planCache.get(
      key: planId,
      ttl: _ttlDetail,
      fetch: () => _remote.fetchPlan(planId),
    );
  }

  @override
  Future<List<AvailableCoupon>> fetchAvailableCoupons({
    required String planId,
    required String analystId,
  }) => _remote.fetchAvailableCoupons(planId: planId, analystId: analystId);

  @override
  Future<CouponVerification> verifyCoupon({
    required String code,
    required String planId,
  }) => _remote.verifyCoupon(code: code, planId: planId);

  @override
  Future<SubscriptionCheckout> createSubscription({
    required String planId,
    String? batchId,
    String? couponCode,
    double? amount,
    double? discountAmount,
  }) =>
      _remote.createSubscription(
        planId: planId,
        batchId: batchId,
        couponCode: couponCode,
        amount: amount,
        discountAmount: discountAmount,
      );

  @override
  Future<void> verifySubscriptionPayment({
    required String subscriptionId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) => _remote.verifySubscriptionPayment(
    subscriptionId: subscriptionId,
    razorpayOrderId: razorpayOrderId,
    razorpayPaymentId: razorpayPaymentId,
    razorpaySignature: razorpaySignature,
  );

  // ── Facets ──────────────────────────────────────────────────────────────────

  @override
  Future<DiscoverAnalystFacets> fetchAnalystFacets({
    bool forceRefresh = false,
  }) {
    if (forceRefresh) {
      return _analystFacetsCache.refresh(
        key: 'analyst_facets',
        ttl: _ttlFacets,
        fetch: _remote.fetchAnalystFacets,
      );
    }
    return _analystFacetsCache.get(
      key: 'analyst_facets',
      ttl: _ttlFacets,
      fetch: _remote.fetchAnalystFacets,
    );
  }

  @override
  Future<DiscoverPlanFacets> fetchPlanFacets({
    bool forceRefresh = false,
  }) {
    if (forceRefresh) {
      return _planFacetsCache.refresh(
        key: 'plan_facets',
        ttl: _ttlFacets,
        fetch: _remote.fetchPlanFacets,
      );
    }
    return _planFacetsCache.get(
      key: 'plan_facets',
      ttl: _ttlFacets,
      fetch: _remote.fetchPlanFacets,
    );
  }

  // ── Cache management ──────────────────────────────────────────────────────

  @override
  /// Call after a user subscribes to a plan — invalidates the relevant plan
  /// and analyst data so the next read reflects updated subscriber counts.
  void invalidatePlan(String planId, {String? analystId}) {
    _planCache.invalidate(planId);
    if (analystId != null) {
      _analystBatchesCache.invalidate(analystId);
      _analystProfileCache.invalidate(analystId);
    }
    // Bust all paginated batch/analyst list pages since subscriber counts
    // are shown in the list cards.
    _batchListCache.clear();
    _analystListCache.clear();
  }

  /// Hard-clears all cached data. Used on logout.
  @override
  void clearAll() {
    _analystListCache.clear();
    _batchListCache.clear();
    _analystProfileCache.clear();
    _analystBatchesCache.clear();
    _planCache.clear();
    _analystFacetsCache.clear();
    _planFacetsCache.clear();
  }
}
