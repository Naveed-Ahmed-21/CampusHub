import 'package:flutter/foundation.dart';

class CareerRoadmapModel {
  final String id;
  final String title;
  final String slug;
  final String category;
  final String description;
  final String level;
  final int estimatedMonths;
  final String? iconName;
  final List<RoadmapNodeModel> nodes;
  final List<LearningResourceModel> resources;
  final List<RoadmapPhaseDetailModel> phases;

  CareerRoadmapModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.category,
    required this.description,
    required this.level,
    required this.estimatedMonths,
    this.iconName,
    this.nodes = const [],
    this.resources = const [],
    this.phases = const [],
  });

  String get targetRole => title;

  factory CareerRoadmapModel.fromJson(Map<String, dynamic> json) {
    final rawNodes = json['nodes'] as List<dynamic>? ?? [];
    final rawResources = json['resources'] as List<dynamic>? ?? [];
    final rawPhases = json['phases_json'] as List<dynamic>? ??
        json['phasesJson'] as List<dynamic>? ??
        json['phases'] as List<dynamic>? ??
        [];

    return CareerRoadmapModel(
      id: json['id'] ?? json['roadmapId'] ?? json['roadmap_id'] ?? '',
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      category: json['category'] ?? 'General',
      description: json['description'] ?? '',
      level: json['level'] ?? 'Beginner',
      estimatedMonths: json['estimated_months'] ?? 3,
      iconName: json['icon_name'],
      nodes: rawNodes.map((n) => RoadmapNodeModel.fromJson(n)).toList(),
      resources: rawResources.map((r) => LearningResourceModel.fromJson(r)).toList(),
      phases: rawPhases.map((p) => RoadmapPhaseDetailModel.fromJson(p as Map<String, dynamic>)).toList(),
    );
  }
}

class RoadmapNodeModel {
  final String id;
  final String roadmapId;
  final String title;
  final String? description;
  final int orderIndex;
  final int? estimatedHours;
  final List<LearningResourceModel> resources;

  RoadmapNodeModel({
    required this.id,
    required this.roadmapId,
    required this.title,
    this.description,
    required this.orderIndex,
    this.estimatedHours,
    this.resources = const [],
  });

  factory RoadmapNodeModel.fromJson(Map<String, dynamic> json) {
    final rawResources = json['resources'] as List<dynamic>? ?? [];
    return RoadmapNodeModel(
      id: json['id'] ?? '',
      roadmapId: json['roadmap_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      orderIndex: json['order_index'] ?? 1,
      estimatedHours: json['estimated_hours'],
      resources: rawResources.map((r) => LearningResourceModel.fromJson(r)).toList(),
    );
  }
}

class LearningResourceModel {
  final String id;
  final String? roadmapId;
  final String? nodeId;
  final String title;
  final String type; // ARTICLE, VIDEO, DOCS, PRACTICE
  final String url;
  final int? durationMins;
  final bool isFree;

  LearningResourceModel({
    required this.id,
    this.roadmapId,
    this.nodeId,
    required this.title,
    required this.type,
    required this.url,
    this.durationMins,
    this.isFree = true,
  });

  factory LearningResourceModel.fromJson(Map<String, dynamic> json) {
    return LearningResourceModel(
      id: json['id'] ?? '',
      roadmapId: json['roadmap_id'],
      nodeId: json['node_id'],
      title: json['title'] ?? '',
      type: json['type'] ?? 'ARTICLE',
      url: json['url'] ?? '',
      durationMins: json['duration_mins'],
      isFree: json['is_free'] ?? true,
    );
  }
}

class WeeklyGoalModel {
  final String id;
  final String userId;
  final String title;
  final String category;
  final DateTime targetDate;
  final bool isCompleted;
  final DateTime? completedAt;

  WeeklyGoalModel({
    required this.id,
    required this.userId,
    required this.title,
    this.category = 'DSA',
    required this.targetDate,
    this.isCompleted = false,
    this.completedAt,
  });

  factory WeeklyGoalModel.fromJson(Map<String, dynamic> json) {
    String rawTitle = json['title'] ?? '';
    String resolvedCategory = json['category'] ?? 'DSA';

    // Parse category prefix like [Development] if embedded in title
    if (rawTitle.startsWith('[') && rawTitle.contains(']')) {
      final endIdx = rawTitle.indexOf(']');
      resolvedCategory = rawTitle.substring(1, endIdx);
      rawTitle = rawTitle.substring(endIdx + 1).trim();
    }

    return WeeklyGoalModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: rawTitle,
      category: resolvedCategory,
      targetDate: json['target_date'] != null ? (DateTime.tryParse(json['target_date']) ?? DateTime.now()) : DateTime.now(),
      isCompleted: json['is_completed'] ?? false,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at']) : null,
    );
  }

  WeeklyGoalModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? category,
    DateTime? targetDate,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return WeeklyGoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      category: category ?? this.category,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class ResumeTipModel {
  final String id;
  final String category;
  final String title;
  final String content;
  final List<String> bulletPoints;
  final String? sampleUrl;

  ResumeTipModel({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    this.bulletPoints = const [],
    this.sampleUrl,
  });

  factory ResumeTipModel.fromJson(Map<String, dynamic> json) {
    final rawBullets = json['bullet_points'] as List<dynamic>? ?? [];
    return ResumeTipModel(
      id: json['id'] ?? '',
      category: json['category'] ?? 'General',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      bulletPoints: rawBullets.map((b) => b.toString()).toList(),
      sampleUrl: json['sample_url'],
    );
  }
}

class PlacementPrepModel {
  final String id;
  final String title;
  final String category;
  final String? description;
  final String? resourceUrl;
  final List<Map<String, dynamic>> contentItems;

  PlacementPrepModel({
    required this.id,
    required this.title,
    required this.category,
    this.description,
    this.resourceUrl,
    this.contentItems = const [],
  });

  factory PlacementPrepModel.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content_json'] as List<dynamic>? ?? [];
    return PlacementPrepModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? 'DSA',
      description: json['description'],
      resourceUrl: json['resource_url'] as String? ?? json['resourceUrl'] as String?,
      contentItems: rawContent.map((c) => Map<String, dynamic>.from(c)).toList(),
    );
  }
}

class MiniProjectModel {
  final String id;
  final String title;
  final String difficulty;
  final List<String> techStack;
  final String problemStatement;
  final List<String> keyFeatures;
  final String? githubTemplateUrl;
  final Map<String, dynamic>? submission;

  MiniProjectModel({
    required this.id,
    required this.title,
    required this.difficulty,
    this.techStack = const [],
    required this.problemStatement,
    this.keyFeatures = const [],
    this.githubTemplateUrl,
    this.submission,
  });

  bool get isSubmitted => submission != null;

  factory MiniProjectModel.fromJson(Map<String, dynamic> json) {
    final rawStack = json['tech_stack'] as List<dynamic>? ?? [];
    final rawFeatures = json['key_features'] as List<dynamic>? ?? [];

    return MiniProjectModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      difficulty: json['difficulty'] ?? 'Intermediate',
      techStack: rawStack.map((s) => s.toString()).toList(),
      problemStatement: json['problem_statement'] ?? '',
      keyFeatures: rawFeatures.map((f) => f.toString()).toList(),
      githubTemplateUrl: json['github_template_url'],
      submission: json['submission'],
    );
  }
}

class CareerPhaseModel {
  final int phaseNumber;
  final String title;
  final int weeks;
  final String description;
  final List<String> topics;

  CareerPhaseModel({
    required this.phaseNumber,
    required this.title,
    required this.weeks,
    required this.description,
    this.topics = const [],
  });

  factory CareerPhaseModel.fromJson(Map<String, dynamic> json) {
    final rawTopics = json['topics'] as List<dynamic>? ?? [];
    return CareerPhaseModel(
      phaseNumber: json['phase_number'] ?? json['phaseNumber'] ?? 1,
      title: json['title'] ?? '',
      weeks: json['weeks'] ?? 3,
      description: json['description'] ?? '',
      topics: rawTopics.map((t) => t.toString()).toList(),
    );
  }
}

class CareerRecommendationModel {
  final String id;
  final String title;
  final String slug;
  final String category;
  final int matchPercentage;
  final String difficulty;
  final String reasoning;
  final String weeklyCommitment;
  final List<String> keySkills;
  final List<String> suggestedProjects;
  final List<CareerPhaseModel> phases;

  CareerRecommendationModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.category,
    required this.matchPercentage,
    required this.difficulty,
    required this.reasoning,
    required this.weeklyCommitment,
    this.keySkills = const [],
    this.suggestedProjects = const [],
    this.phases = const [],
  });

  factory CareerRecommendationModel.fromJson(Map<String, dynamic> json) {
    final rawSkills = json['key_skills'] as List<dynamic>? ?? [];
    final rawProjects = json['suggested_projects'] as List<dynamic>? ?? [];
    final rawPhases = json['phases'] as List<dynamic>? ?? [];

    return CareerRecommendationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      category: json['category'] ?? 'Engineering',
      matchPercentage: json['match_percentage'] ?? 80,
      difficulty: json['difficulty'] ?? 'Beginner',
      reasoning: json['reasoning'] ?? '',
      weeklyCommitment: json['weekly_commitment'] ?? '10 hours/week',
      keySkills: rawSkills.map((s) => s.toString()).toList(),
      suggestedProjects: rawProjects.map((p) => p.toString()).toList(),
      phases: rawPhases.map((p) => CareerPhaseModel.fromJson(p)).toList(),
    );
  }
}

class CareerDecisionResult {
  final String verdict;
  final String summary;
  final String recommendationId;
  final List<String> pros;
  final List<String> cons;

  CareerDecisionResult({
    required this.verdict,
    required this.summary,
    required this.recommendationId,
    this.pros = const [],
    this.cons = const [],
  });

  factory CareerDecisionResult.fromJson(Map<String, dynamic> json) {
    final rawPros = json['pros'] as List<dynamic>? ?? [];
    final rawCons = json['cons'] as List<dynamic>? ?? [];

    return CareerDecisionResult(
      verdict: json['verdict'] ?? '',
      summary: json['summary'] ?? '',
      recommendationId: json['recommendationId'] ?? '',
      pros: rawPros.map((p) => p.toString()).toList(),
      cons: rawCons.map((c) => c.toString()).toList(),
    );
  }
}

class PhaseQuizFeedback {
  final String question;
  final bool isCorrect;
  final int selected;
  final int correct;
  final String explanation;

  PhaseQuizFeedback({
    required this.question,
    required this.isCorrect,
    required this.selected,
    required this.correct,
    required this.explanation,
  });

  factory PhaseQuizFeedback.fromJson(Map<String, dynamic> json) {
    return PhaseQuizFeedback(
      question: json['question'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
      selected: json['selected'] ?? 0,
      correct: json['correct'] ?? 0,
      explanation: json['explanation'] ?? '',
    );
  }
}

class PhaseQuizResult {
  final int phaseNumber;
  final int score;
  final int totalQuestions;
  final int percentage;
  final bool passed;
  final List<PhaseQuizFeedback> feedback;

  PhaseQuizResult({
    required this.phaseNumber,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.passed,
    this.feedback = const [],
  });

  factory PhaseQuizResult.fromJson(Map<String, dynamic> json) {
    final rawFeedback = json['feedback'] as List<dynamic>? ?? [];
    return PhaseQuizResult(
      phaseNumber: json['phaseNumber'] ?? 1,
      score: json['score'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 3,
      percentage: json['percentage'] ?? 0,
      passed: json['passed'] ?? false,
      feedback: rawFeedback.map((f) => PhaseQuizFeedback.fromJson(f)).toList(),
    );
  }
}

class ActiveRoadmapState {
  final String roadmapId;
  final String targetRole;
  final String level;
  final int weeklyHours;
  final String currentFocus;
  final String todayGoal;
  final double progressPercent;
  final List<String> completedNodeIds;
  final Map<String, dynamic>? quizScores;
  final CareerRoadmapModel? roadmapDetails;
  final int version;
  final int streakDays;
  final String status;
  final List<RoadmapPhaseDetailModel> phases;

  ActiveRoadmapState({
    required this.roadmapId,
    required this.targetRole,
    required this.level,
    required this.weeklyHours,
    required this.currentFocus,
    required this.todayGoal,
    required this.progressPercent,
    this.completedNodeIds = const [],
    this.quizScores,
    this.roadmapDetails,
    this.version = 1,
    this.streakDays = 1,
    this.status = 'ACTIVE',
    this.phases = const [],
  });

  int get currentPhaseNumber {
    final match = RegExp(r'Phase\s+(\d+)').firstMatch(currentFocus);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 1;
    }
    return 1;
  }

  String get currentPhaseTitle => currentFocus;

  factory ActiveRoadmapState.fromJson(Map<String, dynamic> json) {
    final rawCompleted = json['completedNodeIds'] as List<dynamic>? ?? [];
    final roadmapJson = json['roadmap'] as Map<String, dynamic>?;
    final roadmap = roadmapJson != null ? CareerRoadmapModel.fromJson(roadmapJson) : null;
    final rawPhases = json['phases'] as List<dynamic>? ??
        roadmapJson?['phases_json'] as List<dynamic>? ??
        roadmapJson?['phasesJson'] as List<dynamic>? ??
        [];
    final parsedPhases = rawPhases.map((p) => RoadmapPhaseDetailModel.fromJson(p as Map<String, dynamic>)).toList();

    return ActiveRoadmapState(
      roadmapId: json['roadmap_id'] ?? json['roadmapId'] ?? json['id'] ?? (roadmap?.id.isNotEmpty == true ? roadmap!.id : ''),
      targetRole: json['target_role'] ?? json['targetRole'] ?? 'Modern Full-Stack Developer',
      level: json['level'] ?? 'Beginner',
      weeklyHours: json['weekly_hours'] ?? json['weeklyHours'] ?? 10,
      currentFocus: json['current_focus'] ?? json['currentFocus'] ?? 'Phase 1: Core Fundamentals',
      todayGoal: json['today_goal'] ?? json['todayGoal'] ?? 'Review basic syntax and run 1 exercise',
      progressPercent: (json['progress_percent'] ?? json['progressPercent'] ?? 0.0).toDouble(),
      completedNodeIds: rawCompleted.map((c) => c.toString()).toList(),
      quizScores: (json['quiz_scores'] ?? json['quizScores']) as Map<String, dynamic>?,
      roadmapDetails: roadmap,
      version: json['version'] ?? (roadmapJson?['version'] ?? 1),
      streakDays: json['streak_days'] ?? json['streakDays'] ?? 1,
      status: json['status'] ?? (roadmapJson?['status'] ?? 'ACTIVE'),
      phases: parsedPhases.isNotEmpty ? parsedPhases : (roadmap?.phases ?? []),
    );
  }

  ActiveRoadmapState copyWith({
    String? roadmapId,
    String? targetRole,
    String? level,
    int? weeklyHours,
    String? currentFocus,
    String? todayGoal,
    double? progressPercent,
    List<String>? completedNodeIds,
    Map<String, dynamic>? quizScores,
    CareerRoadmapModel? roadmapDetails,
  }) {
    return ActiveRoadmapState(
      roadmapId: roadmapId ?? this.roadmapId,
      targetRole: targetRole ?? this.targetRole,
      level: level ?? this.level,
      weeklyHours: weeklyHours ?? this.weeklyHours,
      currentFocus: currentFocus ?? this.currentFocus,
      todayGoal: todayGoal ?? this.todayGoal,
      progressPercent: progressPercent ?? this.progressPercent,
      completedNodeIds: completedNodeIds ?? this.completedNodeIds,
      quizScores: quizScores ?? this.quizScores,
      roadmapDetails: roadmapDetails ?? this.roadmapDetails,
    );
  }
}

class UserRoadmapItemModel {
  final String id;
  final String title;
  final String targetRole;
  final String category;
  final String description;
  final String level;
  final int version;
  final String status;
  final int estimatedMonths;
  final bool isActive;
  final double progressPercent;
  final String currentFocus;
  final String todayGoal;
  final int streakDays;
  final Map<String, dynamic>? quizScores;
  final Map<String, dynamic>? dailyPlan;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<RoadmapNodeModel> nodes;
  final List<RoadmapPhaseDetailModel> phases;
  final SkillGapAnalysisModel? skillGaps;
  final List<SkillMapNodeModel> skillMap;

  UserRoadmapItemModel({
    required this.id,
    required this.title,
    required this.targetRole,
    required this.category,
    required this.description,
    required this.level,
    this.version = 1,
    this.status = 'ACTIVE',
    this.estimatedMonths = 3,
    this.isActive = false,
    this.progressPercent = 0.0,
    this.currentFocus = '',
    this.todayGoal = '',
    this.streakDays = 1,
    this.quizScores,
    this.dailyPlan,
    this.createdAt,
    this.updatedAt,
    this.nodes = const [],
    this.phases = const [],
    this.skillGaps,
    this.skillMap = const [],
  });

  bool get isCompleted => status == 'COMPLETED' || progressPercent >= 1.0;

  factory UserRoadmapItemModel.fromJson(Map<String, dynamic> json) {
    final rawNodes = json['nodes'] as List<dynamic>? ?? [];
    final rawPhases = json['phasesJson'] as List<dynamic>? ?? json['phases_json'] as List<dynamic>? ?? [];
    final rawSkillMap = json['skillMapJson'] as List<dynamic>? ?? json['skill_map_json'] as List<dynamic>? ?? [];
    final rawGaps = json['skillGapsJson'] as Map<String, dynamic>? ?? json['skill_gaps_json'] as Map<String, dynamic>?;

    return UserRoadmapItemModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      targetRole: json['targetRole'] ?? json['target_role'] ?? json['title'] ?? 'Software Engineer',
      category: json['category'] ?? 'Engineering',
      description: json['description'] ?? '',
      level: json['level'] ?? 'Beginner',
      version: json['version'] ?? 1,
      status: json['status'] ?? 'ACTIVE',
      estimatedMonths: json['estimatedMonths'] ?? json['estimated_months'] ?? 3,
      isActive: json['isActive'] ?? json['is_active'] ?? false,
      progressPercent: (json['progressPercent'] ?? json['progress_percent'] ?? 0.0).toDouble(),
      currentFocus: json['currentFocus'] ?? json['current_focus'] ?? 'Phase 1: Foundations',
      todayGoal: json['todayGoal'] ?? json['today_goal'] ?? '',
      streakDays: json['streakDays'] ?? json['streak_days'] ?? 1,
      quizScores: json['quizScores'] ?? json['quiz_scores'],
      dailyPlan: json['dailyPlan'] ?? json['daily_plan'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      nodes: rawNodes.map((n) => RoadmapNodeModel.fromJson(n)).toList(),
      phases: rawPhases.map((p) => RoadmapPhaseDetailModel.fromJson(p)).toList(),
      skillGaps: rawGaps != null ? SkillGapAnalysisModel.fromJson(rawGaps) : null,
      skillMap: rawSkillMap.map((s) => SkillMapNodeModel.fromJson(s)).toList(),
    );
  }
}

class RoadmapTaskDetailModel {
  final String id;
  final String title;
  final String type; // LEARN, PRACTICE, CHALLENGE
  final int durationMins;
  final bool isCompleted;
  final String description;

  RoadmapTaskDetailModel({
    required this.id,
    required this.title,
    required this.type,
    this.durationMins = 20,
    this.isCompleted = false,
    this.description = '',
  });

  String get category => type;
  int get estimatedMinutes => durationMins;
  List<String> get keyTopics => description.isNotEmpty ? [description] : ['Foundations', 'Implementation'];

  factory RoadmapTaskDetailModel.fromJson(Map<String, dynamic> json) {
    return RoadmapTaskDetailModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? json['category'] ?? 'LEARN',
      durationMins: json['duration_mins'] ?? json['durationMins'] ?? 20,
      isCompleted: json['is_completed'] ?? json['isCompleted'] ?? false,
      description: json['description'] ?? '',
    );
  }

  RoadmapTaskDetailModel copyWith({bool? isCompleted, String? description}) {
    return RoadmapTaskDetailModel(
      id: id,
      title: title,
      type: type,
      durationMins: durationMins,
      isCompleted: isCompleted ?? this.isCompleted,
      description: description ?? this.description,
    );
  }
}

class RoadmapPracticalChallengeModel {
  final String id;
  final String title;
  final String description;
  final List<String> requirements;
  final String difficulty;
  final List<String> tasks;
  final List<String>? hints;

  RoadmapPracticalChallengeModel({
    this.id = '',
    required this.title,
    required this.description,
    this.requirements = const [],
    this.difficulty = 'Intermediate',
    this.tasks = const [],
    this.hints,
  });

  factory RoadmapPracticalChallengeModel.fromJson(Map<String, dynamic> json) {
    final rawReqs = json['requirements'] as List<dynamic>? ?? [];
    final rawTasks = json['tasks'] as List<dynamic>? ?? [];
    final rawHints = json['hints'] as List<dynamic>?;
    return RoadmapPracticalChallengeModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      requirements: rawReqs.map((r) => r.toString()).toList(),
      difficulty: json['difficulty'] ?? 'Intermediate',
      tasks: rawTasks.isNotEmpty
          ? rawTasks.map((t) => t.toString()).toList()
          : rawReqs.map((r) => r.toString()).toList(),
      hints: rawHints?.map((h) => h.toString()).toList(),
    );
  }
}

class RoadmapProjectModel {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final List<String> techStack;
  final List<String> milestones;
  final List<String> requirements;
  final bool isCompleted;

  RoadmapProjectModel({
    this.id = '',
    required this.title,
    required this.description,
    this.difficulty = 'Intermediate',
    this.techStack = const [],
    this.milestones = const [],
    this.requirements = const [],
    this.isCompleted = false,
  });

  factory RoadmapProjectModel.fromJson(Map<String, dynamic> json) {
    final rawStack = json['tech_stack'] as List<dynamic>? ?? json['techStack'] as List<dynamic>? ?? [];
    final rawMilestones = json['milestones'] as List<dynamic>? ?? [];
    final rawRequirements = json['requirements'] as List<dynamic>? ?? [];
    return RoadmapProjectModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      difficulty: json['difficulty'] ?? 'Intermediate',
      techStack: rawStack.map((s) => s.toString()).toList(),
      milestones: rawMilestones.map((m) => m.toString()).toList(),
      requirements: rawRequirements.isNotEmpty
          ? rawRequirements.map((r) => r.toString()).toList()
          : rawMilestones.map((m) => m.toString()).toList(),
      isCompleted: json['is_completed'] ?? json['isCompleted'] ?? false,
    );
  }
}

class RoadmapQuizQuestionModel {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  RoadmapQuizQuestionModel({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory RoadmapQuizQuestionModel.fromJson(Map<String, dynamic> json) {
    final rawOpts = json['options'] as List<dynamic>? ?? [];
    return RoadmapQuizQuestionModel(
      question: json['question'] ?? '',
      options: rawOpts.map((o) => o.toString()).toList(),
      correctIndex: json['correct_index'] ?? json['correctIndex'] ?? 0,
      explanation: json['explanation'] ?? '',
    );
  }
}

class RoadmapPhaseDetailModel {
  final int phaseNumber;
  final String title;
  final int weeks;
  final String description;
  final List<String> objectives;
  final List<String> skills;
  final List<RoadmapTaskDetailModel> tasks;
  final RoadmapPracticalChallengeModel? practicalChallenge;
  final RoadmapProjectModel? project;
  final List<RoadmapQuizQuestionModel> quizQuestions;
  final String completionCriteria;

  RoadmapPhaseDetailModel({
    required this.phaseNumber,
    required this.title,
    required this.weeks,
    required this.description,
    this.objectives = const [],
    this.skills = const [],
    this.tasks = const [],
    this.practicalChallenge,
    this.project,
    this.quizQuestions = const [],
    this.completionCriteria = '',
  });

  factory RoadmapPhaseDetailModel.fromJson(Map<String, dynamic> json) {
    final rawObjs = json['objectives'] as List<dynamic>? ?? [];
    final rawSkills = json['skills'] as List<dynamic>? ?? [];
    final rawTasks = json['tasks'] as List<dynamic>? ?? [];
    final rawChallenge = json['practical_challenge'] as Map<String, dynamic>? ?? json['practicalChallenge'] as Map<String, dynamic>?;
    final rawProject = json['project'] as Map<String, dynamic>?;
    final rawQuiz = json['quiz'] as Map<String, dynamic>?;
    final rawQuestions = rawQuiz?['questions'] as List<dynamic>? ?? [];

    return RoadmapPhaseDetailModel(
      phaseNumber: json['phase_number'] ?? json['phaseNumber'] ?? 1,
      title: json['title'] ?? '',
      weeks: json['weeks'] ?? 3,
      description: json['description'] ?? '',
      objectives: rawObjs.map((o) => o.toString()).toList(),
      skills: rawSkills.map((s) => s.toString()).toList(),
      tasks: rawTasks.map((t) => RoadmapTaskDetailModel.fromJson(t)).toList(),
      practicalChallenge: rawChallenge != null ? RoadmapPracticalChallengeModel.fromJson(rawChallenge) : null,
      project: rawProject != null ? RoadmapProjectModel.fromJson(rawProject) : null,
      quizQuestions: rawQuestions.map((q) => RoadmapQuizQuestionModel.fromJson(q)).toList(),
      completionCriteria: json['completion_criteria'] ?? json['completionCriteria'] ?? '',
    );
  }
}

class SkillGapAnalysisModel {
  final String targetRole;
  final List<String> strongSkills;
  final List<String> needsWorkSkills;
  final List<String> missingSkills;
  final String recommendedNextStep;

  SkillGapAnalysisModel({
    required this.targetRole,
    this.strongSkills = const [],
    this.needsWorkSkills = const [],
    this.missingSkills = const [],
    required this.recommendedNextStep,
  });

  List<Map<String, dynamic>> get skillsThatNeedImprovement {
    final list = <Map<String, dynamic>>[];
    for (final s in needsWorkSkills) {
      list.add({
        'skill': s,
        'description': 'Targeted practice recommended to solidify architecture & real-world mastery.',
        'status': 'Needs Work',
      });
    }
    for (final s in missingSkills) {
      list.add({
        'skill': s,
        'description': 'Foundational milestone gap. Complete phase tutorials and hands-on exercises.',
        'status': 'Missing',
      });
    }
    for (final s in strongSkills) {
      list.add({
        'skill': s,
        'description': 'Demonstrated solid proficiency in recent checkpoints and exercises.',
        'status': 'Strong',
      });
    }
    return list;
  }

  factory SkillGapAnalysisModel.fromJson(Map<String, dynamic> json) {
    final rawStrong = json['strong_skills'] as List<dynamic>? ?? json['strongSkills'] as List<dynamic>? ?? [];
    final rawNeedsWork = json['needs_work_skills'] as List<dynamic>? ?? json['needsWorkSkills'] as List<dynamic>? ?? [];
    final rawMissing = json['missing_skills'] as List<dynamic>? ?? json['missingSkills'] as List<dynamic>? ?? [];

    return SkillGapAnalysisModel(
      targetRole: json['target_role'] ?? json['targetRole'] ?? 'Software Engineer',
      strongSkills: rawStrong.map((s) => s.toString()).toList(),
      needsWorkSkills: rawNeedsWork.map((s) => s.toString()).toList(),
      missingSkills: rawMissing.map((s) => s.toString()).toList(),
      recommendedNextStep: json['recommended_next_step'] ?? json['recommendedNextStep'] ?? '',
    );
  }
}

class SkillMapNodeModel {
  final String id;
  final String name;
  final String category;
  final String status; // COMPLETED, IN_PROGRESS, NEEDS_WORK, LOCKED
  final List<String> dependsOn;
  final String? description;
  final int estimatedHours;

  SkillMapNodeModel({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    this.dependsOn = const [],
    this.description,
    this.estimatedHours = 4,
  });

  String get title => name;
  List<String> get prerequisites => dependsOn;

  factory SkillMapNodeModel.fromJson(Map<String, dynamic> json) {
    final rawDeps = json['depends_on'] as List<dynamic>? ?? json['dependsOn'] as List<dynamic>? ?? [];
    return SkillMapNodeModel(
      id: json['id'] ?? '',
      name: json['name'] ?? json['title'] ?? '',
      category: json['category'] ?? 'General',
      status: json['status'] ?? 'LOCKED',
      dependsOn: rawDeps.map((d) => d.toString()).toList(),
      description: json['description'] ?? '',
      estimatedHours: json['estimated_hours'] ?? json['estimatedHours'] ?? 4,
    );
  }
}

class DailyLearningPlanModel {
  final String todayGoal;
  final int estimatedMinutes;
  final String priority;
  final int phaseNumber;
  final String phaseTitle;
  final List<RoadmapTaskDetailModel> tasks;

  DailyLearningPlanModel({
    required this.todayGoal,
    required this.estimatedMinutes,
    required this.priority,
    required this.phaseNumber,
    required this.phaseTitle,
    this.tasks = const [],
  });

  String get microGoal => todayGoal;

  factory DailyLearningPlanModel.fromJson(Map<String, dynamic> json) {
    final rawTasks = json['tasks'] as List<dynamic>? ?? [];
    return DailyLearningPlanModel(
      todayGoal: json['today_goal'] ?? json['todayGoal'] ?? 'Review core syntax and build 1 exercise',
      estimatedMinutes: json['estimated_minutes'] ?? json['estimatedMinutes'] ?? 60,
      priority: json['priority'] ?? 'NORMAL',
      phaseNumber: json['phase_number'] ?? json['phaseNumber'] ?? 1,
      phaseTitle: json['phase_title'] ?? json['phaseTitle'] ?? 'Foundations',
      tasks: rawTasks.map((t) => RoadmapTaskDetailModel.fromJson(t)).toList(),
    );
  }
}

class WeeklyReviewModel {
  final int studyMinutes;
  final String studyHoursFormatted;
  final int tasksCompleted;
  final int quizzesCompleted;
  final int projectsCompleted;
  final int streakDays;
  final List<String> strongestSkills;
  final List<String> weakestSkills;
  final String aiRecommendation;

  WeeklyReviewModel({
    required this.studyMinutes,
    required this.studyHoursFormatted,
    required this.tasksCompleted,
    required this.quizzesCompleted,
    required this.projectsCompleted,
    required this.streakDays,
    this.strongestSkills = const [],
    this.weakestSkills = const [],
    required this.aiRecommendation,
  });

  factory WeeklyReviewModel.fromJson(Map<String, dynamic> json) {
    final rawStrong = json['strongestSkills'] as List<dynamic>? ?? json['strongest_skills'] as List<dynamic>? ?? [];
    final rawWeak = json['weakestSkills'] as List<dynamic>? ?? json['weakest_skills'] as List<dynamic>? ?? [];

    return WeeklyReviewModel(
      studyMinutes: json['studyMinutes'] ?? json['study_minutes'] ?? 0,
      studyHoursFormatted: json['studyHoursFormatted'] ?? json['study_hours_formatted'] ?? '0h 0m',
      tasksCompleted: json['tasksCompleted'] ?? json['tasks_completed'] ?? 0,
      quizzesCompleted: json['quizzesCompleted'] ?? json['quizzes_completed'] ?? 0,
      projectsCompleted: json['projectsCompleted'] ?? json['projects_completed'] ?? 0,
      streakDays: json['streakDays'] ?? json['streak_days'] ?? 1,
      strongestSkills: rawStrong.map((s) => s.toString()).toList(),
      weakestSkills: rawWeak.map((w) => w.toString()).toList(),
      aiRecommendation: json['aiRecommendation'] ?? json['ai_recommendation'] ?? '',
    );
  }
}

class JobReadinessCategoryModel {
  final int? score;
  final String status;
  final String evidence;
  final int assessedCount;

  JobReadinessCategoryModel({
    this.score,
    required this.status,
    required this.evidence,
    this.assessedCount = 0,
  });

  bool get isAssessed => score != null;

  factory JobReadinessCategoryModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return JobReadinessCategoryModel(
        status: 'Not assessed',
        evidence: 'No evaluation data recorded yet.',
      );
    }
    return JobReadinessCategoryModel(
      score: json['score'] as int?,
      status: json['status']?.toString() ?? 'Not assessed',
      evidence: json['evidence']?.toString() ?? '',
      assessedCount: json['assessed_count'] as int? ?? 0,
    );
  }
}

class JobReadinessModel {
  final int? overallPercent;
  final String overallStatus;
  final String readinessLevel;
  final JobReadinessCategoryModel technical;
  final JobReadinessCategoryModel projects;
  final JobReadinessCategoryModel problemSolving;
  final JobReadinessCategoryModel interview;
  final JobReadinessCategoryModel portfolio;
  final JobReadinessCategoryModel learningConsistency;
  final List<String> whyThisScore;
  final List<String> topPriorities;

  JobReadinessModel({
    this.overallPercent,
    required this.overallStatus,
    required this.readinessLevel,
    required this.technical,
    required this.projects,
    required this.problemSolving,
    required this.interview,
    required this.portfolio,
    required this.learningConsistency,
    this.whyThisScore = const [],
    this.topPriorities = const [],
  });

  bool get isAssessed => overallPercent != null;
  int get readinessPercentage => overallPercent ?? 0;
  int get technicalPercent => technical.score ?? 0;
  int get projectsPercent => projects.score ?? 0;
  int get problemSolvingPercent => problemSolving.score ?? 0;
  int get interviewPercent => interview.score ?? 0;
  int get portfolioPercent => portfolio.score ?? 0;
  int get consistencyPercent => learningConsistency.score ?? 0;
  int get passedQuizzes => technical.assessedCount;
  int get completedProjects => projects.assessedCount;
  String get nextPriority => topPriorities.isNotEmpty ? topPriorities.first : 'Complete today\'s study task';

  factory JobReadinessModel.fromJson(Map<String, dynamic> json) {
    final rawWhy = json['whyThisScore'] as List<dynamic>? ?? json['why_this_score'] as List<dynamic>? ?? [];
    final rawPriorities = json['topPriorities'] as List<dynamic>? ?? json['top_priorities'] as List<dynamic>? ?? [];

    final overall = json['overallPercent'] as int? ?? json['overall_percent'] as int?;
    final overallStat = json['overallStatus']?.toString() ?? json['overall_status']?.toString() ?? (overall != null ? '$overall%' : 'Not enough data yet');
    final level = json['readinessLevel']?.toString() ??
        json['readiness_level']?.toString() ??
        (overall != null
            ? (overall >= 75
                ? 'Placement Ready'
                : (overall >= 45 ? 'Intermediate Builder' : 'Early Foundations'))
            : 'Not enough data yet');

    return JobReadinessModel(
      overallPercent: overall,
      overallStatus: overallStat,
      readinessLevel: level,
      technical: JobReadinessCategoryModel.fromJson(json['technical'] as Map<String, dynamic>?),
      projects: JobReadinessCategoryModel.fromJson(json['projects'] as Map<String, dynamic>?),
      problemSolving: JobReadinessCategoryModel.fromJson(json['problemSolving'] as Map<String, dynamic>? ?? json['problem_solving'] as Map<String, dynamic>?),
      interview: JobReadinessCategoryModel.fromJson(json['interview'] as Map<String, dynamic>?),
      portfolio: JobReadinessCategoryModel.fromJson(json['portfolio'] as Map<String, dynamic>?),
      learningConsistency: JobReadinessCategoryModel.fromJson(json['learningConsistency'] as Map<String, dynamic>? ?? json['learning_consistency'] as Map<String, dynamic>?),
      whyThisScore: rawWhy.map((w) => w.toString()).toList(),
      topPriorities: rawPriorities.map((p) => p.toString()).toList(),
    );
  }
}

class InterviewQuestionModel {
  final String id;
  final String type;
  final String question;
  final String? context;
  final List<String> tips;
  final String difficulty;
  final String category;
  final String sampleAnswer;
  final List<String> keyPoints;

  InterviewQuestionModel({
    required this.id,
    required this.type,
    required this.question,
    this.context,
    this.tips = const [],
    this.difficulty = 'Intermediate',
    this.category = 'Technical',
    this.sampleAnswer = '',
    this.keyPoints = const [],
  });

  String get idealAnswer => sampleAnswer;

  factory InterviewQuestionModel.fromJson(Map<String, dynamic> json) {
    final rawTips = json['tips'] as List<dynamic>? ?? [];
    final rawKeyPoints = json['key_points'] as List<dynamic>? ?? json['keyPoints'] as List<dynamic>? ?? [];
    return InterviewQuestionModel(
      id: json['id'] ?? '',
      type: json['type'] ?? 'TECHNICAL',
      question: json['question'] ?? '',
      context: json['context'],
      tips: rawTips.map((t) => t.toString()).toList(),
      difficulty: json['difficulty'] ?? 'Intermediate',
      category: json['category'] ?? json['type'] ?? 'Technical',
      sampleAnswer: json['sample_answer'] ?? json['sampleAnswer'] ?? json['context'] ?? '',
      keyPoints: rawKeyPoints.isNotEmpty
          ? rawKeyPoints.map((t) => t.toString()).toList()
          : rawTips.map((t) => t.toString()).toList(),
    );
  }
}

class DuplicateCheckResultModel {
  final bool exists;
  final String message;
  final Map<String, dynamic>? existingRoadmap;

  DuplicateCheckResultModel({
    required this.exists,
    required this.message,
    this.existingRoadmap,
  });

  bool get hasExisting => exists;

  factory DuplicateCheckResultModel.fromJson(Map<String, dynamic> json) {
    return DuplicateCheckResultModel(
      exists: json['exists'] ?? false,
      message: json['message'] ?? '',
      existingRoadmap: json['existingRoadmap'] as Map<String, dynamic>?,
    );
  }
}

class AskAiResponseModel {
  final String answer;
  final List<String> suggestedActions;
  final String? intent;

  AskAiResponseModel({
    required this.answer,
    this.suggestedActions = const [],
    this.intent,
  });

  List<String> get recommendedActions => suggestedActions;

  factory AskAiResponseModel.fromJson(Map<String, dynamic> json) {
    final rawActions = json['suggestedActions'] as List<dynamic>? ?? json['suggested_actions'] as List<dynamic>? ?? [];
    return AskAiResponseModel(
      answer: json['answer'] ?? '',
      suggestedActions: rawActions.map((a) => a.toString()).toList(),
      intent: json['intent'] as String?,
    );
  }
}

class RoadmapChangeModel {
  final String id;
  final String roadmapId;
  final int fromVersion;
  final int toVersion;
  final String reason;
  final String changesSummary;
  final List<String> weakTopicsDetected;
  final List<String> nodesAdded;
  final List<String> nodesModified;
  final DateTime createdAt;

  RoadmapChangeModel({
    required this.id,
    required this.roadmapId,
    required this.fromVersion,
    required this.toVersion,
    required this.reason,
    required this.changesSummary,
    this.weakTopicsDetected = const [],
    this.nodesAdded = const [],
    this.nodesModified = const [],
    required this.createdAt,
  });

  factory RoadmapChangeModel.fromJson(Map<String, dynamic> json) {
    final rawWeak = json['weak_topics_detected'] as List<dynamic>? ?? json['weakTopicsDetected'] as List<dynamic>? ?? [];
    final rawAdded = json['nodes_added'] as List<dynamic>? ?? json['nodesAdded'] as List<dynamic>? ?? [];
    final rawModified = json['nodes_modified'] as List<dynamic>? ?? json['nodesModified'] as List<dynamic>? ?? [];

    return RoadmapChangeModel(
      id: json['id'] ?? '',
      roadmapId: json['roadmap_id'] ?? json['roadmapId'] ?? '',
      fromVersion: json['from_version'] ?? json['fromVersion'] ?? 1,
      toVersion: json['to_version'] ?? json['toVersion'] ?? 2,
      reason: json['reason'] ?? '',
      changesSummary: json['changes_summary'] ?? json['changesSummary'] ?? '',
      weakTopicsDetected: rawWeak.map((e) => e.toString()).toList(),
      nodesAdded: rawAdded.map((e) => e.toString()).toList(),
      nodesModified: rawModified.map((e) => e.toString()).toList(),
      createdAt: json['created_at'] != null ? (DateTime.tryParse(json['created_at']) ?? DateTime.now()) : DateTime.now(),
    );
  }
}

class InterviewTurnModel {
  final String? id;
  final int turnNumber;
  final String question;
  final List<String> expectedConcepts;
  final String? studentAnswer;
  final int? score;
  final List<String> detectedConcepts;
  final List<String> missingConcepts;
  final String? feedback;
  final String? followUpQuestion;
  final int? durationSeconds;

  InterviewTurnModel({
    this.id,
    required this.turnNumber,
    required this.question,
    this.expectedConcepts = const [],
    this.studentAnswer,
    this.score,
    this.detectedConcepts = const [],
    this.missingConcepts = const [],
    this.feedback,
    this.followUpQuestion,
    this.durationSeconds,
  });

  factory InterviewTurnModel.fromJson(Map<String, dynamic> json) {
    final rawExpected = json['expected_concepts'] as List<dynamic>? ?? json['expectedConcepts'] as List<dynamic>? ?? [];
    final rawDetected = json['detected_concepts'] as List<dynamic>? ?? json['detectedConcepts'] as List<dynamic>? ?? [];
    final rawMissing = json['missing_concepts'] as List<dynamic>? ?? json['missingConcepts'] as List<dynamic>? ?? [];

    return InterviewTurnModel(
      id: json['id'],
      turnNumber: json['turn_number'] ?? json['turnNumber'] ?? 1,
      question: json['question'] ?? '',
      expectedConcepts: rawExpected.map((e) => e.toString()).toList(),
      studentAnswer: json['student_answer'] ?? json['studentAnswer'],
      score: json['score'] as int?,
      detectedConcepts: rawDetected.map((e) => e.toString()).toList(),
      missingConcepts: rawMissing.map((e) => e.toString()).toList(),
      feedback: json['feedback'],
      followUpQuestion: json['follow_up_question'] ?? json['followUpQuestion'],
      durationSeconds: json['duration_seconds'] ?? json['durationSeconds'],
    );
  }
}

class InterviewSessionModel {
  final String id;
  final String status;
  final String targetRole;
  final String mode; // TEXT, VOICE, VIDEO
  final int currentTurn;
  final int totalTurns;
  final int? overallScore;
  final int? technicalScore;
  final int? communicationScore;
  final int? clarityScore;
  final List<String> strengths;
  final List<String> improvements;
  final String? summaryFeedback;
  final List<String> roadmapReinforcements;
  final List<InterviewTurnModel> turns;
  final InterviewTurnModel? nextTurn;
  final DateTime? createdAt;
  final String? finalReport;

  InterviewSessionModel({
    required this.id,
    required this.status,
    required this.targetRole,
    required this.mode,
    required this.currentTurn,
    this.totalTurns = 5,
    this.overallScore,
    this.technicalScore,
    this.communicationScore,
    this.clarityScore,
    this.strengths = const [],
    this.improvements = const [],
    this.summaryFeedback,
    this.roadmapReinforcements = const [],
    this.turns = const [],
    this.nextTurn,
    this.createdAt,
    this.finalReport,
  });

  bool get isCompleted => status == 'COMPLETED';

  factory InterviewSessionModel.fromJson(Map<String, dynamic> json) {
    final rawStrengths = json['strengths'] as List<dynamic>? ?? [];
    final rawImprovements = json['improvements'] as List<dynamic>? ?? [];
    final rawReinforcements = json['roadmap_reinforcements'] as List<dynamic>? ?? json['roadmapReinforcements'] as List<dynamic>? ?? [];
    final rawTurns = json['turns'] as List<dynamic>? ?? [];
    final rawNext = json['next_turn'] as Map<String, dynamic>? ?? json['nextTurn'] as Map<String, dynamic>?;

    return InterviewSessionModel(
      id: json['id'] ?? json['session_id'] ?? '',
      status: json['status'] ?? 'ACTIVE',
      targetRole: json['target_role'] ?? json['targetRole'] ?? 'Software Engineer',
      mode: json['mode'] ?? 'TEXT',
      currentTurn: json['current_turn'] ?? json['currentTurn'] ?? 1,
      totalTurns: json['total_turns'] ?? json['totalTurns'] ?? 5,
      overallScore: json['overall_score'] ?? json['overallScore'],
      technicalScore: json['technical_score'] ?? json['technicalScore'],
      communicationScore: json['communication_score'] ?? json['communicationScore'],
      clarityScore: json['clarity_score'] ?? json['clarityScore'],
      strengths: rawStrengths.map((e) => e.toString()).toList(),
      improvements: rawImprovements.map((e) => e.toString()).toList(),
      summaryFeedback: json['summary_feedback'] ?? json['summaryFeedback'],
      roadmapReinforcements: rawReinforcements.map((e) => e.toString()).toList(),
      turns: rawTurns.map((t) => InterviewTurnModel.fromJson(t)).toList(),
      nextTurn: rawNext != null ? InterviewTurnModel.fromJson(rawNext) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      finalReport: json['final_report'] ?? json['finalReport'] ?? json['summary_feedback'] ?? json['summaryFeedback'],
    );
  }
}

class CareerDirectionMatchModel {
  final String role;
  final int matchScore;
  final String rationale;
  final List<String> evidence;
  final List<String> gaps;
  final List<String> nextSteps;

  CareerDirectionMatchModel({
    required this.role,
    required this.matchScore,
    required this.rationale,
    this.evidence = const [],
    this.gaps = const [],
    this.nextSteps = const [],
  });

  factory CareerDirectionMatchModel.fromJson(Map<String, dynamic> json) {
    final rawEvidence = json['evidence'] as List<dynamic>? ?? [];
    final rawGaps = json['gaps'] as List<dynamic>? ?? [];
    final rawNext = json['nextSteps'] as List<dynamic>? ?? json['next_steps'] as List<dynamic>? ?? [];

    return CareerDirectionMatchModel(
      role: json['role'] ?? '',
      matchScore: (json['matchScore'] ?? json['match_score'] ?? 80) is int
          ? (json['matchScore'] ?? json['match_score'] ?? 80)
          : ((json['matchScore'] ?? json['match_score'] ?? 80) as num).toInt(),
      rationale: json['rationale'] ?? '',
      evidence: rawEvidence.map((e) => e.toString()).toList(),
      gaps: rawGaps.map((g) => g.toString()).toList(),
      nextSteps: rawNext.map((n) => n.toString()).toList(),
    );
  }
}

class PathfinderChatResponse {
  final String message;
  final String conversationId;
  final String? state;
  final String? detectedIntent;
  final List<String> suggestedChips;
  final Map<String, dynamic>? profileSummary;
  final List<CareerDirectionMatchModel> careerMatches;
  final bool isComplete;
  final Map<String, dynamic>? generatedRoadmap;

  PathfinderChatResponse({
    required this.message,
    required this.conversationId,
    this.state,
    this.detectedIntent,
    this.suggestedChips = const [],
    this.profileSummary,
    this.careerMatches = const [],
    this.isComplete = false,
    this.generatedRoadmap,
  });

  factory PathfinderChatResponse.fromJson(Map<String, dynamic> json) {
    final rawChips = json['suggestedChips'] as List<dynamic>? ??
        json['suggested_chips'] as List<dynamic>? ??
        json['suggested_pills'] as List<dynamic>? ??
        [];
    final rawMatches = json['careerMatches'] as List<dynamic>? ??
        json['career_matches'] as List<dynamic>? ??
        [];

    return PathfinderChatResponse(
      message: json['message'] ?? '',
      conversationId: json['conversationId'] ??
          json['conversation_id'] ??
          json['sessionId'] ??
          json['session_id'] ??
          '',
      state: json['state'],
      detectedIntent: json['detectedIntent'] ?? json['detected_intent'],
      suggestedChips: rawChips.map((c) => c.toString()).toList(),
      profileSummary: json['profileSummary'] as Map<String, dynamic>? ??
          json['profile_summary'] as Map<String, dynamic>? ??
          json['extracted_profile'] as Map<String, dynamic>?,
      careerMatches: rawMatches
          .map((m) => CareerDirectionMatchModel.fromJson(m as Map<String, dynamic>))
          .toList(),
      isComplete: json['isComplete'] ??
          json['is_complete'] ??
          json['isConfirmed'] ??
          json['is_confirmed'] ??
          false,
      generatedRoadmap: json['generatedRoadmap'] as Map<String, dynamic>? ??
          json['generated_roadmap'] as Map<String, dynamic>?,
    );
  }
}


class VerifiedResourceModel {
  final String title;
  final String url;
  final String canonicalUrl;
  final String platform; // DOCS, YOUTUBE, GITHUB, ARTICLE
  final String language;
  final String difficulty;
  final String? channelName;
  final String? description;

  VerifiedResourceModel({
    required this.title,
    required this.url,
    required this.canonicalUrl,
    required this.platform,
    required this.language,
    required this.difficulty,
    this.channelName,
    this.description,
  });

  factory VerifiedResourceModel.fromJson(Map<String, dynamic> json) {
    return VerifiedResourceModel(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      canonicalUrl: json['canonicalUrl'] ?? json['canonical_url'] ?? json['url'] ?? '',
      platform: json['platform'] ?? 'DOCS',
      language: json['language'] ?? 'English',
      difficulty: json['difficulty'] ?? 'All Levels',
      channelName: json['channelName'] ?? json['channel_name'],
      description: json['description'],
    );
  }
}

class LearningSessionModel {
  final String id;
  final String roadmapId;
  final String taskId;
  final String taskTitle;
  final int phaseNumber;
  final String status;
  final int durationMinutes;
  final int? selfRating;
  final DateTime startedAt;
  final DateTime? finishedAt;

  LearningSessionModel({
    required this.id,
    required this.roadmapId,
    required this.taskId,
    required this.taskTitle,
    required this.phaseNumber,
    required this.status,
    required this.durationMinutes,
    this.selfRating,
    required this.startedAt,
    this.finishedAt,
  });

  factory LearningSessionModel.fromJson(Map<String, dynamic> json) {
    return LearningSessionModel(
      id: json['id'] ?? '',
      roadmapId: json['roadmap_id'] ?? json['roadmapId'] ?? '',
      taskId: json['task_id'] ?? json['taskId'] ?? '',
      taskTitle: json['task_title'] ?? json['taskTitle'] ?? '',
      phaseNumber: json['phase_number'] ?? json['phaseNumber'] ?? 1,
      status: json['status'] ?? 'IN_PROGRESS',
      durationMinutes: json['duration_minutes'] ?? json['durationMinutes'] ?? 0,
      selfRating: json['self_rating'] as int? ?? json['selfRating'] as int?,
      startedAt: json['started_at'] != null ? (DateTime.tryParse(json['started_at']) ?? DateTime.now()) : DateTime.now(),
      finishedAt: json['finished_at'] != null ? DateTime.tryParse(json['finished_at']) : null,
    );
  }
}

class AdaptiveQuizQuestionModel {
  final String id;
  final String type; // MCQ, SCENARIO, DEBUGGING, CODE_UNDERSTANDING, EDGE_CASE, PERFORMANCE, SECURITY, ARCHITECTURE_TRADEOFF
  final String question;
  final String? codeSnippet;
  final String? scenario;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String difficulty;
  final String testedConcept;

  AdaptiveQuizQuestionModel({
    required this.id,
    required this.type,
    required this.question,
    this.codeSnippet,
    this.scenario,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.difficulty,
    required this.testedConcept,
  });

  String get concept => testedConcept;

  factory AdaptiveQuizQuestionModel.fromJson(Map<String, dynamic> json) {
    final rawOpts = json['options'] as List<dynamic>? ?? [];
    return AdaptiveQuizQuestionModel(
      id: json['id'] ?? '',
      type: json['type'] ?? 'MCQ',
      question: json['question'] ?? '',
      codeSnippet: json['code_snippet'] ?? json['codeSnippet'],
      scenario: json['scenario'],
      options: rawOpts.map((o) => o.toString()).toList(),
      correctIndex: json['correct_index'] ?? json['correctIndex'] ?? 0,
      explanation: json['explanation'] ?? '',
      difficulty: json['difficulty'] ?? 'Beginner',
      testedConcept: json['tested_concept'] ?? json['testedConcept'] ?? 'Fundamentals',
    );
  }
}

class AdaptiveQuizModel {
  final String quizId;
  final String topic;
  final int phaseNumber;
  final String role;
  final String difficulty;
  final List<AdaptiveQuizQuestionModel> questions;
  final int totalQuestions;

  AdaptiveQuizModel({
    required this.quizId,
    required this.topic,
    required this.phaseNumber,
    required this.role,
    required this.difficulty,
    required this.questions,
    required this.totalQuestions,
  });

  factory AdaptiveQuizModel.fromJson(Map<String, dynamic> json) {
    final rawQ = json['questions'] as List<dynamic>? ?? [];
    return AdaptiveQuizModel(
      quizId: json['quiz_id'] ?? json['quizId'] ?? '',
      topic: json['topic'] ?? 'Adaptive Assessment',
      phaseNumber: json['phase_number'] ?? json['phaseNumber'] ?? 1,
      role: json['role'] ?? 'Modern Full-Stack & Cloud Engineer',
      difficulty: json['difficulty'] ?? 'Beginner',
      questions: rawQ.map((q) => AdaptiveQuizQuestionModel.fromJson(q)).toList(),
      totalQuestions: json['total_questions'] ?? json['totalQuestions'] ?? rawQ.length,
    );
  }
}

class ProjectEvaluationModel {
  final int overallScore;
  final int architectureScore;
  final int codeQualityScore;
  final int deploymentScore;
  final String feedback;
  final List<String> strengths;
  final List<String> suggestions;

  ProjectEvaluationModel({
    required this.overallScore,
    required this.architectureScore,
    required this.codeQualityScore,
    required this.deploymentScore,
    required this.feedback,
    required this.strengths,
    required this.suggestions,
  });

  factory ProjectEvaluationModel.fromJson(Map<String, dynamic> json) {
    final rawStrengths = json['strengths'] as List<dynamic>? ?? [];
    final rawSuggestions = json['suggestions'] as List<dynamic>? ?? [];
    return ProjectEvaluationModel(
      overallScore: json['overallScore'] ?? json['overall_score'] ?? 80,
      architectureScore: json['architectureScore'] ?? json['architecture_score'] ?? 80,
      codeQualityScore: json['codeQualityScore'] ?? json['code_quality_score'] ?? 80,
      deploymentScore: json['deploymentScore'] ?? json['deployment_score'] ?? 75,
      feedback: json['feedback'] ?? 'Submission verified.',
      strengths: rawStrengths.map((s) => s.toString()).toList(),
      suggestions: rawSuggestions.map((s) => s.toString()).toList(),
    );
  }
}

class DocumentChapterModel {
  final String id;
  final int chapterNumber;
  final String title;
  final String summary;
  final int estimatedMinutes;
  final String content;

  DocumentChapterModel({
    required this.id,
    required this.chapterNumber,
    required this.title,
    required this.summary,
    required this.estimatedMinutes,
    required this.content,
  });

  factory DocumentChapterModel.fromJson(Map<String, dynamic> json) {
    return DocumentChapterModel(
      id: json['id'] ?? '',
      chapterNumber: json['chapter_number'] ?? json['chapterNumber'] ?? 1,
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      estimatedMinutes: json['estimated_minutes'] ?? json['estimatedMinutes'] ?? 10,
      content: json['content'] ?? json['contentMarkdown'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chapter_number': chapterNumber,
        'title': title,
        'summary': summary,
        'estimated_minutes': estimatedMinutes,
        'content': content,
      };
}

class VerifiedDocumentModel {
  final String id;
  final String title;
  final String tagline;
  final String category;
  final String author;
  final String canonicalUrl;
  final String source;
  final int estimatedMinutes;
  final String coverIcon;
  final String accentColor;
  final int totalChapters;
  final List<DocumentChapterModel> chapters;

  VerifiedDocumentModel({
    required this.id,
    required this.title,
    required this.tagline,
    required this.category,
    required this.author,
    required this.canonicalUrl,
    required this.source,
    required this.estimatedMinutes,
    required this.coverIcon,
    required this.accentColor,
    required this.totalChapters,
    this.chapters = const [],
  });

  factory VerifiedDocumentModel.fromJson(Map<String, dynamic> json) {
    final rawChapters = json['chapters'] as List<dynamic>? ?? [];
    return VerifiedDocumentModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      tagline: json['tagline'] ?? '',
      category: json['category'] ?? 'General',
      author: json['author'] ?? 'Verified Source',
      canonicalUrl: json['canonical_url'] ?? json['canonicalUrl'] ?? '',
      source: json['source'] ?? 'Official Documentation',
      estimatedMinutes: json['estimated_minutes'] ?? json['estimatedMinutes'] ?? 30,
      coverIcon: json['cover_icon'] ?? json['coverIcon'] ?? 'book',
      accentColor: json['accent_color'] ?? json['accentColor'] ?? '#00599C',
      totalChapters: json['total_chapters'] ?? json['totalChapters'] ?? rawChapters.length,
      chapters: rawChapters.map((c) => DocumentChapterModel.fromJson(c as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'tagline': tagline,
        'category': category,
        'author': author,
        'canonical_url': canonicalUrl,
        'source': source,
        'estimated_minutes': estimatedMinutes,
        'cover_icon': coverIcon,
        'accent_color': accentColor,
        'total_chapters': totalChapters,
        'chapters': chapters.map((c) => c.toJson()).toList(),
      };

  String get domain => category;
  String get description => tagline;
  List<String> get tags => [category, source, '${estimatedMinutes}m read'];
}

class ProjectEvidenceModel {
  final String id;
  final String title;
  final String description;
  final String? githubUrl;
  final String? demoUrl;
  final List<String> techStack;
  final bool verified;
  final int evidenceScore;
  final String? aiReview;
  final DateTime createdAt;

  ProjectEvidenceModel({
    required this.id,
    required this.title,
    required this.description,
    this.githubUrl,
    this.demoUrl,
    this.techStack = const [],
    this.verified = false,
    this.evidenceScore = 70,
    this.aiReview,
    required this.createdAt,
  });

  factory ProjectEvidenceModel.fromJson(Map<String, dynamic> json) {
    final rawTech = json['tech_stack'] as List<dynamic>? ??
        json['techStack'] as List<dynamic>? ??
        [];
    return ProjectEvidenceModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      githubUrl: json['github_url'] ?? json['githubUrl'] ?? json['repo_url'],
      demoUrl: json['demo_url'] ?? json['demoUrl'] ?? json['project_url'],
      techStack: rawTech.map((t) => t.toString()).toList(),
      verified: json['verified'] == true,
      evidenceScore: json['evidence_score'] ?? json['evidenceScore'] ?? 70,
      aiReview: json['ai_review'] ?? json['aiReview'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class SkillGraphNode {
  final String id;
  final String title;
  final String description;
  final int estimatedHours;
  final int orderIndex;
  final bool isCompleted;

  SkillGraphNode({
    required this.id,
    required this.title,
    required this.description,
    required this.estimatedHours,
    required this.orderIndex,
    this.isCompleted = false,
  });

  factory SkillGraphNode.fromJson(Map<String, dynamic> json) {
    return SkillGraphNode(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      estimatedHours: json['estimatedHours'] ?? json['estimated_hours'] ?? 4,
      orderIndex: json['orderIndex'] ?? json['order_index'] ?? 1,
      isCompleted: json['isCompleted'] == true,
    );
  }
}

class SkillGraphEdge {
  final String id;
  final String sourceSkill;
  final String targetSkill;
  final String dependencyType;
  final double confidence;

  SkillGraphEdge({
    required this.id,
    required this.sourceSkill,
    required this.targetSkill,
    required this.dependencyType,
    required this.confidence,
  });

  factory SkillGraphEdge.fromJson(Map<String, dynamic> json) {
    return SkillGraphEdge(
      id: json['id'] ?? '',
      sourceSkill: json['sourceSkill'] ?? json['source_skill'] ?? '',
      targetSkill: json['targetSkill'] ?? json['target_skill'] ?? '',
      dependencyType: json['dependencyType'] ?? json['dependency_type'] ?? 'PREREQUISITE',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class SkillGraphModel {
  final List<SkillGraphNode> nodes;
  final List<SkillGraphEdge> edges;
  final String roadmapTitle;
  final String category;

  SkillGraphModel({
    required this.nodes,
    required this.edges,
    required this.roadmapTitle,
    required this.category,
  });

  factory SkillGraphModel.fromJson(Map<String, dynamic> json) {
    final rawNodes = json['nodes'] as List<dynamic>? ?? [];
    final rawEdges = json['edges'] as List<dynamic>? ?? [];
    return SkillGraphModel(
      nodes: rawNodes.map((n) => SkillGraphNode.fromJson(n as Map<String, dynamic>)).toList(),
      edges: rawEdges.map((e) => SkillGraphEdge.fromJson(e as Map<String, dynamic>)).toList(),
      roadmapTitle: json['roadmapTitle'] ?? json['roadmap_title'] ?? '',
      category: json['category'] ?? 'Engineering',
    );
  }
}

class DynamicPathfinderSessionModel {
  final String id;
  final String stage;
  final int step;
  final int totalSteps;
  final String question;
  final List<String> options;
  final String difficulty;
  final List<String> skillsTargeted;
  final String reason;
  final bool isCompleted;
  final Map<String, dynamic>? careerAnalysis;

  DynamicPathfinderSessionModel({
    required this.id,
    required this.stage,
    required this.step,
    required this.totalSteps,
    required this.question,
    required this.options,
    required this.difficulty,
    this.skillsTargeted = const [],
    required this.reason,
    this.isCompleted = false,
    this.careerAnalysis,
  });

  factory DynamicPathfinderSessionModel.fromJson(Map<String, dynamic> json) {
    final currentQ = json['current_question'] as Map<String, dynamic>? ??
        json['currentQuestion'] as Map<String, dynamic>? ??
        {};
    final rawOptions = currentQ['options'] as List<dynamic>? ?? [];
    final rawSkills = currentQ['skillsTargeted'] as List<dynamic>? ??
        currentQ['skills_targeted'] as List<dynamic>? ??
        [];

    return DynamicPathfinderSessionModel(
      id: json['id'] ?? '',
      stage: json['stage'] ?? 'CAREER_DISCOVERY',
      step: currentQ['step'] ?? 1,
      totalSteps: currentQ['totalSteps'] ?? currentQ['total_steps'] ?? 8,
      question: currentQ['question'] ?? 'What is your primary engineering interest?',
      options: rawOptions.map((o) => o.toString()).toList(),
      difficulty: currentQ['difficulty'] ?? 'Beginner',
      skillsTargeted: rawSkills.map((s) => s.toString()).toList(),
      reason: currentQ['reason'] ?? '',
      isCompleted: json['completed'] == true,
      careerAnalysis: json['career_analysis'] as Map<String, dynamic>? ??
          json['careerAnalysis'] as Map<String, dynamic>?,
    );
  }
}

@immutable
class ResourceQuery {
  final String topic;
  final String language;
  final String? domain;
  final int limit;

  const ResourceQuery({
    required this.topic,
    this.language = 'English',
    this.domain,
    this.limit = 6,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResourceQuery &&
          runtimeType == other.runtimeType &&
          topic == other.topic &&
          language == other.language &&
          domain == other.domain &&
          limit == other.limit;

  @override
  int get hashCode =>
      topic.hashCode ^ language.hashCode ^ (domain?.hashCode ?? 0) ^ limit.hashCode;
}

@immutable
class NodeContextQuery {
  final String roadmapId;
  final String? nodeId;

  const NodeContextQuery({
    required this.roadmapId,
    this.nodeId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeContextQuery &&
          runtimeType == other.runtimeType &&
          roadmapId == other.roadmapId &&
          nodeId == other.nodeId;

  @override
  int get hashCode => roadmapId.hashCode ^ (nodeId?.hashCode ?? 0);
}

class YouTubeResourceModel {
  final String id;
  final String title;
  final String channel;
  final String duration;
  final String views;
  final String url;
  final String? thumbnailUrl;
  final String description;
  final int relevanceScore;

  YouTubeResourceModel({
    required this.id,
    required this.title,
    required this.channel,
    required this.duration,
    required this.views,
    required this.url,
    this.thumbnailUrl,
    this.description = '',
    this.relevanceScore = 90,
  });

  factory YouTubeResourceModel.fromJson(Map<String, dynamic> json) {
    return YouTubeResourceModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Technical Video',
      channel: json['channel'] ?? 'Educational',
      duration: json['duration'] ?? '15:00',
      views: json['views'] ?? 'Verified',
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? json['thumbnail_url'],
      description: json['description'] ?? '',
      relevanceScore: json['relevanceScore'] ?? json['relevance_score'] ?? 90,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'channel': channel,
    'duration': duration,
    'views': views,
    'url': url,
    'thumbnailUrl': thumbnailUrl,
    'description': description,
    'relevanceScore': relevanceScore,
  };
}

class YouTubePlaylistModel {
  final String id;
  final String title;
  final String channel;
  final int itemCount;
  final String url;
  final String? thumbnailUrl;
  final String description;

  YouTubePlaylistModel({
    required this.id,
    required this.title,
    required this.channel,
    this.itemCount = 10,
    required this.url,
    this.thumbnailUrl,
    this.description = '',
  });

  factory YouTubePlaylistModel.fromJson(Map<String, dynamic> json) {
    return YouTubePlaylistModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Curated Course Playlist',
      channel: json['channel'] ?? 'Educational Partner',
      itemCount: json['itemCount'] ?? json['item_count'] ?? 10,
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? json['thumbnail_url'],
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'channel': channel,
    'itemCount': itemCount,
    'url': url,
    'thumbnailUrl': thumbnailUrl,
    'description': description,
  };
}

class PracticeTaskModel {
  final String title;
  final String description;
  final String expectedOutput;
  final List<String> hints;
  final String starterCode;
  final String difficulty;

  PracticeTaskModel({
    required this.title,
    required this.description,
    required this.expectedOutput,
    this.hints = const [],
    this.starterCode = '',
    this.difficulty = 'Intermediate',
  });

  factory PracticeTaskModel.fromJson(Map<String, dynamic> json) {
    final rawHints = json['hints'] as List<dynamic>? ?? [];
    return PracticeTaskModel(
      title: json['title'] ?? 'Technical Implementation',
      description: json['description'] ?? '',
      expectedOutput: json['expectedOutput'] ?? json['expected_output'] ?? '',
      hints: rawHints.map((h) => h.toString()).toList(),
      starterCode: json['starterCode'] ?? json['starter_code'] ?? '',
      difficulty: json['difficulty'] ?? 'Intermediate',
    );
  }
}

class RoadmapNodeContextModel {
  final Map<String, dynamic> roadmap;
  final String careerGoal;
  final Map<String, dynamic> phase;
  final Map<String, dynamic>? node;
  final String skill;
  final String topic;
  final String learningObjective;
  final List<String> prerequisites;
  final String studentLevel;
  final int confidenceScore;
  final int evidenceCount;
  final Map<String, dynamic> progress;
  final List<YouTubeResourceModel> videos;
  final List<YouTubePlaylistModel> playlists;
  final List<Map<String, dynamic>> documentation;
  final List<Map<String, dynamic>> github;
  final PracticeTaskModel? practiceTask;
  final Map<String, dynamic> quizAvailability;
  final Map<String, dynamic> interviewContext;

  RoadmapNodeContextModel({
    required this.roadmap,
    required this.careerGoal,
    required this.phase,
    this.node,
    required this.skill,
    required this.topic,
    required this.learningObjective,
    this.prerequisites = const [],
    this.studentLevel = 'Beginner',
    this.confidenceScore = 50,
    this.evidenceCount = 0,
    required this.progress,
    this.videos = const [],
    this.playlists = const [],
    this.documentation = const [],
    this.github = const [],
    this.practiceTask,
    required this.quizAvailability,
    required this.interviewContext,
  });

  factory RoadmapNodeContextModel.fromJson(Map<String, dynamic> json) {
    final rawPrereqs = json['prerequisites'] as List<dynamic>? ?? [];
    final res = json['resources'] as Map<String, dynamic>? ?? {};
    final rawVideos = res['videos'] as List<dynamic>? ?? [];
    final rawPlaylists = res['playlists'] as List<dynamic>? ?? [];
    final rawDocs = res['documentation'] as List<dynamic>? ?? [];
    final rawGh = res['github'] as List<dynamic>? ?? [];
    final practiceJson = json['practiceTask'] as Map<String, dynamic>? ??
        json['practice_task'] as Map<String, dynamic>?;

    return RoadmapNodeContextModel(
      roadmap: json['roadmap'] as Map<String, dynamic>? ?? {},
      careerGoal: json['careerGoal'] ?? json['career_goal'] ?? '',
      phase: json['phase'] as Map<String, dynamic>? ?? {},
      node: json['node'] as Map<String, dynamic>?,
      skill: json['skill'] ?? '',
      topic: json['topic'] ?? '',
      learningObjective: json['learningObjective'] ?? json['learning_objective'] ?? '',
      prerequisites: rawPrereqs.map((p) => p.toString()).toList(),
      studentLevel: json['studentLevel'] ?? json['student_level'] ?? 'Beginner',
      confidenceScore: json['confidenceScore'] ?? json['confidence_score'] ?? 50,
      evidenceCount: json['evidenceCount'] ?? json['evidence_count'] ?? 0,
      progress: json['progress'] as Map<String, dynamic>? ?? {},
      videos: rawVideos.map((v) => YouTubeResourceModel.fromJson(v as Map<String, dynamic>)).toList(),
      playlists: rawPlaylists.map((p) => YouTubePlaylistModel.fromJson(p as Map<String, dynamic>)).toList(),
      documentation: rawDocs.map((d) => Map<String, dynamic>.from(d as Map)).toList(),
      github: rawGh.map((g) => Map<String, dynamic>.from(g as Map)).toList(),
      practiceTask: practiceJson != null ? PracticeTaskModel.fromJson(practiceJson) : null,
      quizAvailability: json['quizAvailability'] as Map<String, dynamic>? ??
          json['quiz_availability'] as Map<String, dynamic>? ??
          {},
      interviewContext: json['interviewContext'] as Map<String, dynamic>? ??
          json['interview_context'] as Map<String, dynamic>? ??
          {},
    );
  }
}


