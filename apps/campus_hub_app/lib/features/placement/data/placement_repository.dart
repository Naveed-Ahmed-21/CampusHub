import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/placement_models.dart';

class PlacementRepository {
  final Dio _dio;

  PlacementRepository(this._dio);

  Future<Map<String, dynamic>> getOfficerDashboardStats() async {
    final response = await _dio.get('/api/v1/placement/dashboard/officer');
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> getStudentDashboardStats() async {
    final response = await _dio.get('/api/v1/placement/dashboard/student');
    return response.data['data'] ?? {};
  }

  Future<List<PlacementDriveModel>> getDrives({String? status, String? search}) async {
    final query = <String, dynamic>{};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final response = await _dio.get('/api/v1/placement/drives', queryParameters: query);
    final data = response.data['data'];
    final List list = data is Map ? (data['drives'] ?? []) : (data ?? []);
    return list.map((json) => PlacementDriveModel.fromJson(json)).toList();
  }

  Future<PlacementDriveModel> getDriveDetails(String id) async {
    final response = await _dio.get('/api/v1/placement/drives/$id');
    return PlacementDriveModel.fromJson(response.data['data']);
  }

  Future<PlacementDriveModel> createDrive({
    required String companyName,
    required String roleTitle,
    required String deadline,
    String? packageCtc,
    String? location,
    String? eligibility,
    double? minCgpa,
    List<String>? allowedDepartments,
    int? maxBacklogs,
    String? jobDescription,
  }) async {
    final response = await _dio.post(
      '/api/v1/placement/drives',
      data: {
        'company_name': companyName,
        'role_title': roleTitle,
        'deadline': deadline,
        'package_ctc': packageCtc,
        'location': location,
        'eligibility': eligibility,
        'min_cgpa': minCgpa,
        'allowed_departments': allowedDepartments,
        'max_backlogs': maxBacklogs,
        'job_description': jobDescription,
      },
    );
    return PlacementDriveModel.fromJson(response.data['data']);
  }

  Future<PlacementApplicationModel> applyForDrive(String driveId, {String? resumeUrl}) async {
    final response = await _dio.post(
      '/api/v1/placement/apply',
      data: {
        'drive_id': driveId,
        'resume_url': resumeUrl,
      },
    );
    return PlacementApplicationModel.fromJson(response.data['data']);
  }

  Future<void> updateApplicationStatus(String applicationId, String status, {String? offerCtc}) async {
    await _dio.patch(
      '/api/v1/placement/applications/$applicationId/status',
      data: {
        'status': status,
        'offer_ctc': offerCtc,
      },
    );
  }

  Future<void> scheduleInterview({
    required String applicationId,
    required String roundName,
    required String scheduledAt,
    String? locationOrLink,
    String? notes,
  }) async {
    await _dio.post(
      '/api/v1/placement/interviews/schedule',
      data: {
        'application_id': applicationId,
        'round_name': roundName,
        'scheduled_at': scheduledAt,
        'location_or_link': locationOrLink,
        'notes': notes,
      },
    );
  }

  Future<void> respondToOffer(String applicationId, String offerStatus) async {
    await _dio.patch(
      '/api/v1/placement/applications/$applicationId/offer-response',
      data: {'offer_status': offerStatus},
    );
  }
}

final placementRepositoryProvider = Provider<PlacementRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return PlacementRepository(dio);
});
