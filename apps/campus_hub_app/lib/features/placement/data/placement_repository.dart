import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/placement_models.dart';

class PlacementRepository {
  final Dio _dio;

  PlacementRepository(this._dio);

  // Dashboards
  Future<Map<String, dynamic>> getOfficerDashboardStats() async {
    final response = await _dio.get('/api/v1/placement/dashboard/officer');
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> getDepartmentPlacementStats([String? departmentId]) async {
    final query = departmentId != null ? {'department_id': departmentId} : null;
    final response = await _dio.get('/api/v1/placement/dashboard/department', queryParameters: query);
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> getStudentDashboardStats() async {
    final response = await _dio.get('/api/v1/placement/dashboard/student');
    return response.data['data'] ?? {};
  }

  // Drives
  Future<List<PlacementDriveModel>> getDrives({
    String? status,
    String? search,
    int? targetYear,
    String? employmentType,
  }) async {
    final query = <String, dynamic>{};
    if (status != null && status.isNotEmpty && status != 'ALL') query['status'] = status;
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (targetYear != null) query['target_year'] = targetYear;
    if (employmentType != null && employmentType.isNotEmpty) query['employment_type'] = employmentType;

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
    String? companyId,
    required String roleTitle,
    required String deadline,
    String? packageCtc,
    String? location,
    String? eligibility,
    double? minCgpa,
    List<String>? allowedDepartments,
    int? maxBacklogs,
    String? jobDescription,
    int? targetYear,
    String? targetBatch,
    String? employmentType,
    String? workMode,
    List<String>? requiredSkills,
    String? driveDate,
    String? venueOrLink,
    String? bannerUrl,
  }) async {
    final response = await _dio.post(
      '/api/v1/placement/drives',
      data: {
        'company_name': companyName,
        if (companyId != null) 'company_id': companyId,
        'role_title': roleTitle,
        'deadline': deadline,
        if (packageCtc != null) 'package_ctc': packageCtc,
        if (location != null) 'location': location,
        if (eligibility != null) 'eligibility': eligibility,
        if (minCgpa != null) 'min_cgpa': minCgpa,
        if (allowedDepartments != null) 'allowed_departments': allowedDepartments,
        if (maxBacklogs != null) 'max_backlogs': maxBacklogs,
        if (jobDescription != null) 'job_description': jobDescription,
        if (targetYear != null) 'target_year': targetYear,
        if (targetBatch != null) 'target_batch': targetBatch,
        if (employmentType != null) 'employment_type': employmentType,
        if (workMode != null) 'work_mode': workMode,
        if (requiredSkills != null) 'required_skills': requiredSkills,
        if (driveDate != null) 'drive_date': driveDate,
        if (venueOrLink != null) 'venue_or_link': venueOrLink,
        if (bannerUrl != null) 'banner_url': bannerUrl,
      },
    );
    return PlacementDriveModel.fromJson(response.data['data']);
  }

  Future<PlacementDriveModel> updateDrive(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/api/v1/placement/drives/$id', data: data);
    return PlacementDriveModel.fromJson(response.data['data']);
  }

  // Applications
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

  Future<List<PlacementApplicationModel>> getApplications({
    String? driveId,
    String? status,
    String? departmentId,
    String? search,
  }) async {
    final query = <String, dynamic>{};
    if (driveId != null && driveId.isNotEmpty) query['drive_id'] = driveId;
    if (status != null && status.isNotEmpty && status != 'ALL') query['status'] = status;
    if (departmentId != null && departmentId.isNotEmpty) query['department_id'] = departmentId;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final response = await _dio.get('/api/v1/placement/applications', queryParameters: query);
    final data = response.data['data'];
    final List list = data is Map ? (data['applications'] ?? []) : (data ?? []);
    return list.map((json) => PlacementApplicationModel.fromJson(json)).toList();
  }

  Future<PlacementApplicationModel> getApplicationById(String applicationId) async {
    final response = await _dio.get('/api/v1/placement/applications/$applicationId');
    return PlacementApplicationModel.fromJson(response.data['data']);
  }

  Future<void> updateApplicationStatus(String applicationId, String status, {String? offerCtc}) async {
    await _dio.patch(
      '/api/v1/placement/applications/$applicationId/status',
      data: {
        'status': status,
        if (offerCtc != null) 'offer_ctc': offerCtc,
      },
    );
  }

  Future<void> bulkUpdateApplicationStatus(List<String> applicationIds, String status, {String? offerCtc}) async {
    await _dio.post(
      '/api/v1/placement/applications/bulk-status',
      data: {
        'application_ids': applicationIds,
        'status': status,
        if (offerCtc != null) 'offer_ctc': offerCtc,
      },
    );
  }

  // Interviews & Offers
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
        if (locationOrLink != null) 'location_or_link': locationOrLink,
        if (notes != null) 'notes': notes,
      },
    );
  }

  Future<List<PlacementInterviewModel>> getInterviews({String? status, String? driveId}) async {
    final query = <String, dynamic>{};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (driveId != null && driveId.isNotEmpty) query['drive_id'] = driveId;

    final response = await _dio.get('/api/v1/placement/interviews', queryParameters: query);
    final data = response.data['data'];
    final List list = data is Map ? (data['interviews'] ?? []) : (data ?? []);
    return list.map((json) => PlacementInterviewModel.fromJson(json)).toList();
  }

  Future<void> respondToOffer(String applicationId, String offerStatus) async {
    await _dio.patch(
      '/api/v1/placement/applications/$applicationId/offer-response',
      data: {'offer_status': offerStatus},
    );
  }

  // Companies
  Future<List<PlacementCompanyModel>> getCompanies({String? search}) async {
    final query = <String, dynamic>{};
    if (search != null && search.isNotEmpty) query['search'] = search;

    final response = await _dio.get('/api/v1/placement/companies', queryParameters: query);
    final List list = response.data['data'] ?? [];
    return list.map((json) => PlacementCompanyModel.fromJson(json)).toList();
  }

  Future<List<CompanyLookupResult>> lookupCompanies(String query) async {
    final response = await _dio.get('/api/v1/placement/companies/lookup', queryParameters: {'query': query});
    final List list = response.data['data'] ?? [];
    return list.map((json) => CompanyLookupResult.fromJson(json)).toList();
  }

  Future<PlacementCompanyModel> createCompany({
    required String name,
    String? website,
    String? logoUrl,
    String? coverImageUrl,
    String? industry,
    String? about,
    String? linkedinUrl,
  }) async {
    final response = await _dio.post(
      '/api/v1/placement/companies',
      data: {
        'name': name,
        if (website != null) 'website': website,
        if (logoUrl != null) 'logo_url': logoUrl,
        if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
        if (industry != null) 'industry': industry,
        if (about != null) 'about': about,
        if (linkedinUrl != null) 'linkedin_url': linkedinUrl,
      },
    );
    return PlacementCompanyModel.fromJson(response.data['data']);
  }

  Future<PlacementCompanyModel> getCompanyDetails(String companyId) async {
    final response = await _dio.get('/api/v1/placement/companies/$companyId');
    return PlacementCompanyModel.fromJson(response.data['data']);
  }

  // Preparation Resources
  Future<List<PlacementResourceModel>> getResources({
    String? category,
    String? resourceType,
    String? companyId,
    String? driveId,
    String? search,
  }) async {
    final query = <String, dynamic>{};
    if (category != null && category.isNotEmpty && category != 'ALL') query['category'] = category;
    if (resourceType != null && resourceType.isNotEmpty && resourceType != 'ALL') query['resource_type'] = resourceType;
    if (companyId != null) query['company_id'] = companyId;
    if (driveId != null) query['drive_id'] = driveId;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final response = await _dio.get('/api/v1/placement/resources', queryParameters: query);
    final data = response.data['data'];
    final List list = data is Map ? (data['resources'] ?? []) : (data ?? []);
    return list.map((json) => PlacementResourceModel.fromJson(json)).toList();
  }

  Future<PlacementResourceModel> createResource({
    required String title,
    String? description,
    required String category,
    required String resourceType,
    String? fileUrl,
    String? externalUrl,
    String? thumbnailUrl,
    List<String>? tags,
    List<String>? targetDepartments,
    int? targetYear,
    String? companyId,
    String? driveId,
  }) async {
    final response = await _dio.post(
      '/api/v1/placement/resources',
      data: {
        'title': title,
        if (description != null) 'description': description,
        'category': category,
        'resource_type': resourceType,
        if (fileUrl != null) 'file_url': fileUrl,
        if (externalUrl != null) 'external_url': externalUrl,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        if (tags != null) 'tags': tags,
        if (targetDepartments != null) 'target_departments': targetDepartments,
        if (targetYear != null) 'target_year': targetYear,
        if (companyId != null) 'company_id': companyId,
        if (driveId != null) 'drive_id': driveId,
      },
    );
    return PlacementResourceModel.fromJson(response.data['data']);
  }

  Future<PlacementResourceModel> getResourceDetails(String resourceId) async {
    final response = await _dio.get('/api/v1/placement/resources/$resourceId');
    return PlacementResourceModel.fromJson(response.data['data']);
  }

  Future<void> deleteResource(String resourceId) async {
    await _dio.delete('/api/v1/placement/resources/$resourceId');
  }

  // Students Directory
  Future<List<PlacementStudentModel>> getStudents({
    String? search,
    String? departmentId,
    int? year,
    String? status,
    double? minCgpa,
  }) async {
    final query = <String, dynamic>{};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (departmentId != null && departmentId.isNotEmpty) query['department_id'] = departmentId;
    if (year != null) query['year'] = year;
    if (status != null && status.isNotEmpty && status != 'ALL') query['status'] = status;
    if (minCgpa != null) query['min_cgpa'] = minCgpa;

    final response = await _dio.get('/api/v1/placement/students', queryParameters: query);
    final data = response.data['data'];
    final List list = data is Map ? (data['students'] ?? []) : (data ?? []);
    return list.map((json) => PlacementStudentModel.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> getStudentPlacementProfile(String userId) async {
    final response = await _dio.get('/api/v1/placement/students/$userId');
    return response.data['data'] ?? {};
  }
}

final placementRepositoryProvider = Provider<PlacementRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return PlacementRepository(dio);
});
