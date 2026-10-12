import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class AdminRemoteDataSource {
  final Dio _dio;

  AdminRemoteDataSource(this._dio);

  Future<Map<String, dynamic>> getMetrics() async {
    final response = await _dio.get('/api/v1/admin/metrics');
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] != null) {
      return Map<String, dynamic>.from(data['data']);
    }
    return {};
  }

  Future<List<dynamic>> getUsers({String? role, String? search}) async {
    final response = await _dio.get('/api/v1/admin/users', queryParameters: {
      if (role != null) 'role': role,
      if (search != null) 'search': search,
      'limit': 100,
    });
    final res = response.data;
    if (res['data'] is List) return res['data'];
    return res['data']?['data'] ?? [];
  }

  Future<Map<String, dynamic>> getUserById(String id) async {
    final response = await _dio.get('/api/v1/admin/users/$id');
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] != null) {
      return Map<String, dynamic>.from(data['data']);
    }
    return {};
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/v1/admin/users', data: data);
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/api/v1/admin/users/$id', data: data);
    return response.data['data'] ?? {};
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    await _dio.patch('/api/v1/admin/users/$userId/role', data: {
      'newRole': newRole,
    });
  }

  Future<void> updateUserStatus(String userId, bool isActive) async {
    await _dio.patch('/api/v1/admin/users/$userId/status', data: {
      'isActive': isActive,
    });
  }

  Future<Map<String, dynamic>> setTemporaryPassword(String userId, {String? tempPassword}) async {
    final response = await _dio.post('/api/v1/admin/users/$userId/temporary-password', data: {
      if (tempPassword != null) 'tempPassword': tempPassword,
    });
    return response.data['data'] ?? {};
  }

  Future<void> deleteUser(String userId) async {
    await _dio.delete('/api/v1/admin/users/$userId');
  }

  Future<List<dynamic>> getBinUsers({String? role, String? departmentId, String? search, int? page, int? limit}) async {
    final response = await _dio.get(
      '/api/v1/admin/users/bin',
      queryParameters: {
        if (role != null) 'role': role,
        if (departmentId != null) 'departmentId': departmentId,
        if (search != null && search.isNotEmpty) 'search': search,
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return List<dynamic>.from(data['data']);
    }
    return [];
  }

  Future<void> restoreUser(String userId) async {
    await _dio.post('/api/v1/admin/users/$userId/restore');
  }

  Future<void> permanentlyDeleteUser(String userId) async {
    await _dio.delete('/api/v1/admin/users/$userId/permanent');
  }

  Future<Map<String, dynamic>> purgeBin() async {
    final response = await _dio.delete('/api/v1/admin/users/bin/purge');
    return response.data['data'] ?? {};
  }

  Future<List<dynamic>> getDepartments() async {
    final response = await _dio.get('/api/v1/admin/departments');
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return List<dynamic>.from(data['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>> getDepartmentById(String id) async {
    final response = await _dio.get('/api/v1/admin/departments/$id');
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] != null) {
      return Map<String, dynamic>.from(data['data']);
    }
    return {};
  }

  Future<Map<String, dynamic>> getDepartmentOverview(String id) async {
    final response = await _dio.get('/api/v1/admin/departments/$id/overview');
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] != null) {
      return Map<String, dynamic>.from(data['data']);
    }
    return {};
  }

  Future<Map<String, dynamic>> getDepartmentStudents(
    String id, {
    String? year,
    String? search,
    int? page,
    int? limit,
  }) async {
    final response = await _dio.get(
      '/api/v1/admin/departments/$id/students',
      queryParameters: {
        if (year != null) 'year': year,
        if (search != null && search.isNotEmpty) 'search': search,
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  Future<Map<String, dynamic>> getDepartmentFaculty(
    String id, {
    String? search,
    int? page,
    int? limit,
  }) async {
    final response = await _dio.get(
      '/api/v1/admin/departments/$id/faculty',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  Future<Map<String, dynamic>> createDepartment({
    required String name,
    required String code,
    String? description,
    String? hodName,
  }) async {
    final response = await _dio.post('/api/v1/admin/departments', data: {
      'name': name,
      'code': code,
      if (description != null) 'description': description,
      if (hodName != null) 'hodName': hodName,
    });
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> updateDepartment(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/api/v1/admin/departments/$id', data: data);
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> updateDepartmentStatus(String id, bool isActive) async {
    final response = await _dio.patch('/api/v1/admin/departments/$id/status', data: {'isActive': isActive});
    return response.data['data'] ?? {};
  }

  Future<void> deleteDepartment(String id) async {
    await _dio.delete('/api/v1/admin/departments/$id');
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    final response = await _dio.get('/api/v1/admin/analytics');
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] != null) {
      return Map<String, dynamic>.from(data['data']);
    }
    return {};
  }

  Future<List<dynamic>> getAuditReports({String? action, String? category, String? entityType}) async {
    final response = await _dio.get('/api/v1/admin/reports', queryParameters: {
      if (action != null) 'action': action,
      if (category != null) 'category': category,
      if (entityType != null) 'entityType': entityType,
    });
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return List<dynamic>.from(data['data']);
    }
    return [];
  }

  // ==========================================
  // ACADEMIC YEARS
  // ==========================================
  Future<List<dynamic>> getAcademicYears() async {
    final response = await _dio.get('/api/v1/admin/academic-years');
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return List<dynamic>.from(data['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>> createAcademicYear(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/v1/admin/academic-years', data: data);
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> updateAcademicYear(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/api/v1/admin/academic-years/$id', data: data);
    return response.data['data'] ?? {};
  }

  Future<void> setActiveAcademicYear(String id) async {
    await _dio.patch('/api/v1/admin/academic-years/$id/active');
  }

  // ==========================================
  // ACADEMIC TERMS
  // ==========================================
  Future<List<dynamic>> getAcademicTerms({String? academicYearId}) async {
    final response = await _dio.get('/api/v1/admin/academic-terms', queryParameters: {
      if (academicYearId != null) 'academicYearId': academicYearId,
    });
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return List<dynamic>.from(data['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>> createAcademicTerm(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/v1/admin/academic-terms', data: data);
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> updateAcademicTerm(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/api/v1/admin/academic-terms/$id', data: data);
    return response.data['data'] ?? {};
  }

  // ==========================================
  // ACADEMIC PROGRAMS
  // ==========================================
  Future<List<dynamic>> getAcademicPrograms({String? departmentId}) async {
    final response = await _dio.get('/api/v1/admin/programs', queryParameters: {
      if (departmentId != null) 'departmentId': departmentId,
    });
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return List<dynamic>.from(data['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>> createAcademicProgram(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/v1/admin/programs', data: data);
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> updateAcademicProgram(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/api/v1/admin/programs/$id', data: data);
    return response.data['data'] ?? {};
  }

  // ==========================================
  // BATCHES
  // ==========================================
  Future<List<dynamic>> getBatches({String? programId, String? departmentId}) async {
    final response = await _dio.get('/api/v1/admin/batches', queryParameters: {
      if (programId != null) 'programId': programId,
      if (departmentId != null) 'departmentId': departmentId,
    });
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return List<dynamic>.from(data['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>> createBatch(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/v1/admin/batches', data: data);
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> updateBatch(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/api/v1/admin/batches/$id', data: data);
    return response.data['data'] ?? {};
  }

  // ==========================================
  // SUBJECTS / COURSES
  // ==========================================
  Future<List<dynamic>> getSubjects({
    String? departmentId,
    String? semester,
    String? academicTermId,
  }) async {
    final response = await _dio.get('/api/v1/admin/subjects', queryParameters: {
      if (departmentId != null) 'departmentId': departmentId,
      if (semester != null) 'semester': semester,
      if (academicTermId != null) 'academicTermId': academicTermId,
    });
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return List<dynamic>.from(data['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>> createSubject(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/v1/admin/subjects', data: data);
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> updateSubject(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/api/v1/admin/subjects/$id', data: data);
    return response.data['data'] ?? {};
  }

  // ==========================================
  // CURRICULUM SUBJECTS
  // ==========================================
  Future<List<dynamic>> getCurriculumSubjects({
    String? programId,
    int? batchYear,
    int? semesterNumber,
  }) async {
    final response = await _dio.get('/api/v1/admin/curriculum', queryParameters: {
      if (programId != null) 'programId': programId,
      if (batchYear != null) 'batchYear': batchYear,
      if (semesterNumber != null) 'semesterNumber': semesterNumber,
    });
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return List<dynamic>.from(data['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>> createCurriculumSubject(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/v1/admin/curriculum', data: data);
    return response.data['data'] ?? {};
  }

  Future<void> deleteCurriculumSubject(String id) async {
    await _dio.delete('/api/v1/admin/curriculum/$id');
  }

  // ==========================================
  // ACADEMIC CLASSES
  // ==========================================
  Future<List<dynamic>> getAcademicClasses({
    String? departmentId,
    int? yearOfStudy,
    int? semester,
  }) async {
    final response = await _dio.get('/api/v1/admin/classes', queryParameters: {
      if (departmentId != null) 'departmentId': departmentId,
      if (yearOfStudy != null) 'yearOfStudy': yearOfStudy,
      if (semester != null) 'semester': semester,
    });
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return List<dynamic>.from(data['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>> createAcademicClass(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/v1/admin/classes', data: data);
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> updateAcademicClass(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/api/v1/admin/classes/$id', data: data);
    return response.data['data'] ?? {};
  }

  // ==========================================
  // ROOMS & FACILITIES
  // ==========================================
  Future<List<dynamic>> getRooms({String? roomType, bool? isActive}) async {
    final response = await _dio.get('/api/v1/admin/rooms', queryParameters: {
      if (roomType != null) 'roomType': roomType,
      if (isActive != null) 'isActive': isActive,
    });
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return List<dynamic>.from(data['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>> createRoom(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/v1/admin/rooms', data: data);
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> updateRoom(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/api/v1/admin/rooms/$id', data: data);
    return response.data['data'] ?? {};
  }

  // ==========================================
  // FACULTY SUBJECT ASSIGNMENTS
  // ==========================================
  Future<List<dynamic>> getFacultyAssignments({
    String? facultyId,
    String? subjectId,
    String? academicTermId,
  }) async {
    final response = await _dio.get('/api/v1/admin/faculty-assignments', queryParameters: {
      if (facultyId != null) 'facultyId': facultyId,
      if (subjectId != null) 'subjectId': subjectId,
      if (academicTermId != null) 'academicTermId': academicTermId,
    });
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return List<dynamic>.from(data['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>> createFacultyAssignment(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/v1/admin/faculty-assignments', data: data);
    return response.data['data'] ?? {};
  }

  Future<void> deleteFacultyAssignment(String id) async {
    await _dio.delete('/api/v1/admin/faculty-assignments/$id');
  }

  // ==========================================
  // FACULTY SCHEDULES / TIMETABLE
  // ==========================================
  Future<List<dynamic>> getSchedules({
    String? facultyId,
    String? classId,
    String? roomId,
    String? dayOfWeek,
    String? academicTermId,
  }) async {
    final response = await _dio.get('/api/v1/admin/schedules', queryParameters: {
      if (facultyId != null) 'facultyId': facultyId,
      if (classId != null) 'classId': classId,
      if (roomId != null) 'roomId': roomId,
      if (dayOfWeek != null) 'dayOfWeek': dayOfWeek,
      if (academicTermId != null) 'academicTermId': academicTermId,
    });
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return List<dynamic>.from(data['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>> createSchedule(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/v1/admin/schedules', data: data);
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> updateSchedule(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/api/v1/admin/schedules/$id', data: data);
    return response.data['data'] ?? {};
  }

  Future<void> deleteSchedule(String id) async {
    await _dio.delete('/api/v1/admin/schedules/$id');
  }

  // ==========================================
  // ACADEMIC MONITORING (PHASE 6)
  // ==========================================
  Future<Map<String, dynamic>> getAcademicMonitoringMetrics({String? departmentId}) async {
    final response = await _dio.get('/api/v1/admin/monitoring/metrics', queryParameters: {
      if (departmentId != null) 'departmentId': departmentId,
    });
    return response.data['data'] ?? {};
  }

  Future<List<dynamic>> getMonitoringAttendanceSessions({
    String? departmentId,
    String? subjectId,
    String? academicTermId,
  }) async {
    final response = await _dio.get('/api/v1/admin/monitoring/attendance', queryParameters: {
      if (departmentId != null) 'departmentId': departmentId,
      if (subjectId != null) 'subjectId': subjectId,
      if (academicTermId != null) 'academicTermId': academicTermId,
    });
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return List<dynamic>.from(data['data']);
    }
    return [];
  }

  Future<List<dynamic>> getMonitoringAssignments({
    String? departmentId,
    String? subjectId,
    String? academicTermId,
  }) async {
    final response = await _dio.get('/api/v1/admin/monitoring/assignments', queryParameters: {
      if (departmentId != null) 'departmentId': departmentId,
      if (subjectId != null) 'subjectId': subjectId,
      if (academicTermId != null) 'academicTermId': academicTermId,
    });
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return List<dynamic>.from(data['data']);
    }
    return [];
  }

  Future<List<dynamic>> getMonitoringAssessments({
    String? departmentId,
    String? subjectId,
    String? academicTermId,
  }) async {
    final response = await _dio.get('/api/v1/admin/monitoring/assessments', queryParameters: {
      if (departmentId != null) 'departmentId': departmentId,
      if (subjectId != null) 'subjectId': subjectId,
      if (academicTermId != null) 'academicTermId': academicTermId,
    });
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return List<dynamic>.from(data['data']);
    }
    return [];
  }

  // ==========================================
  // PHASE 7: BROADCAST NOTIFICATIONS & MODERATION
  // ==========================================
  Future<Map<String, dynamic>> sendBroadcastNotification(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/v1/admin/broadcast-notification', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getModerationEvents({String? departmentId, String? scope}) async {
    final response = await _dio.get('/api/v1/admin/moderation/events', queryParameters: {
      if (departmentId != null) 'departmentId': departmentId,
      if (scope != null) 'scope': scope,
    });
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return List<dynamic>.from(data['data']);
    }
    return [];
  }

  Future<void> deleteModerationEvent(String eventId) async {
    await _dio.delete('/api/v1/admin/moderation/events/$eventId');
  }

  Future<List<dynamic>> getModerationPosts({String? departmentId, String? clubId}) async {
    final response = await _dio.get('/api/v1/admin/moderation/posts', queryParameters: {
      if (departmentId != null) 'departmentId': departmentId,
      if (clubId != null) 'clubId': clubId,
    });
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return List<dynamic>.from(data['data']);
    }
    return [];
  }

  Future<void> deleteModerationPost(String postId) async {
    await _dio.delete('/api/v1/admin/moderation/posts/$postId');
  }

  // ==========================================
  // PHASE 8: CAREER HUB & PLACEMENT ADMIN
  // ==========================================
  Future<Map<String, dynamic>> getPlacementOfficerStats() async {
    final response = await _dio.get('/api/v1/placement/dashboard/officer');
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return data['data'] as Map<String, dynamic>;
    }
    return {};
  }

  Future<List<dynamic>> getPlacementDrives({String? status, String? search}) async {
    final response = await _dio.get('/api/v1/placement/drives', queryParameters: {
      if (status != null) 'status': status,
      if (search != null) 'search': search,
    });
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic> && data['data']['drives'] is List) {
      return List<dynamic>.from(data['data']['drives']);
    }
    return [];
  }

  Future<Map<String, dynamic>> getPlacementDriveDetails(String driveId) async {
    final response = await _dio.get('/api/v1/placement/drives/$driveId');
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return data['data'] as Map<String, dynamic>;
    }
    return {};
  }

  Future<Map<String, dynamic>> createPlacementDrive(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/v1/placement/drives', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> updatePlacementApplicationStatus(String applicationId, Map<String, dynamic> data) async {
    await _dio.patch('/api/v1/placement/applications/$applicationId/status', data: data);
  }

  // ==========================================
  // PHASE 9: INSTITUTIONAL SETTINGS & AUDIT CSV
  // ==========================================
  Future<String> getAuditReportsCsv({String? action, String? category}) async {
    final response = await _dio.get<String>(
      '/api/v1/admin/reports/csv',
      queryParameters: {
        if (action != null) 'action': action,
        if (category != null) 'category': category,
      },
    );
    return response.data ?? '';
  }

  Future<Map<String, dynamic>> getCollegeSettings() async {
    final response = await _dio.get('/api/v1/admin/college');
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return data['data'] as Map<String, dynamic>;
    }
    return {};
  }

  Future<Map<String, dynamic>> updateCollegeSettings(Map<String, dynamic> data) async {
    final response = await _dio.patch('/api/v1/admin/college', data: data);
    return response.data as Map<String, dynamic>;
  }

  // ==========================================
  // PHASE 10: PROFILE CHANGE REQUEST APPROVAL WORKFLOW
  // ==========================================
  Future<Map<String, dynamic>> getChangeRequests({
    String? status,
    String? departmentId,
    String? category,
    int? page,
    int? limit,
  }) async {
    final response = await _dio.get('/api/v1/admin/change-requests', queryParameters: {
      if (status != null) 'status': status,
      if (departmentId != null) 'departmentId': departmentId,
      if (category != null) 'category': category,
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
    });
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] != null) {
      return Map<String, dynamic>.from(data['data']);
    }
    return {'items': [], 'total': 0};
  }

  Future<Map<String, dynamic>> approveChangeRequest(String id, {String? reviewComment}) async {
    final response = await _dio.post('/api/v1/admin/change-requests/$id/approve', data: {
      if (reviewComment != null && reviewComment.trim().isNotEmpty) 'reviewComment': reviewComment.trim(),
    });
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> rejectChangeRequest(String id, {required String rejectionReason}) async {
    final response = await _dio.post('/api/v1/admin/change-requests/$id/reject', data: {
      'rejectionReason': rejectionReason.trim(),
    });
    return response.data['data'] ?? {};
  }
}

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return AdminRemoteDataSource(dio);
});

