import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_notification.dart';
import '../models/app_notification_model.dart';

class NotificationsRemoteDataSource {
  NotificationsRemoteDataSource(this._dio);

  final Dio _dio;

  static const int pageSize = 20;

  /// GET /notifications/?page=&limit=&unread_only=
  Future<NotificationsPage_> fetchNotifications({
    required int page,
    bool unreadOnly = false,
  }) async {
    try {
      final res = await _dio.get<dynamic>(
        '/notifications/',
        queryParameters: <String, dynamic>{
          'page': page,
          'limit': pageSize,
          if (unreadOnly) 'read': false,
        },
      );
      if (res.statusCode == 401) throw const AuthFailure();
      if (res.statusCode == 403) {
        return NotificationsPage_(
          notifications: const <AppNotification>[],
          total: 0,
          page: page,
          hasMore: false,
        );
      }
      if (res.statusCode != 200) {
        throw ServerFailure(
            'Failed to load notifications (${res.statusCode})');
      }

      final data = (res.data as Map).cast<String, dynamic>();
      final raw = (data['notifications'] as List?) ?? const <dynamic>[];
      final notifications = raw
          .whereType<Map>()
          .map((e) =>
              AppNotificationModel.fromJson(e.cast<String, dynamic>()))
          .toList();

      final total = (data['total'] as num?)?.toInt() ?? raw.length;
      final loaded = (page - 1) * pageSize + raw.length;

      return NotificationsPage_(
        notifications: notifications,
        total: total,
        page: page,
        hasMore: raw.isNotEmpty && loaded < total,
      );
    } on DioException catch (e) {
      _rethrowNetwork(e);
      rethrow;
    }
  }

  /// GET /notifications/?limit=1&unread_only=true — lightweight count fetch.
  Future<int> fetchUnreadCount() async {
    try {
      final res = await _dio.get<dynamic>(
        '/notifications/',
        queryParameters: <String, dynamic>{
          'page': 1,
          'limit': 1,
          'read': false,
        },
      );
      if (res.statusCode == 401) throw const AuthFailure();
      if (res.statusCode == 403 || res.statusCode != 200) return 0;
      final data = res.data;
      if (data is! Map) return 0;
      return (data['total'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      _rethrowNetwork(e);
      rethrow;
    }
  }

  /// POST /notifications/:notification_id/read
  Future<AppNotification> markRead(String notificationId) async {
    try {
      final res = await _dio.post<dynamic>(
        '/notifications/$notificationId/read',
      );
      if (res.statusCode == 401) throw const AuthFailure();
      if (res.statusCode != 200) {
        throw ServerFailure(
            'Failed to mark notification read (${res.statusCode})');
      }
      final data = (res.data as Map).cast<String, dynamic>();
      return AppNotificationModel.fromJson(data);
    } on DioException catch (e) {
      _rethrowNetwork(e);
      rethrow;
    }
  }

  /// POST /notifications/read-all
  Future<int> markAllRead() async {
    try {
      final res = await _dio.post<dynamic>('/notifications/read-all');
      if (res.statusCode == 401) throw const AuthFailure();
      if (res.statusCode != 200) {
        throw ServerFailure(
            'Failed to mark all notifications read (${res.statusCode})');
      }
      final data = (res.data as Map).cast<String, dynamic>();
      return (data['updated'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      _rethrowNetwork(e);
      rethrow;
    }
  }

  void _rethrowNetwork(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      throw const NetworkFailure();
    }
  }
}
