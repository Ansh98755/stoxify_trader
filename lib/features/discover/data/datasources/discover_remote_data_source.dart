import 'package:dio/dio.dart';
import '../models/discover_analyst_model.dart';
import '../models/discover_batch_model.dart';
import '../models/discover_facets_model.dart';

class DiscoverRemoteDataSource {
  const DiscoverRemoteDataSource(this._dio);

  final Dio _dio;

  static const int pageSize = 20;

  Future<DiscoverAnalystModel> fetchAnalystProfile(String analystId) async {
    final res = await _dio.get('/users/analysts/$analystId');
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch analyst profile');
    }
    return DiscoverAnalystModel.fromJson(
      (res.data as Map).cast<String, dynamic>(),
    );
  }

  Future<List<DiscoverBatchModel>> fetchAnalystBatches(
    String analystId,
  ) async {
    final res = await _dio.get('/plans/public/analysts/$analystId');
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch analyst plans');
    }
    final data = (res.data as Map).cast<String, dynamic>();
    final raw = (data['plans'] as List?) ??
        (data['batches'] as List?) ??
        const <dynamic>[];
    return raw
        .whereType<Map>()
        .map((item) =>
            DiscoverBatchModel.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<DiscoverBatchModel> fetchPlan(String planId) async {
    final res = await _dio.get('/plans/$planId');
    if (res.statusCode != 200) throw Exception('Failed to fetch plan');
    final data = (res.data as Map).cast<String, dynamic>();
    final raw = data['plan'] is Map
        ? (data['plan'] as Map).cast<String, dynamic>()
        : data;
    return DiscoverBatchModel.fromJson(raw);
  }

  Future<List<AvailableCoupon>> fetchAvailableCoupons({
    required String planId,
    required String analystId,
  }) async {
    final res = await _dio.get(
      '/plans/coupons/available',
      queryParameters: <String, String>{
        'plan_id': planId,
        'analyst_id': analystId,
      },
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch available coupons');
    }
    final data = (res.data as Map).cast<String, dynamic>();
    return ((data['coupons'] as List?) ?? const <dynamic>[])
        .whereType<Map>()
        .map((coupon) => AvailableCoupon.fromJson(coupon.cast<String, dynamic>()))
        .toList();
  }

  Future<CouponVerification> verifyCoupon({
    required String code,
    required String planId,
  }) async {
    final res = await _dio.post(
      '/plans/coupons/verify',
      data: <String, String>{'code': code, 'plan_id': planId},
    );
    if (res.statusCode != 200) {
      throw Exception('Unable to verify this coupon');
    }
    return CouponVerification.fromJson(
      (res.data as Map).cast<String, dynamic>(),
    );
  }

  Future<SubscriptionCheckout> createSubscription({
    required String planId,
    String? batchId,
    String? couponCode,
    double? amount,
    double? discountAmount,
  }) async {
    final res = await _dio.post(
      '/subscriptions/',
      data: _clean(<String, dynamic>{
        'plan_id': planId,
        'batch_id': batchId,
        'coupon_code': couponCode,
        // Client-computed payable (rupees) after flat / percentage coupon cut.
        'amount': amount,
        'discount_amount': discountAmount,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Unable to create subscription');
    }
    return SubscriptionCheckout.fromJson(
      (res.data as Map).cast<String, dynamic>(),
    );
  }

  Future<void> verifySubscriptionPayment({
    required String subscriptionId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final res = await _dio.post(
      '/subscriptions/$subscriptionId/verify-payment',
      data: <String, String>{
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      },
    );
    if (res.statusCode != 200) {
      throw Exception('Payment verification failed');
    }
  }

  Future<DiscoverAnalystFacets> fetchAnalystFacets() async {
    final res = await _dio.get('/users/analysts/facets');
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch analyst facets');
    }
    return DiscoverAnalystFacets.fromJson(
      (res.data as Map).cast<String, dynamic>(),
    );
  }

  Future<DiscoverPlanFacets> fetchPlanFacets() async {
    final res = await _dio.get('/plans/facets');
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch plan facets');
    }
    return DiscoverPlanFacets.fromJson(
      (res.data as Map).cast<String, dynamic>(),
    );
  }

  Future<List<DiscoverAnalystModel>> fetchAnalysts({
    required int page,
    String? search,
    String? segment,
    String? horizon,
    String? sort,
  }) async {
    final res = await _dio.get(
      '/users/analysts/discover',
      queryParameters: _clean({
        'page': page,
        'limit': pageSize,
        'sort': _mapAnalystSort(sort),
        'search': search,
        'segments': (segment != null && segment != 'All') ? segment : null,
        'horizons': (horizon != null && horizon != 'All') ? horizon : null,
      }),
    );
    if (res.statusCode != 200) throw Exception('Failed to fetch analysts');
    final data = res.data as Map<String, dynamic>;
    final items = (data['analysts'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => DiscoverAnalystModel.fromJson(e.cast<String, dynamic>()))
        .toList();
    return _filterAnalysts(
      items,
      search: search,
      segment: segment,
      horizon: horizon,
    );
  }

  Future<List<DiscoverBatchModel>> fetchBatches({
    required int page,
    String? search,
    String? segment,
    String? horizon,
    String? riskLevel,
    String? sort,
  }) async {
    final res = await _dio.get(
      '/plans/',
      queryParameters: _clean({
        'page': page,
        'limit': pageSize,
        'is_active': 'true',
        'sort': _mapBatchSort(sort),
        'search': search,
        'segments': (segment != null && segment != 'All') ? segment : null,
        'risk_levels':
            (riskLevel != null && riskLevel != 'All') ? riskLevel : null,
        'horizons': (horizon != null && horizon != 'All') ? horizon : null,
      }),
    );
    if (res.statusCode != 200) throw Exception('Failed to fetch batches');
    final data = res.data as Map<String, dynamic>;
    final items = (data['plans'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => DiscoverBatchModel.fromJson(e.cast<String, dynamic>()))
        .toList();
    return _filterBatches(
      items,
      search: search,
      segment: segment,
      horizon: horizon,
      riskLevel: riskLevel,
    );
  }

  Set<String> _csvTokens(String? csv) {
    if (csv == null || csv.trim().isEmpty || csv == 'All') {
      return const <String>{};
    }
    return csv
        .split(',')
        .map((s) => s.trim().toUpperCase())
        .where((s) => s.isNotEmpty && s != 'ALL')
        .toSet();
  }

  bool _tokenMatch(String raw, Set<String> wanted) {
    if (wanted.isEmpty) return true;
    final value = raw.trim().toUpperCase();
    if (value.isEmpty) return false;
    final normalized = value.replaceAll('&', '').replaceAll(' ', '');
    if (wanted.contains(value) || wanted.contains(normalized)) return true;
    if ((value == 'FNO' || normalized == 'FNO' || normalized == 'FO') &&
        (wanted.contains('FNO') ||
            wanted.contains('FO') ||
            wanted.contains('F&O'))) {
      return true;
    }
    return false;
  }

  bool _listMatchesAny(List<String> values, Set<String> wanted) {
    if (wanted.isEmpty) return true;
    if (values.isEmpty) return false;
    return values.any((v) => _tokenMatch(v, wanted));
  }

  /// Client-side name + multi-facet filter so wrong selections never surface
  /// rows that ignore the multi-select API params.
  List<DiscoverAnalystModel> _filterAnalysts(
    List<DiscoverAnalystModel> items, {
    String? search,
    String? segment,
    String? horizon,
  }) {
    final q = search?.trim().toLowerCase() ?? '';
    final segments = _csvTokens(segment);
    final horizons = _csvTokens(horizon);

    return items.where((a) {
      if (q.isNotEmpty && !a.name.toLowerCase().contains(q)) return false;
      if (!_listMatchesAny(a.segmentsCovered, segments)) return false;
      if (!_listMatchesAny(a.horizonsCovered, horizons)) return false;
      return true;
    }).toList();
  }

  List<DiscoverBatchModel> _filterBatches(
    List<DiscoverBatchModel> items, {
    String? search,
    String? segment,
    String? horizon,
    String? riskLevel,
  }) {
    final q = search?.trim().toLowerCase() ?? '';
    final segments = _csvTokens(segment);
    final horizons = _csvTokens(horizon);
    final risks = _csvTokens(riskLevel);

    return items.where((b) {
      if (q.isNotEmpty) {
        final hitName = b.name.toLowerCase().contains(q);
        final hitDesc = (b.description ?? '').toLowerCase().contains(q);
        final hitTier =
            b.tiers.any((t) => t.name.toLowerCase().contains(q));
        if (!hitName && !hitDesc && !hitTier) return false;
      }
      if (!_listMatchesAny(b.segments, segments)) return false;
      if (!_listMatchesAny(b.horizons, horizons)) return false;
      if (risks.isNotEmpty) {
        final risk = (b.riskLevel ?? '').toUpperCase();
        if (risk.isEmpty || !risks.contains(risk)) return false;
      }
      return true;
    }).toList();
  }

  String _mapAnalystSort(String? sort) {
    if (sort == 'Avg P&L') return 'avg_pnl';
    if (sort == 'Subscribers') return 'subscribers';
    return 'win_rate';
  }

  String _mapBatchSort(String? sort) {
    if (sort == 'Price: low to high') return 'price_asc';
    if (sort == 'Price: high to low') return 'price_desc';
    return 'popularity';
  }

  Map<String, dynamic> _clean(Map<String, dynamic> q) {
    q.removeWhere((_, v) => v == null || (v is String && v.trim().isEmpty));
    return q;
  }
}
