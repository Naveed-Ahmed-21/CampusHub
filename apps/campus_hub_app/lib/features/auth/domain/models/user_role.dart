enum UserRole {
  student,
  faculty,
  placementOfficer,
  admin;

  static UserRole fromString(String? role) {
    if (role == null) return UserRole.student;
    final upper = role.toUpperCase();
    switch (upper) {
      case 'FACULTY':
        return UserRole.faculty;
      case 'PLACEMENT_OFFICER':
        return UserRole.placementOfficer;
      case 'ADMIN':
      case 'COLLEGE_ADMIN':
      case 'SUPER_ADMIN':
      case 'DEPT_ADMIN':
        return UserRole.admin;
      case 'STUDENT':
      default:
        return UserRole.student;
    }
  }

  String toServerString() {
    switch (this) {
      case UserRole.faculty:
        return 'FACULTY';
      case UserRole.placementOfficer:
        return 'PLACEMENT_OFFICER';
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.student:
        return 'STUDENT';
    }
  }
}
