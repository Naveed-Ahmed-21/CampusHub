import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/faculty_remote_datasource.dart';
import '../../domain/models/faculty_models.dart';

final facultyDashboardProvider = FutureProvider<FacultyDashboard>((ref) async {
  final dataSource = ref.watch(facultyRemoteDataSourceProvider);
  return dataSource.getDashboard();
});

final facultySubjectsProvider =
    FutureProvider<List<FacultySubject>>((ref) async {
  final dataSource = ref.watch(facultyRemoteDataSourceProvider);
  return dataSource.getSubjects();
});

final facultySubjectDetailProvider = FutureProvider.autoDispose
    .family<FacultySubject, String>((ref, subjectId) async {
  final dataSource = ref.watch(facultyRemoteDataSourceProvider);
  return dataSource.getSubjectDetails(subjectId);
});

final facultyScheduleProvider =
    FutureProvider<List<ClassScheduleSlot>>((ref) async {
  final dataSource = ref.watch(facultyRemoteDataSourceProvider);
  return dataSource.getTodaySchedule();
});

final facultyMenteesProvider = FutureProvider<List<MenteeStudent>>((ref) async {
  final dataSource = ref.watch(facultyRemoteDataSourceProvider);
  return dataSource.getMentees();
});

final facultyProfileProvider = FutureProvider<FacultyProfileModel>((ref) async {
  final dataSource = ref.watch(facultyRemoteDataSourceProvider);
  return dataSource.getProfile();
});

final facultySubjectAssignmentsProvider = FutureProvider.autoDispose
    .family<List<SubjectAssignment>, String>((ref, subjectId) async {
  final dataSource = ref.watch(facultyRemoteDataSourceProvider);
  return dataSource.getSubjectAssignments(subjectId);
});

final assignmentSubmissionsProvider = FutureProvider.autoDispose
    .family<List<AssignmentSubmission>, String>((ref, assignmentId) async {
  final dataSource = ref.watch(facultyRemoteDataSourceProvider);
  return dataSource.getAssignmentSubmissions(assignmentId);
});

final facultyAttendanceSessionsProvider = FutureProvider.autoDispose
    .family<List<AttendanceSession>, String>((ref, subjectId) async {
  final dataSource = ref.watch(facultyRemoteDataSourceProvider);
  return dataSource.getAttendanceSessions(subjectId);
});

final facultySubjectAssessmentsProvider = FutureProvider.autoDispose
    .family<List<SubjectAssessment>, String>((ref, subjectId) async {
  final dataSource = ref.watch(facultyRemoteDataSourceProvider);
  return dataSource.getSubjectAssessments(subjectId);
});

final facultyAssessmentResultsProvider = FutureProvider.autoDispose
    .family<List<StudentAssessmentResult>, String>((ref, assessmentId) async {
  final dataSource = ref.watch(facultyRemoteDataSourceProvider);
  return dataSource.getAssessmentResults(assessmentId);
});

final facultyAcademicContextProvider =
    FutureProvider.autoDispose<FacultyAcademicContext>((ref) async {
  final dataSource = ref.watch(facultyRemoteDataSourceProvider);
  return dataSource.getAcademicContext();
});

final sessionAttendanceProvider = FutureProvider.autoDispose
    .family<SessionAttendanceDetail, String>((ref, sessionId) async {
  final dataSource = ref.watch(facultyRemoteDataSourceProvider);
  return dataSource.getSessionAttendance(sessionId);
});

final facultyControllerProvider =
    StateNotifierProvider<FacultyController, AsyncValue<void>>((ref) {
  final dataSource = ref.watch(facultyRemoteDataSourceProvider);
  return FacultyController(ref, dataSource);
});

class FacultyController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final FacultyRemoteDataSource _dataSource;

  FacultyController(this._ref, this._dataSource)
      : super(const AsyncValue.data(null));

  Future<bool> createSubject({
    required String code,
    required String name,
    required String semester,
    String? section,
    int? credits,
    String? description,
    String? departmentName,
    String? academicYear,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.createSubject(
        code: code,
        name: name,
        semester: semester,
        section: section,
        credits: credits,
        description: description,
        departmentName: departmentName,
        academicYear: academicYear,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(facultySubjectsProvider);
      _ref.invalidate(facultyDashboardProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateSubject({
    required String subjectId,
    String? code,
    String? name,
    String? semester,
    String? section,
    int? credits,
    String? description,
    String? departmentName,
    String? academicYear,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.updateSubject(
        subjectId: subjectId,
        code: code,
        name: name,
        semester: semester,
        section: section,
        credits: credits,
        description: description,
        departmentName: departmentName,
        academicYear: academicYear,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(facultySubjectsProvider);
      _ref.invalidate(facultySubjectDetailProvider(subjectId));
      _ref.invalidate(facultyDashboardProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteSubject(String subjectId) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.deleteSubject(subjectId);
      state = const AsyncValue.data(null);
      _ref.invalidate(facultySubjectsProvider);
      _ref.invalidate(facultyDashboardProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> uploadSubjectResource({
    required String subjectId,
    required String title,
    String? description,
    required String fileUrl,
    required String fileType,
    String? unit,
    String? topic,
    String? resourceType,
    String? visibility,
    String? thumbnailUrl,
    String? academicYear,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.uploadSubjectResource(
        subjectId: subjectId,
        title: title,
        description: description,
        fileUrl: fileUrl,
        fileType: fileType,
        unit: unit,
        topic: topic,
        resourceType: resourceType,
        visibility: visibility,
        thumbnailUrl: thumbnailUrl,
        academicYear: academicYear,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(facultySubjectDetailProvider(subjectId));
      _ref.invalidate(facultySubjectsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateSubjectResource({
    required String subjectId,
    required String resourceId,
    String? title,
    String? description,
    String? fileUrl,
    String? fileType,
    String? unit,
    String? topic,
    String? resourceType,
    String? visibility,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.updateSubjectResource(
        subjectId: subjectId,
        resourceId: resourceId,
        title: title,
        description: description,
        fileUrl: fileUrl,
        fileType: fileType,
        unit: unit,
        topic: topic,
        resourceType: resourceType,
        visibility: visibility,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(facultySubjectDetailProvider(subjectId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteSubjectResource({
    required String subjectId,
    required String resourceId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.deleteSubjectResource(
        subjectId: subjectId,
        resourceId: resourceId,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(facultySubjectDetailProvider(subjectId));
      _ref.invalidate(facultySubjectsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> createSubjectAnnouncement({
    required String subjectId,
    required String title,
    required String content,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.createSubjectAnnouncement(
        subjectId: subjectId,
        title: title,
        content: content,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(facultySubjectDetailProvider(subjectId));
      _ref.invalidate(facultyDashboardProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> payload) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.updateProfile(payload);
      state = const AsyncValue.data(null);
      _ref.invalidate(facultyProfileProvider);
      _ref.invalidate(facultyDashboardProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> createScheduleSlot(Map<String, dynamic> payload) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.createScheduleSlot(payload);
      state = const AsyncValue.data(null);
      _ref.invalidate(facultyScheduleProvider);
      _ref.invalidate(facultyDashboardProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateScheduleSlot(
      String id, Map<String, dynamic> payload) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.updateScheduleSlot(id, payload);
      state = const AsyncValue.data(null);
      _ref.invalidate(facultyScheduleProvider);
      _ref.invalidate(facultyDashboardProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteScheduleSlot(String id) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.deleteScheduleSlot(id);
      state = const AsyncValue.data(null);
      _ref.invalidate(facultyScheduleProvider);
      _ref.invalidate(facultyDashboardProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> createAssignment(
      String subjectId, Map<String, dynamic> payload) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.createAssignment(subjectId, payload);
      state = const AsyncValue.data(null);
      _ref.invalidate(facultySubjectAssignmentsProvider(subjectId));
      _ref.invalidate(facultySubjectDetailProvider(subjectId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> gradeSubmission(String assignmentId, String submissionId,
      Map<String, dynamic> payload, String subjectId) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.gradeSubmission(assignmentId, submissionId, payload);
      state = const AsyncValue.data(null);
      _ref.invalidate(assignmentSubmissionsProvider(assignmentId));
      _ref.invalidate(facultySubjectAssignmentsProvider(subjectId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> recordAttendance(
      String subjectId, Map<String, dynamic> payload) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.recordAttendance(subjectId, payload);
      state = const AsyncValue.data(null);
      _ref.invalidate(facultyAttendanceSessionsProvider(subjectId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> createAssessment(
      String subjectId, Map<String, dynamic> payload) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.createAssessment(subjectId, payload);
      state = const AsyncValue.data(null);
      _ref.invalidate(facultySubjectAssessmentsProvider(subjectId));
      _ref.invalidate(facultySubjectDetailProvider(subjectId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> recordAssessmentMarks(String assessmentId,
      Map<String, dynamic> payload, String subjectId) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.recordAssessmentMarks(assessmentId, payload);
      state = const AsyncValue.data(null);
      _ref.invalidate(facultyAssessmentResultsProvider(assessmentId));
      _ref.invalidate(facultySubjectAssessmentsProvider(subjectId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> bulkRecordAttendance({
    required String sessionId,
    required List<Map<String, dynamic>> records,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.bulkRecordAttendance(
        sessionId: sessionId,
        records: records,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(sessionAttendanceProvider(sessionId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateAttendanceRecord({
    required String sessionId,
    required String recordId,
    required String status,
    String? remarks,
  }) async {
    try {
      final ok = await _dataSource.updateAttendanceRecord(
        recordId: recordId,
        status: status,
        remarks: remarks,
      );
      if (ok) {
        _ref.invalidate(sessionAttendanceProvider(sessionId));
      }
      return ok;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleSessionLock({
    required String sessionId,
    required bool lock,
  }) async {
    state = const AsyncValue.loading();
    try {
      final ok = await _dataSource.toggleSessionLock(sessionId, lock);
      state = const AsyncValue.data(null);
      if (ok) {
        _ref.invalidate(sessionAttendanceProvider(sessionId));
      }
      return ok;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
