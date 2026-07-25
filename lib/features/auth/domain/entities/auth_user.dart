class AuthUser {
  const AuthUser({
    required this.userId,
    required this.name,
    required this.phone,
    required this.state,
    this.email,
    this.isNewUser = false,
    this.interests = const [],
    this.deletionCancelled = false,
  });

  final String userId;
  final String name;
  final String phone;
  final String state;
  final String? email;
  final bool isNewUser;
  final List<String> interests;
  final bool deletionCancelled;

  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'there';
    if (RegExp(r'^User \d{3,}$').hasMatch(trimmed)) return trimmed;
    return trimmed.split(RegExp(r'\s+')).first;
  }

  factory AuthUser.fromVerifyResponse(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return AuthUser(
      userId: user['user_id'] as String,
      name: user['name'] as String? ?? '',
      phone: user['phone'] as String? ?? '',
      state: user['state'] as String? ?? '',
      email: user['email'] as String?,
      isNewUser: json['is_new_user'] as bool? ?? false,
      interests: (user['interests'] as List?)?.cast<String>() ?? const [],
      deletionCancelled: json['deletion_cancelled'] as bool? ?? false,
    );
  }

  factory AuthUser.fromProfile(Map<String, dynamic> json) {
    return AuthUser(
      userId: json['user_id'] as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      state: json['state'] as String? ?? '',
      email: json['email'] as String?,
      interests: (json['interests'] as List?)?.cast<String>() ?? const [],
    );
  }
}
