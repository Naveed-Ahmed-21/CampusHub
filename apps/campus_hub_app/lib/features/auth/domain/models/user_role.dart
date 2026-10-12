enum UserRole {
  admin,
  deptAdmin,
  faculty,
  placement,
  student;

  /// Compatibility alias for placement
  static const UserRole placementOfficer = UserRole.placement;

  static UserRole fromString(String? role) {
    if (role == null) return UserRole.student;
    final upper = role.toUpperCase();
    switch (upper) {
      case 'ADMIN':
      case 'SUPER_ADMIN':
      case 'COLLEGE_ADMIN':
        return UserRole.admin;
      case 'DEPT_ADMIN':
        return UserRole.deptAdmin;
      case 'FACULTY':
        return UserRole.faculty;
      case 'PLACEMENT':
      case 'PLACEMENT_OFFICER':
        return UserRole.placement;
      case 'STUDENT':
      default:
        return UserRole.student;
    }
  }

  String toServerString() {
    switch (this) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.deptAdmin:
        return 'DEPT_ADMIN';
      case UserRole.faculty:
        return 'FACULTY';
      case UserRole.placement:
        return 'PLACEMENT';
      case UserRole.student:
        return 'STUDENT';
    }
  }
}
