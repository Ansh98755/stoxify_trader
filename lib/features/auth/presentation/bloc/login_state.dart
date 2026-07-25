import 'package:equatable/equatable.dart';

class LoginState extends Equatable {
  const LoginState({
    this.phoneNumber = '',
    this.isSubmitting = false,
    this.otpSentCount = 0,
    this.verifySuccessCount = 0,
    this.isNewUser = false,
    this.errorMessage,
  });

  final String phoneNumber;
  final bool isSubmitting;
  final int otpSentCount;
  final int verifySuccessCount;
  final bool isNewUser;
  final String? errorMessage;

  bool get isPhoneValid => phoneNumber.length == 10;

  String get e164Phone => '+91$phoneNumber';

  LoginState copyWith({
    String? phoneNumber,
    bool? isSubmitting,
    int? otpSentCount,
    int? verifySuccessCount,
    bool? isNewUser,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LoginState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      otpSentCount: otpSentCount ?? this.otpSentCount,
      verifySuccessCount: verifySuccessCount ?? this.verifySuccessCount,
      isNewUser: isNewUser ?? this.isNewUser,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        phoneNumber,
        isSubmitting,
        otpSentCount,
        verifySuccessCount,
        isNewUser,
        errorMessage,
      ];
}
