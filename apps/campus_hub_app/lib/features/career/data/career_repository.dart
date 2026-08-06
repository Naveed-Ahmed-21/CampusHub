import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/career_models.dart';

class CareerRepository {
  final Dio _dio;

  CareerRepository(this._dio);

  Future<List<CareerRoadmapModel>> getRoadmaps({String? category, String? level, String? search}) async {
    final query = <String, dynamic>{};
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (level != null && level.isNotEmpty) query['level'] = level;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final response = await _dio.get('/api/v1/career/roadmaps', queryParameters: query);
    final List list = response.data['data'] ?? [];
    return list.map((json) => CareerRoadmapModel.fromJson(json)).toList();
  }

  Future<CareerRoadmapModel> getRoadmapDetails(String id) async {
    final response = await _dio.get('/api/v1/career/roadmaps/$id');
    return CareerRoadmapModel.fromJson(response.data['data']);
  }

  Future<Map<String, dynamic>> getUserProgress() async {
    final response = await _dio.get('/api/v1/career/progress');
    return response.data['data'] ?? {};
  }

  Future<void> toggleNodeProgress(String nodeId, bool isCompleted) async {
    await _dio.post(
      '/api/v1/career/nodes/progress',
      data: {
        'node_id': nodeId,
        'is_completed': isCompleted,
      },
    );
  }

  Future<List<WeeklyGoalModel>> getWeeklyGoals() async {
    final response = await _dio.get('/api/v1/career/goals');
    final List list = response.data['data'] ?? [];
    return list.map((json) => WeeklyGoalModel.fromJson(json)).toList();
  }

  Future<WeeklyGoalModel> createWeeklyGoal(String title, {String? targetDate}) async {
    final response = await _dio.post(
      '/api/v1/career/goals',
      data: {
        'title': title,
        'target_date': targetDate,
      },
    );
    return WeeklyGoalModel.fromJson(response.data['data']);
  }

  Future<void> toggleWeeklyGoal(String goalId, bool isCompleted) async {
    await _dio.patch(
      '/api/v1/career/goals/$goalId',
      data: {'is_completed': isCompleted},
    );
  }

  Future<List<ResumeTipModel>> getResumeTips() async {
    final response = await _dio.get('/api/v1/career/resume-tips');
    final List list = response.data['data'] ?? [];
    return list.map((json) => ResumeTipModel.fromJson(json)).toList();
  }

  Future<List<PlacementPrepModel>> getPlacementPrep() async {
    final response = await _dio.get('/api/v1/career/placement-prep');
    final List list = response.data['data'] ?? [];
    return list.map((json) => PlacementPrepModel.fromJson(json)).toList();
  }

  Future<List<MiniProjectModel>> getMiniProjects() async {
    final response = await _dio.get('/api/v1/career/mini-projects');
    final List list = response.data['data'] ?? [];
    return list.map((json) => MiniProjectModel.fromJson(json)).toList();
  }

  Future<void> submitMiniProject(String projectId, String repoUrl, {String? liveDemoUrl}) async {
    await _dio.post(
      '/api/v1/career/mini-projects/submit',
      data: {
        'project_id': projectId,
        'repo_url': repoUrl,
        'live_demo_url': liveDemoUrl,
      },
    );
  }
}

final careerRepositoryProvider = Provider<CareerRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return CareerRepository(dio);
});
