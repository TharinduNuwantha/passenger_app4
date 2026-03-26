class UserModel {
  final String id;
  final String phoneNumber;
  final String? firstName;
  final String? lastName;
  final String? email;
  final List<String> roles;
  final bool profileCompleted;
  final bool phoneVerified;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.id,
    required this.phoneNumber,
    this.firstName,
    this.lastName,
    this.email,
    required this.roles,
    required this.profileCompleted,
    required this.phoneVerified,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
  });

  // From JSON - matches backend response
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phoneNumber:
          json['phone']
              as String, // Backend returns 'phone', not 'phone_number'
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      roles:
          (json['roles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['passenger'],
      profileCompleted: json['profile_completed'] as bool? ?? false,
      phoneVerified: json['phone_verified'] as bool? ?? false,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phoneNumber,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'roles': roles,
      'profile_completed': profileCompleted,
      'phone_verified': phoneVerified,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  // Computed properties
  bool get isNewUser => !profileCompleted;

  String get name {
    if (firstName == null && lastName == null) return '';
    return '${firstName ?? ''} ${lastName ?? ''}'.trim();
  }

  String get fullName => name;

  // Copy with
  UserModel copyWith({
    String? id,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    String? email,
    List<String>? roles,
    bool? profileCompleted,
    bool? phoneVerified,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      roles: roles ?? this.roles,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, phoneNumber: $phoneNumber, name: $name, email: $email, roles: $roles, profileCompleted: $profileCompleted)';
  }
}
