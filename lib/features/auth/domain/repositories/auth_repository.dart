import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<void> requestOtp(String phoneE164);

  /// Sends an OTP to the account phone before an account deletion request.
  /// Returns the masked destination supplied by the server.
  Future<String> requestAccountDeletionOtp();

  /// Confirms account deletion with the OTP and the user's stated reason.
  /// Returns the scheduled deletion time when supplied by the API.
  Future<DateTime?> deleteAccount({required String otp, required String reason});

  Future<AuthUser> verifyOtp({
    required String phoneE164,
    required String otp,
  });

  Future<AuthUser> getMe();

  Future<AuthUser> updateProfile({
    String? name,
    String? email,
    String? profilePicUrl,
  });

  /// Upload avatar image. [imageBase64] is the base64-encoded image bytes.
  /// [contentType] is e.g. 'image/jpeg' or 'image/png'.
  /// Returns the hosted URL of the uploaded avatar.
  Future<String> uploadAvatar({
    required String imageBase64,
    required String contentType,
  });

  Future<void> updateInterests(List<String> interests);

  /// Submit Aadhaar number for KYC verification.
  /// Returns the updated account state (e.g. 'ACTIVE') on success.
  Future<String> submitKyc({required String aadhaarNumber});

  Future<void> refreshToken();

  Future<String> requestWsChannel();

  Future<void> logout();
}
