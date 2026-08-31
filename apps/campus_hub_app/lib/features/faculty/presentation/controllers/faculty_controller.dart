import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/faculty_remote_datasource.dart';
import '../../domain/models/faculty_models.dart';

final facultyDashboardProvider = FutureProvider<FacultyDashboard>((ref) async {
  final dataSource = ref.watch(facultyRemoteDataSourceProvider);
  return dataSource.getDashboard();
});

final facultySubjectsProvider = FutureProvider<List<FacultySubject>>((ref) async {
  final dataSource = ref.watch(facultyRemoteDataSourceProvider);
  return dataSource.getSubjects();
});

final facultySubjectDetailProvider = FutureProvider.autoDispose.family<FacultySubject, String>((ref, subjectId) async {
  final dataSource = ref.watch(facultyRemoteDataSourceProvider);
  return dataSource.getSubjectDetails(subjectId);
});

final facultyScheduleProvider = FutureProvider<List<ClassScheduleSlot>>((ref) async {
  final dataSource = ref.watch(facultyRemoteDataSourceProvider);
  return dataSource.getTodaySchedule();
});

final facultyMenteesProvider = FutureProvider<List<MenteeStudent>>((ref) async {
  final dataSource = ref.watch(facultyRemoteDataSourceProvider);
  return dataSource.getMentees();
});

final facultyControllerProvider = StateNotifierProvider<FacultyController, AsyncValue<void>>((ref) {
  final dataSource = ref.watch(facultyRemoteDataSourceProvider);
  return FacultyController(ref, dataSource);
});

class FacultyController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final FacultyRemoteDataSource _dataSource;

  FacultyController(this._ref, this._dataSource) : super(const AsyncValue.data(null));

  Future<bool> createSubject({
    required String code,
    required String name,
    required String semester,
    String? section,
    int? credits,
    String? description,
    String? departmentName,
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

  Future<bool> uploadSubjectResource({
    required String subjectId,
    required String title,
    String? description,
    required String fileUrl,
    required String fileType,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.uploadSubjectResource(
        subjectId: subjectId,
        title: title,
        description: description,
        fileUrl: fileUrl,
        fileType: fileType,
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
}
