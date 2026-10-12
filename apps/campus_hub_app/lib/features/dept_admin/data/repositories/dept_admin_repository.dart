import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/dept_admin_models.dart';

class DeptAdminRepository {
  final Dio _dio;

  DeptAdminRepository(this._dio);

  // 1. Dashboard
  Future<DeptDashboardData> getDashboard() async {
    final response = await _dio.get('/api/v1/dept-admin/dashboard');
    final data = response.data['data'] as Map<String, dynamic>;
    return DeptDashboardData.fromJson(data);
  }

  // 2. Students
  Future<List<DeptStudent>> getStudents({
    String? year,
    String? batchId,
    String? section,
    String? search,
    String? placementStatus,
    int page = 1,
    int limit = 50,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (year != null && year.isNotEmpty && year != 'All') query['year'] = year;
    if (batchId != null && batchId.isNotEmpty) query['batch_id'] = batchId;
    if (section != null && section.isNotEmpty) query['section'] = section;
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (placementStatus != null && placementStatus.isNotEmpty && placementStatus != 'All') {
      query['placement_status'] = placementStatus;
    }

    final response = await _dio.get('/api/v1/dept-admin/students', queryParameters: query);
    final data = response.data['data'];
    final List list = data is Map ? (data['students'] ?? []) : (data ?? []);
    return list.map((json) => DeptStudent.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<DeptStudentDetail> getStudentById(String id) async {
    final response = await _dio.get('/api/v1/dept-admin/students/$id');
    final data = response.data['data'] as Map<String, dynamic>;
    return DeptStudentDetail.fromJson(data);
  }

  // 3. Faculty
  Future<List<DeptFaculty>> getFaculty({
    String? search,
    String? designation,
    int page = 1,
    int limit = 50,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (designation != null && designation.isNotEmpty) query['designation'] = designation;

    final response = await _dio.get('/api/v1/dept-admin/faculty', queryParameters: query);
    final data = response.data['data'];
    final List list = data is Map ? (data['faculty'] ?? []) : (data ?? []);
    return list.map((json) => DeptFaculty.fromJson(json as Map<String, dynamic>)).toList();
  }

  // 4. Academics
  Future<DeptAcademicsData> getAcademics() async {
    final response = await _dio.get('/api/v1/dept-admin/academics');
    final data = response.data['data'] as Map<String, dynamic>;
    return DeptAcademicsData.fromJson(data);
  }

  // 5. Timetable
  Future<List<DeptTimetableSlot>> getTimetable({
    String? dayOfWeek,
    String? classId,
  }) async {
    final query = <String, dynamic>{};
    if (dayOfWeek != null && dayOfWeek.isNotEmpty) query['day_of_week'] = dayOfWeek;
    if (classId != null && classId.isNotEmpty) query['class_id'] = classId;

    final response = await _dio.get('/api/v1/dept-admin/timetable', queryParameters: query);
    final List list = response.data['data'] as List? ?? [];
    return list.map((json) => DeptTimetableSlot.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<DeptTimetableSlot> createTimetableSlot({
    required String facultyId,
    required String subjectId,
    required String classId,
    String? roomId,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    final response = await _dio.post(
      '/api/v1/dept-admin/timetable',
      data: {
        'facultyId': facultyId,
        'subjectId': subjectId,
        'classId': classId,
        'roomId': roomId,
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return DeptTimetableSlot.fromJson(data);
  }

  // 6. Attendance
  Future<DeptAttendanceData> getAttendance() async {
    final response = await _dio.get('/api/v1/dept-admin/attendance');
    final data = response.data['data'] as Map<String, dynamic>;
    return DeptAttendanceData.fromJson(data);
  }

  Future<List<DeptLowAttendanceStudent>> getLowAttendanceStudents() async {
    final response = await _dio.get('/api/v1/dept-admin/attendance/low');
    final List list = response.data['data'] as List? ?? [];
    return list.map((json) => DeptLowAttendanceStudent.fromJson(json as Map<String, dynamic>)).toList();
  }

  // 7. Assignments & Assessments
  Future<List<DeptAssignment>> getAssignments({String? status}) async {
    final query = <String, dynamic>{};
    if (status != null && status.isNotEmpty) query['status'] = status;

    final response = await _dio.get('/api/v1/dept-admin/assignments', queryParameters: query);
    final List list = response.data['data'] as List? ?? [];
    return list.map((json) => DeptAssignment.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<DeptAssessment>> getAssessments() async {
    final response = await _dio.get('/api/v1/dept-admin/assessments');
    final List list = response.data['data'] as List? ?? [];
    return list.map((json) => DeptAssessment.fromJson(json as Map<String, dynamic>)).toList();
  }

  // 8. Resources
  Future<List<DeptResource>> getResources() async {
    final response = await _dio.get('/api/v1/dept-admin/resources');
    final List list = response.data['data'] as List? ?? [];
    return list.map((json) => DeptResource.fromJson(json as Map<String, dynamic>)).toList();
  }

  // 9. Placement
  Future<DeptPlacementSummary> getPlacementSummary() async {
    final response = await _dio.get('/api/v1/dept-admin/placement');
    final data = response.data['data'] as Map<String, dynamic>;
    return DeptPlacementSummary.fromJson(data);
  }

  // 10. Reports
  Future<DeptReportsData> getReports([String? academicYear]) async {
    final query = academicYear != null ? {'academic_year': academicYear} : null;
    final response = await _dio.get('/api/v1/dept-admin/reports', queryParameters: query);
    final data = response.data['data'] as Map<String, dynamic>;
    return DeptReportsData.fromJson(data);
  }

  // 11. Announcements
  Future<void> createAnnouncement({
    required String title,
    required String content,
    int? targetYear,
    String? targetBatch,
  }) async {
    await _dio.post(
      '/api/v1/dept-admin/announcements',
      data: {
        'title': title,
        'content': content,
        if (targetYear != null) 'targetYear': targetYear,
        if (targetBatch != null) 'targetBatch': targetBatch,
      },
    );
  }
}

final deptAdminRepositoryProvider = Provider<DeptAdminRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return DeptAdminRepository(dio);
});
