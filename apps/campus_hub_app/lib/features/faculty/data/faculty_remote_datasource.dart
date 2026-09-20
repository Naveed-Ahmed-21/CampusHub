import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/models/faculty_models.dart';

final facultyRemoteDataSourceProvider =
    Provider<FacultyRemoteDataSource>((ref) {
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
    return list
        .map((e) => FacultySubject.fromJson(e as Map<String, dynamic>))
        .toList();
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

  Future<FacultySubject> updateSubject({
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
    final response = await _dio.put(
      '/api/v1/faculty/subjects/$subjectId',
      data: {
        if (code != null) 'code': code,
        if (name != null) 'name': name,
        if (semester != null) 'semester': semester,
        if (section != null) 'section': section,
        if (credits != null) 'credits': credits,
        if (description != null) 'description': description,
        if (departmentName != null) 'departmentName': departmentName,
        if (academicYear != null) 'academicYear': academicYear,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return FacultySubject.fromJson(data);
  }

  Future<void> deleteSubject(String subjectId) async {
    await _dio.delete('/api/v1/faculty/subjects/$subjectId');
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
    await _dio
        .delete('/api/v1/faculty/subjects/$subjectId/resources/$resourceId');
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
    return list
        .map((e) => ClassScheduleSlot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ClassScheduleSlot> createScheduleSlot(
      Map<String, dynamic> payload) async {
    final response =
        await _dio.post('/api/v1/faculty/classes/schedule', data: payload);
    final data = response.data['data'] as Map<String, dynamic>;
    return ClassScheduleSlot.fromJson(data);
  }

  Future<ClassScheduleSlot> updateScheduleSlot(
      String id, Map<String, dynamic> payload) async {
    final response =
        await _dio.put('/api/v1/faculty/classes/schedule/$id', data: payload);
    final data = response.data['data'] as Map<String, dynamic>;
    return ClassScheduleSlot.fromJson(data);
  }

  Future<void> deleteScheduleSlot(String id) async {
    await _dio.delete('/api/v1/faculty/classes/schedule/$id');
  }

  Future<List<MenteeStudent>> getMentees() async {
    final response = await _dio.get('/api/v1/faculty/mentees');
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => MenteeStudent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FacultyProfileModel> getProfile() async {
    final response = await _dio.get('/api/v1/faculty/profile');
    final data = response.data['data'] as Map<String, dynamic>;
    return FacultyProfileModel.fromJson(data);
  }

  Future<FacultyProfileModel> updateProfile(
      Map<String, dynamic> payload) async {
    final response = await _dio.put('/api/v1/faculty/profile', data: payload);
    final data = response.data['data'] as Map<String, dynamic>;
    return FacultyProfileModel.fromJson(data);
  }

  Future<SubjectAssignment> createAssignment(
      String subjectId, Map<String, dynamic> payload) async {
    final response = await _dio
        .post('/api/v1/faculty/subjects/$subjectId/assignments', data: payload);
    final data = response.data['data'] as Map<String, dynamic>;
    return SubjectAssignment.fromJson(data);
  }

  Future<List<SubjectAssignment>> getSubjectAssignments(
      String subjectId) async {
    final response =
        await _dio.get('/api/v1/faculty/subjects/$subjectId/assignments');
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => SubjectAssignment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AssignmentSubmission>> getAssignmentSubmissions(
      String assignmentId) async {
    final response =
        await _dio.get('/api/v1/faculty/assignments/$assignmentId/submissions');
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => AssignmentSubmission.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AssignmentSubmission> gradeSubmission(String assignmentId,
      String submissionId, Map<String, dynamic> payload) async {
    final response = await _dio.post(
        '/api/v1/faculty/assignments/$assignmentId/submissions/$submissionId/grade',
        data: payload);
    final data = response.data['data'] as Map<String, dynamic>;
    return AssignmentSubmission.fromJson(data);
  }

  Future<AttendanceSession> recordAttendance(
      String subjectId, Map<String, dynamic> payload) async {
    final response = await _dio
        .post('/api/v1/faculty/subjects/$subjectId/attendance', data: payload);
    final data = response.data['data'] as Map<String, dynamic>;
    return AttendanceSession.fromJson(data);
  }

  Future<List<AttendanceSession>> getAttendanceSessions(
      String subjectId) async {
    final response =
        await _dio.get('/api/v1/faculty/subjects/$subjectId/attendance');
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => AttendanceSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SubjectAssessment> createAssessment(
      String subjectId, Map<String, dynamic> payload) async {
    final response = await _dio
        .post('/api/v1/faculty/subjects/$subjectId/assessments', data: payload);
    final data = response.data['data'] as Map<String, dynamic>;
    return SubjectAssessment.fromJson(data);
  }

  Future<List<SubjectAssessment>> getSubjectAssessments(
      String subjectId) async {
    final response =
        await _dio.get('/api/v1/faculty/subjects/$subjectId/assessments');
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => SubjectAssessment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StudentAssessmentResult>> getAssessmentResults(
      String assessmentId) async {
    final response =
        await _dio.get('/api/v1/faculty/assessments/$assessmentId/results');
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => StudentAssessmentResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StudentAssessmentResult>> recordAssessmentMarks(
      String assessmentId, Map<String, dynamic> payload) async {
    final response = await _dio.post(
        '/api/v1/faculty/assessments/$assessmentId/results',
        data: payload);
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => StudentAssessmentResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FacultyAcademicContext> getAcademicContext({String? date}) async {
    final response = await _dio.get(
      '/api/v1/faculty/academic-context',
      queryParameters: {
        if (date != null) 'date': date,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return FacultyAcademicContext.fromJson(data);
  }

  Future<SessionAttendanceDetail> getSessionAttendance(String sessionId) async {
    final response =
        await _dio.get('/api/v1/faculty/sessions/$sessionId/attendance');
    final data = response.data['data'] as Map<String, dynamic>;
    return SessionAttendanceDetail.fromJson(data);
  }

  Future<SessionAttendanceDetail> bulkRecordAttendance({
    required String sessionId,
    required List<Map<String, dynamic>> records,
  }) async {
    final response = await _dio.post(
      '/api/v1/faculty/attendance/bulk',
      data: {
        'sessionId': sessionId,
        'records': records,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return SessionAttendanceDetail.fromJson(data);
  }

  Future<bool> updateAttendanceRecord({
    required String recordId,
    required String status,
    String? remarks,
  }) async {
    final response = await _dio.patch(
      '/api/v1/faculty/attendance/$recordId',
      data: {
        'status': status,
        if (remarks != null) 'remarks': remarks,
      },
    );
    return response.data['success'] == true;
  }

  Future<bool> toggleSessionLock(String sessionId, bool lock) async {
    final response = await _dio.patch(
      '/api/v1/faculty/sessions/$sessionId/lock',
      data: {'locked': lock},
    );
    return response.data['success'] == true;
  }
}
