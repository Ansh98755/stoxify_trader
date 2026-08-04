import 'package:flutter/foundation.dart';

class ApiLogEntry {
  const ApiLogEntry({
    required this.time,
    required this.method,
    required this.path,
    required this.status,
    required this.duration,
    this.requestBody,
    this.responseBody,
    this.error,
  });

  final DateTime time;
  final String method;
  final String path;
  final int? status;
  final Duration duration;
  final Object? requestBody;
  final Object? responseBody;
  final String? error;
}

/// In-memory debug diagnostics only. No request bodies or auth headers are kept.
class ApiLogStore {
  ApiLogStore._();

  static final ApiLogStore instance = ApiLogStore._();
  final ValueNotifier<List<ApiLogEntry>> entries =
      ValueNotifier<List<ApiLogEntry>>(const <ApiLogEntry>[]);

  void add(ApiLogEntry entry) {
    final updated = <ApiLogEntry>[entry, ...entries.value];
    entries.value = updated.take(100).toList(growable: false);
  }

  void clear() => entries.value = const <ApiLogEntry>[];
}
