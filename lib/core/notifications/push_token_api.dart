import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Registers / unregisters FCM device tokens with the gateway.
///
/// - `POST /notifications/device-token`
///   body: `{ "deviceId", "token", "platform" }`  (platform: android | ios)
/// - `DELETE /notifications/device-token/:token`
class PushTokenApi {
  PushTokenApi(this._dio);

  final Dio _dio;

  Future<void> registerToken({
    required String deviceId,
    required String token,
    required String platform,
  }) async {
    try {
      final res = await _dio.post<dynamic>(
        '/notifications/device-token',
        data: <String, dynamic>{
          'deviceId': deviceId,
          'token': token,
          'platform': platform.toLowerCase(),
        },
      );
      debugPrint(
        '[FCM] register device-token → ${res.statusCode}',
      );
    } on DioException catch (e) {
      debugPrint(
        '[FCM] register token failed: ${e.response?.statusCode} ${e.message}',
      );
      rethrow;
    }
  }

  Future<void> unregisterToken({required String token}) async {
    try {
      final encoded = Uri.encodeComponent(token);
      final res = await _dio.delete<dynamic>(
        '/notifications/device-token/$encoded',
      );
      debugPrint(
        '[FCM] delete device-token → ${res.statusCode}',
      );
    } on DioException catch (e) {
      debugPrint(
        '[FCM] unregister token failed: ${e.response?.statusCode} ${e.message}',
      );
      // Best-effort on logout; don't block session clear.
    }
  }
}
