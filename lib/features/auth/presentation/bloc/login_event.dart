import 'package:equatable/equatable.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

final class LoginPhoneChanged extends LoginEvent {
  const LoginPhoneChanged(this.phoneNumber);

  final String phoneNumber;

  @override
  List<Object?> get props => <Object?>[phoneNumber];
}

final class LoginSubmitted extends LoginEvent {
  const LoginSubmitted();
}
