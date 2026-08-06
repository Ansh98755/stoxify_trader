import 'package:dio/dio.dart';

/// Reads live prices and instrument metadata from the market-data service.
class MarketDataRemoteDataSource {
  MarketDataRemoteDataSource(this._dio);

  final Dio _dio;

  static const _kMaxSymbolsPerRequest = 50;

  /// Latest prices for [symbols], chunked at 50. Never throws.
  Future<Map<String, double>> prices(List<String> symbols) async {
    final wanted = symbols.where((s) => s.isNotEmpty).toList();
    if (wanted.isEmpty) return const {};

    final result = <String, double>{};
    for (var i = 0; i < wanted.length; i += _kMaxSymbolsPerRequest) {
      final chunk = wanted.skip(i).take(_kMaxSymbolsPerRequest).toList();
      try {
        final res = await _dio.post(
          '/market-data/prices',
          data: {'symbols': chunk},
        );
        final data = res.data;
        if (res.statusCode == 200 && data is Map && data['prices'] is Map) {
          (data['prices'] as Map).forEach((symbol, price) {
            if (symbol is String && price is num) {
              result[symbol] = price.toDouble();
            }
          });
        }
      } catch (_) {
        // Skip this chunk; the next poll tick retries.
      }
    }
    return result;
  }

  /// GET /market-data/search?q= — returns [iconUrl] for the best symbol match.
  /// Never throws; returns null when no icon is available.
  Future<String?> searchIconUrl(String query) async {
    final q = query.trim();
    if (q.isEmpty) return null;

    try {
      final res = await _dio.get<dynamic>(
        '/market-data/search',
        queryParameters: <String, dynamic>{'q': q},
      );
      if (res.statusCode != 200 || res.data is! Map) return null;

      final raw = ((res.data as Map)['results'] as List?) ?? const <dynamic>[];
      final results = raw
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .where((r) {
            final url = (r['iconUrl'] as String?)?.trim();
            return url != null && url.isNotEmpty;
          })
          .toList();
      if (results.isEmpty) return null;

      final needle = q.toUpperCase();

      Map<String, dynamic>? exact;
      Map<String, dynamic>? close;
      for (final r in results) {
        final symbol = (r['symbol'] as String?)?.toUpperCase() ?? '';
        if (symbol == needle || symbol == '$needle-EQ') {
          exact = r;
          break;
        }
        if (close == null &&
            (symbol.startsWith(needle) || needle.startsWith(symbol))) {
          close = r;
        }
      }

      final chosen = exact ?? close ?? results.first;
      return (chosen['iconUrl'] as String).trim();
    } catch (_) {
      return null;
    }
  }
}
