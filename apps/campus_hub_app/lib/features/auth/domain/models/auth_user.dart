import 'package:freezed_annotation/freezed_annotation.dart';
import 'user_role.dart';

part 'auth_user.freezed.dart';
part 'auth_user.g.dart';

@freezed
class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String id,
    required String email,
    required String firstName,
    required String lastName,
    required String role,
    required String collegeId,
    String? departmentId,
    String? rollNumber,
  }) = _AuthUser;

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      _$AuthUserFromJson(json);
}

extension AuthUserRoleX on AuthUser {
  UserRole get userRole => UserRole.fromString(role);
  bool get isStudent => userRole == UserRole.student;
  bool get isFaculty => userRole == UserRole.faculty;
  bool get isPlacementOfficer => userRole == UserRole.placementOfficer;
  bool get isAdmin => userRole == UserRole.admin;
}
