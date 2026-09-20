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
      faculty:
          FacultyInfo.fromJson(json['faculty'] as Map<String, dynamic>? ?? {}),
      stats:
          FacultyStats.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
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
      department:
          json['department'] as String? ?? 'Department of Computer Science',
      avatarUrl: json['avatarUrl'] as String?,
      officeRoom: json['officeRoom'] as String? ?? 'Room 304, Tech Block',
      officeHours:
          json['officeHours'] as String? ?? 'Mon - Thu: 2:00 PM - 4:00 PM',
      specialization: json['specialization'] as String? ??
          'Distributed Systems & Cloud Computing',
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
      publishedAnnouncementsCount:
          (json['publishedAnnouncementsCount'] as num?)?.toInt() ?? 0,
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
  final List<SubjectStudent> students;

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
    this.students = const [],
  });

  List<SubjectStudent> get enrolledStudents => students;

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
      students: (json['students'] as List<dynamic>? ?? [])
          .map((e) => SubjectStudent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SubjectStudent {
  final String id;
  final String name;
  final String email;
  final String rollNumber;
  final String? avatarUrl;
  final String department;
  final String semester;
  final String section;

  const SubjectStudent({
    required this.id,
    required this.name,
    required this.email,
    required this.rollNumber,
    this.avatarUrl,
    required this.department,
    this.semester = 'Semester 5',
    this.section = 'A',
  });

  factory SubjectStudent.fromJson(Map<String, dynamic> json) {
    return SubjectStudent(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Student',
      email: json['email'] as String? ?? '',
      rollNumber: json['rollNumber'] as String? ?? '21CS101',
      avatarUrl: json['avatarUrl'] as String?,
      department: json['department'] as String? ?? 'Computer Science',
      semester: json['semester'] as String? ?? 'Semester 5',
      section: json['section'] as String? ?? 'A',
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
      resourceType: json['resourceType'] as String? ??
          json['resource_type'] as String? ??
          'NOTES',
      visibility: json['visibility'] as String? ?? 'PUBLIC',
      thumbnailUrl:
          json['thumbnailUrl'] as String? ?? json['thumbnail_url'] as String?,
      academicYear: json['academicYear'] as String? ??
          json['academic_year'] as String? ??
          '2024-2025',
      downloadCount: (json['downloadCount'] as num?)?.toInt() ??
          (json['download_count'] as num?)?.toInt() ??
          0,
      viewCount: (json['viewCount'] as num?)?.toInt() ??
          (json['view_count'] as num?)?.toInt() ??
          0,
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
  final String? subjectId;
  final String subjectCode;
  final String subjectName;
  final String roomOrVenue;
  final String startTime;
  final String endTime;
  final String semester;
  final String section;
  final String dayOfWeek;
  final String? topic;
  final String sessionType;
  final String status;

  const ClassScheduleSlot({
    required this.id,
    this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    required this.roomOrVenue,
    required this.startTime,
    required this.endTime,
    required this.semester,
    required this.section,
    required this.dayOfWeek,
    this.topic,
    this.sessionType = 'THEORY',
    this.status = 'SCHEDULED',
  });

  factory ClassScheduleSlot.fromJson(Map<String, dynamic> json) {
    return ClassScheduleSlot(
      id: json['id'] as String? ?? '',
      subjectId: json['subjectId'] as String?,
      subjectCode: json['subjectCode'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      roomOrVenue: json['roomOrVenue'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      semester: json['semester'] as String? ?? '',
      section: json['section'] as String? ?? 'A',
      dayOfWeek: json['dayOfWeek'] as String? ?? 'MONDAY',
      topic: json['topic'] as String?,
      sessionType: json['sessionType'] as String? ?? 'THEORY',
      status: json['status'] as String? ?? 'SCHEDULED',
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
      department:
          json['department'] as String? ?? 'Department of Computer Science',
      specialization:
          json['specialization'] as String? ?? 'Distributed Systems',
      bio: json['bio'] as String? ?? '',
      officeRoom: json['officeRoom'] as String? ?? 'Room 304, Block B',
      officeHours:
          json['officeHours'] as String? ?? 'Mon - Thu: 2:00 PM - 4:00 PM',
      expertise: (json['expertise'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      publications: (json['publications'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      linkedinUrl: json['linkedinUrl'] as String?,
      googleScholar: json['googleScholar'] as String?,
      subjectsCount: (json['subjectsCount'] as num?)?.toInt() ?? 0,
      menteesCount: (json['menteesCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class SubjectAssignment {
  final String id;
  final String subjectId;
  final String facultyId;
  final String title;
  final String? description;
  final String? unit;
  final String? topic;
  final List<dynamic> attachments;
  final int maxMarks;
  final DateTime dueAt;
  final String submissionType;
  final bool allowLate;
  final int submissionsCount;
  final int gradedCount;
  final DateTime createdAt;

  const SubjectAssignment({
    required this.id,
    required this.subjectId,
    required this.facultyId,
    required this.title,
    this.description,
    this.unit,
    this.topic,
    this.attachments = const [],
    required this.maxMarks,
    required this.dueAt,
    this.submissionType = 'FILE',
    this.allowLate = true,
    this.submissionsCount = 0,
    this.gradedCount = 0,
    required this.createdAt,
  });

  factory SubjectAssignment.fromJson(Map<String, dynamic> json) {
    return SubjectAssignment(
      id: json['id'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      facultyId: json['facultyId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      unit: json['unit'] as String?,
      topic: json['topic'] as String?,
      attachments: (json['attachments'] as List<dynamic>? ?? []),
      maxMarks: (json['maxMarks'] as num?)?.toInt() ?? 100,
      dueAt: json['dueAt'] != null
          ? DateTime.tryParse(json['dueAt'].toString()) ??
              DateTime.now().add(const Duration(days: 7))
          : DateTime.now().add(const Duration(days: 7)),
      submissionType: json['submissionType'] as String? ?? 'FILE',
      allowLate: json['allowLate'] as bool? ?? true,
      submissionsCount: (json['submissionsCount'] as num?)?.toInt() ?? 0,
      gradedCount: (json['gradedCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AssignmentSubmission {
  final String id;
  final String assignmentId;
  final String studentId;
  final String studentName;
  final String? studentRollNumber;
  final String? studentAvatarUrl;
  final String submissionType;
  final String? fileUrl;
  final String? linkUrl;
  final String? textContent;
  final double? marks;
  final String? feedback;
  final String status;
  final DateTime submittedAt;
  final DateTime? gradedAt;

  const AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    this.studentRollNumber,
    this.studentAvatarUrl,
    this.submissionType = 'FILE',
    this.fileUrl,
    this.linkUrl,
    this.textContent,
    this.marks,
    this.feedback,
    this.status = 'SUBMITTED',
    required this.submittedAt,
    this.gradedAt,
  });

  factory AssignmentSubmission.fromJson(Map<String, dynamic> json) {
    return AssignmentSubmission(
      id: json['id'] as String? ?? '',
      assignmentId: json['assignmentId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      studentName: json['studentName'] as String? ?? 'Student',
      studentRollNumber: json['studentRollNumber'] as String?,
      studentAvatarUrl: json['studentAvatarUrl'] as String?,
      submissionType: json['submissionType'] as String? ?? 'FILE',
      fileUrl: json['fileUrl'] as String?,
      linkUrl: json['linkUrl'] as String?,
      textContent: json['textContent'] as String?,
      marks: (json['marks'] as num?)?.toDouble(),
      feedback: json['feedback'] as String?,
      status: json['status'] as String? ?? 'SUBMITTED',
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      gradedAt: json['gradedAt'] != null
          ? DateTime.tryParse(json['gradedAt'].toString())
          : null,
    );
  }
}

class AttendanceSession {
  final String id;
  final String subjectId;
  final String facultyId;
  final String sessionDate;
  final String? startTime;
  final String? endTime;
  final String? topic;
  final int totalStudents;
  final int presentCount;
  final String status;
  final String section;
  final DateTime createdAt;
  final List<StudentAttendanceRecord> records;

  const AttendanceSession({
    required this.id,
    required this.subjectId,
    required this.facultyId,
    required this.sessionDate,
    this.startTime,
    this.endTime,
    this.topic,
    this.totalStudents = 0,
    this.presentCount = 0,
    this.status = 'OPEN',
    this.section = 'A',
    required this.createdAt,
    this.records = const [],
  });

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    return AttendanceSession(
      id: json['id'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      facultyId: json['facultyId'] as String? ?? '',
      sessionDate: json['sessionDate'] as String? ?? '',
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      topic: json['topic'] as String?,
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      presentCount: (json['presentCount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'OPEN',
      section: json['section'] as String? ?? 'A',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      records: (json['records'] as List<dynamic>? ?? [])
          .map((e) =>
              StudentAttendanceRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StudentAttendanceRecord {
  final String? id;
  final String studentId;
  final String studentName;
  final String? studentRollNumber;
  final String? studentAvatarUrl;
  final String status;
  final String? remarks;

  const StudentAttendanceRecord({
    this.id,
    required this.studentId,
    this.studentName = 'Student',
    this.studentRollNumber,
    this.studentAvatarUrl,
    this.status = 'PRESENT',
    this.remarks,
  });

  factory StudentAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceRecord(
      id: json['id'] as String?,
      studentId: json['studentId'] as String? ?? '',
      studentName: json['studentName'] as String? ?? 'Student',
      studentRollNumber: json['studentRollNumber'] as String?,
      studentAvatarUrl: json['studentAvatarUrl'] as String?,
      status: json['status'] as String? ?? 'PRESENT',
      remarks: json['remarks'] as String?,
    );
  }
}

class SubjectAssessment {
  final String id;
  final String subjectId;
  final String facultyId;
  final String title;
  final String? description;
  final String assessmentType;
  final String? unit;
  final String? topic;
  final int totalMarks;
  final int passingMarks;
  final int? durationMinutes;
  final DateTime? scheduledAt;
  final String status;
  final int evaluatedCount;
  final double? averageMarks;
  final DateTime createdAt;

  const SubjectAssessment({
    required this.id,
    required this.subjectId,
    required this.facultyId,
    required this.title,
    this.description,
    this.assessmentType = 'INTERNAL_EXAM',
    this.unit,
    this.topic,
    this.totalMarks = 50,
    this.passingMarks = 20,
    this.durationMinutes = 60,
    this.scheduledAt,
    this.status = 'SCHEDULED',
    this.evaluatedCount = 0,
    this.averageMarks,
    required this.createdAt,
  });

  factory SubjectAssessment.fromJson(Map<String, dynamic> json) {
    return SubjectAssessment(
      id: json['id'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      facultyId: json['facultyId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      assessmentType: json['assessmentType'] as String? ?? 'INTERNAL_EXAM',
      unit: json['unit'] as String?,
      topic: json['topic'] as String?,
      totalMarks: (json['totalMarks'] as num?)?.toInt() ?? 50,
      passingMarks: (json['passingMarks'] as num?)?.toInt() ?? 20,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.tryParse(json['scheduledAt'].toString())
          : null,
      status: json['status'] as String? ?? 'SCHEDULED',
      evaluatedCount: (json['evaluatedCount'] as num?)?.toInt() ?? 0,
      averageMarks: (json['averageMarks'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class StudentAssessmentResult {
  final String? id;
  final String assessmentId;
  final String subjectId;
  final String studentId;
  final String studentName;
  final String? studentRollNumber;
  final String? studentAvatarUrl;
  final double? marksObtained;
  final String? grade;
  final String? remarks;
  final String status;
  final DateTime? evaluatedAt;

  const StudentAssessmentResult({
    this.id,
    required this.assessmentId,
    required this.subjectId,
    required this.studentId,
    this.studentName = 'Student',
    this.studentRollNumber,
    this.studentAvatarUrl,
    this.marksObtained,
    this.grade,
    this.remarks,
    this.status = 'EVALUATED',
    this.evaluatedAt,
  });

  factory StudentAssessmentResult.fromJson(Map<String, dynamic> json) {
    return StudentAssessmentResult(
      id: json['id'] as String?,
      assessmentId: json['assessmentId'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      studentName: json['studentName'] as String? ?? 'Student',
      studentRollNumber: json['studentRollNumber'] as String?,
      studentAvatarUrl: json['studentAvatarUrl'] as String?,
      marksObtained: (json['marksObtained'] as num?)?.toDouble(),
      grade: json['grade'] as String?,
      remarks: json['remarks'] as String?,
      status: json['status'] as String? ?? 'EVALUATED',
      evaluatedAt: json['evaluatedAt'] != null
          ? DateTime.tryParse(json['evaluatedAt'].toString())
          : null,
    );
  }
}

class FacultyAcademicContext {
  final String academicYear;
  final String termName;
  final String termType;
  final String startDate;
  final String endDate;
  final String academicHeader;
  final List<FacultySubject> assignedSubjects;
  final List<ClassSummary> classes;
  final List<ClassScheduleSlot> todaySchedule;

  const FacultyAcademicContext({
    required this.academicYear,
    required this.termName,
    required this.termType,
    required this.startDate,
    required this.endDate,
    required this.academicHeader,
    required this.assignedSubjects,
    required this.classes,
    required this.todaySchedule,
  });

  factory FacultyAcademicContext.fromJson(Map<String, dynamic> json) {
    final term = json['currentTerm'] as Map<String, dynamic>? ?? {};
    return FacultyAcademicContext(
      academicYear: term['academicYear'] as String? ?? '2026-27',
      termName: term['termName'] as String? ?? 'Semester 1',
      termType: term['termType'] as String? ?? 'ODD',
      startDate: term['startDate'] as String? ?? '',
      endDate: term['endDate'] as String? ?? '',
      academicHeader: json['academicHeader'] as String? ??
          '2026–27 • Semester 1 | My Teaching',
      assignedSubjects: (json['assignedSubjects'] as List<dynamic>? ?? [])
          .map((e) => FacultySubject.fromJson(e as Map<String, dynamic>))
          .toList(),
      classes: (json['classes'] as List<dynamic>? ?? [])
          .map((e) => ClassSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      todaySchedule: (json['todaySchedule'] as List<dynamic>? ?? [])
          .map((e) => ClassScheduleSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ClassSummary {
  final String semester;
  final String section;
  final int subjectCount;
  final int studentCount;

  const ClassSummary({
    required this.semester,
    required this.section,
    required this.subjectCount,
    required this.studentCount,
  });

  factory ClassSummary.fromJson(Map<String, dynamic> json) {
    return ClassSummary(
      semester: json['semester'] as String? ?? '',
      section: json['section'] as String? ?? 'A',
      subjectCount: (json['subjectCount'] as num?)?.toInt() ?? 0,
      studentCount: (json['studentCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class EnrolledAttendanceStudent {
  final String id;
  final String name;
  final String rollNumber;
  final String? avatarUrl;
  final String? email;
  final String? department;
  final String? recordId;
  final String status;
  final String? remarks;

  const EnrolledAttendanceStudent({
    required this.id,
    required this.name,
    required this.rollNumber,
    this.avatarUrl,
    this.email,
    this.department,
    this.recordId,
    required this.status,
    this.remarks,
  });

  factory EnrolledAttendanceStudent.fromJson(Map<String, dynamic> json) {
    return EnrolledAttendanceStudent(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Student',
      rollNumber: json['rollNumber'] as String? ?? 'N/A',
      avatarUrl: json['avatarUrl'] as String?,
      email: json['email'] as String?,
      department: json['department'] as String?,
      recordId: json['recordId'] as String?,
      status: json['status'] as String? ?? 'UNMARKED',
      remarks: json['remarks'] as String?,
    );
  }

  EnrolledAttendanceStudent copyWith({
    String? status,
    String? remarks,
    String? recordId,
  }) {
    return EnrolledAttendanceStudent(
      id: id,
      name: name,
      rollNumber: rollNumber,
      avatarUrl: avatarUrl,
      email: email,
      department: department,
      recordId: recordId ?? this.recordId,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
    );
  }
}

class AttendanceMetrics {
  final int total;
  final int present;
  final int absent;
  final int unmarked;
  final int late;
  final int excused;

  const AttendanceMetrics({
    required this.total,
    required this.present,
    required this.absent,
    required this.unmarked,
    required this.late,
    required this.excused,
  });

  factory AttendanceMetrics.fromJson(Map<String, dynamic> json) {
    return AttendanceMetrics(
      total: (json['total'] as num?)?.toInt() ?? 0,
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      unmarked: (json['unmarked'] as num?)?.toInt() ?? 0,
      late: (json['late'] as num?)?.toInt() ?? 0,
      excused: (json['excused'] as num?)?.toInt() ?? 0,
    );
  }
}

class SessionAttendanceDetail {
  final AttendanceSession session;
  final AttendanceMetrics metrics;
  final List<EnrolledAttendanceStudent> students;

  const SessionAttendanceDetail({
    required this.session,
    required this.metrics,
    required this.students,
  });

  factory SessionAttendanceDetail.fromJson(Map<String, dynamic> json) {
    return SessionAttendanceDetail(
      session: AttendanceSession.fromJson(
          json['session'] as Map<String, dynamic>? ?? {}),
      metrics: AttendanceMetrics.fromJson(
          json['metrics'] as Map<String, dynamic>? ?? {}),
      students: (json['students'] as List<dynamic>? ?? [])
          .map((e) =>
              EnrolledAttendanceStudent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
