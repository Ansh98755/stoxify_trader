enum AppNotificationType {
  tradeCreated,
  tradeClosed,
  tradeModified,
  tradePriceUpdate,
  tradeValueOpportunity,
  tradeHighProfit,
  planCreated,
  batchCreated,
  subscriptionActivated,
  subscriptionExpiring,
  subscriptionExpired,
  adminBroadcast,
  other,
}

class AppNotification {
  const AppNotification({
    required this.notificationId,
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    required this.createdAt,
    this.relatedEntityId,
    this.relatedEntityType,
    this.payload,
    this.expiresAt,
    this.readAt,
    this.broadcastSentBy,
  });

  final String notificationId;
  final AppNotificationType type;
  final String title;
  final String message;
  final bool read;
  final DateTime createdAt;
  final String? relatedEntityId;
  final String? relatedEntityType;
  final Map<String, dynamic>? payload;
  final DateTime? expiresAt;
  final DateTime? readAt;
  final String? broadcastSentBy;

  AppNotification copyWith({bool? read, DateTime? readAt}) {
    return AppNotification(
      notificationId: notificationId,
      type: type,
      title: title,
      message: message,
      read: read ?? this.read,
      createdAt: createdAt,
      relatedEntityId: relatedEntityId,
      relatedEntityType: relatedEntityType,
      payload: payload,
      expiresAt: expiresAt,
      readAt: readAt ?? this.readAt,
      broadcastSentBy: broadcastSentBy,
    );
  }
}

class NotificationsPage_ {
  const NotificationsPage_({
    required this.notifications,
    required this.total,
    required this.page,
    required this.hasMore,
  });

  final List<AppNotification> notifications;
  final int total;
  final int page;
  final bool hasMore;
}
