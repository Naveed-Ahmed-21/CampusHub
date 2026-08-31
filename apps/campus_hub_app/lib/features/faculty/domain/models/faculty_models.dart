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

  const FacultyInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.designation,
    required this.department,
    this.avatarUrl,
  });

  factory FacultyInfo.fromJson(Map<String, dynamic> json) {
    return FacultyInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Faculty Member',
      email: json['email'] as String? ?? '',
      designation: json['designation'] as String? ?? 'Associate Professor',
      department: json['department'] as String? ?? 'Department of Computer Science',
      avatarUrl: json['avatarUrl'] as String?,
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
  final String code;
  final String name;
  final String department;
  final String semester;
  final String section;
  final int credits;
  final String? description;
  final int resourcesCount;
  final int announcementsCount;
  final int studentsCount;
  final List<SubjectResource> resources;
  final List<SubjectAnnouncement> announcements;

  const FacultySubject({
    required this.id,
    this.facultyId,
    required this.code,
    required this.name,
    required this.department,
    required this.semester,
    required this.section,
    required this.credits,
    this.description,
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
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      department: json['department'] as String? ?? 'Computer Science',
      semester: json['semester'] as String? ?? 'Semester 5',
      section: json['section'] as String? ?? 'A',
      credits: (json['credits'] as num?)?.toInt() ?? 3,
      description: json['description'] as String?,
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
  final String uploadedByName;
  final DateTime createdAt;

  const SubjectResource({
    required this.id,
    required this.subjectId,
    required this.title,
    this.description,
    required this.fileUrl,
    required this.fileType,
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
