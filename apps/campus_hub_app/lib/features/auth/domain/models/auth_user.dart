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
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
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
    );
  }

  bool get isStudent => role == 'STUDENT';
  bool get isFaculty => role == 'FACULTY';
  bool get isPlacementOfficer => role == 'PLACEMENT_OFFICER';
  bool get isAdmin => role == 'ADMIN' || role == 'COLLEGE_ADMIN' || role == 'SUPER_ADMIN';

  UserRole get userRole {
    switch (role) {
      case 'STUDENT':
        return UserRole.student;
      case 'FACULTY':
        return UserRole.faculty;
      case 'PLACEMENT_OFFICER':
        return UserRole.placementOfficer;
      case 'ADMIN':
      case 'COLLEGE_ADMIN':
      case 'SUPER_ADMIN':
        return UserRole.admin;
      default:
        return UserRole.student;
    }
  }
}
