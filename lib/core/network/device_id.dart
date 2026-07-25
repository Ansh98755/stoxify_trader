import 'package:uuid/uuid.dart';

import '../storage/secure_storage.dart';

/// Stable per-install device id sent as `X-Device-ID`.
class DeviceIdProvider {
  DeviceIdProvider(this._storage);

  final SecureStorage _storage;
  String? _cached;

  Future<String> get() async {
    if (_cached != null) return _cached!;
    final existing = await _storage.read(SecureStorage.deviceId);
    if (existing != null && existing.isNotEmpty) {
      _cached = existing;
      return existing;
    }
    final generated = const Uuid().v4();
    await _storage.write(SecureStorage.deviceId, generated);
    _cached = generated;
    return generated;
  }
}
