import '../../features/auth/domain/models/auth_user.dart';

class PermissionGuard {
  static bool hasPermission(AuthUser? user, String permission) {
    if (user == null) return false;

    switch (permission) {
      case 'ACADEMIC_MANAGEMENT':
      case 'USER_MANAGEMENT':
      case 'DEPARTMENT_MANAGEMENT':
      case 'BROADCAST_NOTIFICATION':
      case 'AUDIT_LOG_VIEW':
      case 'COLLEGE_SETTINGS_EDIT':
        return user.isAdmin;
      case 'TIMETABLE_COORDINATION':
        return user.isAdmin || user.isFaculty;
      case 'CAMPUS_MODERATION':
        return user.isAdmin;
      case 'PLACEMENT_MANAGEMENT':
        return user.isAdmin || user.isPlacementOfficer;
      case 'CREATE_POST':
        return true; // All authenticated users can create posts
      default:
        return false;
    }
  }

  static bool canManageDepartment(AuthUser? user, String? targetDepartmentId) {
    if (user == null) return false;
    return user.isAdmin;
  }

  static bool canModeratePost(AuthUser? user, String? postDepartmentId) {
    if (user == null) return false;
    return user.isAdmin;
  }

  static bool canBroadcastTo(AuthUser? user, String audience, String? departmentId) {
    if (user == null) return false;
    return user.isAdmin;
  }

  static bool canCreateCampusPost(AuthUser? user) {
    return user != null;
  }

  static bool canAccessAuditLogs(AuthUser? user) {
    return user != null && user.isAdmin;
  }

  static bool canAccessSystemSettings(AuthUser? user) {
    return user != null && user.isAdmin;
  }
}
