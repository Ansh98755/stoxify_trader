import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;

import '../storage/secure_storage.dart';
import 'device_id.dart';
import 'api_log.dart';
import 'request_signer.dart';

const _envBaseUrl = String.fromEnvironment('API_BASE_URL');

const _cloudBaseUrl =
    'https://stoxify-gateway.thankfulriver-811030ea.centralindia.azurecontainerapps.io';

String get apiBaseUrl {
  if (kReleaseMode) {
    if (_envBaseUrl.isEmpty) return _cloudBaseUrl;
    if (!_envBaseUrl.startsWith('https://')) {
      throw StateError(
        'Release builds require an HTTPS API_BASE_URL; got "$_envBaseUrl".',
      );
    }
    return _envBaseUrl;
  }
  if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
  return _cloudBaseUrl;
}

Dio buildDio({
  required RequestSigner signer,
  required DeviceIdProvider deviceIds,
  required SecureStorage storage,
  void Function()? onSessionExpired,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      validateStatus: (code) => code != null && code < 500,
    ),
  );

  dio.interceptors.add(
    _SignedAuthInterceptor(
      dio: dio,
      signer: signer,
      deviceIds: deviceIds,
      storage: storage,
      onSessionExpired: onSessionExpired,
    ),
  );

  return dio;
}

class _SignedAuthInterceptor extends Interceptor {
  _SignedAuthInterceptor({
    required this.dio,
    required this.signer,
    required this.deviceIds,
    required this.storage,
    this.onSessionExpired,
  });

  final Dio dio;
  final RequestSigner signer;
  final DeviceIdProvider deviceIds;
  final SecureStorage storage;
  final void Function()? onSessionExpired;

  static const _retriedFlag = '__auth_retried';
  Future<bool>? _pendingRefresh;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final method = options.method.toUpperCase();
    // Gateway verifies the path *after* the Vercel /api reverse-proxy rewrite.
    // Browser hits `/api/auth/...` but Azure sees `/auth/...` ? sign the
    // upstream path so it matches what the gateway recomputes.
    final path = _pathForSignature(options);

    final isBodyless = method == 'GET' || method == 'HEAD';
    final body = isBodyless
        ? '{}'
        : (options.data is String
            ? options.data as String
            : jsonEncode(options.data ?? const <String, dynamic>{}));
    if (!isBodyless) options.data = body;

    final deviceId = await deviceIds.get();
    final sigHeaders = await signer.buildSignatureHeaders(
      method: method,
      path: path,
      body: body,
      deviceId: deviceId,
    );

    options.headers['Content-Type'] = 'application/json';
    options.headers['X-Device-ID'] = deviceId;
    options.headers.addAll(sigHeaders);

    final token = await storage.read(SecureStorage.accessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.extra['api_log_started_at'] = DateTime.now();

    handler.next(options);
  }

  /// Path used in the ECDSA message: `METHOD|path|body|ts|nonce|deviceId`.
  ///
  /// Always the gateway path (e.g. `/auth/login/request-otp`), never the
  /// browser proxy prefix (`/api/...`).
  static String _pathForSignature(RequestOptions options) {
    // Prefer the path passed to Dio (e.g. '/auth/login/request-otp').
    var path = options.path;
    if (path.isEmpty) {
      path = options.uri.path;
    }
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    final query = options.uri.query;
    if (query.isNotEmpty && !path.contains('?')) {
      path = '$path?$query';
    }
    // Resolved URI with base `.../api` can become `/api/auth/...`.
    if (path == '/api') {
      path = '/';
    } else if (path.startsWith('/api/')) {
      path = path.substring(4); // '/api'.length
    } else if (path.startsWith('/api?')) {
      path = path.replaceFirst('/api', '');
      if (!path.startsWith('/')) path = '/$path';
    }
    return path;
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final options = response.requestOptions;
    _recordApiLog(
      options,
      status: response.statusCode,
      responseBody: response.data,
    );
    final isAuthEndpoint = options.path.startsWith('/auth/');
    final alreadyRetried = options.extra[_retriedFlag] == true;
    if (response.statusCode != 401 || isAuthEndpoint || alreadyRetried) {
      return handler.next(response);
    }

    final refreshed = await _refreshOnce();
    if (!refreshed) {
      await storage.delete(SecureStorage.accessToken);
      await storage.delete(SecureStorage.refreshToken);
      onSessionExpired?.call();
      return handler.next(response);
    }

    try {
      options.extra[_retriedFlag] = true;
      final retried = await dio.fetch<dynamic>(options);
      return handler.resolve(retried);
    } catch (_) {
      return handler.next(response);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _recordApiLog(
      err.requestOptions,
      status: err.response?.statusCode,
      responseBody: err.response?.data,
      error: err.message,
    );
    handler.next(err);
  }

  void _recordApiLog(
    RequestOptions options, {
    required int? status,
    Object? responseBody,
    String? error,
  }) {
    final startedAt = options.extra['api_log_started_at'] as DateTime?;
    final path = options.uri.query.isEmpty
        ? options.path
        : '${options.path}?${options.uri.query}';
    ApiLogStore.instance.add(
      ApiLogEntry(
        time: DateTime.now(),
        method: options.method.toUpperCase(),
        path: path,
        status: status,
        duration: startedAt == null
            ? Duration.zero
            : DateTime.now().difference(startedAt),
        requestBody: options.data,
        responseBody: responseBody,
        error: error,
      ),
    );
  }

  Future<bool> _refreshOnce() {
    return _pendingRefresh ??=
        _doRefresh().whenComplete(() => _pendingRefresh = null);
  }

  Future<bool> _doRefresh() async {
    final refresh = await storage.read(SecureStorage.refreshToken);
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res =
          await dio.post<dynamic>('/auth/refresh', data: <String, dynamic>{
        'refresh_token': refresh,
      });
      if (res.statusCode != 200) return false;
      final data = res.data;
      if (data is! Map) return false;
      final access = data['access_token'];
      if (access is! String || access.isEmpty) return false;
      await storage.write(SecureStorage.accessToken, access);
      final rotated = data['refresh_token'];
      if (rotated is String && rotated.isNotEmpty) {
        await storage.write(SecureStorage.refreshToken, rotated);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
