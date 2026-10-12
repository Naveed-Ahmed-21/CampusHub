import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

export '../../data/datasources/admin_remote_datasource.dart';

final adminMetricsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final user = ref.watch(authControllerProvider).asData?.value;
  if (user == null || !user.isAdmin) return {};
  return ref.watch(adminRemoteDataSourceProvider).getMetrics();
});

class AdminUsersFilter {
  final String? role;
  final String? search;

  const AdminUsersFilter({this.role, this.search});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminUsersFilter && role == other.role && search == other.search;

  @override
  int get hashCode => role.hashCode ^ search.hashCode;
}

final adminUsersProvider = FutureProvider.family<List<dynamic>, AdminUsersFilter?>((ref, filter) {
  return ref.watch(adminRemoteDataSourceProvider).getUsers(
        role: filter?.role,
        search: filter?.search,
      );
});

final adminBinUsersProvider = FutureProvider.family<List<dynamic>, AdminUsersFilter?>((ref, filter) {
  return ref.watch(adminRemoteDataSourceProvider).getBinUsers(
        role: filter?.role,
        search: filter?.search,
      );
});

final adminDepartmentsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRemoteDataSourceProvider).getDepartments();
});

final adminDepartmentOverviewProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, departmentId) {
  return ref.watch(adminRemoteDataSourceProvider).getDepartmentOverview(departmentId);
});

class DepartmentStudentsFilter {
  final String departmentId;
  final String? year;
  final String? search;
  final int? page;
  final int? limit;

  const DepartmentStudentsFilter({
    required this.departmentId,
    this.year,
    this.search,
    this.page,
    this.limit,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DepartmentStudentsFilter &&
          runtimeType == other.runtimeType &&
          departmentId == other.departmentId &&
          year == other.year &&
          search == other.search &&
          page == other.page &&
          limit == other.limit;

  @override
  int get hashCode => Object.hash(departmentId, year, search, page, limit);
}

final adminDepartmentStudentsProvider = FutureProvider.family<Map<String, dynamic>, DepartmentStudentsFilter>((ref, filter) {
  return ref.watch(adminRemoteDataSourceProvider).getDepartmentStudents(
        filter.departmentId,
        year: filter.year,
        search: filter.search,
        page: filter.page,
        limit: filter.limit,
      );
});

class DepartmentFacultyFilter {
  final String departmentId;
  final String? search;
  final int? page;
  final int? limit;

  const DepartmentFacultyFilter({
    required this.departmentId,
    this.search,
    this.page,
    this.limit,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DepartmentFacultyFilter &&
          runtimeType == other.runtimeType &&
          departmentId == other.departmentId &&
          search == other.search &&
          page == other.page &&
          limit == other.limit;

  @override
  int get hashCode => Object.hash(departmentId, search, page, limit);
}

final adminDepartmentFacultyProvider = FutureProvider.family<Map<String, dynamic>, DepartmentFacultyFilter>((ref, filter) {
  return ref.watch(adminRemoteDataSourceProvider).getDepartmentFaculty(
        filter.departmentId,
        search: filter.search,
        page: filter.page,
        limit: filter.limit,
      );
});

final adminAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminRemoteDataSourceProvider).getAnalytics();
});

final adminAuditReportsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRemoteDataSourceProvider).getAuditReports();
});

final adminAcademicYearsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRemoteDataSourceProvider).getAcademicYears();
});

final adminAcademicTermsProvider = FutureProvider.family<List<dynamic>, String?>((ref, yearId) {
  return ref.watch(adminRemoteDataSourceProvider).getAcademicTerms(academicYearId: yearId);
});

final adminProgramsProvider = FutureProvider.family<List<dynamic>, String?>((ref, deptId) {
  return ref.watch(adminRemoteDataSourceProvider).getAcademicPrograms(departmentId: deptId);
});

final adminBatchesProvider = FutureProvider.family<List<dynamic>, String?>((ref, programId) {
  return ref.watch(adminRemoteDataSourceProvider).getBatches(programId: programId);
});

class AdminSubjectsFilter {
  final String? departmentId;
  final String? semester;
  final String? academicTermId;

  const AdminSubjectsFilter({this.departmentId, this.semester, this.academicTermId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminSubjectsFilter &&
          departmentId == other.departmentId &&
          semester == other.semester &&
          academicTermId == other.academicTermId;

  @override
  int get hashCode => departmentId.hashCode ^ semester.hashCode ^ academicTermId.hashCode;
}

final adminSubjectsProvider = FutureProvider.family<List<dynamic>, AdminSubjectsFilter?>((ref, filter) {
  return ref.watch(adminRemoteDataSourceProvider).getSubjects(
        departmentId: filter?.departmentId,
        semester: filter?.semester,
        academicTermId: filter?.academicTermId,
      );
});

class AdminCurriculumFilter {
  final String? programId;
  final int? batchYear;
  final int? semesterNumber;

  const AdminCurriculumFilter({this.programId, this.batchYear, this.semesterNumber});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminCurriculumFilter &&
          programId == other.programId &&
          batchYear == other.batchYear &&
          semesterNumber == other.semesterNumber;

  @override
  int get hashCode => (programId.hashCode) ^ (batchYear.hashCode) ^ (semesterNumber.hashCode);
}

final adminCurriculumProvider = FutureProvider.family<List<dynamic>, AdminCurriculumFilter?>((ref, filter) {
  return ref.watch(adminRemoteDataSourceProvider).getCurriculumSubjects(
        programId: filter?.programId,
        batchYear: filter?.batchYear,
        semesterNumber: filter?.semesterNumber,
      );
});

class AdminClassesFilter {
  final String? departmentId;
  final int? yearOfStudy;
  final int? semester;

  const AdminClassesFilter({this.departmentId, this.yearOfStudy, this.semester});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminClassesFilter &&
          departmentId == other.departmentId &&
          yearOfStudy == other.yearOfStudy &&
          semester == other.semester;

  @override
  int get hashCode => (departmentId.hashCode) ^ (yearOfStudy.hashCode) ^ (semester.hashCode);
}

final adminClassesProvider = FutureProvider.family<List<dynamic>, AdminClassesFilter?>((ref, filter) {
  return ref.watch(adminRemoteDataSourceProvider).getAcademicClasses(
        departmentId: filter?.departmentId,
        yearOfStudy: filter?.yearOfStudy,
        semester: filter?.semester,
      );
});

class AdminRoomsFilter {
  final String? roomType;
  final bool? isActive;

  const AdminRoomsFilter({this.roomType, this.isActive});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminRoomsFilter && roomType == other.roomType && isActive == other.isActive;

  @override
  int get hashCode => roomType.hashCode ^ isActive.hashCode;
}

final adminRoomsProvider = FutureProvider.family<List<dynamic>, AdminRoomsFilter?>((ref, filter) {
  return ref.watch(adminRemoteDataSourceProvider).getRooms(
        roomType: filter?.roomType,
        isActive: filter?.isActive,
      );
});

class AdminFacultyAssignmentsFilter {
  final String? facultyId;
  final String? subjectId;
  final String? academicTermId;

  const AdminFacultyAssignmentsFilter({this.facultyId, this.subjectId, this.academicTermId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminFacultyAssignmentsFilter &&
          facultyId == other.facultyId &&
          subjectId == other.subjectId &&
          academicTermId == other.academicTermId;

  @override
  int get hashCode => (facultyId.hashCode) ^ (subjectId.hashCode) ^ (academicTermId.hashCode);
}

final adminFacultyAssignmentsProvider =
    FutureProvider.family<List<dynamic>, AdminFacultyAssignmentsFilter?>((ref, filter) {
  return ref.watch(adminRemoteDataSourceProvider).getFacultyAssignments(
        facultyId: filter?.facultyId,
        subjectId: filter?.subjectId,
        academicTermId: filter?.academicTermId,
      );
});

class AdminSchedulesFilter {
  final String? facultyId;
  final String? classId;
  final String? roomId;
  final String? dayOfWeek;
  final String? academicTermId;

  const AdminSchedulesFilter({
    this.facultyId,
    this.classId,
    this.roomId,
    this.dayOfWeek,
    this.academicTermId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminSchedulesFilter &&
          facultyId == other.facultyId &&
          classId == other.classId &&
          roomId == other.roomId &&
          dayOfWeek == other.dayOfWeek &&
          academicTermId == other.academicTermId;

  @override
  int get hashCode =>
      (facultyId.hashCode) ^
      (classId.hashCode) ^
      (roomId.hashCode) ^
      (dayOfWeek.hashCode) ^
      (academicTermId.hashCode);
}

final adminSchedulesProvider =
    FutureProvider.family<List<dynamic>, AdminSchedulesFilter?>((ref, filter) {
  return ref.watch(adminRemoteDataSourceProvider).getSchedules(
        facultyId: filter?.facultyId,
        classId: filter?.classId,
        roomId: filter?.roomId,
        dayOfWeek: filter?.dayOfWeek,
        academicTermId: filter?.academicTermId,
      );
});

class AdminMonitoringFilter {
  final String? departmentId;
  final String? subjectId;
  final String? academicTermId;

  const AdminMonitoringFilter({
    this.departmentId,
    this.subjectId,
    this.academicTermId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminMonitoringFilter &&
          departmentId == other.departmentId &&
          subjectId == other.subjectId &&
          academicTermId == other.academicTermId;

  @override
  int get hashCode =>
      (departmentId.hashCode) ^ (subjectId.hashCode) ^ (academicTermId.hashCode);
}

final adminMonitoringMetricsProvider =
    FutureProvider.family<Map<String, dynamic>, String?>((ref, departmentId) {
  return ref.watch(adminRemoteDataSourceProvider).getAcademicMonitoringMetrics(
        departmentId: departmentId,
      );
});

final adminMonitoringAttendanceProvider =
    FutureProvider.family<List<dynamic>, AdminMonitoringFilter?>((ref, filter) {
  return ref.watch(adminRemoteDataSourceProvider).getMonitoringAttendanceSessions(
        departmentId: filter?.departmentId,
        subjectId: filter?.subjectId,
        academicTermId: filter?.academicTermId,
      );
});

final adminMonitoringAssignmentsProvider =
    FutureProvider.family<List<dynamic>, AdminMonitoringFilter?>((ref, filter) {
  return ref.watch(adminRemoteDataSourceProvider).getMonitoringAssignments(
        departmentId: filter?.departmentId,
        subjectId: filter?.subjectId,
        academicTermId: filter?.academicTermId,
      );
});

final adminMonitoringAssessmentsProvider =
    FutureProvider.family<List<dynamic>, AdminMonitoringFilter?>((ref, filter) {
  return ref.watch(adminRemoteDataSourceProvider).getMonitoringAssessments(
        departmentId: filter?.departmentId,
        subjectId: filter?.subjectId,
        academicTermId: filter?.academicTermId,
      );
});

// ==========================================
// PHASE 7: MODERATION & BROADCAST PROVIDERS
// ==========================================
class AdminModerationEventFilter {
  final String? departmentId;
  final String? scope;

  const AdminModerationEventFilter({this.departmentId, this.scope});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminModerationEventFilter &&
          departmentId == other.departmentId &&
          scope == other.scope;

  @override
  int get hashCode => (departmentId.hashCode) ^ (scope.hashCode);
}

final adminModerationEventsProvider =
    FutureProvider.family<List<dynamic>, AdminModerationEventFilter?>((ref, filter) {
  return ref.watch(adminRemoteDataSourceProvider).getModerationEvents(
        departmentId: filter?.departmentId,
        scope: filter?.scope,
      );
});

class AdminModerationPostFilter {
  final String? departmentId;
  final String? clubId;

  const AdminModerationPostFilter({this.departmentId, this.clubId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminModerationPostFilter &&
          departmentId == other.departmentId &&
          clubId == other.clubId;

  @override
  int get hashCode => (departmentId.hashCode) ^ (clubId.hashCode);
}

final adminModerationPostsProvider =
    FutureProvider.family<List<dynamic>, AdminModerationPostFilter?>((ref, filter) {
  return ref.watch(adminRemoteDataSourceProvider).getModerationPosts(
        departmentId: filter?.departmentId,
        clubId: filter?.clubId,
      );
});

// ==========================================
// PHASE 8: PLACEMENT & CAREER ADMIN PROVIDERS
// ==========================================
final adminPlacementOfficerStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminRemoteDataSourceProvider).getPlacementOfficerStats();
});

class AdminPlacementDrivesFilter {
  final String? status;
  final String? search;

  const AdminPlacementDrivesFilter({this.status, this.search});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminPlacementDrivesFilter &&
          status == other.status &&
          search == other.search;

  @override
  int get hashCode => (status.hashCode) ^ (search.hashCode);
}

final adminPlacementDrivesProvider =
    FutureProvider.family<List<dynamic>, AdminPlacementDrivesFilter?>((ref, filter) {
  return ref.watch(adminRemoteDataSourceProvider).getPlacementDrives(
        status: filter?.status,
        search: filter?.search,
      );
});

final adminPlacementDriveDetailsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, driveId) {
  return ref.watch(adminRemoteDataSourceProvider).getPlacementDriveDetails(driveId);
});

// ==========================================
// PHASE 9: INSTITUTIONAL SETTINGS & AUDIT PROVIDERS
// ==========================================
final adminCollegeSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final user = ref.watch(authControllerProvider).asData?.value;
  if (user == null || !user.isAdmin) return {};
  return ref.watch(adminRemoteDataSourceProvider).getCollegeSettings();
});

class AdminAuditLogsFilter {
  final String? action;
  final String? category;
  final String? entityType;

  const AdminAuditLogsFilter({this.action, this.category, this.entityType});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminAuditLogsFilter &&
          action == other.action &&
          category == other.category &&
          entityType == other.entityType;

  @override
  int get hashCode => (action.hashCode) ^ (category.hashCode) ^ (entityType.hashCode);
}

final adminAuditReportsFilteredProvider =
    FutureProvider.family<List<dynamic>, AdminAuditLogsFilter?>((ref, filter) {
  return ref.watch(adminRemoteDataSourceProvider).getAuditReports(
        action: filter?.action,
        category: filter?.category,
        entityType: filter?.entityType,
      );
});

// ==========================================
// PHASE 10: PROFILE CHANGE REQUESTS
// ==========================================
class AdminChangeRequestsFilter {
  final String? status;
  final String? departmentId;
  final String? category;
  final int? page;
  final int? limit;

  const AdminChangeRequestsFilter({
    this.status,
    this.departmentId,
    this.category,
    this.page,
    this.limit,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminChangeRequestsFilter &&
          status == other.status &&
          departmentId == other.departmentId &&
          category == other.category &&
          page == other.page &&
          limit == other.limit;

  @override
  int get hashCode =>
      (status.hashCode) ^
      (departmentId.hashCode) ^
      (category.hashCode) ^
      (page.hashCode) ^
      (limit.hashCode);
}

final adminChangeRequestsProvider =
    FutureProvider.family<Map<String, dynamic>, AdminChangeRequestsFilter?>((ref, filter) {
  return ref.watch(adminRemoteDataSourceProvider).getChangeRequests(
        status: filter?.status,
        departmentId: filter?.departmentId,
        category: filter?.category,
        page: filter?.page,
        limit: filter?.limit,
      );
});

final adminPendingChangeRequestsCountProvider = FutureProvider<int>((ref) async {
  final res = await ref.watch(adminRemoteDataSourceProvider).getChangeRequests(
        status: 'PENDING',
        limit: 1,
      );
  return (res['total'] as num?)?.toInt() ?? 0;
});





