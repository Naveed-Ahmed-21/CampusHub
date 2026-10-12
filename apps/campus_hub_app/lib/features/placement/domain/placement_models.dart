class PlacementDriveModel {
  final String id;
  final String collegeId;
  final String? companyId;
  final String companyName;
  final String roleTitle;
  final String? packageCtc;
  final String? location;
  final String? eligibility;
  final double minCgpa;
  final List<String> allowedDepartments;
  final int maxBacklogs;
  final String? jobDescription;
  final DateTime deadline;
  final String status; // UPCOMING, ONGOING, COMPLETED, CANCELLED
  final int applicationCount;
  final int? targetYear;
  final String? targetBatch;
  final String employmentType; // FULL_TIME, INTERNSHIP, INTERN_TO_FULL_TIME
  final String workMode; // ON_SITE, HYBRID, REMOTE
  final List<String> requiredSkills;
  final DateTime? driveDate;
  final DateTime? testDate;
  final DateTime? interviewDate;
  final String? venueOrLink;
  final String? chatRoomId;
  final List<PlacementResourceModel> resources;
  final String? bannerUrl;
  final String? companyLogo;
  final String? companyCoverImage;
  final PlacementCompanyModel? company;

  PlacementDriveModel({
    required this.id,
    required this.collegeId,
    this.companyId,
    required this.companyName,
    required this.roleTitle,
    this.packageCtc,
    this.location,
    this.eligibility,
    this.minCgpa = 0.0,
    this.allowedDepartments = const [],
    this.maxBacklogs = 0,
    this.jobDescription,
    required this.deadline,
    required this.status,
    this.applicationCount = 0,
    this.targetYear,
    this.targetBatch,
    this.employmentType = 'FULL_TIME',
    this.workMode = 'ON_SITE',
    this.requiredSkills = const [],
    this.driveDate,
    this.testDate,
    this.interviewDate,
    this.venueOrLink,
    this.chatRoomId,
    this.resources = const [],
    this.bannerUrl,
    this.companyLogo,
    this.companyCoverImage,
    this.company,
  });

  bool get isExpired => DateTime.now().isAfter(deadline);

  factory PlacementDriveModel.fromJson(Map<String, dynamic> json) {
    final countMap = json['_count'] as Map<String, dynamic>? ?? {};
    final rawDepts = json['allowed_departments'] as List<dynamic>? ?? [];
    final rawSkills = json['required_skills'] as List<dynamic>? ?? [];
    final rawResources = json['resources'] as List<dynamic>? ?? [];
    final compJson = json['company'] as Map<String, dynamic>?;

    return PlacementDriveModel(
      id: json['id'] ?? '',
      collegeId: json['college_id'] ?? '',
      companyId: json['company_id'],
      companyName: json['company_name'] ?? compJson?['name'] ?? '',
      roleTitle: json['role_title'] ?? '',
      packageCtc: json['package_ctc'],
      location: json['location'],
      eligibility: json['eligibility'],
      minCgpa: (json['min_cgpa'] as num?)?.toDouble() ?? 0.0,
      allowedDepartments: rawDepts.map((d) => d.toString()).toList(),
      maxBacklogs: json['max_backlogs'] ?? 0,
      jobDescription: json['job_description'],
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : DateTime.now(),
      status: json['status'] ?? 'UPCOMING',
      applicationCount: countMap['applications'] ?? 0,
      targetYear: json['target_year'] as int?,
      targetBatch: json['target_batch'],
      employmentType: json['employment_type'] ?? 'FULL_TIME',
      workMode: json['work_mode'] ?? 'ON_SITE',
      requiredSkills: rawSkills.map((s) => s.toString()).toList(),
      driveDate: json['drive_date'] != null ? DateTime.tryParse(json['drive_date']) : null,
      testDate: json['test_date'] != null ? DateTime.tryParse(json['test_date']) : null,
      interviewDate: json['interview_date'] != null ? DateTime.tryParse(json['interview_date']) : null,
      venueOrLink: json['venue_or_link'],
      chatRoomId: json['chat_room_id'],
      resources: rawResources.map((r) => PlacementResourceModel.fromJson(r)).toList(),
      bannerUrl: json['banner_url'] ?? compJson?['cover_image_url'],
      companyLogo: json['company_logo'] ?? compJson?['logo_url'],
      companyCoverImage: json['company_cover_image'] ?? compJson?['cover_image_url'],
      company: compJson != null ? PlacementCompanyModel.fromJson(compJson) : null,
    );
  }
}

class PlacementInterviewModel {
  final String id;
  final String applicationId;
  final String roundName;
  final DateTime scheduledAt;
  final String? locationOrLink;
  final String status;
  final String? notes;
  final String? candidateName;
  final String? companyName;
  final String? roleTitle;

  PlacementInterviewModel({
    required this.id,
    required this.applicationId,
    required this.roundName,
    required this.scheduledAt,
    this.locationOrLink,
    required this.status,
    this.notes,
    this.candidateName,
    this.companyName,
    this.roleTitle,
  });

  factory PlacementInterviewModel.fromJson(Map<String, dynamic> json) {
    final app = json['application'] as Map<String, dynamic>?;
    final student = app?['student'] as Map<String, dynamic>?;
    final drive = app?['drive'] as Map<String, dynamic>?;

    String? candidateName;
    if (student != null) {
      candidateName = '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.trim();
    }

    return PlacementInterviewModel(
      id: json['id'] ?? '',
      applicationId: json['application_id'] ?? '',
      roundName: json['round_name'] ?? '',
      scheduledAt: json['scheduled_at'] != null ? DateTime.parse(json['scheduled_at']) : DateTime.now(),
      locationOrLink: json['location_or_link'],
      status: json['status'] ?? 'SCHEDULED',
      notes: json['notes'],
      candidateName: candidateName,
      companyName: drive?['company_name'],
      roleTitle: drive?['role_title'],
    );
  }
}

class PlacementApplicationModel {
  final String id;
  final String driveId;
  final String studentId;
  final String status; // APPLIED, SHORTLISTED, INTERVIEW_SCHEDULED, REJECTED, OFFERED
  final String? resumeUrl;
  final String? offerCtc;
  final String? offerStatus; // PENDING, ACCEPTED, DECLINED
  final DateTime appliedAt;
  final PlacementDriveModel? drive;
  final List<PlacementInterviewModel> interviews;
  final String? studentName;
  final String? studentRoll;
  final String? studentEmail;
  final String? studentAvatar;
  final String? departmentCode;
  final double studentCgpa;

  PlacementApplicationModel({
    required this.id,
    required this.driveId,
    required this.studentId,
    required this.status,
    this.resumeUrl,
    this.offerCtc,
    this.offerStatus,
    required this.appliedAt,
    this.drive,
    this.interviews = const [],
    this.studentName,
    this.studentRoll,
    this.studentEmail,
    this.studentAvatar,
    this.departmentCode,
    this.studentCgpa = 0.0,
  });

  factory PlacementApplicationModel.fromJson(Map<String, dynamic> json) {
    final rawInterviews = json['interviews'] as List<dynamic>? ?? [];
    final student = json['student'] as Map<String, dynamic>?;
    final dept = student?['department'] as Map<String, dynamic>?;
    final portfolio = student?['portfolio'] as Map<String, dynamic>?;

    String? name;
    if (student != null) {
      name = '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.trim();
    }

    return PlacementApplicationModel(
      id: json['id'] ?? '',
      driveId: json['drive_id'] ?? '',
      studentId: json['student_id'] ?? '',
      status: json['status'] ?? 'APPLIED',
      resumeUrl: json['resume_url'] ?? portfolio?['resume_url'],
      offerCtc: json['offer_ctc'],
      offerStatus: json['offer_status'],
      appliedAt: json['applied_at'] != null ? DateTime.parse(json['applied_at']) : DateTime.now(),
      drive: json['drive'] != null ? PlacementDriveModel.fromJson(json['drive']) : null,
      interviews: rawInterviews.map((i) => PlacementInterviewModel.fromJson(i)).toList(),
      studentName: name,
      studentRoll: student?['roll_number'],
      studentEmail: student?['email'],
      studentAvatar: student?['avatar_url'],
      departmentCode: dept?['code'] ?? dept?['name'],
      studentCgpa: (portfolio?['cgpa'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PlacementCompanyModel {
  final String id;
  final String name;
  final String? website;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? industry;
  final String? about;
  final String? linkedinUrl;
  final int drivesCount;
  final int resourcesCount;
  final List<PlacementDriveModel> drives;

  PlacementCompanyModel({
    required this.id,
    required this.name,
    this.website,
    this.logoUrl,
    this.coverImageUrl,
    this.industry,
    this.about,
    this.linkedinUrl,
    this.drivesCount = 0,
    this.resourcesCount = 0,
    this.drives = const [],
  });

  factory PlacementCompanyModel.fromJson(Map<String, dynamic> json) {
    final count = json['_count'] as Map<String, dynamic>? ?? {};
    final rawDrives = json['drives'] as List<dynamic>? ?? [];

    return PlacementCompanyModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      website: json['website'],
      logoUrl: json['logo_url'],
      coverImageUrl: json['cover_image_url'],
      industry: json['industry'],
      about: json['about'],
      linkedinUrl: json['linkedin_url'],
      drivesCount: count['drives'] ?? rawDrives.length,
      resourcesCount: count['resources'] ?? 0,
      drives: rawDrives.map((d) => PlacementDriveModel.fromJson(d)).toList(),
    );
  }
}

class CompanyLookupResult {
  final String name;
  final String? domain;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? industry;
  final String? about;
  final String? website;
  final String? linkedinUrl;

  CompanyLookupResult({
    required this.name,
    this.domain,
    this.logoUrl,
    this.coverImageUrl,
    this.industry,
    this.about,
    this.website,
    this.linkedinUrl,
  });

  factory CompanyLookupResult.fromJson(Map<String, dynamic> json) {
    return CompanyLookupResult(
      name: json['name'] ?? '',
      domain: json['domain'],
      logoUrl: json['logo_url'],
      coverImageUrl: json['cover_image_url'],
      industry: json['industry'],
      about: json['about'],
      website: json['website'],
      linkedinUrl: json['linkedin_url'],
    );
  }
}

class PlacementResourceModel {
  final String id;
  final String title;
  final String? description;
  final String category; // APTITUDE, TECHNICAL, HR, COMPANY_SPECIFIC
  final String resourceType; // PDF, VIDEO, YOUTUBE_PLAYLIST, EXTERNAL_LINK, MOCK_TEST, NOTES
  final String? fileUrl;
  final String? externalUrl;
  final String? thumbnailUrl;
  final List<String> tags;
  final int viewsCount;
  final int likesCount;
  final String? creatorName;
  final String? companyName;
  final String? driveTitle;
  final DateTime createdAt;

  PlacementResourceModel({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.resourceType,
    this.fileUrl,
    this.externalUrl,
    this.thumbnailUrl,
    this.tags = const [],
    this.viewsCount = 0,
    this.likesCount = 0,
    this.creatorName,
    this.companyName,
    this.driveTitle,
    required this.createdAt,
  });

  factory PlacementResourceModel.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'] as List<dynamic>? ?? [];
    final creator = json['creator'] as Map<String, dynamic>?;
    final company = json['company'] as Map<String, dynamic>?;
    final drive = json['drive'] as Map<String, dynamic>?;

    String? creatorName;
    if (creator != null) {
      creatorName = '${creator['first_name'] ?? ''} ${creator['last_name'] ?? ''}'.trim();
    }

    return PlacementResourceModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      category: json['category'] ?? 'TECHNICAL',
      resourceType: json['resource_type'] ?? 'NOTES',
      fileUrl: json['file_url'],
      externalUrl: json['external_url'],
      thumbnailUrl: json['thumbnail_url'],
      tags: rawTags.map((t) => t.toString()).toList(),
      viewsCount: json['views_count'] ?? 0,
      likesCount: json['likes_count'] ?? 0,
      creatorName: creatorName,
      companyName: company?['name'],
      driveTitle: drive?['role_title'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}

class PlacementStudentModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? rollNumber;
  final String? avatarUrl;
  final String? departmentCode;
  final String? departmentName;
  final double cgpa;
  final String? resumeUrl;
  final String? githubUrl;
  final String? linkedinUrl;
  final int? currentYear;
  final String placementStatus; // PLACED, OFFERED, IN_PROCESS, ELIGIBLE
  final int applicationsCount;

  PlacementStudentModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.rollNumber,
    this.avatarUrl,
    this.departmentCode,
    this.departmentName,
    this.cgpa = 0.0,
    this.resumeUrl,
    this.githubUrl,
    this.linkedinUrl,
    this.currentYear,
    required this.placementStatus,
    this.applicationsCount = 0,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory PlacementStudentModel.fromJson(Map<String, dynamic> json) {
    final dept = json['department'] as Map<String, dynamic>?;
    final portfolio = json['portfolio'] as Map<String, dynamic>?;
    final academic = json['academic_profile'] as Map<String, dynamic>?;

    return PlacementStudentModel(
      id: json['id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      rollNumber: json['roll_number'],
      avatarUrl: json['avatar_url'],
      departmentCode: dept?['code'],
      departmentName: dept?['name'],
      cgpa: (json['cgpa'] as num?)?.toDouble() ?? (portfolio?['cgpa'] as num?)?.toDouble() ?? 0.0,
      resumeUrl: portfolio?['resume_url'],
      githubUrl: portfolio?['github_url'],
      linkedinUrl: portfolio?['linkedin_url'],
      currentYear: academic?['current_year'] as int?,
      placementStatus: json['placementStatus'] ?? 'ELIGIBLE',
      applicationsCount: json['applicationsCount'] ?? 0,
    );
  }
}

class DepartmentPlacementStat {
  final String id;
  final String name;
  final String code;
  final int totalStudents;
  final int placedStudents;
  final int placementRate;

  DepartmentPlacementStat({
    required this.id,
    required this.name,
    required this.code,
    required this.totalStudents,
    required this.placedStudents,
    required this.placementRate,
  });

  factory DepartmentPlacementStat.fromJson(Map<String, dynamic> json) {
    return DepartmentPlacementStat(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      totalStudents: json['totalStudents'] ?? 0,
      placedStudents: json['placedStudents'] ?? 0,
      placementRate: json['placementRate'] ?? 0,
    );
  }
}
