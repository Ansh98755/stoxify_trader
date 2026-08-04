import 'dart:async';

/// A single cached value with a timestamp and TTL.
class CacheEntry<T> {
  CacheEntry({
    required this.data,
    required this.ttl,
  }) : _fetchedAt = DateTime.now();

  final T data;
  final Duration ttl;
  final DateTime _fetchedAt;

  /// Whether the entry is still within its TTL.
  bool get isValid => DateTime.now().difference(_fetchedAt) < ttl;

  /// How old this entry is.
  Duration get age => DateTime.now().difference(_fetchedAt);
}

/// Thread-safe in-memory key-value cache with TTL and
/// Stale-While-Revalidate (SWR) support.
///
/// Usage:
/// ```dart
/// final cache = InMemoryCache<String, MyModel>();
///
/// final result = await cache.get(
///   key: 'analysts_page_1',
///   ttl: const Duration(minutes: 10),
///   fetch: () => remote.fetchAnalysts(page: 1),
///   onRevalidated: (fresh) => doSomethingWith(fresh),
/// );
/// ```
class InMemoryCache<K, V> {
  InMemoryCache();

  final Map<K, CacheEntry<V>> _store = {};
  final Map<K, Future<V>> _inFlight = {};

  // Tracks in-flight revalidations so we never fire two simultaneous
  // background fetches for the same key.
  final Set<K> _revalidating = {};

  /// Returns cached data if valid, otherwise fetches fresh data.
  ///
  /// If data is stale (past TTL) but exists, it is returned immediately
  /// (SWR behaviour) and a background revalidation is triggered.
  /// [onRevalidated] is called with the fresh data when it arrives.
  Future<V> get({
    required K key,
    required Duration ttl,
    required Future<V> Function() fetch,
    void Function(V fresh)? onRevalidated,
  }) async {
    final entry = _store[key];

    // Cache hit and still valid — return immediately, no network call.
    if (entry != null && entry.isValid) {
      return entry.data;
    }

    // Stale-while-revalidate — return stale data immediately, kick off a
    // background refresh so the next read gets fresh data.
    if (entry != null && !entry.isValid) {
      _revalidateInBackground(
        key: key,
        ttl: ttl,
        fetch: fetch,
        onRevalidated: onRevalidated,
      );
      return entry.data;
    }

    // Cache miss — must fetch synchronously and populate cache.
    return _fetchOnce(key: key, ttl: ttl, fetch: fetch);
  }

  /// Force-fetches fresh data, updates the cache, and returns the result.
  /// Use this for manual pull-to-refresh.
  Future<V> refresh({
    required K key,
    required Duration ttl,
    required Future<V> Function() fetch,
  }) async {
    return _fetchOnce(key: key, ttl: ttl, fetch: fetch);
  }

  /// Writes a value directly into the cache (e.g. after a mutation).
  void write(K key, V value, {required Duration ttl}) {
    _store[key] = CacheEntry(data: value, ttl: ttl);
  }

  /// Removes a single key, forcing the next [get] to fetch fresh.
  void invalidate(K key) {
    _store.remove(key);
    _revalidating.remove(key);
  }

  /// Removes all keys matching [predicate].
  void invalidateWhere(bool Function(K key) predicate) {
    _store.removeWhere((key, _) => predicate(key));
    _revalidating.removeWhere(predicate);
  }

  /// Clears the entire cache.
  void clear() {
    _store.clear();
    _revalidating.clear();
    _inFlight.clear();
  }

  /// Whether a valid (non-stale) entry exists for [key].
  bool isValid(K key) {
    final entry = _store[key];
    return entry != null && entry.isValid;
  }

  /// Whether any entry (valid or stale) exists for [key].
  bool contains(K key) => _store.containsKey(key);

  /// All keys currently in the cache (valid or stale).
  Iterable<K> get keys => _store.keys;

  /// Returns the cached value for [key] without checking TTL, or null if absent.
  V? peek(K key) => _store[key]?.data;

  Future<V> _fetchOnce({
    required K key,
    required Duration ttl,
    required Future<V> Function() fetch,
  }) {
    final active = _inFlight[key];
    if (active != null) return active;
    final request = fetch().then((fresh) {
      _store[key] = CacheEntry(data: fresh, ttl: ttl);
      return fresh;
    });
    _inFlight[key] = request;
    return request.whenComplete(() => _inFlight.remove(key));
  }

  // ── Internal ────────────────────────────────────────────────────────────────

  void _revalidateInBackground({
    required K key,
    required Duration ttl,
    required Future<V> Function() fetch,
    void Function(V fresh)? onRevalidated,
  }) {
    if (_revalidating.contains(key)) return; // already in flight
    _revalidating.add(key);

    unawaited(
      _fetchOnce(key: key, ttl: ttl, fetch: fetch).then((fresh) {
        onRevalidated?.call(fresh);
      }).catchError((_) {
        // Silently swallow — stale data is already in use, network errors
        // during background revalidation should never surface to the user.
      }).whenComplete(() => _revalidating.remove(key)),
    );
  }
}
