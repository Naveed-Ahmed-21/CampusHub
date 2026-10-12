import 'user_role.dart';

class AuthUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String collegeId;
  final String? departmentId;
  final String? rollNumber;
  final String? avatarUrl;
  final String? phone;
  final DateTime? lastSeen;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isPasswordConfigured;
  final bool isProfileCompleted;
  final bool firstLoginCompleted;
  final String status;

  const AuthUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.collegeId,
    this.departmentId,
    this.rollNumber,
    this.avatarUrl,
    this.phone,
    this.lastSeen,
    this.createdAt,
    this.updatedAt,
    this.isPasswordConfigured = true,
    this.isProfileCompleted = true,
    this.firstLoginCompleted = true,
    this.status = 'ACTIVE',
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    return AuthUser(
      id: json['id'] as String? ?? json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? json['first_name'] as String? ?? '',
      lastName: json['lastName'] as String? ?? json['last_name'] as String? ?? '',
      role: json['role'] as String? ?? 'STUDENT',
      collegeId: json['collegeId'] as String? ?? json['college_id'] as String? ?? '',
      departmentId: json['departmentId'] as String? ?? json['department_id'] as String?,
      rollNumber: json['rollNumber'] as String? ?? json['roll_number'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      lastSeen: parseDate(json['lastSeen'] ?? json['last_seen']),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
      isPasswordConfigured: json['isPasswordConfigured'] as bool? ??
          json['is_password_configured'] as bool? ??
          true,
      isProfileCompleted: json['isProfileCompleted'] as bool? ??
          json['is_profile_completed'] as bool? ??
          true,
      firstLoginCompleted: json['firstLoginCompleted'] as bool? ??
          json['first_login_completed'] as bool? ??
          true,
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'collegeId': collegeId,
      'departmentId': departmentId,
      'rollNumber': rollNumber,
      'avatarUrl': avatarUrl,
      'phone': phone,
      'lastSeen': lastSeen?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isPasswordConfigured': isPasswordConfigured,
      'isProfileCompleted': isProfileCompleted,
      'firstLoginCompleted': firstLoginCompleted,
      'status': status,
    };
  }

  AuthUser copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? role,
    String? collegeId,
    String? departmentId,
    String? rollNumber,
    String? avatarUrl,
    String? phone,
    DateTime? lastSeen,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPasswordConfigured,
    bool? isProfileCompleted,
    bool? firstLoginCompleted,
    String? status,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      rollNumber: rollNumber ?? this.rollNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPasswordConfigured: isPasswordConfigured ?? this.isPasswordConfigured,
      isProfileCompleted: isProfileCompleted ?? this.isProfileCompleted,
      firstLoginCompleted: firstLoginCompleted ?? this.firstLoginCompleted,
      status: status ?? this.status,
    );
  }


  String get fullName => '$firstName $lastName'.trim().isEmpty ? email : '$firstName $lastName'.trim();

  bool get isStudent => role == 'STUDENT';
  bool get isFaculty => role == 'FACULTY';
  bool get isPlacementOfficer => role == 'PLACEMENT' || role == 'PLACEMENT_OFFICER';
  bool get isAdmin =>
      role == 'ADMIN' ||
      role == 'DEPT_ADMIN';
  bool get isMainAdmin => role == 'ADMIN';
  bool get isDeptAdmin => role == 'DEPT_ADMIN';
  bool get isSuperAdmin => false;
  bool get isCollegeAdmin => false;
  bool get isClubCoordinator => false;

  UserRole get userRole => UserRole.fromString(role);
}
