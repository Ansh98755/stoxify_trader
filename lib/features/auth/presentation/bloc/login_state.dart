import 'package:equatable/equatable.dart';

class LoginState extends Equatable {
  const LoginState({this.phoneNumber = '', this.submissionCount = 0});

  final String phoneNumber;
  final int submissionCount;

  bool get isPhoneValid => phoneNumber.length == 10;

  LoginState copyWith({String? phoneNumber, int? submissionCount}) {
    return LoginState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      submissionCount: submissionCount ?? this.submissionCount,
    );
  }

  @override
  List<Object?> get props => <Object?>[phoneNumber, submissionCount];
}
