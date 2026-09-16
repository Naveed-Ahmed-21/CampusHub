import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/models/academic_models.dart';

final academicsRemoteDatasourceProvider = Provider<AcademicsRemoteDatasource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return AcademicsRemoteDatasource(dio);
});

class AcademicsRemoteDatasource {
  final Dio _dio;

  AcademicsRemoteDatasource(this._dio);

  Future<List<AcademicSubjectModel>> getSubjects({
    String? query,
    String? departmentId,
    String? semester,
    String? academicYear,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _dio.get(
      '/api/v1/academics/subjects',
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (departmentId != null && departmentId.isNotEmpty) 'departmentId': departmentId,
        if (semester != null && semester.isNotEmpty) 'semester': semester,
        if (academicYear != null && academicYear.isNotEmpty) 'academicYear': academicYear,
        'page': page,
        'limit': limit,
      },
    );

    final List list = response.data['data'] ?? [];
    return list.map((json) => AcademicSubjectModel.fromJson(json)).toList();
  }

  Future<AcademicSubjectDetailModel> getSubjectDetails(String subjectId) async {
    final response = await _dio.get('/api/v1/academics/subjects/$subjectId');
    return AcademicSubjectDetailModel.fromJson(response.data['data']);
  }

  Future<bool> enrollSubject(String subjectId) async {
    final response = await _dio.post('/api/v1/academics/subjects/$subjectId/enroll');
    return response.data['success'] == true;
  }

  Future<bool> unenrollSubject(String subjectId) async {
    final response = await _dio.delete('/api/v1/academics/subjects/$subjectId/enroll');
    return response.data['success'] == true;
  }

  Future<List<AcademicSubjectModel>> getMyEnrolledSubjects() async {
    final response = await _dio.get('/api/v1/academics/subjects/enrolled');
    final List list = response.data['data'] ?? [];
    return list.map((json) => AcademicSubjectModel.fromJson(json)).toList();
  }

  Future<List<ResourceSearchResultModel>> searchResources({
    String? query,
    String? unit,
    String? resourceType,
    String? departmentId,
    String? semester,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _dio.get(
      '/api/v1/academics/resources/search',
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (unit != null && unit.isNotEmpty) 'unit': unit,
        if (resourceType != null && resourceType.isNotEmpty) 'resourceType': resourceType,
        if (departmentId != null && departmentId.isNotEmpty) 'departmentId': departmentId,
        if (semester != null && semester.isNotEmpty) 'semester': semester,
        'page': page,
        'limit': limit,
      },
    );

    final List list = response.data['data'] ?? [];
    return list.map((json) => ResourceSearchResultModel.fromJson(json)).toList();
  }

  Future<void> recordResourceView(String resourceId) async {
    try {
      await _dio.post('/api/v1/academics/resources/$resourceId/view');
    } catch (_) {}
  }

  Future<void> recordResourceDownload(String resourceId) async {
    try {
      await _dio.post('/api/v1/academics/resources/$resourceId/download');
    } catch (_) {}
  }

  Future<List<AcademicFacultyFull>> getFacultyDirectory({
    String? query,
    String? departmentId,
  }) async {
    final response = await _dio.get(
      '/api/v1/academics/faculty',
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (departmentId != null && departmentId.isNotEmpty) 'departmentId': departmentId,
      },
    );

    final List list = response.data['data'] ?? [];
    return list.map((json) => AcademicFacultyFull.fromJson(json)).toList();
  }

  Future<AcademicFacultyFull> getFacultyProfile(String facultyId) async {
    final response = await _dio.get('/api/v1/academics/faculty/$facultyId');
    return AcademicFacultyFull.fromJson(response.data['data']);
  }
}
