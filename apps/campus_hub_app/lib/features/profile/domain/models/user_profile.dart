class SkillItem {
  final String id;
  final String skillName;
  final String? proficiency;

  const SkillItem({
    required this.id,
    required this.skillName,
    this.proficiency,
  });

  factory SkillItem.fromJson(Map<String, dynamic> json) {
    return SkillItem(
      id: json['id'] as String? ?? '',
      skillName: json['skillName'] as String? ?? json['skill_name'] as String? ?? '',
      proficiency: json['proficiency'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'skillName': skillName,
        'proficiency': proficiency,
      };
}

class ProjectItem {
  final String id;
  final String title;
  final String? description;
  final String? projectUrl;
  final String? repoUrl;

  const ProjectItem({
    required this.id,
    required this.title,
    this.description,
    this.projectUrl,
    this.repoUrl,
  });

  factory ProjectItem.fromJson(Map<String, dynamic> json) {
    return ProjectItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      projectUrl: json['projectUrl'] as String? ?? json['project_url'] as String?,
      repoUrl: json['repoUrl'] as String? ?? json['repo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'projectUrl': projectUrl,
        'repoUrl': repoUrl,
      };
}

class UserProfile {
  final String id;
  final String? username;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? department;
  final String? rollNumber;
  final String? phone;
  final String? avatarUrl;
  final String? bio;
  final String? githubUrl;
  final String? linkedinUrl;
  final String? websiteUrl;
  final String? resumeUrl;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isFollowing;
  final List<SkillItem> skills;
  final List<ProjectItem> projects;

  const UserProfile({
    required this.id,
    this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.role = 'STUDENT',
    this.department,
    this.rollNumber,
    this.phone,
    this.avatarUrl,
    this.bio,
    this.githubUrl,
    this.linkedinUrl,
    this.websiteUrl,
    this.resumeUrl,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.isFollowing = false,
    this.skills = const [],
    this.projects = const [],
  });

  String get fullName => '$firstName $lastName'.trim();
  String get displayUsername => username != null && username!.isNotEmpty
      ? (username!.startsWith('@') ? username! : '@$username')
      : (email.isNotEmpty ? '@${email.split('@').first}' : '@user');

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawSkills = json['skills'] as List<dynamic>? ?? [];
    final rawProjects = json['projects'] as List<dynamic>? ?? [];
    final deptData = json['department'];
    final deptName = deptData is Map ? deptData['name'] as String? : (deptData is String ? deptData : null);

    final emailStr = json['email'] as String? ?? '';
    final rawUsername = json['username'] as String?;
    final resolvedUsername = rawUsername ?? (emailStr.isNotEmpty ? '@${emailStr.split('@').first}' : null);

    return UserProfile(
      id: json['id'] as String? ?? '',
      username: resolvedUsername,
      firstName: json['firstName'] as String? ?? json['first_name'] as String? ?? '',
      lastName: json['lastName'] as String? ?? json['last_name'] as String? ?? '',
      email: emailStr,
      role: json['role'] as String? ?? 'STUDENT',
      department: deptName,
      rollNumber: json['rollNumber'] as String? ?? json['roll_number'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      githubUrl: json['githubUrl'] as String? ?? json['github_url'] as String?,
      linkedinUrl: json['linkedinUrl'] as String? ?? json['linkedin_url'] as String?,
      websiteUrl: json['websiteUrl'] as String? ?? json['website_url'] as String?,
      resumeUrl: json['resumeUrl'] as String? ?? json['resume_url'] as String?,
      followersCount: json['followersCount'] as int? ?? json['followers_count'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? json['following_count'] as int? ?? 0,
      postsCount: json['postsCount'] as int? ?? json['posts_count'] as int? ?? 0,
      isFollowing: json['isFollowing'] as bool? ?? json['is_following'] as bool? ?? false,
      skills: rawSkills.map((s) => SkillItem.fromJson(s as Map<String, dynamic>)).toList(),
      projects: rawProjects.map((p) => ProjectItem.fromJson(p as Map<String, dynamic>)).toList(),
    );
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? firstName,
    String? lastName,
    String? email,
    String? role,
    String? department,
    String? rollNumber,
    String? phone,
    String? avatarUrl,
    String? bio,
    String? githubUrl,
    String? linkedinUrl,
    String? websiteUrl,
    String? resumeUrl,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    bool? isFollowing,
    List<SkillItem>? skills,
    List<ProjectItem>? projects,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      rollNumber: rollNumber ?? this.rollNumber,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      githubUrl: githubUrl ?? this.githubUrl,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      isFollowing: isFollowing ?? this.isFollowing,
      skills: skills ?? this.skills,
      projects: projects ?? this.projects,
    );
  }
}
