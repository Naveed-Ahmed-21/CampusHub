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

  Future<List<UserRoadmapItemModel>> getUserRoadmaps() async {
    final response = await _dio.get('/api/v1/career/user-roadmaps');
    final List list = response.data['data'] ?? [];
    return list.map((json) => UserRoadmapItemModel.fromJson(json)).toList();
  }

  Future<CareerRoadmapModel> getRoadmapDetails(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty || cleanId == 'null') {
      final userRoadmaps = await getUserRoadmaps();
      if (userRoadmaps.isNotEmpty) {
        return getRoadmapDetails(userRoadmaps.first.id);
      }
      final roadmaps = await getRoadmaps();
      if (roadmaps.isNotEmpty) return roadmaps.first;
      throw StateError('No roadmaps available');
    }
    final response = await _dio.get('/api/v1/career/roadmaps/$cleanId');
    final data = response.data['data'];
    if (data is List) {
      if (data.isEmpty) throw StateError('Roadmap not found');
      return CareerRoadmapModel.fromJson(data.first as Map<String, dynamic>);
    }
    return CareerRoadmapModel.fromJson(data as Map<String, dynamic>);
  }

  Future<DuplicateCheckResultModel> checkDuplicate(String targetRole) async {
    final response = await _dio.post(
      '/api/v1/career/check-duplicate',
      data: {'target_role': targetRole},
    );
    return DuplicateCheckResultModel.fromJson(response.data['data']);
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

  Future<void> setActiveRoadmap(String roadmapId) async {
    await _dio.post('/api/v1/career/roadmaps/$roadmapId/activate');
  }

  Future<void> updateRoadmap(String roadmapId, {String? status, String? title}) async {
    await _dio.patch(
      '/api/v1/career/roadmaps/$roadmapId',
      data: {
        if (status != null) 'status': status,
        if (title != null) 'title': title,
      },
    );
  }

  Future<void> deleteRoadmap(String roadmapId) async {
    await _dio.delete('/api/v1/career/roadmaps/$roadmapId');
  }

  Future<DailyLearningPlanModel?> getDailyPlan({String? roadmapId}) async {
    final response = await _dio.get(
      '/api/v1/career/daily-plan',
      queryParameters: roadmapId != null ? {'roadmap_id': roadmapId} : null,
    );
    final data = response.data['data'];
    if (data == null) return null;
    return DailyLearningPlanModel.fromJson(data);
  }

  Future<void> toggleDailyTask(String roadmapId, String taskId, bool isCompleted) async {
    await _dio.post(
      '/api/v1/career/roadmaps/$roadmapId/daily-task',
      data: {
        'task_id': taskId,
        'is_completed': isCompleted,
      },
    );
  }

  Future<Map<String, dynamic>> adaptRoadmap(String roadmapId, {String? feedbackNote}) async {
    final response = await _dio.post(
      '/api/v1/career/roadmaps/$roadmapId/adapt',
      data: {
        if (feedbackNote != null) 'feedback_note': feedbackNote,
      },
    );
    return response.data['data'] ?? {};
  }

  Future<AskAiResponseModel> askAiAboutRoadmap(String roadmapId, String prompt, {int? currentPhase}) async {
    final response = await _dio.post(
      '/api/v1/career/roadmaps/ask-ai',
      data: {
        'roadmap_id': roadmapId,
        'prompt': prompt,
        if (currentPhase != null) 'current_phase': currentPhase,
      },
    );
    return AskAiResponseModel.fromJson(response.data['data']);
  }

  Future<SkillGapAnalysisModel> getSkillGapAnalysis(String roadmapId) async {
    final response = await _dio.get('/api/v1/career/roadmaps/$roadmapId/skill-gap');
    return SkillGapAnalysisModel.fromJson(response.data['data']);
  }

  Future<List<SkillMapNodeModel>> getSkillMap(String roadmapId) async {
    final response = await _dio.get('/api/v1/career/roadmaps/$roadmapId/skill-map');
    final List list = response.data['data'] ?? [];
    return list.map((json) => SkillMapNodeModel.fromJson(json)).toList();
  }

  Future<WeeklyReviewModel> getWeeklyReview({String? roadmapId}) async {
    final response = await _dio.get(
      '/api/v1/career/weekly-review',
      queryParameters: roadmapId != null ? {'roadmap_id': roadmapId} : null,
    );
    return WeeklyReviewModel.fromJson(response.data['data']);
  }

  Future<JobReadinessModel> getJobReadiness({String? roadmapId}) async {
    final response = await _dio.get(
      '/api/v1/career/job-readiness',
      queryParameters: roadmapId != null ? {'roadmap_id': roadmapId} : null,
    );
    return JobReadinessModel.fromJson(response.data['data']);
  }

  Future<List<InterviewQuestionModel>> getInterviewPrep({String? roadmapId}) async {
    final response = await _dio.get(
      '/api/v1/career/interview-prep',
      queryParameters: roadmapId != null ? {'roadmap_id': roadmapId} : null,
    );
    final List list = response.data['data'] ?? [];
    return list.map((json) => InterviewQuestionModel.fromJson(json)).toList();
  }

  Future<void> exportProjectToPortfolio(
    String roadmapId,
    String title,
    List<String> techStack, {
    String? description,
    String? projectUrl,
    String? repoUrl,
  }) async {
    await _dio.post(
      '/api/v1/career/export-portfolio',
      data: {
        'roadmap_id': roadmapId,
        'title': title,
        'tech_stack': techStack,
        if (description != null) 'description': description,
        if (projectUrl != null) 'project_url': projectUrl,
        if (repoUrl != null) 'repo_url': repoUrl,
      },
    );
  }

  Future<void> askFacultyMentor(String roadmapId, String message, {String? facultyId}) async {
    await _dio.post(
      '/api/v1/career/ask-mentor',
      data: {
        'roadmap_id': roadmapId,
        'message': message,
        if (facultyId != null) 'faculty_id': facultyId,
      },
    );
  }

  Future<List<WeeklyGoalModel>> getWeeklyGoals() async {
    final response = await _dio.get('/api/v1/career/goals');
    final List list = response.data['data'] ?? [];
    return list.map((json) => WeeklyGoalModel.fromJson(json)).toList();
  }

  Future<WeeklyGoalModel> createWeeklyGoal(String title, {String? targetDate, String? category}) async {
    final effectiveTitle = category != null && category.isNotEmpty && category != 'Custom'
        ? '[$category] $title'
        : title;
    final response = await _dio.post(
      '/api/v1/career/goals',
      data: {
        'title': effectiveTitle,
        if (targetDate != null) 'target_date': targetDate,
        if (category != null) 'category': category,
      },
    );
    return WeeklyGoalModel.fromJson(response.data['data']);
  }

  Future<WeeklyGoalModel> updateWeeklyGoal(
    String goalId, {
    String? title,
    String? targetDate,
    String? category,
    bool? isCompleted,
  }) async {
    final effectiveTitle = title != null
        ? (category != null && category.isNotEmpty && category != 'Custom' ? '[$category] $title' : title)
        : null;

    final response = await _dio.put(
      '/api/v1/career/goals/$goalId',
      data: {
        if (effectiveTitle != null) 'title': effectiveTitle,
        if (targetDate != null) 'target_date': targetDate,
        if (category != null) 'category': category,
        if (isCompleted != null) 'is_completed': isCompleted,
      },
    );
    return WeeklyGoalModel.fromJson(response.data['data']);
  }

  Future<void> deleteWeeklyGoal(String goalId) async {
    await _dio.delete('/api/v1/career/goals/$goalId');
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

  Future<ProjectEvaluationModel?> submitMiniProject(String projectId, String repoUrl, {String? liveDemoUrl}) async {
    final response = await _dio.post(
      '/api/v1/career/mini-projects/submit',
      data: {
        'project_id': projectId,
        'repo_url': repoUrl,
        'live_demo_url': liveDemoUrl,
      },
    );
    final evalData = response.data['data']?['evaluation'];
    if (evalData != null) {
      return ProjectEvaluationModel.fromJson(evalData);
    }
    return null;
  }

  Future<AdaptiveQuizModel> generateAdaptiveQuiz({
    String? roadmapId,
    int? phaseNumber,
    String? role,
    String? topic,
    String? difficulty,
    int? numQuestions,
  }) async {
    final response = await _dio.post(
      '/api/v1/career/quiz/generate',
      data: {
        if (roadmapId != null && roadmapId.isNotEmpty) 'roadmap_id': roadmapId,
        if (phaseNumber != null) 'phase_number': phaseNumber,
        if (role != null) 'role': role,
        if (topic != null) 'topic': topic,
        if (difficulty != null) 'difficulty': difficulty,
        if (numQuestions != null) 'num_questions': numQuestions,
      },
    );
    return AdaptiveQuizModel.fromJson(response.data['data']);
  }

  // ==========================================
  // AI CAREER DISCOVERY & PERSONALIZED ROADMAP
  // ==========================================

  Future<List<CareerRecommendationModel>> submitAssessment(Map<String, dynamic> answers) async {
    final response = await _dio.post('/api/v1/career/assessment', data: answers);
    final List rawList = response.data['data']?['recommendations'] ?? [];
    return rawList.map((json) => CareerRecommendationModel.fromJson(json)).toList();
  }

  Future<CareerDecisionResult> helpMeDecide({
    required String visualVsLogic,
    required String fastVsDeep,
    required String startupVsEnterprise,
    String? confusionNotes,
  }) async {
    final response = await _dio.post(
      '/api/v1/career/decide',
      data: {
        'visual_vs_logic': visualVsLogic,
        'fast_vs_deep': fastVsDeep,
        'startup_vs_enterprise': startupVsEnterprise,
        if (confusionNotes != null && confusionNotes.trim().isNotEmpty)
          'confusion_notes': confusionNotes.trim(),
      },
    );
    return CareerDecisionResult.fromJson(response.data['data']);
  }

  Future<ActiveRoadmapState?> getActiveRoadmap() async {
    try {
      final response = await _dio.get('/api/v1/career/active-roadmap');
      final data = response.data['data'];
      if (data == null) return null;
      return ActiveRoadmapState.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> generateOrActivateRoadmap({
    required String role,
    required String level,
    required int weeklyHours,
    String? goal,
    int? deadlineDays,
    bool? isPlacementFocused,
    bool? createNewVersion,
    Map<String, dynamic>? assessmentData,
  }) async {
    final response = await _dio.post(
      '/api/v1/career/generate-roadmap',
      data: {
        'role': role,
        'level': level,
        'weekly_hours': weeklyHours,
        if (goal != null) 'goal': goal,
        if (deadlineDays != null) 'deadline_days': deadlineDays,
        if (isPlacementFocused != null) 'is_placement_focused': isPlacementFocused,
        if (createNewVersion != null) 'create_new_version': createNewVersion,
        if (assessmentData != null) 'assessment_data': assessmentData,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<PhaseQuizResult> submitPhaseQuiz({
    required int phaseNumber,
    required String role,
    required Map<int, int> answers,
    String? roadmapId,
  }) async {
    final formattedAnswers = answers.map((k, v) => MapEntry(k.toString(), v));
    final response = await _dio.post(
      '/api/v1/career/quiz/submit',
      data: {
        'phase_number': phaseNumber,
        'role': role,
        'answers': formattedAnswers,
        if (roadmapId != null && roadmapId.trim().isNotEmpty)
          'roadmap_id': roadmapId.trim(),
      },
    );
    return PhaseQuizResult.fromJson(response.data['data']);
  }

  // Conversational Pathfinder
  Future<PathfinderChatResponse> startPathfinderSession({bool resumeActive = true}) async {
    final response = await _dio.post(
      '/api/v1/career/pathfinder/session',
      data: {'resume_active': resumeActive},
    );
    return PathfinderChatResponse.fromJson(response.data['data']);
  }

  Future<PathfinderChatResponse> pathfinderChat({
    required String message,
    String? conversationId,
  }) async {
    final response = await _dio.post(
      '/api/v1/career/pathfinder/chat',
      data: {
        'message': message,
        if (conversationId != null) 'conversation_id': conversationId,
      },
    );
    return PathfinderChatResponse.fromJson(response.data['data']);
  }

  Future<Map<String, dynamic>> confirmPathfinderJourney({
    required String conversationId,
    String? selectedDirection,
  }) async {
    final response = await _dio.post(
      '/api/v1/career/pathfinder/confirm',
      data: {
        'conversation_id': conversationId,
        if (selectedDirection != null) 'selected_direction': selectedDirection,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  // Ask AI Doubt
  Future<AskAiResponseModel> askAiDoubt({
    required String prompt,
    String? roadmapId,
  }) async {
    final response = await _dio.post(
      '/api/v1/career/ask-ai',
      data: {
        'prompt': prompt,
        if (roadmapId != null) 'roadmap_id': roadmapId,
      },
    );
    return AskAiResponseModel.fromJson(response.data['data']);
  }

  // Roadmap Changes History & Improvement
  Future<List<RoadmapChangeModel>> getRoadmapChanges(String roadmapId) async {
    final response = await _dio.get('/api/v1/career/roadmaps/$roadmapId/changes');
    final List list = response.data['data'] ?? [];
    return list.map((json) => RoadmapChangeModel.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> improveRoadmap({
    required String roadmapId,
    required String reason,
    Map<String, dynamic>? details,
  }) async {
    final response = await _dio.post(
      '/api/v1/career/roadmaps/$roadmapId/improve',
      data: {
        'reason': reason,
        if (details != null) 'details': details,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  // Verified Learning Resources
  Future<List<VerifiedResourceModel>> searchResources({
    required String topic,
    String? language,
    String? level,
    String? targetRole,
  }) async {
    final response = await _dio.get(
      '/api/v1/career/resources/search',
      queryParameters: {
        'topic': topic,
        if (language != null) 'language': language,
        if (level != null) 'level': level,
        if (targetRole != null) 'target_role': targetRole,
      },
    );
    final List list = response.data['data'] ?? [];
    return list.map((json) => VerifiedResourceModel.fromJson(json)).toList();
  }

  // Learning Sessions
  Future<LearningSessionModel> startLearningSession({
    required String roadmapId,
    required String taskId,
    required String taskTitle,
    required int phaseNumber,
  }) async {
    final response = await _dio.post(
      '/api/v1/career/learning-session/start',
      data: {
        'roadmap_id': roadmapId,
        'task_id': taskId,
        'task_title': taskTitle,
        'phase_number': phaseNumber,
      },
    );
    return LearningSessionModel.fromJson(response.data['data']);
  }

  Future<LearningSessionModel> finishLearningSession({
    required String sessionId,
    required int durationMinutes,
    required String status,
    int? selfRating,
  }) async {
    final response = await _dio.post(
      '/api/v1/career/learning-session/finish',
      data: {
        'session_id': sessionId,
        'duration_minutes': durationMinutes,
        'status': status,
        if (selfRating != null) 'self_rating': selfRating,
      },
    );
    return LearningSessionModel.fromJson(response.data['data']);
  }

  // EVA AI Mock Interview
  Future<InterviewSessionModel> startInterviewSession({
    String? roadmapId,
    required String targetRole,
    String mode = 'TEXT',
  }) async {
    final response = await _dio.post(
      '/api/v1/career/interview/start',
      data: {
        if (roadmapId != null) 'roadmap_id': roadmapId,
        'target_role': targetRole,
        'mode': mode,
      },
    );
    return InterviewSessionModel.fromJson(response.data['data']);
  }

  Future<Map<String, dynamic>> submitInterviewTurn({
    required String sessionId,
    required String studentAnswer,
  }) async {
    final response = await _dio.post(
      '/api/v1/career/interview/turn',
      data: {
        'session_id': sessionId,
        'student_answer': studentAnswer,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<InterviewSessionModel> finishInterviewSession({
    required String sessionId,
  }) async {
    final response = await _dio.post(
      '/api/v1/career/interview/finish',
      data: {
        'session_id': sessionId,
      },
    );
    return InterviewSessionModel.fromJson(response.data['data']);
  }

  Future<Map<String, dynamic>> applyInterviewRoadmapUpdate({
    required String sessionId,
  }) async {
    final response = await _dio.post(
      '/api/v1/career/interview/apply-roadmap-update',
      data: {
        'session_id': sessionId,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<List<InterviewSessionModel>> getInterviewHistory() async {
    final response = await _dio.get('/api/v1/career/interview/history');
    final list = (response.data['data'] as List<dynamic>?) ?? [];
    return list.map((json) => InterviewSessionModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> resetCareerData() async {
    final response = await _dio.post('/api/v1/career/reset');
    return (response.data['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<List<VerifiedDocumentModel>> getVerifiedDocuments() async {
    try {
      final response = await _dio.get('/api/v1/career/docs');
      final list = (response.data['data'] as List<dynamic>?) ?? [];
      return list.map((item) => VerifiedDocumentModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<VerifiedDocumentModel?> getVerifiedDocument(String docId) async {
    try {
      final response = await _dio.get('/api/v1/career/docs/$docId');
      final data = response.data['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return VerifiedDocumentModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  // ==========================================
  // V2 REBUILD METHODS
  // ==========================================

  Future<DynamicPathfinderSessionModel> startPathfinderSessionV2({
    String? targetDomain,
    String? preferredLanguage,
    String? department,
  }) async {
    final response = await _dio.post(
      '/api/v1/career/pathfinder/session/start',
      data: {
        if (targetDomain != null) 'target_domain': targetDomain,
        if (preferredLanguage != null) 'preferred_language': preferredLanguage,
        if (department != null) 'department': department,
      },
    );
    return DynamicPathfinderSessionModel.fromJson(response.data['data']);
  }

  Future<Map<String, dynamic>> answerPathfinderQuestionV2({
    required String sessionId,
    required String answer,
    String? questionId,
  }) async {
    final response = await _dio.post(
      '/api/v1/career/pathfinder/session/$sessionId/answer',
      data: {
        'answer': answer,
        if (questionId != null) 'question_id': questionId,
      },
    );
    return (response.data['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<DynamicPathfinderSessionModel> getPathfinderSessionV2(String sessionId) async {
    final response = await _dio.get('/api/v1/career/pathfinder/session/$sessionId');
    return DynamicPathfinderSessionModel.fromJson(response.data['data']);
  }

  Future<DynamicPathfinderSessionModel> stepBackPathfinderSessionV2(String sessionId) async {
    final response = await _dio.post('/api/v1/career/pathfinder/session/$sessionId/previous');
    return DynamicPathfinderSessionModel.fromJson(response.data['data']['session']);
  }

  Future<CareerRoadmapModel> generatePersonalizedRoadmap({
    required String targetRole,
    String? department,
    String? currentLevel,
    int? hoursPerWeek,
    int? timelineWeeks,
    String? primaryGoal,
    String? preferredLanguage,
  }) async {
    final response = await _dio.post(
      '/api/v1/career/generate-personalized-roadmap',
      data: {
        'target_role': targetRole,
        if (department != null) 'department': department,
        if (currentLevel != null) 'current_level': currentLevel,
        if (hoursPerWeek != null) 'hours_per_week': hoursPerWeek,
        if (timelineWeeks != null) 'timeline_weeks': timelineWeeks,
        if (primaryGoal != null) 'primary_goal': primaryGoal,
        if (preferredLanguage != null) 'preferred_language': preferredLanguage,
      },
    );
    return CareerRoadmapModel.fromJson(response.data['data']);
  }

  Future<SkillGraphModel> getRoadmapGraph(String roadmapId) async {
    final response = await _dio.get('/api/v1/career/roadmaps/$roadmapId/graph');
    return SkillGraphModel.fromJson(response.data['data']);
  }

  Future<List<Map<String, dynamic>>> searchGitHubResources({
    required String topic,
    int limit = 6,
    String? language,
  }) async {
    final response = await _dio.get(
      '/api/v1/career/resources/github',
      queryParameters: {
        'topic': topic,
        'limit': limit,
        if (language != null) 'language': language,
      },
    );
    final list = (response.data['data'] as List<dynamic>?) ?? [];
    return list.map((item) => item as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> getYouTubeResources({
    required String topic,
    String language = 'English',
    int limit = 6,
  }) async {
    final response = await _dio.get(
      '/api/v1/career/resources/youtube',
      queryParameters: {
        'topic': topic,
        'language': language,
        'limit': limit,
      },
    );
    final list = (response.data['data'] as List<dynamic>?) ?? [];
    return list.map((item) => item as Map<String, dynamic>).toList();
  }

  Future<AdaptiveQuizModel> generateAdaptiveQuizV2({
    required String topic,
    int phaseNumber = 1,
    String? roadmapId,
    String? skillName,
    String? difficulty,
  }) async {
    final response = await _dio.post(
      '/api/v1/career/quiz/adaptive-generate',
      data: {
        'topic': topic,
        'phase_number': phaseNumber,
        if (roadmapId != null) 'roadmap_id': roadmapId,
        if (skillName != null) 'skill_name': skillName,
        if (difficulty != null) 'difficulty': difficulty,
      },
    );
    return AdaptiveQuizModel.fromJson(response.data['data']);
  }

  Future<Map<String, dynamic>> submitAdaptiveQuizV2({
    String? roadmapId,
    int phaseNumber = 1,
    required String topic,
    String? skillName,
    required Map<String, dynamic> answers,
    required List<Map<String, dynamic>> questions,
    int timeSpentSeconds = 60,
  }) async {
    final response = await _dio.post(
      '/api/v1/career/quiz/adaptive-submit',
      data: {
        if (roadmapId != null) 'roadmap_id': roadmapId,
        'phase_number': phaseNumber,
        'topic': topic,
        if (skillName != null) 'skill_name': skillName,
        'answers': answers,
        'questions': questions,
        'time_spent_seconds': timeSpentSeconds,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<List<ProjectEvidenceModel>> getProjects() async {
    final response = await _dio.get('/api/v1/career/projects');
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    final list = (data['evidences'] as List<dynamic>?) ?? [];
    return list.map((item) => ProjectEvidenceModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<ProjectEvidenceModel> createProjectEvidence({
    required String title,
    required String description,
    String? githubUrl,
    String? demoUrl,
    List<String> techStack = const [],
  }) async {
    final response = await _dio.post(
      '/api/v1/career/projects',
      data: {
        'title': title,
        'description': description,
        if (githubUrl != null && githubUrl.isNotEmpty) 'github_url': githubUrl,
        if (demoUrl != null && demoUrl.isNotEmpty) 'demo_url': demoUrl,
        'tech_stack': techStack,
      },
    );
    return ProjectEvidenceModel.fromJson(response.data['data']);
  }

  Future<void> deleteProjectEvidence(String id) async {
    await _dio.delete('/api/v1/career/projects/$id');
  }

  Future<void> deleteInterviewSession(String sessionId) async {
    await _dio.delete('/api/v1/career/interview/session/$sessionId');
  }

  Future<Map<String, dynamic>> getDetailedJobReadiness({String? targetRole}) async {
    final response = await _dio.get(
      '/api/v1/career/job-readiness/detailed',
      queryParameters: targetRole != null ? {'target_role': targetRole} : null,
    );
    return (response.data['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<List<Map<String, dynamic>>> getYouTubePlaylists({
    required String topic,
    String language = 'English',
    int limit = 3,
  }) async {
    final response = await _dio.get(
      '/api/v1/career/resources/youtube/playlists',
      queryParameters: {
        'topic': topic,
        'language': language,
        'limit': limit,
      },
    );
    final list = (response.data['data'] as List<dynamic>?) ?? [];
    return list.map((item) => item as Map<String, dynamic>).toList();
  }

  Future<RoadmapNodeContextModel> getRoadmapNodeContext({
    required String roadmapId,
    String? nodeId,
  }) async {
    final path = (nodeId != null && nodeId.isNotEmpty)
        ? '/api/v1/career/roadmaps/$roadmapId/nodes/$nodeId/context'
        : '/api/v1/career/roadmaps/$roadmapId/context';
    final response = await _dio.get(path);
    return RoadmapNodeContextModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}

final careerRepositoryProvider = Provider<CareerRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return CareerRepository(dio);
});
