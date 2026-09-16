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
    final response = await _dio.get('/api/v1/faculty/dashboard');
    final data = response.data['data'] as Map<String, dynamic>;
    return FacultyDashboard.fromJson(data);
  }

  Future<List<FacultySubject>> getSubjects() async {
    final response = await _dio.get('/api/v1/faculty/subjects');
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list.map((e) => FacultySubject.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FacultySubject> getSubjectDetails(String subjectId) async {
    final response = await _dio.get('/api/v1/faculty/subjects/$subjectId');
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
    String? academicYear,
  }) async {
    final response = await _dio.post(
      '/api/v1/faculty/subjects',
      data: {
        'code': code,
        'name': name,
        'semester': semester,
        'section': section ?? 'A',
        'credits': credits ?? 3,
        if (description != null) 'description': description,
        if (departmentName != null) 'departmentName': departmentName,
        if (academicYear != null) 'academicYear': academicYear,
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
    String? unit,
    String? topic,
    String? resourceType,
    String? visibility,
    String? thumbnailUrl,
    String? academicYear,
  }) async {
    final response = await _dio.post(
      '/api/v1/faculty/subjects/$subjectId/resources',
      data: {
        'title': title,
        if (description != null) 'description': description,
        'fileUrl': fileUrl,
        'fileType': fileType,
        if (unit != null) 'unit': unit,
        if (topic != null) 'topic': topic,
        if (resourceType != null) 'resourceType': resourceType,
        if (visibility != null) 'visibility': visibility,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        if (academicYear != null) 'academicYear': academicYear,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return SubjectResource.fromJson(data);
  }

  Future<SubjectResource> updateSubjectResource({
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
    final response = await _dio.put(
      '/api/v1/faculty/subjects/$subjectId/resources/$resourceId',
      data: {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (fileUrl != null) 'fileUrl': fileUrl,
        if (fileType != null) 'fileType': fileType,
        if (unit != null) 'unit': unit,
        if (topic != null) 'topic': topic,
        if (resourceType != null) 'resourceType': resourceType,
        if (visibility != null) 'visibility': visibility,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return SubjectResource.fromJson(data);
  }

  Future<void> deleteSubjectResource({
    required String subjectId,
    required String resourceId,
  }) async {
    await _dio.delete('/api/v1/faculty/subjects/$subjectId/resources/$resourceId');
  }

  Future<SubjectAnnouncement> createSubjectAnnouncement({
    required String subjectId,
    required String title,
    required String content,
  }) async {
    final response = await _dio.post(
      '/api/v1/faculty/subjects/$subjectId/announcements',
      data: {
        'title': title,
        'content': content,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return SubjectAnnouncement.fromJson(data);
  }

  Future<List<ClassScheduleSlot>> getTodaySchedule() async {
    final response = await _dio.get('/api/v1/faculty/classes/today');
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list.map((e) => ClassScheduleSlot.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MenteeStudent>> getMentees() async {
    final response = await _dio.get('/api/v1/faculty/mentees');
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list.map((e) => MenteeStudent.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FacultyProfileModel> getProfile() async {
    final response = await _dio.get('/api/v1/faculty/profile');
    final data = response.data['data'] as Map<String, dynamic>;
    return FacultyProfileModel.fromJson(data);
  }

  Future<FacultyProfileModel> updateProfile(Map<String, dynamic> payload) async {
    final response = await _dio.put('/api/v1/faculty/profile', data: payload);
    final data = response.data['data'] as Map<String, dynamic>;
    return FacultyProfileModel.fromJson(data);
  }
}
