import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/academics_remote_datasource.dart';
import '../../domain/models/academic_models.dart';

class AcademicFilterState {
  final String query;
  final String? departmentId;
  final String? semester;
  final String? section;
  final String? academicYear;
  final bool onlyEnrolled;

  const AcademicFilterState({
    this.query = '',
    this.departmentId,
    this.semester,
    this.section,
    this.academicYear,
    this.onlyEnrolled = false,
  });

  AcademicFilterState copyWith({
    String? query,
    String? departmentId,
    String? semester,
    String? section,
    String? academicYear,
    bool? onlyEnrolled,
    bool clearDepartment = false,
    bool clearSemester = false,
    bool clearSection = false,
  }) {
    return AcademicFilterState(
      query: query ?? this.query,
      departmentId:
          clearDepartment ? null : (departmentId ?? this.departmentId),
      semester: clearSemester ? null : (semester ?? this.semester),
      section: clearSection ? null : (section ?? this.section),
      academicYear: academicYear ?? this.academicYear,
      onlyEnrolled: onlyEnrolled ?? this.onlyEnrolled,
    );
  }
}

class AcademicFilterNotifier extends Notifier<AcademicFilterState> {
  @override
  AcademicFilterState build() => const AcademicFilterState();

  void setQuery(String q) {
    state = state.copyWith(query: q);
  }

  void setDepartment(String? deptId) {
    if (deptId == null) {
      state = state.copyWith(clearDepartment: true);
    } else {
      state = state.copyWith(departmentId: deptId);
    }
  }

  void setSemester(String? sem) {
    if (sem == null) {
      state = state.copyWith(clearSemester: true);
    } else {
      state = state.copyWith(semester: sem);
    }
  }

  void setSection(String? sec) {
    if (sec == null) {
      state = state.copyWith(clearSection: true);
    } else {
      state = state.copyWith(section: sec);
    }
  }

  void toggleOnlyEnrolled() {
    state = state.copyWith(onlyEnrolled: !state.onlyEnrolled);
  }

  void reset() {
    state = const AcademicFilterState();
  }
}

final academicFilterProvider =
    NotifierProvider<AcademicFilterNotifier, AcademicFilterState>(
  AcademicFilterNotifier.new,
);

final academicSubjectsProvider =
    FutureProvider.autoDispose<List<AcademicSubjectModel>>((ref) async {
  final ds = ref.watch(academicsRemoteDatasourceProvider);
  final filter = ref.watch(academicFilterProvider);

  if (filter.onlyEnrolled) {
    var list = await ds.getMyEnrolledSubjects();
    if (filter.semester != null) {
      list = list
          .where(
              (s) => s.semester.toLowerCase() == filter.semester!.toLowerCase())
          .toList();
    }
    if (filter.section != null) {
      final clean =
          filter.section!.replaceAll('Section ', '').trim().toLowerCase();
      list = list.where((s) {
        final sec = s.section.replaceAll('Section ', '').trim().toLowerCase();
        return sec == clean ||
            s.section.toLowerCase() == filter.section!.toLowerCase();
      }).toList();
    }
    if (filter.query.isNotEmpty) {
      final q = filter.query.toLowerCase();
      return list
          .where((s) =>
              s.code.toLowerCase().contains(q) ||
              s.name.toLowerCase().contains(q) ||
              s.faculty.name.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  return ds.getSubjects(
    query: filter.query,
    departmentId: filter.departmentId,
    semester: filter.semester,
    section: filter.section,
    academicYear: filter.academicYear,
  );
});

final currentAcademicTermProvider =
    FutureProvider.autoDispose<AcademicTermModel>((ref) async {
  final ds = ref.watch(academicsRemoteDatasourceProvider);
  return ds.getCurrentTerm();
});

final academicContextProvider =
    FutureProvider.autoDispose<StudentAcademicContextModel>((ref) async {
  final ds = ref.watch(academicsRemoteDatasourceProvider);
  return ds.getStudentAcademicContext();
});

final academicSubjectDetailProvider = FutureProvider.autoDispose
    .family<AcademicSubjectDetailModel, String>((ref, subjectId) async {
  final ds = ref.watch(academicsRemoteDatasourceProvider);
  return ds.getSubjectDetails(subjectId);
});

final myEnrolledSubjectsProvider =
    FutureProvider.autoDispose<List<AcademicSubjectModel>>((ref) async {
  final ds = ref.watch(academicsRemoteDatasourceProvider);
  return ds.getMyEnrolledSubjects();
});

final academicFacultyDirectoryProvider = FutureProvider.autoDispose
    .family<List<AcademicFacultyFull>, String?>((ref, query) async {
  final ds = ref.watch(academicsRemoteDatasourceProvider);
  return ds.getFacultyDirectory(query: query);
});

final academicFacultyDetailProvider = FutureProvider.autoDispose
    .family<AcademicFacultyFull, String>((ref, facultyId) async {
  final ds = ref.watch(academicsRemoteDatasourceProvider);
  return ds.getFacultyProfile(facultyId);
});

class AcademicEnrollmentNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> toggleEnrollment(
      String subjectId, bool currentlyEnrolled) async {
    final ds = ref.read(academicsRemoteDatasourceProvider);
    state = const AsyncValue.loading();

    try {
      if (currentlyEnrolled) {
        await ds.unenrollSubject(subjectId);
      } else {
        await ds.enrollSubject(subjectId);
      }

      // Invalidate relevant providers
      ref.invalidate(academicSubjectsProvider);
      ref.invalidate(academicSubjectDetailProvider(subjectId));
      ref.invalidate(myEnrolledSubjectsProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final academicEnrollmentNotifierProvider =
    AutoDisposeAsyncNotifierProvider<AcademicEnrollmentNotifier, void>(
  AcademicEnrollmentNotifier.new,
);

final studentSubjectAssignmentsProvider = FutureProvider.autoDispose
    .family<List<StudentAssignmentModel>, String>((ref, subjectId) async {
  final ds = ref.watch(academicsRemoteDatasourceProvider);
  return ds.getSubjectAssignments(subjectId);
});

final studentPendingAssignmentsProvider =
    FutureProvider.autoDispose<List<StudentAssignmentModel>>((ref) async {
  final ds = ref.watch(academicsRemoteDatasourceProvider);
  return ds.getPendingAssignments();
});

final studentSubjectAttendanceProvider = FutureProvider.autoDispose
    .family<StudentAttendanceSummaryModel, String>((ref, subjectId) async {
  final ds = ref.watch(academicsRemoteDatasourceProvider);
  return ds.getSubjectAttendance(subjectId);
});

final studentOverallAttendanceProvider =
    FutureProvider.autoDispose<List<StudentAttendanceSummaryModel>>(
        (ref) async {
  final ds = ref.watch(academicsRemoteDatasourceProvider);
  return ds.getOverallAttendanceSummary();
});

final studentTimetableProvider =
    FutureProvider.autoDispose<List<StudentTimetableSlot>>((ref) async {
  final ds = ref.watch(academicsRemoteDatasourceProvider);
  return ds.getTimetable();
});

final studentTodayTimetableProvider =
    FutureProvider.autoDispose<List<StudentTimetableSlot>>((ref) async {
  final ds = ref.watch(academicsRemoteDatasourceProvider);
  return ds.getTodayTimetable();
});

class StudentAssignmentSubmissionNotifier
    extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> submit({
    required String assignmentId,
    required String subjectId,
    required Map<String, dynamic> payload,
  }) async {
    final ds = ref.read(academicsRemoteDatasourceProvider);
    state = const AsyncValue.loading();
    try {
      await ds.submitAssignment(assignmentId, payload);
      ref.invalidate(studentSubjectAssignmentsProvider(subjectId));
      ref.invalidate(studentPendingAssignmentsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final studentAssignmentSubmissionNotifierProvider =
    AutoDisposeAsyncNotifierProvider<StudentAssignmentSubmissionNotifier, void>(
  StudentAssignmentSubmissionNotifier.new,
);

final studentSubjectAssessmentsProvider = FutureProvider.autoDispose
    .family<List<StudentSubjectAssessmentModel>, String>(
        (ref, subjectId) async {
  final ds = ref.watch(academicsRemoteDatasourceProvider);
  return ds.getSubjectAssessments(subjectId);
});

final studentAssessmentsSummaryProvider =
    FutureProvider.autoDispose<List<StudentAssessmentSummaryModel>>(
        (ref) async {
  final ds = ref.watch(academicsRemoteDatasourceProvider);
  return ds.getAssessmentsSummary();
});
