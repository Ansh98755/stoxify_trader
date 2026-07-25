import 'dart:io' show Platform;

import 'package:dio/dio.dart';

import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_exception.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required Dio dio,
    required SecureStorage storage,
  })  : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final SecureStorage _storage;

  String get _deviceType => Platform.isIOS ? 'IOS' : 'ANDROID';
  String get _deviceName => 'StoXify ${Platform.operatingSystem}';

  @override
  Future<void> requestOtp(String phoneE164) async {
    final res = await _dio.post(
      '/auth/login/request-otp',
      data: {'identifier': phoneE164},
    );
    if (res.statusCode != 200) throw _errorFrom(res);
  }

  @override
  Future<AuthUser> verifyOtp({
    required String phoneE164,
    required String otp,
  }) async {
    final res = await _dio.post(
      '/auth/login/verify-otp',
      data: {
        'identifier': phoneE164,
        'otp': otp,
        'device_type': _deviceType,
        'device_name': _deviceName,
      },
    );
    if (res.statusCode != 200) throw _errorFrom(res);

    final data = res.data as Map<String, dynamic>;
    await _storage.write(
      SecureStorage.accessToken,
      data['access_token'] as String,
    );
    await _storage.write(
      SecureStorage.refreshToken,
      data['refresh_token'] as String,
    );

    return AuthUser.fromVerifyResponse(data);
  }

  @override
  Future<AuthUser> getMe() async {
    final res = await _dio.get('/users/me');
    if (res.statusCode != 200) throw _errorFrom(res);
    return AuthUser.fromProfile(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> updateInterests(List<String> interests) async {
    final res = await _dio.patch(
      '/users/interests',
      data: {'interests': interests},
    );
    if (res.statusCode != 200) throw _errorFrom(res);
  }

  @override
  Future<String> requestWsChannel() async {
    final res = await _dio.post('/auth/request-ws-channel');
    if (res.statusCode != 200) throw _errorFrom(res);
    final data = res.data as Map<String, dynamic>;
    final channelId = data['channel_id'];
    if (channelId is! String) {
      throw AuthException('INVALID_RESPONSE', 'Invalid channel ID received');
    }
    return channelId;
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // Best-effort revoke; always clear local tokens.
    } finally {
      await _storage.delete(SecureStorage.accessToken);
      await _storage.delete(SecureStorage.refreshToken);
    }
  }

  AuthException _errorFrom(Response<dynamic> res) {
    final data = res.data;
    if (data is Map) {
      return AuthException(
        (data['code'] ?? 'UNKNOWN').toString(),
        (data['message'] ?? data['error'] ?? 'Something went wrong').toString(),
        statusCode: res.statusCode,
      );
    }
    return AuthException(
      'UNKNOWN',
      'Something went wrong',
      statusCode: res.statusCode,
    );
  }
}
