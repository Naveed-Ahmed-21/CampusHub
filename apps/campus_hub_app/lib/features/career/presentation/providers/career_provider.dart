import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/career_repository.dart';
import '../../domain/career_models.dart';

final careerRoadmapsProvider = FutureProvider.autoDispose<List<CareerRoadmapModel>>((ref) async {
  final repo = ref.watch(careerRepositoryProvider);
  return repo.getRoadmaps();
});

final userCareerProgressProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(careerRepositoryProvider);
  return repo.getUserProgress();
});

final weeklyGoalsProvider = FutureProvider.autoDispose<List<WeeklyGoalModel>>((ref) async {
  final repo = ref.watch(careerRepositoryProvider);
  return repo.getWeeklyGoals();
});

final resumeTipsProvider = FutureProvider.autoDispose<List<ResumeTipModel>>((ref) async {
  final repo = ref.watch(careerRepositoryProvider);
  return repo.getResumeTips();
});

final placementPrepProvider = FutureProvider.autoDispose<List<PlacementPrepModel>>((ref) async {
  final repo = ref.watch(careerRepositoryProvider);
  return repo.getPlacementPrep();
});

final miniProjectsProvider = FutureProvider.autoDispose<List<MiniProjectModel>>((ref) async {
  final repo = ref.watch(careerRepositoryProvider);
  return repo.getMiniProjects();
});
