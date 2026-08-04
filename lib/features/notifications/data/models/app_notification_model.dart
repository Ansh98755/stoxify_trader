import '../../domain/entities/app_notification.dart';

class AppNotificationModel {
  const AppNotificationModel._();

  static AppNotification fromJson(Map<String, dynamic> json) {
    return AppNotification(
      notificationId: (json['notification_id'] as String?) ?? '',
      type: _type(json['type'] as String?),
      title: (json['title'] as String?) ?? '',
      message: (json['message'] as String?) ?? '',
      read: (json['read'] as bool?) ?? false,
      createdAt: _date(json['created_at']) ?? DateTime.now(),
      relatedEntityId: json['related_entity_id'] as String?,
      relatedEntityType: json['related_entity_type'] as String?,
      payload: (json['payload'] as Map?)?.cast<String, dynamic>(),
      expiresAt: _date(json['expires_at']),
      readAt: _date(json['read_at']),
      broadcastSentBy: json['broadcast_sent_by'] as String?,
    );
  }

  static AppNotificationType _type(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'TRADE_CREATED':
        return AppNotificationType.tradeCreated;
      case 'TRADE_CLOSED':
        return AppNotificationType.tradeClosed;
      case 'TRADE_MODIFIED':
        return AppNotificationType.tradeModified;
      case 'ADMIN_BROADCAST':
        return AppNotificationType.adminBroadcast;
      default:
        return AppNotificationType.other;
    }
  }

  static DateTime? _date(dynamic v) {
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal();
    return null;
  }
}
