class PortfolioModel {
  final String id;
  final String userId;
  final String? customUsername;
  final bool isPublic;
  final String? bio;
  final String? githubUrl;
  final String? linkedinUrl;
  final String? websiteUrl;
  final String? resumeUrl;
  final double cgpa;
  final String userName;
  final String userEmail;
  final String? avatarUrl;
  final String? departmentName;
  final List<PortfolioProjectModel> projects;
  final List<PortfolioSkillModel> skills;
  final List<PortfolioCertificateModel> certificates;
  final List<PortfolioAchievementModel> achievements;

  PortfolioModel({
    required this.id,
    required this.userId,
    this.customUsername,
    this.isPublic = true,
    this.bio,
    this.githubUrl,
    this.linkedinUrl,
    this.websiteUrl,
    this.resumeUrl,
    this.cgpa = 0.0,
    required this.userName,
    required this.userEmail,
    this.avatarUrl,
    this.departmentName,
    this.projects = const [],
    this.skills = const [],
    this.certificates = const [],
    this.achievements = const [],
  });

  factory PortfolioModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final dept = user['department'] as Map<String, dynamic>? ?? {};
    final rawProjects = json['projects'] as List<dynamic>? ?? [];
    final rawSkills = json['skills'] as List<dynamic>? ?? [];
    final rawCertificates = json['certificates'] as List<dynamic>? ?? [];
    final rawAchievements = json['achievements'] as List<dynamic>? ?? [];

    return PortfolioModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? user['id'] ?? '',
      customUsername: json['custom_username'],
      isPublic: json['is_public'] ?? true,
      bio: json['bio'],
      githubUrl: json['github_url'],
      linkedinUrl: json['linkedin_url'],
      websiteUrl: json['website_url'],
      resumeUrl: json['resume_url'],
      cgpa: (json['cgpa'] as num?)?.toDouble() ?? 0.0,
      userName: '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim(),
      userEmail: user['email'] ?? '',
      avatarUrl: user['avatar_url'],
      departmentName: dept['name'],
      projects: rawProjects.map((p) => PortfolioProjectModel.fromJson(p)).toList(),
      skills: rawSkills.map((s) => PortfolioSkillModel.fromJson(s)).toList(),
      certificates: rawCertificates.map((c) => PortfolioCertificateModel.fromJson(c)).toList(),
      achievements: rawAchievements.map((a) => PortfolioAchievementModel.fromJson(a)).toList(),
    );
  }
}

class PortfolioProjectModel {
  final String id;
  final String title;
  final String? description;
  final List<String> techStack;
  final String? projectUrl;
  final String? repoUrl;
  final String? imageUrl;

  PortfolioProjectModel({
    required this.id,
    required this.title,
    this.description,
    this.techStack = const [],
    this.projectUrl,
    this.repoUrl,
    this.imageUrl,
  });

  factory PortfolioProjectModel.fromJson(Map<String, dynamic> json) {
    final rawStack = json['tech_stack'] as List<dynamic>? ?? [];
    return PortfolioProjectModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      techStack: rawStack.map((s) => s.toString()).toList(),
      projectUrl: json['project_url'],
      repoUrl: json['repo_url'],
      imageUrl: json['image_url'],
    );
  }
}

class PortfolioSkillModel {
  final String id;
  final String skillName;
  final String category;
  final String proficiency;

  PortfolioSkillModel({
    required this.id,
    required this.skillName,
    this.category = 'General',
    this.proficiency = 'Intermediate',
  });

  factory PortfolioSkillModel.fromJson(Map<String, dynamic> json) {
    return PortfolioSkillModel(
      id: json['id'] ?? '',
      skillName: json['skill_name'] ?? '',
      category: json['category'] ?? 'General',
      proficiency: json['proficiency'] ?? 'Intermediate',
    );
  }
}

class PortfolioCertificateModel {
  final String id;
  final String title;
  final String issuer;
  final DateTime? issueDate;
  final String? credentialUrl;
  final String? credentialId;

  PortfolioCertificateModel({
    required this.id,
    required this.title,
    required this.issuer,
    this.issueDate,
    this.credentialUrl,
    this.credentialId,
  });

  factory PortfolioCertificateModel.fromJson(Map<String, dynamic> json) {
    return PortfolioCertificateModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      issuer: json['issuer'] ?? '',
      issueDate: json['issue_date'] != null ? DateTime.parse(json['issue_date']) : null,
      credentialUrl: json['credential_url'],
      credentialId: json['credential_id'],
    );
  }
}

class PortfolioAchievementModel {
  final String id;
  final String title;
  final String category;
  final String? description;
  final DateTime? dateAchieved;
  final String? proofUrl;

  PortfolioAchievementModel({
    required this.id,
    required this.title,
    this.category = 'General',
    this.description,
    this.dateAchieved,
    this.proofUrl,
  });

  factory PortfolioAchievementModel.fromJson(Map<String, dynamic> json) {
    return PortfolioAchievementModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? 'General',
      description: json['description'],
      dateAchieved: json['date_achieved'] != null ? DateTime.parse(json['date_achieved']) : null,
      proofUrl: json['proof_url'],
    );
  }
}
