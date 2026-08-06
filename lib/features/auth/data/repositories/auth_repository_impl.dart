import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/notifications/fcm_service.dart';
import '../../../../core/platform/app_platform.dart';
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

  String get _deviceType => AppPlatform.deviceType;
  String get _deviceName => AppPlatform.deviceName;

  @override
  Future<void> requestOtp(String phoneE164) async {
    final res = await _dio.post(
      '/auth/login/request-otp',
      data: {'identifier': phoneE164},
    );
    if (res.statusCode != 200) throw _errorFrom(res);
  }

  @override
  Future<String> requestAccountDeletionOtp() async {
    final res = await _dio.post('/users/me/delete/request-otp');
    if (res.statusCode != 200) throw _errorFrom(res);
    final data = (res.data as Map).cast<String, dynamic>();
    return data['phone_masked'] as String? ?? 'your registered mobile number';
  }

  @override
  Future<DateTime?> deleteAccount({
    required String otp,
    required String reason,
  }) async {
    final res = await _dio.post(
      '/users/me/delete',
      data: <String, String>{'otp': otp, 'reason': reason},
    );
    if (res.statusCode != 200) throw _errorFrom(res);
    _cachedUser = null;
    final data = (res.data as Map).cast<String, dynamic>();
    final scheduledAt = data['deletion_scheduled_at'] as String?;
    return scheduledAt == null ? null : DateTime.tryParse(scheduledAt)?.toLocal();
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
    if (res.statusCode == 200) {
      debugPrint("Hurray!!! verify-otp working fine ");
    }

    final user = AuthUser.fromVerifyResponse(data);
    if (user.isNewUser) {
      await _storage.write(SecureStorage.isNewUser, 'true');
    }
    // Don't block login navigation on push-token registration.
    unawaited(
      FcmService.instance.registerTokenForSession().catchError((_) => null),
    );
    return user;
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
  Future<void> refreshToken() async {
    final token = await _storage.read(SecureStorage.refreshToken);
    if (token == null || token.isEmpty) {
      throw AuthException('MISSING_REFRESH_TOKEN', 'Session refresh is unavailable');
    }

    final res = await _dio.post<dynamic>(
      '/auth/refresh',
      data: <String, dynamic>{'refresh_token': token},
    );
    if (res.statusCode != 200) throw _errorFrom(res);

    final data = (res.data as Map).cast<String, dynamic>();
    final access = data['access_token'] as String?;
    final refresh = data['refresh_token'] as String?;

    if (access == null || access.isEmpty) {
      throw AuthException('INVALID_REFRESH_RESPONSE', 'Session refresh failed');
    }
    await _storage.write(SecureStorage.accessToken, access);
    if (refresh != null && refresh.isNotEmpty) {
      await _storage.write(SecureStorage.refreshToken, refresh);
    }
  }

  @override
  Future<String> submitKyc({required String aadhaarNumber}) async {
    final res = await _dio.post<dynamic>(
      '/users/kyc/submit',
      data: <String, dynamic>{'aadhaar_number': aadhaarNumber},
    );
    if (res.statusCode != 200) throw _errorFrom(res);
    final data = (res.data as Map).cast<String, dynamic>();
    final state = data['state'] as String? ?? 'ACTIVE';

    // KYC changes the permissions embedded in the session. Refreshing is a
    // required part of a successful KYC flow in every build mode, not a
    // best-effort background task.
    await refreshToken();

    // Replace the pre-KYC cached profile only after the new token is stored.
    _cachedUser = null;
    await getMe();
    return state;
  }

  @override
  Future<AuthUser> updateProfile({
    String? name,
    String? email,
    String? profilePicUrl,
  }) async {
    final payload = <String, dynamic>{
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (profilePicUrl != null && profilePicUrl.trim().isNotEmpty)
        'profile_pic_url': profilePicUrl.trim(),
    };
    final res = await _dio.patch('/users/me', data: payload);
    if (res.statusCode != 200) throw _errorFrom(res);
    // Bust the cache so getMe() fetches fresh complete data on next call.
    _cachedUser = null;
    final updated = AuthUser.fromProfile(res.data as Map<String, dynamic>);
    return updated;
  }

  @override
  Future<String> uploadAvatar({
    required String imageBase64,
    required String contentType,
  }) async {
    final res = await _dio.post<dynamic>(
      '/users/me/avatar',
      data: <String, dynamic>{
        'image_base64': imageBase64,
        'content_type': contentType,
      },
    );
    if (res.statusCode != 200) throw _errorFrom(res);
    final data = res.data as Map<String, dynamic>;
    final url = data['profile_pic_url'] ?? data['url'] ?? data['avatar_url'];
    if (url is! String || url.isEmpty) {
      throw AuthException('INVALID_RESPONSE', 'Avatar URL missing in response');
    }
    // Bust cache so next getMe() returns updated profilePicUrl.
    _cachedUser = _cachedUser?.copyWith(profilePicUrl: url);
    return url;
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
      await FcmService.instance.unregisterForSession();
    } catch (_) {}
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // Best-effort revoke; always clear local tokens.
    } finally {
      _cachedUser = null;
      _getMeRequest = null;
      await _storage.clearSession();
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
