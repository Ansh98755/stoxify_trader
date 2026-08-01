import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  AuthUser? _cachedUser;
  Future<AuthUser>? _getMeRequest;

  String get _deviceType {
    if (kIsWeb) return 'WEB';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'IOS';
      case TargetPlatform.macOS:
        return 'MACOS';
      default:
        return 'ANDROID';
    }
  }

  String get _deviceName {
    if (kIsWeb) return 'StoXify Web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'StoXify iOS';
      case TargetPlatform.macOS:
        return 'StoXify macOS';
      case TargetPlatform.windows:
        return 'StoXify Windows';
      default:
        return 'StoXify Android';
    }
  }

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
    if(res.statusCode==200)
      {
        debugPrint("Hurray!!! verify-otp working fine ");
      }

    return AuthUser.fromVerifyResponse(data);
  }

  @override
  Future<AuthUser> getMe() {
    final cached = _cachedUser;
    if (cached != null) return Future.value(cached);

    final activeRequest = _getMeRequest;
    if (activeRequest != null) return activeRequest;

    final request = _fetchMe();
    _getMeRequest = request;
    return request.whenComplete(() => _getMeRequest = null);
  }

  Future<AuthUser> _fetchMe() async {
    final res = await _dio.get('/users/me');
    if (res.statusCode != 200) throw _errorFrom(res);
    final user = AuthUser.fromProfile(res.data as Map<String, dynamic>);
    _cachedUser = user;
    return user;
  }

  @override
  Future<void> updateInterests(List<String> interests) async {
    final res = await _dio.patch(
      '/users/interests',
      data: {'interests': interests},
    );
    if (res.statusCode != 200) throw _errorFrom(res);
    _cachedUser = null;
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
      _cachedUser = null;
      _getMeRequest = null;
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
