import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/dept_admin_repository.dart';
import '../../domain/models/dept_admin_models.dart';

class DeptStudentsFilter {
  final String? year;
  final String? batchId;
  final String? section;
  final String? search;
  final String? placementStatus;

  const DeptStudentsFilter({
    this.year,
    this.batchId,
    this.section,
    this.search,
    this.placementStatus,
  });

  DeptStudentsFilter copyWith({
    String? year,
    String? batchId,
    String? section,
    String? search,
    String? placementStatus,
  }) {
    return DeptStudentsFilter(
      year: year ?? this.year,
      batchId: batchId ?? this.batchId,
      section: section ?? this.section,
      search: search ?? this.search,
      placementStatus: placementStatus ?? this.placementStatus,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeptStudentsFilter &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          batchId == other.batchId &&
          section == other.section &&
          search == other.search &&
          placementStatus == other.placementStatus;

  @override
  int get hashCode =>
      year.hashCode ^
      batchId.hashCode ^
      section.hashCode ^
      search.hashCode ^
      placementStatus.hashCode;
}

// 1. Dashboard Provider
final deptDashboardProvider = FutureProvider<DeptDashboardData>((ref) async {
  final repo = ref.watch(deptAdminRepositoryProvider);
  return repo.getDashboard();
});

// 2. Students Provider
final deptStudentsFilterProvider = StateProvider<DeptStudentsFilter>((ref) {
  return const DeptStudentsFilter();
});

final deptStudentsListProvider = FutureProvider<List<DeptStudent>>((ref) async {
  final repo = ref.watch(deptAdminRepositoryProvider);
  final filter = ref.watch(deptStudentsFilterProvider);
  return repo.getStudents(
    year: filter.year,
    batchId: filter.batchId,
    section: filter.section,
    search: filter.search,
    placementStatus: filter.placementStatus,
  );
});

final deptStudentDetailProvider = FutureProvider.family<DeptStudentDetail, String>((ref, id) async {
  final repo = ref.watch(deptAdminRepositoryProvider);
  return repo.getStudentById(id);
});

// 3. Faculty Provider
final deptFacultySearchProvider = StateProvider<String>((ref) => '');

final deptFacultyProvider = FutureProvider<List<DeptFaculty>>((ref) async {
  final repo = ref.watch(deptAdminRepositoryProvider);
  final search = ref.watch(deptFacultySearchProvider);
  return repo.getFaculty(search: search.isNotEmpty ? search : null);
});

// 4. Academics Provider
final deptAcademicsProvider = FutureProvider<DeptAcademicsData>((ref) async {
  final repo = ref.watch(deptAdminRepositoryProvider);
  return repo.getAcademics();
});

// 5. Timetable Provider
final deptTimetableDayProvider = StateProvider<String>((ref) => 'MONDAY');
final deptTimetableClassProvider = StateProvider<String?>((ref) => null);

final deptTimetableProvider = FutureProvider<List<DeptTimetableSlot>>((ref) async {
  final repo = ref.watch(deptAdminRepositoryProvider);
  final day = ref.watch(deptTimetableDayProvider);
  final classId = ref.watch(deptTimetableClassProvider);
  return repo.getTimetable(dayOfWeek: day, classId: classId);
});

// 6. Attendance Providers
final deptAttendanceProvider = FutureProvider<DeptAttendanceData>((ref) async {
  final repo = ref.watch(deptAdminRepositoryProvider);
  return repo.getAttendance();
});

final deptLowAttendanceProvider = FutureProvider<List<DeptLowAttendanceStudent>>((ref) async {
  final repo = ref.watch(deptAdminRepositoryProvider);
  return repo.getLowAttendanceStudents();
});

// 7. Assignments & Assessments
final deptAssignmentsStatusFilterProvider = StateProvider<String?>((ref) => null);

final deptAssignmentsProvider = FutureProvider<List<DeptAssignment>>((ref) async {
  final repo = ref.watch(deptAdminRepositoryProvider);
  final status = ref.watch(deptAssignmentsStatusFilterProvider);
  return repo.getAssignments(status: status);
});

final deptAssessmentsProvider = FutureProvider<List<DeptAssessment>>((ref) async {
  final repo = ref.watch(deptAdminRepositoryProvider);
  return repo.getAssessments();
});

// 8. Resources
final deptResourcesProvider = FutureProvider<List<DeptResource>>((ref) async {
  final repo = ref.watch(deptAdminRepositoryProvider);
  return repo.getResources();
});

// 9. Placement
final deptPlacementProvider = FutureProvider<DeptPlacementSummary>((ref) async {
  final repo = ref.watch(deptAdminRepositoryProvider);
  return repo.getPlacementSummary();
});

// 10. Reports
final deptReportsYearProvider = StateProvider<String>((ref) => '2026 - 2027');

final deptReportsProvider = FutureProvider<DeptReportsData>((ref) async {
  final repo = ref.watch(deptAdminRepositoryProvider);
  final year = ref.watch(deptReportsYearProvider);
  return repo.getReports(year);
});
