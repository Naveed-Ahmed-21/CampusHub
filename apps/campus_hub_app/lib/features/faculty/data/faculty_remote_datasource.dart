import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/models/faculty_models.dart';

final facultyRemoteDataSourceProvider = Provider<FacultyRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return FacultyRemoteDataSource(dio);
});

class FacultyRemoteDataSource {
  final Dio _dio;

  FacultyRemoteDataSource(this._dio);

  Future<FacultyDashboard> getDashboard() async {
    final response = await _dio.get('/faculty/dashboard');
    final data = response.data['data'] as Map<String, dynamic>;
    return FacultyDashboard.fromJson(data);
  }

  Future<List<FacultySubject>> getSubjects() async {
    final response = await _dio.get('/faculty/subjects');
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list.map((e) => FacultySubject.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FacultySubject> getSubjectDetails(String subjectId) async {
    final response = await _dio.get('/faculty/subjects/$subjectId');
    final data = response.data['data'] as Map<String, dynamic>;
    return FacultySubject.fromJson(data);
  }

  Future<FacultySubject> createSubject({
    required String code,
    required String name,
    required String semester,
    String? section,
    int? credits,
    String? description,
    String? departmentName,
  }) async {
    final response = await _dio.post(
      '/faculty/subjects',
      data: {
        'code': code,
        'name': name,
        'semester': semester,
        'section': section ?? 'A',
        'credits': credits ?? 3,
        if (description != null) 'description': description,
        if (departmentName != null) 'departmentName': departmentName,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return FacultySubject.fromJson(data);
  }

  Future<SubjectResource> uploadSubjectResource({
    required String subjectId,
    required String title,
    String? description,
    required String fileUrl,
    required String fileType,
  }) async {
    final response = await _dio.post(
      '/faculty/subjects/$subjectId/resources',
      data: {
        'title': title,
        if (description != null) 'description': description,
        'fileUrl': fileUrl,
        'fileType': fileType,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return SubjectResource.fromJson(data);
  }

  Future<SubjectAnnouncement> createSubjectAnnouncement({
    required String subjectId,
    required String title,
    required String content,
  }) async {
    final response = await _dio.post(
      '/faculty/subjects/$subjectId/announcements',
      data: {
        'title': title,
        'content': content,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return SubjectAnnouncement.fromJson(data);
  }

  Future<List<ClassScheduleSlot>> getTodaySchedule() async {
    final response = await _dio.get('/faculty/classes/today');
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list.map((e) => ClassScheduleSlot.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MenteeStudent>> getMentees() async {
    final response = await _dio.get('/faculty/mentees');
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list.map((e) => MenteeStudent.fromJson(e as Map<String, dynamic>)).toList();
  }
}
