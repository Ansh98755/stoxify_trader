import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<void> requestOtp(String phoneE164);

  Future<AuthUser> verifyOtp({
    required String phoneE164,
    required String otp,
  });

  Future<AuthUser> getMe();

  Future<void> updateInterests(List<String> interests);

  Future<String> requestWsChannel();

  Future<void> logout();
}
