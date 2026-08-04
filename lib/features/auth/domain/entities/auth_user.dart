class AuthUser {
  const AuthUser({
    required this.userId,
    required this.name,
    required this.phone,
    required this.state,
    this.databaseId,
    this.userType,
    this.email,
    this.profilePicUrl,
    this.isNewUser = false,
    this.interests = const [],
    this.deletionCancelled = false,
    this.lastLogin,
    this.failedLoginAttempts = 0,
    this.deletionRequestedAt,
    this.deletionScheduledAt,
    this.deletionReminderSentAt,
    this.stateBeforeDeletion,
    this.aadhaarVerified = false,
    this.verificationAttempts = 0,
    this.kycVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.stateHistory = const [],
  });

  final String userId;
  final String name;
  final String phone;
  final String state;
  final String? databaseId;
  final String? userType;
  final String? email;
  final String? profilePicUrl;
  final bool isNewUser;
  final List<String> interests;
  final bool deletionCancelled;
  final DateTime? lastLogin;
  final int failedLoginAttempts;
  final DateTime? deletionRequestedAt;
  final DateTime? deletionScheduledAt;
  final DateTime? deletionReminderSentAt;
  final String? stateBeforeDeletion;
  final bool aadhaarVerified;
  final int verificationAttempts;
  final DateTime? kycVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<AuthStateHistoryEntry> stateHistory;

  String get firstName {
    var trimmed = name.trim();
    if (trimmed.isEmpty) return 'there';
    if (RegExp(r'^User \d{3,}$').hasMatch(trimmed)) return trimmed;

    // Strip "I'm ", "Im ", "I am " prefix if present.
    trimmed = trimmed.replaceFirst(RegExp(r"^(i'm|im|i am)\s+", caseSensitive: false), '');
    if (trimmed.isEmpty) return 'there';

    return trimmed.split(RegExp(r'\s+')).first;
  }

  AuthUser copyWith({
    String? name,
    String? email,
    String? profilePicUrl,
  }) {
    return AuthUser(
      userId: userId,
      name: name ?? this.name,
      phone: phone,
      state: state,
      databaseId: databaseId,
      userType: userType,
      email: email ?? this.email,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      isNewUser: isNewUser,
      interests: interests,
      deletionCancelled: deletionCancelled,
      lastLogin: lastLogin,
      failedLoginAttempts: failedLoginAttempts,
      deletionRequestedAt: deletionRequestedAt,
      deletionScheduledAt: deletionScheduledAt,
      deletionReminderSentAt: deletionReminderSentAt,
      stateBeforeDeletion: stateBeforeDeletion,
      aadhaarVerified: aadhaarVerified,
      verificationAttempts: verificationAttempts,
      kycVerifiedAt: kycVerifiedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      stateHistory: stateHistory,
    );
  }

  factory AuthUser.fromVerifyResponse(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return AuthUser(
      userId: user['user_id'] as String,
      name: user['name'] as String? ?? '',
      phone: user['phone'] as String? ?? '',
      state: user['state'] as String? ?? '',
      email: user['email'] as String?,
      profilePicUrl: user['profile_pic_url'] as String?,
      isNewUser: json['is_new_user'] as bool? ?? false,
      interests: (user['interests'] as List?)?.cast<String>() ?? const [],
      deletionCancelled: json['deletion_cancelled'] as bool? ?? false,
    );
  }

  factory AuthUser.fromProfile(Map<String, dynamic> json) {
    final kyc = json['kyc'] is Map
        ? (json['kyc'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    return AuthUser(
      userId: json['user_id'] as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      state: json['state'] as String? ?? '',
      databaseId: json['_id'] as String?,
      userType: json['user_type'] as String?,
      email: json['email'] as String?,
      profilePicUrl: json['profile_pic_url'] as String?,
      interests: (json['interests'] as List?)?.cast<String>() ?? const [],
      lastLogin: _date(json['last_login']),
      failedLoginAttempts:
          (json['failed_login_attempts'] as num?)?.toInt() ?? 0,
      deletionRequestedAt: _date(json['deletion_requested_at']),
      deletionScheduledAt: _date(json['deletion_scheduled_at']),
      deletionReminderSentAt: _date(json['deletion_reminder_sent_at']),
      stateBeforeDeletion: json['state_before_deletion'] as String?,
      aadhaarVerified: kyc['aadhaar_verified'] as bool? ?? false,
      verificationAttempts:
          (kyc['verification_attempts'] as num?)?.toInt() ?? 0,
      kycVerifiedAt: _date(kyc['verified_at']),
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
      stateHistory: (json['state_history'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => AuthStateHistoryEntry.fromJson(
              item.cast<String, dynamic>(),
            ),
          )
          .toList(),
    );
  }

  static DateTime? _date(dynamic value) =>
      value is String ? DateTime.tryParse(value) : null;
}

class AuthStateHistoryEntry {
  const AuthStateHistoryEntry({
    this.fromState,
    required this.toState,
    this.timestamp,
    required this.reason,
    required this.changedBy,
  });

  final String? fromState;
  final String toState;
  final DateTime? timestamp;
  final String reason;
  final String changedBy;

  factory AuthStateHistoryEntry.fromJson(Map<String, dynamic> json) {
    return AuthStateHistoryEntry(
      fromState: json['from_state'] as String?,
      toState: json['to_state'] as String? ?? '',
      timestamp: AuthUser._date(json['timestamp']),
      reason: json['reason'] as String? ?? '',
      changedBy: json['changed_by'] as String? ?? '',
    );
  }
}
