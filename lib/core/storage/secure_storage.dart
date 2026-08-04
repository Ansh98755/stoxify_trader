import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around [FlutterSecureStorage] for tokens and device id.
class SecureStorage {
  SecureStorage();

  // On web, flutter_secure_storage falls back to localStorage.
  // Passing WebOptions ensures the key prefix is set and iDBNoWrap is false
  // so reads/writes work correctly across page reloads.
  static final FlutterSecureStorage _storage = FlutterSecureStorage(
    webOptions: const WebOptions(
      dbName: 'stoxify_secure',
      publicKey: 'stoxify_key',
    ),
  );

  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String deviceId = 'device_id';

  /// Written when OTP verification identifies a new user. It lasts for the
  /// signed-in session and is cleared on logout.
  static const String isNewUser = 'is_new_user';

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> clear() => _storage.deleteAll();

  Future<void> clearSession() async {
    await Future.wait(<Future<void>>[
      delete(accessToken),
      delete(refreshToken),
      delete(isNewUser),
    ]);
  }

  Future<bool> get hasToken async => (await read(accessToken)) != null;
}
