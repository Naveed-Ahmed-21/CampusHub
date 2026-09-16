import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/academics_remote_datasource.dart';
import '../../domain/models/academic_models.dart';

class AcademicFilterState {
  final String query;
  final String? departmentId;
  final String? semester;
  final String? academicYear;
  final bool onlyEnrolled;

  const AcademicFilterState({
    this.query = '',
    this.departmentId,
    this.semester,
    this.academicYear,
    this.onlyEnrolled = false,
  });

  AcademicFilterState copyWith({
    String? query,
    String? departmentId,
    String? semester,
    String? academicYear,
    bool? onlyEnrolled,
    bool clearDepartment = false,
    bool clearSemester = false,
  }) {
    return AcademicFilterState(
      query: query ?? this.query,
      departmentId: clearDepartment ? null : (departmentId ?? this.departmentId),
      semester: clearSemester ? null : (semester ?? this.semester),
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

  void toggleOnlyEnrolled() {
    state = state.copyWith(onlyEnrolled: !state.onlyEnrolled);
  }

  void reset() {
    state = const AcademicFilterState();
  }
}

final academicFilterProvider = NotifierProvider<AcademicFilterNotifier, AcademicFilterState>(
  AcademicFilterNotifier.new,
);

final academicSubjectsProvider = FutureProvider.autoDispose<List<AcademicSubjectModel>>((ref) async {
  final ds = ref.watch(academicsRemoteDatasourceProvider);
  final filter = ref.watch(academicFilterProvider);

  if (filter.onlyEnrolled) {
    final list = await ds.getMyEnrolledSubjects();
    if (filter.query.isNotEmpty) {
      final q = filter.query.toLowerCase();
      return list.where((s) =>
        s.code.toLowerCase().contains(q) ||
        s.name.toLowerCase().contains(q) ||
        s.faculty.name.toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  return ds.getSubjects(
    query: filter.query,
    departmentId: filter.departmentId,
    semester: filter.semester,
    academicYear: filter.academicYear,
  );
});

final academicSubjectDetailProvider =
    FutureProvider.autoDispose.family<AcademicSubjectDetailModel, String>((ref, subjectId) async {
  final ds = ref.watch(academicsRemoteDatasourceProvider);
  return ds.getSubjectDetails(subjectId);
});

final myEnrolledSubjectsProvider = FutureProvider.autoDispose<List<AcademicSubjectModel>>((ref) async {
  final ds = ref.watch(academicsRemoteDatasourceProvider);
  return ds.getMyEnrolledSubjects();
});

final academicFacultyDirectoryProvider =
    FutureProvider.autoDispose.family<List<AcademicFacultyFull>, String?>((ref, query) async {
  final ds = ref.watch(academicsRemoteDatasourceProvider);
  return ds.getFacultyDirectory(query: query);
});

final academicFacultyDetailProvider =
    FutureProvider.autoDispose.family<AcademicFacultyFull, String>((ref, facultyId) async {
  final ds = ref.watch(academicsRemoteDatasourceProvider);
  return ds.getFacultyProfile(facultyId);
});

class AcademicEnrollmentNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> toggleEnrollment(String subjectId, bool currentlyEnrolled) async {
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
