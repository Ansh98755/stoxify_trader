import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable implements Exception {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No Internet Connection']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Session expired. Please sign in again.']);
}
