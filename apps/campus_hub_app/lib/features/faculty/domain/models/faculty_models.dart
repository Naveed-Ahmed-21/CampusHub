class FacultyDashboard {
  final FacultyInfo faculty;
  final FacultyStats stats;
  final List<ClassScheduleSlot> todaySchedule;
  final List<SubjectAnnouncement> recentAnnouncements;
  final List<FacultyEventSummary> upcomingEvents;

  const FacultyDashboard({
    required this.faculty,
    required this.stats,
    required this.todaySchedule,
    required this.recentAnnouncements,
    required this.upcomingEvents,
  });

  factory FacultyDashboard.fromJson(Map<String, dynamic> json) {
    return FacultyDashboard(
      faculty: FacultyInfo.fromJson(json['faculty'] as Map<String, dynamic>? ?? {}),
      stats: FacultyStats.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
      todaySchedule: (json['todaySchedule'] as List<dynamic>? ?? [])
          .map((e) => ClassScheduleSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentAnnouncements: (json['recentAnnouncements'] as List<dynamic>? ?? [])
          .map((e) => SubjectAnnouncement.fromJson(e as Map<String, dynamic>))
          .toList(),
      upcomingEvents: (json['upcomingEvents'] as List<dynamic>? ?? [])
          .map((e) => FacultyEventSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FacultyInfo {
  final String id;
  final String name;
  final String email;
  final String designation;
  final String department;
  final String? avatarUrl;
  final String officeRoom;
  final String officeHours;
  final String specialization;

  const FacultyInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.designation,
    required this.department,
    this.avatarUrl,
    this.officeRoom = 'Room 304, Tech Block',
    this.officeHours = 'Mon - Thu: 2:00 PM - 4:00 PM',
    this.specialization = 'Distributed Systems & Cloud Computing',
  });

  factory FacultyInfo.fromJson(Map<String, dynamic> json) {
    return FacultyInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Faculty Member',
      email: json['email'] as String? ?? '',
      designation: json['designation'] as String? ?? 'Associate Professor',
      department: json['department'] as String? ?? 'Department of Computer Science',
      avatarUrl: json['avatarUrl'] as String?,
      officeRoom: json['officeRoom'] as String? ?? 'Room 304, Tech Block',
      officeHours: json['officeHours'] as String? ?? 'Mon - Thu: 2:00 PM - 4:00 PM',
      specialization: json['specialization'] as String? ?? 'Distributed Systems & Cloud Computing',
    );
  }
}

class FacultyStats {
  final int totalSubjects;
  final int totalMentees;
  final int todayClassesCount;
  final int upcomingEventsCount;
  final int publishedAnnouncementsCount;

  const FacultyStats({
    required this.totalSubjects,
    required this.totalMentees,
    required this.todayClassesCount,
    required this.upcomingEventsCount,
    required this.publishedAnnouncementsCount,
  });

  factory FacultyStats.fromJson(Map<String, dynamic> json) {
    return FacultyStats(
      totalSubjects: (json['totalSubjects'] as num?)?.toInt() ?? 0,
      totalMentees: (json['totalMentees'] as num?)?.toInt() ?? 0,
      todayClassesCount: (json['todayClassesCount'] as num?)?.toInt() ?? 0,
      upcomingEventsCount: (json['upcomingEventsCount'] as num?)?.toInt() ?? 0,
      publishedAnnouncementsCount: (json['publishedAnnouncementsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class FacultySubject {
  final String id;
  final String? facultyId;
  final String? facultyName;
  final String? facultyEmail;
  final String? facultyDesignation;
  final String? facultyOfficeRoom;
  final String? facultyOfficeHours;
  final String code;
  final String name;
  final String department;
  final String semester;
  final String section;
  final int credits;
  final String? description;
  final String academicYear;
  final int resourcesCount;
  final int announcementsCount;
  final int studentsCount;
  final List<SubjectResource> resources;
  final List<SubjectAnnouncement> announcements;

  const FacultySubject({
    required this.id,
    this.facultyId,
    this.facultyName,
    this.facultyEmail,
    this.facultyDesignation,
    this.facultyOfficeRoom,
    this.facultyOfficeHours,
    required this.code,
    required this.name,
    required this.department,
    required this.semester,
    required this.section,
    required this.credits,
    this.description,
    this.academicYear = '2024-2025',
    required this.resourcesCount,
    required this.announcementsCount,
    required this.studentsCount,
    this.resources = const [],
    this.announcements = const [],
  });

  factory FacultySubject.fromJson(Map<String, dynamic> json) {
    return FacultySubject(
      id: json['id'] as String? ?? '',
      facultyId: json['facultyId'] as String?,
      facultyName: json['facultyName'] as String?,
      facultyEmail: json['facultyEmail'] as String?,
      facultyDesignation: json['facultyDesignation'] as String?,
      facultyOfficeRoom: json['facultyOfficeRoom'] as String?,
      facultyOfficeHours: json['facultyOfficeHours'] as String?,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      department: json['department'] as String? ?? 'Computer Science',
      semester: json['semester'] as String? ?? 'Semester 5',
      section: json['section'] as String? ?? 'A',
      credits: (json['credits'] as num?)?.toInt() ?? 3,
      description: json['description'] as String?,
      academicYear: json['academicYear'] as String? ?? '2024-2025',
      resourcesCount: (json['resourcesCount'] as num?)?.toInt() ?? 0,
      announcementsCount: (json['announcementsCount'] as num?)?.toInt() ?? 0,
      studentsCount: (json['studentsCount'] as num?)?.toInt() ?? 0,
      resources: (json['resources'] as List<dynamic>? ?? [])
          .map((e) => SubjectResource.fromJson(e as Map<String, dynamic>))
          .toList(),
      announcements: (json['announcements'] as List<dynamic>? ?? [])
          .map((e) => SubjectAnnouncement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SubjectResource {
  final String id;
  final String subjectId;
  final String title;
  final String? description;
  final String fileUrl;
  final String fileType;
  final String? unit;
  final String? topic;
  final String resourceType;
  final String visibility;
  final String? thumbnailUrl;
  final String academicYear;
  final int downloadCount;
  final int viewCount;
  final String uploadedByName;
  final DateTime createdAt;

  const SubjectResource({
    required this.id,
    required this.subjectId,
    required this.title,
    this.description,
    required this.fileUrl,
    required this.fileType,
    this.unit,
    this.topic,
    this.resourceType = 'NOTES',
    this.visibility = 'PUBLIC',
    this.thumbnailUrl,
    this.academicYear = '2024-2025',
    this.downloadCount = 0,
    this.viewCount = 0,
    required this.uploadedByName,
    required this.createdAt,
  });

  factory SubjectResource.fromJson(Map<String, dynamic> json) {
    return SubjectResource(
      id: json['id'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      fileUrl: json['fileUrl'] as String? ?? '',
      fileType: json['fileType'] as String? ?? 'PDF',
      unit: json['unit'] as String?,
      topic: json['topic'] as String?,
      resourceType: json['resourceType'] as String? ?? json['resource_type'] as String? ?? 'NOTES',
      visibility: json['visibility'] as String? ?? 'PUBLIC',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? json['thumbnail_url'] as String?,
      academicYear: json['academicYear'] as String? ?? json['academic_year'] as String? ?? '2024-2025',
      downloadCount: (json['downloadCount'] as num?)?.toInt() ?? (json['download_count'] as num?)?.toInt() ?? 0,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? (json['view_count'] as num?)?.toInt() ?? 0,
      uploadedByName: json['uploadedByName'] as String? ?? 'Faculty',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class SubjectAnnouncement {
  final String id;
  final String? subjectId;
  final String? subjectName;
  final String title;
  final String content;
  final String authorName;
  final DateTime createdAt;

  const SubjectAnnouncement({
    required this.id,
    this.subjectId,
    this.subjectName,
    required this.title,
    required this.content,
    required this.authorName,
    required this.createdAt,
  });

  factory SubjectAnnouncement.fromJson(Map<String, dynamic> json) {
    return SubjectAnnouncement(
      id: json['id'] as String? ?? '',
      subjectId: json['subjectId'] as String?,
      subjectName: json['subjectName'] as String?,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Faculty',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ClassScheduleSlot {
  final String id;
  final String subjectCode;
  final String subjectName;
  final String roomOrVenue;
  final String startTime;
  final String endTime;
  final String semester;
  final String section;
  final String dayOfWeek;

  const ClassScheduleSlot({
    required this.id,
    required this.subjectCode,
    required this.subjectName,
    required this.roomOrVenue,
    required this.startTime,
    required this.endTime,
    required this.semester,
    required this.section,
    required this.dayOfWeek,
  });

  factory ClassScheduleSlot.fromJson(Map<String, dynamic> json) {
    return ClassScheduleSlot(
      id: json['id'] as String? ?? '',
      subjectCode: json['subjectCode'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      roomOrVenue: json['roomOrVenue'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      semester: json['semester'] as String? ?? '',
      section: json['section'] as String? ?? 'A',
      dayOfWeek: json['dayOfWeek'] as String? ?? 'MONDAY',
    );
  }
}

class MenteeStudent {
  final String id;
  final String name;
  final String rollNumber;
  final String department;
  final String semester;
  final double cgpa;
  final String email;
  final String? avatarUrl;
  final bool hasPortfolio;

  const MenteeStudent({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.department,
    required this.semester,
    required this.cgpa,
    required this.email,
    this.avatarUrl,
    required this.hasPortfolio,
  });

  factory MenteeStudent.fromJson(Map<String, dynamic> json) {
    return MenteeStudent(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      rollNumber: json['rollNumber'] as String? ?? '',
      department: json['department'] as String? ?? '',
      semester: json['semester'] as String? ?? 'Semester 7',
      cgpa: (json['cgpa'] as num?)?.toDouble() ?? 0.0,
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      hasPortfolio: json['hasPortfolio'] as bool? ?? false,
    );
  }
}

class FacultyEventSummary {
  final String id;
  final String title;
  final String startTime;
  final String venue;
  final String scope;

  const FacultyEventSummary({
    required this.id,
    required this.title,
    required this.startTime,
    required this.venue,
    required this.scope,
  });

  factory FacultyEventSummary.fromJson(Map<String, dynamic> json) {
    return FacultyEventSummary(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      venue: json['venue'] as String? ?? '',
      scope: json['scope'] as String? ?? 'GENERAL',
    );
  }
}

class FacultyProfileModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String? avatarUrl;
  final String designation;
  final String qualification;
  final String department;
  final String specialization;
  final String bio;
  final String officeRoom;
  final String officeHours;
  final List<String> expertise;
  final List<Map<String, dynamic>> publications;
  final String? linkedinUrl;
  final String? googleScholar;
  final int subjectsCount;
  final int menteesCount;

  const FacultyProfileModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.designation,
    required this.qualification,
    required this.department,
    required this.specialization,
    required this.bio,
    required this.officeRoom,
    required this.officeHours,
    this.expertise = const [],
    this.publications = const [],
    this.linkedinUrl,
    this.googleScholar,
    this.subjectsCount = 0,
    this.menteesCount = 0,
  });

  factory FacultyProfileModel.fromJson(Map<String, dynamic> json) {
    return FacultyProfileModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? 'Faculty Member',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      designation: json['designation'] as String? ?? 'Associate Professor',
      qualification: json['qualification'] as String? ?? 'Ph.D., M.Tech',
      department: json['department'] as String? ?? 'Department of Computer Science',
      specialization: json['specialization'] as String? ?? 'Distributed Systems',
      bio: json['bio'] as String? ?? '',
      officeRoom: json['officeRoom'] as String? ?? 'Room 304, Block B',
      officeHours: json['officeHours'] as String? ?? 'Mon - Thu: 2:00 PM - 4:00 PM',
      expertise: (json['expertise'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      publications: (json['publications'] as List<dynamic>? ?? []).map((e) => e as Map<String, dynamic>).toList(),
      linkedinUrl: json['linkedinUrl'] as String?,
      googleScholar: json['googleScholar'] as String?,
      subjectsCount: (json['subjectsCount'] as num?)?.toInt() ?? 0,
      menteesCount: (json['menteesCount'] as num?)?.toInt() ?? 0,
    );
  }
}
