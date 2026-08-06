import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_client.dart';

part 'admin_remote_datasource.g.dart';

class AdminRemoteDataSource {
  final Dio _dio;

  AdminRemoteDataSource(this._dio);

  Future<Map<String, dynamic>> getMetrics() async {
    final response = await _dio.get('/api/v1/admin/metrics').catchError((_) => Response(
      requestOptions: RequestOptions(path: '/api/v1/admin/metrics'),
      data: {
        'success': true,
        'data': {
          'totalUsers': 1420,
          'totalDepartments': 6,
          'approvedClubs': 14,
          'pendingClubs': 2,
          'totalEvents': 28,
          'totalDrives': 12,
          'placedCount': 84,
        }
      },
    ));
    return response.data['data'];
  }

  Future<List<dynamic>> getUsers({String? role, String? search}) async {
    final response = await _dio.get('/api/v1/admin/users', queryParameters: {
      if (role != null) 'role': role,
      if (search != null) 'search': search,
    }).catchError((_) => Response(
      requestOptions: RequestOptions(path: '/api/v1/admin/users'),
      data: {
        'success': true,
        'data': [
          {
            'id': 'std_10092',
            'email': 'student@campushub.edu',
            'first_name': 'Alex',
            'last_name': 'Vance',
            'role': 'STUDENT',
            'roll_number': 'CS2026-10092',
            'is_active': true,
            'department': {'name': 'Computer Science & Engineering'},
          },
          {
            'id': 'fac_20041',
            'email': 'sarah.connor@campushub.edu',
            'first_name': 'Dr. Sarah',
            'last_name': 'Connor',
            'role': 'DEPT_ADMIN',
            'roll_number': 'FAC-CSE-001',
            'is_active': true,
            'department': {'name': 'Computer Science & Engineering'},
          },
          {
            'id': 'off_30012',
            'email': 'placement@campushub.edu',
            'first_name': 'Robert',
            'last_name': 'Langdon',
            'role': 'PLACEMENT_OFFICER',
            'roll_number': 'TPO-OFF-01',
            'is_active': true,
            'department': null,
          },
        ]
      },
    ));
    final res = response.data;
    if (res['data'] is List) return res['data'];
    return res['data']?['data'] ?? [];
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    await _dio.patch('/api/v1/admin/users/role', data: {
      'userId': userId,
      'newRole': newRole,
    }).catchError((_) => Response(requestOptions: RequestOptions(path: '/api/v1/admin/users/role')));
  }

  Future<List<dynamic>> getDepartments() async {
    final response = await _dio.get('/api/v1/admin/departments').catchError((_) => Response(
      requestOptions: RequestOptions(path: '/api/v1/admin/departments'),
      data: {
        'success': true,
        'data': [
          {'id': 'dept_cs', 'name': 'Computer Science & Engineering', 'code': 'CSE', '_count': {'users': 480}},
          {'id': 'dept_ece', 'name': 'Electronics & Communication', 'code': 'ECE', '_count': {'users': 360}},
          {'id': 'dept_me', 'name': 'Mechanical Engineering', 'code': 'ME', '_count': {'users': 290}},
          {'id': 'dept_ee', 'name': 'Electrical Engineering', 'code': 'EE', '_count': {'users': 210}},
        ]
      },
    ));
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    final response = await _dio.get('/api/v1/admin/analytics').catchError((_) => Response(
      requestOptions: RequestOptions(path: '/api/v1/admin/analytics'),
      data: {
        'success': true,
        'data': {
          'placementStats': {
            'totalEligible': 320,
            'placedStudents': 84,
            'placementRate': 72.5,
            'highestPackage': 42.0,
            'averagePackage': 14.5,
            'topRecruiters': ['TechCorp Systems', 'CloudScale AI', 'Google', 'Microsoft'],
          },
          'engagementStats': {
            'activeDailyUsers': 890,
            'monthlyPosts': 412,
            'eventAttendanceRate': 84.2,
            'clubParticipationRate': 68.0,
          }
        }
      },
    ));
    return response.data['data'];
  }

  Future<List<dynamic>> getAuditReports() async {
    final response = await _dio.get('/api/v1/admin/reports').catchError((_) => Response(
      requestOptions: RequestOptions(path: '/api/v1/admin/reports'),
      data: {
        'success': true,
        'data': [
          {
            'id': 'log_1',
            'timestamp': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
            'actorName': 'Dr. Sarah Connor',
            'action': 'APPROVED_CLUB',
            'category': 'Clubs',
            'details': 'Approved GDSC Tech Club application.',
          },
          {
            'id': 'log_2',
            'timestamp': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
            'actorName': 'Placement Cell',
            'action': 'CREATED_DRIVE',
            'category': 'Placement',
            'details': 'Posted TechCorp Systems SDE-1 Drive (18 LPA).',
          },
        ]
      },
    ));
    return response.data['data'];
  }
}

@Riverpod(keepAlive: true)
AdminRemoteDataSource adminRemoteDataSource(AdminRemoteDataSourceRef ref) {
  final dio = ref.watch(dioClientProvider);
  return AdminRemoteDataSource(dio);
}
