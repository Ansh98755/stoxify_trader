import 'package:dio/dio.dart';
import '../models/discover_analyst_model.dart';
import '../models/discover_batch_model.dart';

class DiscoverRemoteDataSource {
  const DiscoverRemoteDataSource(this._dio);

  final Dio _dio;

  static const int pageSize = 20;

  Future<List<DiscoverAnalystModel>> fetchAnalysts({
    required int page,
    String? search,
    String? segment,
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
    String? sort,
  }) async {
    String? riskLevel;
    String? mappedSegment = segment;
    if (segment == 'Low risk') {
      riskLevel = 'LOW';
      mappedSegment = null;
    } else if (segment == 'Medium risk') {
      riskLevel = 'MEDIUM';
      mappedSegment = null;
    } else if (segment == 'All') {
      mappedSegment = null;
    }

    final res = await _dio.get(
      '/plans/',
      queryParameters: _clean({
        'page': page,
        'limit': pageSize,
        'is_active': 'true',
        'require_active_tier': 'true',
        'sort': _mapBatchSort(sort),
        'search': search,
        'segments': mappedSegment,
        'risk_levels': riskLevel,
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
