import 'package:equatable/equatable.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => const [];
}

final class LoginPhoneChanged extends LoginEvent {
  const LoginPhoneChanged(this.phoneNumber);

  final String phoneNumber;

  @override
  List<Object?> get props => [phoneNumber];
}

final class LoginSubmitted extends LoginEvent {
  const LoginSubmitted();
}

final class LoginOtpSubmitted extends LoginEvent {
  const LoginOtpSubmitted(this.otp);

  final String otp;

  @override
  List<Object?> get props => [otp];
}

final class LoginOtpResendRequested extends LoginEvent {
  const LoginOtpResendRequested();
}
