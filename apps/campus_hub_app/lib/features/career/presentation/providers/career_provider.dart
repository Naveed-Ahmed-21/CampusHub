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

final activeUserRoadmapProvider = FutureProvider.autoDispose<ActiveRoadmapState?>((ref) async {
  final repo = ref.watch(careerRepositoryProvider);
  return repo.getActiveRoadmap();
});

final userRoadmapsProvider = FutureProvider.autoDispose<List<UserRoadmapItemModel>>((ref) async {
  final repo = ref.watch(careerRepositoryProvider);
  return repo.getUserRoadmaps();
});

final dailyPlanProvider = FutureProvider.family.autoDispose<DailyLearningPlanModel?, String?>((ref, roadmapId) async {
  final repo = ref.watch(careerRepositoryProvider);
  return repo.getDailyPlan(roadmapId: roadmapId);
});

final skillGapProvider = FutureProvider.family.autoDispose<SkillGapAnalysisModel, String>((ref, roadmapId) async {
  final repo = ref.watch(careerRepositoryProvider);
  return repo.getSkillGapAnalysis(roadmapId);
});

final skillMapProvider = FutureProvider.family.autoDispose<List<SkillMapNodeModel>, String>((ref, roadmapId) async {
  final repo = ref.watch(careerRepositoryProvider);
  return repo.getSkillMap(roadmapId);
});

final weeklyReviewProvider = FutureProvider.family.autoDispose<WeeklyReviewModel, String?>((ref, roadmapId) async {
  final repo = ref.watch(careerRepositoryProvider);
  return repo.getWeeklyReview(roadmapId: roadmapId);
});

final jobReadinessProvider = FutureProvider.family.autoDispose<JobReadinessModel, String?>((ref, roadmapId) async {
  final repo = ref.watch(careerRepositoryProvider);
  return repo.getJobReadiness(roadmapId: roadmapId);
});

final interviewPrepProvider = FutureProvider.family.autoDispose<List<InterviewQuestionModel>, String?>((ref, roadmapId) async {
  final repo = ref.watch(careerRepositoryProvider);
  return repo.getInterviewPrep(roadmapId: roadmapId);
});

final interviewHistoryProvider = FutureProvider.autoDispose<List<InterviewSessionModel>>((ref) async {
  final repo = ref.watch(careerRepositoryProvider);
  return repo.getInterviewHistory();
});

final roadmapChangesProvider = FutureProvider.family.autoDispose<List<RoadmapChangeModel>, String>((ref, roadmapId) async {
  final repo = ref.watch(careerRepositoryProvider);
  return repo.getRoadmapChanges(roadmapId);
});

final adaptiveQuizProvider = FutureProvider.family.autoDispose<AdaptiveQuizModel, Map<String, dynamic>>((ref, params) async {
  final repo = ref.watch(careerRepositoryProvider);
  return repo.generateAdaptiveQuiz(
    roadmapId: params['roadmapId'],
    phaseNumber: params['phaseNumber'],
    role: params['role'],
    topic: params['topic'],
    difficulty: params['difficulty'],
    numQuestions: params['numQuestions'],
  );
});

final verifiedDocumentsProvider = FutureProvider.autoDispose<List<VerifiedDocumentModel>>((ref) async {
  final repo = ref.watch(careerRepositoryProvider);
  return repo.getVerifiedDocuments();
});

final verifiedDocumentDetailProvider = FutureProvider.family.autoDispose<VerifiedDocumentModel?, String>((ref, docId) async {
  final repo = ref.watch(careerRepositoryProvider);
  return repo.getVerifiedDocument(docId);
});

// V2 Providers
final detailedJobReadinessProvider = FutureProvider.family.autoDispose<Map<String, dynamic>, String?>((ref, targetRole) async {
  final repo = ref.watch(careerRepositoryProvider);
  return repo.getDetailedJobReadiness(targetRole: targetRole);
});

final projectEvidencesProvider = FutureProvider.autoDispose<List<ProjectEvidenceModel>>((ref) async {
  final repo = ref.watch(careerRepositoryProvider);
  return repo.getProjects();
});

final skillGraphProvider = FutureProvider.family.autoDispose<SkillGraphModel, String>((ref, roadmapId) async {
  final repo = ref.watch(careerRepositoryProvider);
  return repo.getRoadmapGraph(roadmapId);
});

final gitHubResourcesProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, topic) async {
  final repo = ref.watch(careerRepositoryProvider);
  return repo.searchGitHubResources(topic: topic);
});

final youTubeResourcesProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, ResourceQuery>((ref, query) async {
  final repo = ref.watch(careerRepositoryProvider);
  return repo.getYouTubeResources(
    topic: query.topic,
    language: query.language,
    limit: query.limit,
  );
});

final youTubePlaylistsProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, ResourceQuery>((ref, query) async {
  final repo = ref.watch(careerRepositoryProvider);
  return repo.getYouTubePlaylists(
    topic: query.topic,
    language: query.language,
    limit: query.limit,
  );
});

final roadmapNodeContextProvider = FutureProvider.family.autoDispose<RoadmapNodeContextModel, NodeContextQuery>((ref, query) async {
  final repo = ref.watch(careerRepositoryProvider);
  return repo.getRoadmapNodeContext(
    roadmapId: query.roadmapId,
    nodeId: query.nodeId,
  );
});



