class AuthException implements Exception {
  AuthException(this.code, this.message, {this.statusCode});

  final String code;
  final String message;
  final int? statusCode;

  @override
  String toString() => 'AuthException($code: $message)';
}
