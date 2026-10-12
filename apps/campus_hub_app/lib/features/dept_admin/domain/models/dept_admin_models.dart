class DeptInfo {
  final String id;
  final String name;
  final String code;
  final String degree;
  final String collegeName;

  const DeptInfo({
    required this.id,
    required this.name,
    required this.code,
    required this.degree,
    required this.collegeName,
  });

  factory DeptInfo.fromJson(Map<String, dynamic> json) {
    return DeptInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      degree: json['degree'] as String? ?? 'B.E.',
      collegeName: json['collegeName'] as String? ?? 'Government College of Engineering, Erode',
    );
  }
}

class DeptKpis {
  final int totalStudents;
  final int totalFaculty;
  final int totalClasses;
  final int totalSubjects;
  final int avgAttendance;
  final int activePlacementDrives;
  final int eligibleStudents;

  const DeptKpis({
    required this.totalStudents,
    required this.totalFaculty,
    required this.totalClasses,
    required this.totalSubjects,
    required this.avgAttendance,
    required this.activePlacementDrives,
    required this.eligibleStudents,
  });

  factory DeptKpis.fromJson(Map<String, dynamic> json) {
    return DeptKpis(
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      totalFaculty: (json['totalFaculty'] as num?)?.toInt() ?? 0,
      totalClasses: (json['totalClasses'] as num?)?.toInt() ?? 0,
      totalSubjects: (json['totalSubjects'] as num?)?.toInt() ?? 0,
      avgAttendance: (json['avgAttendance'] as num?)?.toInt() ?? 0,
      activePlacementDrives: (json['activePlacementDrives'] as num?)?.toInt() ?? 0,
      eligibleStudents: (json['eligibleStudents'] as num?)?.toInt() ?? 0,
    );
  }
}

class DeptAlerts {
  final int lowAttendanceCount;
  final int activeDrivesCount;
  final int upcomingAssessmentsCount;
  final int assignmentsDeadlinesCount;
  final int recentAnnouncementsCount;

  const DeptAlerts({
    required this.lowAttendanceCount,
    required this.activeDrivesCount,
    required this.upcomingAssessmentsCount,
    required this.assignmentsDeadlinesCount,
    required this.recentAnnouncementsCount,
  });

  factory DeptAlerts.fromJson(Map<String, dynamic> json) {
    return DeptAlerts(
      lowAttendanceCount: (json['lowAttendanceCount'] as num?)?.toInt() ?? 0,
      activeDrivesCount: (json['activeDrivesCount'] as num?)?.toInt() ?? 0,
      upcomingAssessmentsCount: (json['upcomingAssessmentsCount'] as num?)?.toInt() ?? 0,
      assignmentsDeadlinesCount: (json['assignmentsDeadlinesCount'] as num?)?.toInt() ?? 0,
      recentAnnouncementsCount: (json['recentAnnouncementsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class DeptDashboardData {
  final DeptInfo department;
  final String academicYear;
  final String semester;
  final DeptKpis kpis;
  final DeptAlerts alerts;

  const DeptDashboardData({
    required this.department,
    required this.academicYear,
    required this.semester,
    required this.kpis,
    required this.alerts,
  });

  factory DeptDashboardData.fromJson(Map<String, dynamic> json) {
    return DeptDashboardData(
      department: DeptInfo.fromJson(json['department'] as Map<String, dynamic>? ?? {}),
      academicYear: json['academicYear'] as String? ?? '2026-2027',
      semester: json['semester'] as String? ?? 'Even Semester',
      kpis: DeptKpis.fromJson(json['kpis'] as Map<String, dynamic>? ?? {}),
      alerts: DeptAlerts.fromJson(json['alerts'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class DeptStudent {
  final String id;
  final String name;
  final String rollNumber;
  final String regNumber;
  final String email;
  final String? avatarUrl;
  final int year;
  final String yearLabel;
  final String batch;
  final String section;
  final double cgpa;
  final int attendance;
  final String placementStatus;

  const DeptStudent({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.regNumber,
    required this.email,
    this.avatarUrl,
    required this.year,
    required this.yearLabel,
    required this.batch,
    required this.section,
    required this.cgpa,
    required this.attendance,
    required this.placementStatus,
  });

  factory DeptStudent.fromJson(Map<String, dynamic> json) {
    return DeptStudent(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      rollNumber: json['rollNumber'] as String? ?? '',
      regNumber: json['regNumber'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      year: (json['year'] as num?)?.toInt() ?? 4,
      yearLabel: json['yearLabel'] as String? ?? '4th Year',
      batch: json['batch'] as String? ?? '',
      section: json['section'] as String? ?? '',
      cgpa: (json['cgpa'] as num?)?.toDouble() ?? 0.0,
      attendance: (json['attendance'] as num?)?.toInt() ?? 0,
      placementStatus: json['placementStatus'] as String? ?? 'ELIGIBLE',
    );
  }
}

class DeptStudentActivity {
  final String title;
  final String date;
  final String type;

  const DeptStudentActivity({
    required this.title,
    required this.date,
    required this.type,
  });

  factory DeptStudentActivity.fromJson(Map<String, dynamic> json) {
    return DeptStudentActivity(
      title: json['title'] as String? ?? '',
      date: json['date'] as String? ?? '',
      type: json['type'] as String? ?? '',
    );
  }
}

class DeptStudentCourse {
  final String code;
  final String name;
  final String attendance;
  final String internal;

  const DeptStudentCourse({
    required this.code,
    required this.name,
    required this.attendance,
    required this.internal,
  });

  factory DeptStudentCourse.fromJson(Map<String, dynamic> json) {
    return DeptStudentCourse(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      attendance: json['attendance'] as String? ?? '',
      internal: json['internal'] as String? ?? '',
    );
  }
}

class DeptStudentDetail {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String regNumber;
  final String rollNumber;
  final String department;
  final String degree;
  final int year;
  final String batch;
  final String section;
  final double cgpa;
  final int attendance;
  final int backlogs;
  final String placementStatus;
  final List<String> skills;
  final int projectsCount;
  final int certificationsCount;
  final int applicationsCount;
  final int offersCount;
  final List<DeptStudentCourse> courses;
  final List<DeptStudentActivity> recentActivity;

  const DeptStudentDetail({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    required this.regNumber,
    required this.rollNumber,
    required this.department,
    required this.degree,
    required this.year,
    required this.batch,
    required this.section,
    required this.cgpa,
    required this.attendance,
    required this.backlogs,
    required this.placementStatus,
    required this.skills,
    required this.projectsCount,
    required this.certificationsCount,
    required this.applicationsCount,
    required this.offersCount,
    this.courses = const [],
    required this.recentActivity,
  });

  factory DeptStudentDetail.fromJson(Map<String, dynamic> json) {
    final rawSkills = json['skills'] as List? ?? [];
    final rawCourses = json['courses'] as List? ?? [];
    final rawActivity = json['recentActivity'] as List? ?? [];

    return DeptStudentDetail(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      regNumber: json['regNumber'] as String? ?? '',
      rollNumber: json['rollNumber'] as String? ?? '',
      department: json['department'] as String? ?? '',
      degree: json['degree'] as String? ?? 'B.E.',
      year: (json['year'] as num?)?.toInt() ?? 4,
      batch: json['batch'] as String? ?? '',
      section: json['section'] as String? ?? '',
      cgpa: (json['cgpa'] as num?)?.toDouble() ?? 0.0,
      attendance: (json['attendance'] as num?)?.toInt() ?? 0,
      backlogs: (json['backlogs'] as num?)?.toInt() ?? 0,
      placementStatus: json['placementStatus'] as String? ?? 'ELIGIBLE',
      skills: rawSkills.map((e) => e.toString()).toList(),
      projectsCount: (json['projectsCount'] as num?)?.toInt() ?? 0,
      certificationsCount: (json['certificationsCount'] as num?)?.toInt() ?? 0,
      applicationsCount: (json['applicationsCount'] as num?)?.toInt() ?? 0,
      offersCount: (json['offersCount'] as num?)?.toInt() ?? 0,
      courses: rawCourses.map((e) => DeptStudentCourse.fromJson(e as Map<String, dynamic>)).toList(),
      recentActivity: rawActivity.map((e) => DeptStudentActivity.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class DeptFaculty {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String designation;
  final List<String> assignedSubjects;
  final List<String> classes;
  final int workloadHours;
  final String status;

  const DeptFaculty({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.designation,
    required this.assignedSubjects,
    required this.classes,
    required this.workloadHours,
    required this.status,
  });

  factory DeptFaculty.fromJson(Map<String, dynamic> json) {
    final rawSubjects = json['assignedSubjects'] as List? ?? [];
    final rawClasses = json['classes'] as List? ?? [];

    return DeptFaculty(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      designation: json['designation'] as String? ?? 'Assistant Professor',
      assignedSubjects: rawSubjects.map((e) => e.toString()).toList(),
      classes: rawClasses.map((e) => e.toString()).toList(),
      workloadHours: (json['workloadHours'] as num?)?.toInt() ?? 16,
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }
}

class DeptBatch {
  final String id;
  final String name;
  final String yearLabel;
  final int admissionYear;
  final int graduationYear;

  const DeptBatch({
    required this.id,
    required this.name,
    required this.yearLabel,
    required this.admissionYear,
    required this.graduationYear,
  });

  factory DeptBatch.fromJson(Map<String, dynamic> json) {
    return DeptBatch(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      yearLabel: json['yearLabel'] as String? ?? '',
      admissionYear: (json['admissionYear'] as num?)?.toInt() ?? 0,
      graduationYear: (json['graduationYear'] as num?)?.toInt() ?? 0,
    );
  }
}

class DeptClass {
  final String id;
  final String name;
  final String section;
  final int yearOfStudy;
  final int studentCount;

  const DeptClass({
    required this.id,
    required this.name,
    required this.section,
    required this.yearOfStudy,
    required this.studentCount,
  });

  factory DeptClass.fromJson(Map<String, dynamic> json) {
    return DeptClass(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      section: json['section'] as String? ?? '',
      yearOfStudy: (json['yearOfStudy'] as num?)?.toInt() ?? 1,
      studentCount: (json['studentCount'] as num?)?.toInt() ?? 60,
    );
  }
}

class DeptSubject {
  final String id;
  final String code;
  final String name;
  final int credits;
  final String facultyName;
  final int classesCount;
  final int studentCount;

  const DeptSubject({
    required this.id,
    required this.code,
    required this.name,
    required this.credits,
    required this.facultyName,
    required this.classesCount,
    required this.studentCount,
  });

  factory DeptSubject.fromJson(Map<String, dynamic> json) {
    return DeptSubject(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      credits: (json['credits'] as num?)?.toInt() ?? 3,
      facultyName: json['facultyName'] as String? ?? 'Unassigned',
      classesCount: (json['classesCount'] as num?)?.toInt() ?? 2,
      studentCount: (json['studentCount'] as num?)?.toInt() ?? 60,
    );
  }
}

class DeptAcademicsData {
  final DeptInfo department;
  final String academicYear;
  final String semester;
  final List<DeptBatch> batches;
  final List<DeptClass> classes;
  final List<DeptSubject> subjects;

  const DeptAcademicsData({
    required this.department,
    required this.academicYear,
    required this.semester,
    required this.batches,
    required this.classes,
    required this.subjects,
  });

  factory DeptAcademicsData.fromJson(Map<String, dynamic> json) {
    final rawBatches = json['batches'] as List? ?? [];
    final rawClasses = json['classes'] as List? ?? [];
    final rawSubjects = json['subjects'] as List? ?? [];

    return DeptAcademicsData(
      department: DeptInfo.fromJson(json['department'] as Map<String, dynamic>? ?? {}),
      academicYear: json['academicYear'] as String? ?? '2026-2027',
      semester: json['semester'] as String? ?? 'Even Semester',
      batches: rawBatches.map((e) => DeptBatch.fromJson(e as Map<String, dynamic>)).toList(),
      classes: rawClasses.map((e) => DeptClass.fromJson(e as Map<String, dynamic>)).toList(),
      subjects: rawSubjects.map((e) => DeptSubject.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class DeptTimetableSlot {
  final String id;
  final String day;
  final String startTime;
  final String endTime;
  final String subjectCode;
  final String subjectName;
  final String facultyName;
  final String room;
  final String className;

  const DeptTimetableSlot({
    required this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.subjectCode,
    required this.subjectName,
    required this.facultyName,
    required this.room,
    required this.className,
  });

  factory DeptTimetableSlot.fromJson(Map<String, dynamic> json) {
    return DeptTimetableSlot(
      id: json['id'] as String? ?? '',
      day: json['day'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      subjectCode: json['subjectCode'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      facultyName: json['facultyName'] as String? ?? '',
      room: json['room'] as String? ?? '',
      className: json['className'] as String? ?? '',
    );
  }
}

class DeptSubjectAttendance {
  final String subject;
  final String code;
  final int percentage;
  final bool isBelowThreshold;

  const DeptSubjectAttendance({
    required this.subject,
    required this.code,
    required this.percentage,
    required this.isBelowThreshold,
  });

  factory DeptSubjectAttendance.fromJson(Map<String, dynamic> json) {
    return DeptSubjectAttendance(
      subject: json['subject'] as String? ?? '',
      code: json['code'] as String? ?? '',
      percentage: (json['percentage'] as num?)?.toInt() ?? 0,
      isBelowThreshold: json['isBelowThreshold'] as bool? ?? false,
    );
  }
}

class DeptAttendanceData {
  final int averageAttendance;
  final Map<String, int> breakdown;
  final List<DeptSubjectAttendance> subjectAttendance;
  final int lowAttendanceCount;

  const DeptAttendanceData({
    required this.averageAttendance,
    required this.breakdown,
    required this.subjectAttendance,
    required this.lowAttendanceCount,
  });

  factory DeptAttendanceData.fromJson(Map<String, dynamic> json) {
    final rawBreakdown = json['breakdown'] as Map<String, dynamic>? ?? {};
    final rawSubjects = json['subjectAttendance'] as List? ?? [];

    return DeptAttendanceData(
      averageAttendance: (json['averageAttendance'] as num?)?.toInt() ?? 0,
      breakdown: rawBreakdown.map((k, v) => MapEntry(k, (v as num).toInt())),
      subjectAttendance: rawSubjects.map((e) => DeptSubjectAttendance.fromJson(e as Map<String, dynamic>)).toList(),
      lowAttendanceCount: (json['lowAttendanceCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class DeptLowAttendanceStudent {
  final String id;
  final String name;
  final String regNumber;
  final String className;
  final String subject;
  final int attendancePercentage;
  final int requiredPercentage;
  final String status;
  final String? avatarUrl;

  const DeptLowAttendanceStudent({
    required this.id,
    required this.name,
    required this.regNumber,
    required this.className,
    required this.subject,
    required this.attendancePercentage,
    required this.requiredPercentage,
    required this.status,
    this.avatarUrl,
  });

  factory DeptLowAttendanceStudent.fromJson(Map<String, dynamic> json) {
    return DeptLowAttendanceStudent(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      regNumber: json['regNumber'] as String? ?? '',
      className: json['className'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      attendancePercentage: (json['attendancePercentage'] as num?)?.toInt() ?? 0,
      requiredPercentage: (json['requiredPercentage'] as num?)?.toInt() ?? 75,
      status: json['status'] as String? ?? 'Critical',
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

class DeptAssignment {
  final String id;
  final String title;
  final String subjectName;
  final String facultyName;
  final String className;
  final String dueDate;
  final int submittedCount;
  final int totalCount;
  final String status;

  const DeptAssignment({
    required this.id,
    required this.title,
    required this.subjectName,
    required this.facultyName,
    required this.className,
    required this.dueDate,
    required this.submittedCount,
    required this.totalCount,
    required this.status,
  });

  factory DeptAssignment.fromJson(Map<String, dynamic> json) {
    return DeptAssignment(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      facultyName: json['facultyName'] as String? ?? '',
      className: json['className'] as String? ?? '',
      dueDate: json['dueDate'] as String? ?? '',
      submittedCount: (json['submittedCount'] as num?)?.toInt() ?? 0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'Due',
    );
  }
}

class DeptAssessment {
  final String id;
  final String name;
  final String subjectName;
  final String className;
  final String facultyName;
  final String date;
  final double averageScore;
  final double passPercentage;

  const DeptAssessment({
    required this.id,
    required this.name,
    required this.subjectName,
    required this.className,
    required this.facultyName,
    required this.date,
    required this.averageScore,
    required this.passPercentage,
  });

  factory DeptAssessment.fromJson(Map<String, dynamic> json) {
    return DeptAssessment(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      className: json['className'] as String? ?? '',
      facultyName: json['facultyName'] as String? ?? '',
      date: json['date'] as String? ?? '',
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      passPercentage: (json['passPercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DeptResource {
  final String id;
  final String title;
  final String subjectName;
  final String uploadedBy;
  final String date;
  final String fileType;
  final String fileSize;
  final String? fileUrl;

  const DeptResource({
    required this.id,
    required this.title,
    required this.subjectName,
    required this.uploadedBy,
    required this.date,
    required this.fileType,
    required this.fileSize,
    this.fileUrl,
  });

  factory DeptResource.fromJson(Map<String, dynamic> json) {
    return DeptResource(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      uploadedBy: json['uploadedBy'] as String? ?? '',
      date: json['date'] as String? ?? '',
      fileType: json['fileType'] as String? ?? 'PDF',
      fileSize: json['fileSize'] as String? ?? 'Document',
      fileUrl: json['fileUrl'] as String?,
    );
  }
}

class DeptPlacementDrive {
  final String id;
  final String companyName;
  final String roleTitle;
  final String packageCtc;
  final String status;
  final String deadline;

  const DeptPlacementDrive({
    required this.id,
    required this.companyName,
    required this.roleTitle,
    required this.packageCtc,
    required this.status,
    required this.deadline,
  });

  factory DeptPlacementDrive.fromJson(Map<String, dynamic> json) {
    return DeptPlacementDrive(
      id: json['id'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      roleTitle: json['roleTitle'] as String? ?? '',
      packageCtc: json['packageCtc'] as String? ?? '7.0 LPA',
      status: json['status'] as String? ?? 'ONGOING',
      deadline: json['deadline'] as String? ?? '',
    );
  }
}

class DeptPlacementSummary {
  final int activeDrives;
  final int eligibleStudents;
  final int applications;
  final int selected;
  final List<DeptPlacementDrive> recentDrives;

  const DeptPlacementSummary({
    required this.activeDrives,
    required this.eligibleStudents,
    required this.applications,
    required this.selected,
    required this.recentDrives,
  });

  factory DeptPlacementSummary.fromJson(Map<String, dynamic> json) {
    final rawDrives = json['recentDrives'] as List? ?? [];
    return DeptPlacementSummary(
      activeDrives: (json['activeDrives'] as num?)?.toInt() ?? 0,
      eligibleStudents: (json['eligibleStudents'] as num?)?.toInt() ?? 0,
      applications: (json['applications'] as num?)?.toInt() ?? 0,
      selected: (json['selected'] as num?)?.toInt() ?? 0,
      recentDrives: rawDrives.map((e) => DeptPlacementDrive.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class DeptYearMetric {
  final String year;
  final int count;

  const DeptYearMetric({required this.year, required this.count});

  factory DeptYearMetric.fromJson(Map<String, dynamic> json) {
    return DeptYearMetric(
      year: json['year'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class DeptPlacementBreakdown {
  final int placed;
  final int shortlisted;
  final int applied;
  final int eligible;
  final int total;

  const DeptPlacementBreakdown({
    required this.placed,
    required this.shortlisted,
    required this.applied,
    required this.eligible,
    required this.total,
  });

  factory DeptPlacementBreakdown.fromJson(Map<String, dynamic> json) {
    return DeptPlacementBreakdown(
      placed: (json['placed'] as num?)?.toInt() ?? 0,
      shortlisted: (json['shortlisted'] as num?)?.toInt() ?? 0,
      applied: (json['applied'] as num?)?.toInt() ?? 0,
      eligible: (json['eligible'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class DeptReportMetrics {
  final int students;
  final int faculty;
  final double avgCgpa;
  final int attendance;

  const DeptReportMetrics({
    required this.students,
    required this.faculty,
    required this.avgCgpa,
    required this.attendance,
  });

  factory DeptReportMetrics.fromJson(Map<String, dynamic> json) {
    return DeptReportMetrics(
      students: (json['students'] as num?)?.toInt() ?? 0,
      faculty: (json['faculty'] as num?)?.toInt() ?? 0,
      avgCgpa: (json['avgCgpa'] as num?)?.toDouble() ?? 0.0,
      attendance: (json['attendance'] as num?)?.toInt() ?? 0,
    );
  }
}

class DeptReportsData {
  final String academicYear;
  final DeptReportMetrics metrics;
  final List<DeptYearMetric> studentsByYear;
  final DeptPlacementBreakdown placementStatus;

  const DeptReportsData({
    required this.academicYear,
    required this.metrics,
    required this.studentsByYear,
    required this.placementStatus,
  });

  factory DeptReportsData.fromJson(Map<String, dynamic> json) {
    final rawYears = json['studentsByYear'] as List? ?? [];
    return DeptReportsData(
      academicYear: json['academicYear'] as String? ?? '2026 - 2027',
      metrics: DeptReportMetrics.fromJson(json['metrics'] as Map<String, dynamic>? ?? {}),
      studentsByYear: rawYears.map((e) => DeptYearMetric.fromJson(e as Map<String, dynamic>)).toList(),
      placementStatus: DeptPlacementBreakdown.fromJson(json['placementStatus'] as Map<String, dynamic>? ?? {}),
    );
  }
}
