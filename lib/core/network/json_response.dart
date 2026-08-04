import 'package:dio/dio.dart';

/// Safely treat a Dio `response.data` value as a JSON object.
///
/// Avoids `type 'String' is not a subtype of type 'Map'` when Vercel (or
/// another host) returns SPA `index.html` instead of JSON.
Map<String, dynamic> requireJsonMap(dynamic data, {String? context}) {
  if (data is Map) {
    return data.cast<String, dynamic>();
  }
  final where = context == null ? '' : ' ($context)';
  if (data is String) {
    final t = data.trimLeft();
    if (t.startsWith('<!DOCTYPE') ||
        t.startsWith('<!doctype') ||
        t.startsWith('<html')) {
      throw DioException(
        requestOptions: RequestOptions(path: context ?? ''),
        type: DioExceptionType.badResponse,
        message:
            'API returned HTML instead of JSON$where. Check API base URL.',
        error: 'API_HTML_RESPONSE',
      );
    }
  }
  throw DioException(
    requestOptions: RequestOptions(path: context ?? ''),
    type: DioExceptionType.badResponse,
    message: 'Unexpected API response type ${data.runtimeType}$where',
    error: 'API_BAD_JSON',
  );
}

Map<String, dynamic>? tryJsonMap(dynamic data) {
  if (data is Map) return data.cast<String, dynamic>();
  return null;
}
