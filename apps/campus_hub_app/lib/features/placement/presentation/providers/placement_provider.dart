import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/placement_repository.dart';
import '../../domain/placement_models.dart';

final placementDrivesProvider = FutureProvider.autoDispose<List<PlacementDriveModel>>((ref) async {
  final repo = ref.watch(placementRepositoryProvider);
  return repo.getDrives();
});

final studentDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(placementRepositoryProvider);
  return repo.getStudentDashboardStats();
});

final officerDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(placementRepositoryProvider);
  return repo.getOfficerDashboardStats();
});
