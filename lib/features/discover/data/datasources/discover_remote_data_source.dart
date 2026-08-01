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
    return items;
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
        'require_active_tier': 'true',
        'sort': _mapBatchSort(sort),
        'search': search,
        'segments': segment,
        'risk_levels': riskLevel,
        'horizons': horizon,
      }),
    );
    if (res.statusCode != 200) throw Exception('Failed to fetch batches');
    final data = res.data as Map<String, dynamic>;
    final items = (data['plans'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => DiscoverBatchModel.fromJson(e.cast<String, dynamic>()))
        .toList();
    return items;
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
