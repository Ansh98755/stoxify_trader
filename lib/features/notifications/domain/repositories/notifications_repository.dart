import '../entities/app_notification.dart';

abstract class NotificationsRepository {
  Future<NotificationsPage_> fetchNotifications({
    required int page,
    bool unreadOnly = false,
  });

  Future<int> fetchUnreadCount();

  Future<AppNotification> markRead(String notificationId);

  Future<int> markAllRead();

  /// Invalidates page-1 list and unread count caches — called when a new
  /// notification arrives via WebSocket so the next screen open is fresh.
  void invalidateOnNewNotification();

  /// Clears all cached data. Called on logout.
  void clearAll();
}
