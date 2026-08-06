import '../../../../core/cache/in_memory_cache.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_data_source.dart';

// ── TTL constants ─────────────────────────────────────────────────────────────
// Notifications page 1 — 2 min. WebSocket already handles real-time delivery
// so the list only needs to be reasonably fresh when the screen opens.
// Unread count is never cached — home red-dot is strictly driven by the
// live `read=false` notifications API response.

const _ttlList = Duration(minutes: 2);

String _listKey(int page, bool unreadOnly) =>
    'notifications|p$page|unread$unreadOnly';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._remote);

  final NotificationsRemoteDataSource _remote;

  final _listCache = InMemoryCache<String, NotificationsPage_>();

  // ── Fetch ─────────────────────────────────────────────────────────────────

  @override
  Future<NotificationsPage_> fetchNotifications({
    required int page,
    bool unreadOnly = false,
  }) {
    final key = _listKey(page, unreadOnly);
    return _listCache.get(
      key: key,
      ttl: _ttlList,
      fetch: () => _remote.fetchNotifications(
        page: page,
        unreadOnly: unreadOnly,
      ),
    );
  }

  @override
  Future<int> fetchUnreadCount() {
    // Always hit the network — red-dot must match live `read=false` data.
    return _remote.fetchUnreadCount();
  }

  // ── Mutations — update cache locally, no refetch needed ───────────────────

  @override
  Future<AppNotification> markRead(String notificationId) async {
    final updated = await _remote.markRead(notificationId);

    // Patch the read flag in-place on every cached page so the unread dot
    // disappears immediately AND the read state survives a pull-to-refresh
    // without needing a network round-trip.
    for (final key in _listCache.keys) {
      final page = _listCache.peek(key);
      if (page == null) continue;
      final patched = page.notifications.map((n) {
        return n.notificationId == notificationId ? updated : n;
      }).toList();
      if (patched.any((n) => n.notificationId == notificationId)) {
        _listCache.write(
          key,
          NotificationsPage_(
            notifications: patched,
            total: page.total,
            page: page.page,
            hasMore: page.hasMore,
          ),
          ttl: _ttlList,
        );
      }
    }

    return updated;
  }

  @override
  Future<int> markAllRead() async {
    final updated = await _remote.markAllRead();

    // Bust all cached notification list pages — they all need unread=false.
    _listCache.clear();

    return updated;
  }

  // ── Cache management ──────────────────────────────────────────────────────

  @override
  /// Force-invalidates the list cache for page 1 — call when a new
  /// notification arrives via WebSocket so the next open shows it.
  void invalidateOnNewNotification() {
    _listCache.invalidateWhere((key) => key.startsWith('notifications|p1'));
  }

  /// Hard-clears all cached data. Used on logout.
  @override
  void clearAll() {
    _listCache.clear();
  }
}
