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
  });

  factory CareerRoadmapModel.fromJson(Map<String, dynamic> json) {
    final rawNodes = json['nodes'] as List<dynamic>? ?? [];
    final rawResources = json['resources'] as List<dynamic>? ?? [];

    return CareerRoadmapModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      category: json['category'] ?? 'General',
      description: json['description'] ?? '',
      level: json['level'] ?? 'Beginner',
      estimatedMonths: json['estimated_months'] ?? 3,
      iconName: json['icon_name'],
      nodes: rawNodes.map((n) => RoadmapNodeModel.fromJson(n)).toList(),
      resources: rawResources.map((r) => LearningResourceModel.fromJson(r)).toList(),
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
  final DateTime targetDate;
  final bool isCompleted;
  final DateTime? completedAt;

  WeeklyGoalModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetDate,
    this.isCompleted = false,
    this.completedAt,
  });

  factory WeeklyGoalModel.fromJson(Map<String, dynamic> json) {
    return WeeklyGoalModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      targetDate: json['target_date'] != null ? DateTime.parse(json['target_date']) : DateTime.now(),
      isCompleted: json['is_completed'] ?? false,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
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
  final List<Map<String, dynamic>> contentItems;

  PlacementPrepModel({
    required this.id,
    required this.title,
    required this.category,
    this.description,
    this.contentItems = const [],
  });

  factory PlacementPrepModel.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content_json'] as List<dynamic>? ?? [];
    return PlacementPrepModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? 'DSA',
      description: json['description'],
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
