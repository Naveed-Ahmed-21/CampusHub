import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/placement_repository.dart';
import '../../domain/placement_models.dart';

final placementDrivesProvider = FutureProvider<List<PlacementDriveModel>>((ref) async {
  final repo = ref.watch(placementRepositoryProvider);
  return repo.getDrives();
});

final placementDrivesByStatusProvider = FutureProvider.family<List<PlacementDriveModel>, String?>((ref, status) async {
  final repo = ref.watch(placementRepositoryProvider);
  return repo.getDrives(status: status);
});

final driveDetailsProvider = FutureProvider.family<PlacementDriveModel, String>((ref, driveId) async {
  final repo = ref.watch(placementRepositoryProvider);
  return repo.getDriveDetails(driveId);
});

final studentDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(placementRepositoryProvider);
  return repo.getStudentDashboardStats();
});

final officerDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(placementRepositoryProvider);
  return repo.getOfficerDashboardStats();
});

final departmentPlacementStatsProvider = FutureProvider.family<Map<String, dynamic>, String?>((ref, deptId) async {
  final repo = ref.watch(placementRepositoryProvider);
  return repo.getDepartmentPlacementStats(deptId);
});

final placementApplicationsProvider = FutureProvider.family<List<PlacementApplicationModel>, String?>((ref, driveId) async {
  final repo = ref.watch(placementRepositoryProvider);
  return repo.getApplications(driveId: driveId);
});

final applicationDetailsProvider = FutureProvider.family<PlacementApplicationModel, String>((ref, applicationId) async {
  final repo = ref.watch(placementRepositoryProvider);
  return repo.getApplicationById(applicationId);
});

final placementInterviewsProvider = FutureProvider.autoDispose<List<PlacementInterviewModel>>((ref) async {
  final repo = ref.watch(placementRepositoryProvider);
  return repo.getInterviews();
});

final placementCompaniesProvider = FutureProvider.autoDispose<List<PlacementCompanyModel>>((ref) async {
  final repo = ref.watch(placementRepositoryProvider);
  return repo.getCompanies();
});

final companyDetailsProvider = FutureProvider.family<PlacementCompanyModel, String>((ref, companyId) async {
  final repo = ref.watch(placementRepositoryProvider);
  return repo.getCompanyDetails(companyId);
});

final placementResourcesProvider = FutureProvider.family<List<PlacementResourceModel>, String?>((ref, category) async {
  final repo = ref.watch(placementRepositoryProvider);
  return repo.getResources(category: category);
});

final resourceDetailsProvider = FutureProvider.family<PlacementResourceModel, String>((ref, resourceId) async {
  final repo = ref.watch(placementRepositoryProvider);
  return repo.getResourceDetails(resourceId);
});

final placementStudentsProvider = FutureProvider.family<List<PlacementStudentModel>, String?>((ref, status) async {
  final repo = ref.watch(placementRepositoryProvider);
  return repo.getStudents(status: status);
});

final studentPlacementProfileProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final repo = ref.watch(placementRepositoryProvider);
  return repo.getStudentPlacementProfile(userId);
});

final companyLookupProvider = FutureProvider.family<List<CompanyLookupResult>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final repo = ref.watch(placementRepositoryProvider);
  return repo.lookupCompanies(query.trim());
});

