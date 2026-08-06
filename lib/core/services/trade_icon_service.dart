import '../../features/home/data/datasources/market_data_remote_data_source.dart';

/// Resolves trade instrument icons via `GET /market-data/search`.
///
/// In-memory cache + in-flight de-dupe so list cards don't hammer the API
/// for the same symbol.
class TradeIconService {
  TradeIconService(this._market);

  final MarketDataRemoteDataSource _market;

  final Map<String, String?> _cache = <String, String?>{};
  final Map<String, Future<String?>> _inflight = <String, Future<String?>>{};

  /// Returns a hosted icon URL for [symbol], or null when unavailable.
  Future<String?> iconFor({
    required String symbol,
    String? companyName,
    String? knownLogoUrl,
  }) async {
    final known = knownLogoUrl?.trim();
    if (known != null && known.isNotEmpty) return known;

    final cacheKey = _cacheKey(symbol, companyName);
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];

    final active = _inflight[cacheKey];
    if (active != null) return active;

    final future = _resolve(symbol, companyName).whenComplete(() {
      _inflight.remove(cacheKey);
    });
    _inflight[cacheKey] = future;
    final url = await future;
    _cache[cacheKey] = url;
    return url;
  }

  Future<String?> _resolve(String symbol, String? companyName) async {
    for (final query in _searchQueries(symbol, companyName)) {
      final url = await _market.searchIconUrl(query);
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }

  static String _cacheKey(String symbol, String? companyName) {
    final s = symbol.trim().toUpperCase();
    final c = companyName?.trim().toUpperCase() ?? '';
    return c.isEmpty ? s : '$s|$c';
  }

  /// Ordered candidates for market-data search.
  static List<String> _searchQueries(String symbol, String? companyName) {
    final out = <String>[];
    void add(String? value) {
      final v = value?.trim() ?? '';
      if (v.isEmpty) return;
      if (!out.any((e) => e.toUpperCase() == v.toUpperCase())) {
        out.add(v);
      }
    }

    var s = symbol.trim();
    if (s.contains('/')) {
      s = s.split('/').first.trim();
    }

    // Full trade symbol first (equity / exact match), then underlying root.
    add(s);
    final root = RegExp(r'^([A-Za-z]+)').firstMatch(s)?.group(1);
    if (root != null && root.length >= 2) add(root);

    final company = companyName?.trim();
    if (company != null && company.isNotEmpty) {
      add(company);
      // First word of company name often matches market search better.
      final firstWord = company.split(RegExp(r'\s+')).first;
      add(firstWord);
    }

    return out;
  }

  void clear() {
    _cache.clear();
    _inflight.clear();
  }
}
