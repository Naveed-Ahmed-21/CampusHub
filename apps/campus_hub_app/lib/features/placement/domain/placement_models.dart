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
  });

  bool get isExpired => DateTime.now().isAfter(deadline);

  factory PlacementDriveModel.fromJson(Map<String, dynamic> json) {
    final countMap = json['_count'] as Map<String, dynamic>? ?? {};
    final rawDepts = json['allowed_departments'] as List<dynamic>? ?? [];

    return PlacementDriveModel(
      id: json['id'] ?? '',
      collegeId: json['college_id'] ?? '',
      companyId: json['company_id'],
      companyName: json['company_name'] ?? '',
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

  PlacementInterviewModel({
    required this.id,
    required this.applicationId,
    required this.roundName,
    required this.scheduledAt,
    this.locationOrLink,
    required this.status,
    this.notes,
  });

  factory PlacementInterviewModel.fromJson(Map<String, dynamic> json) {
    return PlacementInterviewModel(
      id: json['id'] ?? '',
      applicationId: json['application_id'] ?? '',
      roundName: json['round_name'] ?? '',
      scheduledAt: json['scheduled_at'] != null ? DateTime.parse(json['scheduled_at']) : DateTime.now(),
      locationOrLink: json['location_or_link'],
      status: json['status'] ?? 'SCHEDULED',
      notes: json['notes'],
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
  });

  factory PlacementApplicationModel.fromJson(Map<String, dynamic> json) {
    final rawInterviews = json['interviews'] as List<dynamic>? ?? [];

    return PlacementApplicationModel(
      id: json['id'] ?? '',
      driveId: json['drive_id'] ?? '',
      studentId: json['student_id'] ?? '',
      status: json['status'] ?? 'APPLIED',
      resumeUrl: json['resume_url'],
      offerCtc: json['offer_ctc'],
      offerStatus: json['offer_status'],
      appliedAt: json['applied_at'] != null ? DateTime.parse(json['applied_at']) : DateTime.now(),
      drive: json['drive'] != null ? PlacementDriveModel.fromJson(json['drive']) : null,
      interviews: rawInterviews.map((i) => PlacementInterviewModel.fromJson(i)).toList(),
    );
  }
}
