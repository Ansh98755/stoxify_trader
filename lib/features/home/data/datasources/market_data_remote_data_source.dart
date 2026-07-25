import 'package:dio/dio.dart';

/// Reads live prices from the market-data service.
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
}
