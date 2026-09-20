import '../../../faculty/domain/models/faculty_models.dart';

class AcademicSubjectModel {
  final String id;
  final String code;
  final String name;
  final String department;
  final String? departmentCode;
  final String? departmentId;
  final String semester;
  final String section;
  final int credits;
  final String? description;
  final String academicYear;
  final AcademicFacultySummary faculty;
  final int resourcesCount;
  final int unitsCount;
  final List<String> units;
  final bool isEnrolled;

  const AcademicSubjectModel({
    required this.id,
    required this.code,
    required this.name,
    required this.department,
    this.departmentCode,
    this.departmentId,
    required this.semester,
    required this.section,
    required this.credits,
    this.description,
    required this.academicYear,
    required this.faculty,
    required this.resourcesCount,
    required this.unitsCount,
    required this.units,
    required this.isEnrolled,
  });

  factory AcademicSubjectModel.fromJson(Map<String, dynamic> json) {
    return AcademicSubjectModel(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      department: json['department'] as String? ?? 'Computer Science',
      departmentCode: json['departmentCode'] as String?,
      departmentId: json['departmentId'] as String?,
      semester: json['semester'] as String? ?? '',
      section: json['section'] as String? ?? 'A',
      credits: (json['credits'] as num?)?.toInt() ?? 3,
      description: json['description'] as String?,
      academicYear: json['academicYear'] as String? ?? '2024-2025',
      faculty: AcademicFacultySummary.fromJson(
          json['faculty'] as Map<String, dynamic>? ?? {}),
      resourcesCount: (json['resourcesCount'] as num?)?.toInt() ?? 0,
      unitsCount: (json['unitsCount'] as num?)?.toInt() ?? 0,
      units: (json['units'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      isEnrolled: json['isEnrolled'] as bool? ?? false,
    );
  }

  AcademicSubjectModel copyWith({bool? isEnrolled}) {
    return AcademicSubjectModel(
      id: id,
      code: code,
      name: name,
      department: department,
      departmentCode: departmentCode,
      departmentId: departmentId,
      semester: semester,
      section: section,
      credits: credits,
      description: description,
      academicYear: academicYear,
      faculty: faculty,
      resourcesCount: resourcesCount,
      unitsCount: unitsCount,
      units: units,
      isEnrolled: isEnrolled ?? this.isEnrolled,
    );
  }
}

class AcademicFacultySummary {
  final String id;
  final String name;
  final String email;
  final String designation;
  final String? avatarUrl;

  const AcademicFacultySummary({
    required this.id,
    required this.name,
    required this.email,
    required this.designation,
    this.avatarUrl,
  });

  factory AcademicFacultySummary.fromJson(Map<String, dynamic> json) {
    return AcademicFacultySummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Faculty Member',
      email: json['email'] as String? ?? '',
      designation: json['designation'] as String? ?? 'Associate Professor',
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

class AcademicSubjectDetailModel {
  final String id;
  final String code;
  final String name;
  final String department;
  final String? departmentCode;
  final String? departmentId;
  final String semester;
  final String section;
  final int credits;
  final String? description;
  final String academicYear;
  final AcademicFacultyFull faculty;
  final bool isEnrolled;
  final List<SubjectAnnouncement> announcements;
  final Map<String, List<SubjectResource>> resourcesByUnit;
  final List<SubjectResource> allResources;

  const AcademicSubjectDetailModel({
    required this.id,
    required this.code,
    required this.name,
    required this.department,
    this.departmentCode,
    this.departmentId,
    required this.semester,
    required this.section,
    required this.credits,
    this.description,
    required this.academicYear,
    required this.faculty,
    required this.isEnrolled,
    required this.announcements,
    required this.resourcesByUnit,
    required this.allResources,
  });

  factory AcademicSubjectDetailModel.fromJson(Map<String, dynamic> json) {
    final rawByUnit = json['resourcesByUnit'] as Map<String, dynamic>? ?? {};
    final Map<String, List<SubjectResource>> parsedByUnit = {};
    rawByUnit.forEach((key, list) {
      if (list is List) {
        parsedByUnit[key] = list
            .map((e) => SubjectResource.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    });

    return AcademicSubjectDetailModel(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      department: json['department'] as String? ?? 'Computer Science',
      departmentCode: json['departmentCode'] as String?,
      departmentId: json['departmentId'] as String?,
      semester: json['semester'] as String? ?? '',
      section: json['section'] as String? ?? 'A',
      credits: (json['credits'] as num?)?.toInt() ?? 3,
      description: json['description'] as String?,
      academicYear: json['academicYear'] as String? ?? '2024-2025',
      faculty: AcademicFacultyFull.fromJson(
          json['faculty'] as Map<String, dynamic>? ?? {}),
      isEnrolled: json['isEnrolled'] as bool? ?? false,
      announcements: (json['announcements'] as List<dynamic>? ?? [])
          .map((e) => SubjectAnnouncement.fromJson(e as Map<String, dynamic>))
          .toList(),
      resourcesByUnit: parsedByUnit,
      allResources: (json['allResources'] as List<dynamic>? ?? [])
          .map((e) => SubjectResource.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  AcademicSubjectDetailModel copyWith({bool? isEnrolled}) {
    return AcademicSubjectDetailModel(
      id: id,
      code: code,
      name: name,
      department: department,
      departmentCode: departmentCode,
      departmentId: departmentId,
      semester: semester,
      section: section,
      credits: credits,
      description: description,
      academicYear: academicYear,
      faculty: faculty,
      isEnrolled: isEnrolled ?? this.isEnrolled,
      announcements: announcements,
      resourcesByUnit: resourcesByUnit,
      allResources: allResources,
    );
  }
}

class AcademicFacultyFull {
  final String id;
  final String name;
  final String email;
  final String designation;
  final String qualification;
  final String department;
  final String specialization;
  final String officeRoom;
  final String officeHours;
  final String bio;
  final String? avatarUrl;
  final List<String> expertise;
  final List<Map<String, dynamic>> publications;

  const AcademicFacultyFull({
    required this.id,
    required this.name,
    required this.email,
    required this.designation,
    required this.qualification,
    required this.department,
    required this.specialization,
    required this.officeRoom,
    required this.officeHours,
    required this.bio,
    this.avatarUrl,
    this.expertise = const [],
    this.publications = const [],
  });

  factory AcademicFacultyFull.fromJson(Map<String, dynamic> json) {
    return AcademicFacultyFull(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Faculty Member',
      email: json['email'] as String? ?? '',
      designation: json['designation'] as String? ?? 'Associate Professor',
      qualification: json['qualification'] as String? ?? 'Ph.D., M.Tech',
      department:
          json['department'] as String? ?? 'Department of Computer Science',
      specialization:
          json['specialization'] as String? ?? 'Distributed Systems',
      officeRoom: json['officeRoom'] as String? ?? 'Room 304, Block B',
      officeHours:
          json['officeHours'] as String? ?? 'Mon - Thu: 2:00 PM - 4:00 PM',
      bio: json['bio'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      expertise: (json['expertise'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      publications: (json['publications'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }
}

class ResourceSearchResultModel {
  final String id;
  final String subjectId;
  final String subjectCode;
  final String subjectName;
  final String departmentName;
  final String facultyName;
  final String title;
  final String? description;
  final String fileUrl;
  final String fileType;
  final String? unit;
  final String? topic;
  final String resourceType;
  final String visibility;
  final int downloadCount;
  final int viewCount;
  final DateTime createdAt;

  const ResourceSearchResultModel({
    required this.id,
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    required this.departmentName,
    required this.facultyName,
    required this.title,
    this.description,
    required this.fileUrl,
    required this.fileType,
    this.unit,
    this.topic,
    required this.resourceType,
    required this.visibility,
    required this.downloadCount,
    required this.viewCount,
    required this.createdAt,
  });

  factory ResourceSearchResultModel.fromJson(Map<String, dynamic> json) {
    return ResourceSearchResultModel(
      id: json['id'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      subjectCode: json['subjectCode'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      departmentName: json['departmentName'] as String? ?? '',
      facultyName: json['facultyName'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      fileUrl: json['fileUrl'] as String? ?? '',
      fileType: json['fileType'] as String? ?? 'PDF',
      unit: json['unit'] as String?,
      topic: json['topic'] as String?,
      resourceType: json['resourceType'] as String? ?? 'NOTES',
      visibility: json['visibility'] as String? ?? 'PUBLIC',
      downloadCount: (json['downloadCount'] as num?)?.toInt() ?? 0,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class StudentAssignmentModel {
  final String id;
  final String subjectId;
  final String subjectCode;
  final String subjectName;
  final String facultyName;
  final String title;
  final String? description;
  final String? unit;
  final String? topic;
  final List<dynamic> attachments;
  final int maxMarks;
  final DateTime dueAt;
  final String submissionType;
  final bool allowLate;
  final AssignmentSubmission? submission;

  const StudentAssignmentModel({
    required this.id,
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    required this.facultyName,
    required this.title,
    this.description,
    this.unit,
    this.topic,
    this.attachments = const [],
    required this.maxMarks,
    required this.dueAt,
    this.submissionType = 'FILE',
    this.allowLate = true,
    this.submission,
  });

  factory StudentAssignmentModel.fromJson(Map<String, dynamic> json) {
    return StudentAssignmentModel(
      id: json['id'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      subjectCode: json['subjectCode'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      facultyName: json['facultyName'] as String? ?? 'Faculty Member',
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
      submission: json['submission'] != null
          ? AssignmentSubmission.fromJson(
              json['submission'] as Map<String, dynamic>)
          : null,
    );
  }
}

class StudentAttendanceSummaryModel {
  final String subjectId;
  final String subjectCode;
  final String subjectName;
  final String facultyName;
  final int totalSessions;
  final int attendedSessions;
  final int percentage;
  final List<StudentAttendanceRecordDetail> records;

  const StudentAttendanceSummaryModel({
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    required this.facultyName,
    required this.totalSessions,
    required this.attendedSessions,
    required this.percentage,
    this.records = const [],
  });

  factory StudentAttendanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceSummaryModel(
      subjectId: json['subjectId'] as String? ?? '',
      subjectCode: json['subjectCode'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      facultyName: json['facultyName'] as String? ?? '',
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      attendedSessions: (json['attendedSessions'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toInt() ?? 100,
      records: (json['records'] as List<dynamic>? ?? [])
          .map((e) =>
              StudentAttendanceRecordDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StudentAttendanceRecordDetail {
  final String id;
  final String date;
  final String? startTime;
  final String? endTime;
  final String? topic;
  final String status;
  final String? remarks;

  const StudentAttendanceRecordDetail({
    required this.id,
    required this.date,
    this.startTime,
    this.endTime,
    this.topic,
    required this.status,
    this.remarks,
  });

  factory StudentAttendanceRecordDetail.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceRecordDetail(
      id: json['id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      topic: json['topic'] as String?,
      status: json['status'] as String? ?? 'PRESENT',
      remarks: json['remarks'] as String?,
    );
  }
}

class StudentTimetableSlot {
  final String id;
  final String? subjectId;
  final String subjectCode;
  final String subjectName;
  final String? facultyId;
  final String facultyName;
  final String? facultyAvatarUrl;
  final String roomOrVenue;
  final String startTime;
  final String endTime;
  final String dayOfWeek;
  final String? topic;
  final String sessionType;
  final String status;

  const StudentTimetableSlot({
    required this.id,
    this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    this.facultyId,
    required this.facultyName,
    this.facultyAvatarUrl,
    required this.roomOrVenue,
    required this.startTime,
    required this.endTime,
    required this.dayOfWeek,
    this.topic,
    this.sessionType = 'THEORY',
    this.status = 'SCHEDULED',
  });

  factory StudentTimetableSlot.fromJson(Map<String, dynamic> json) {
    return StudentTimetableSlot(
      id: json['id'] as String? ?? '',
      subjectId: json['subjectId'] as String?,
      subjectCode: json['subjectCode'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      facultyId: json['facultyId'] as String?,
      facultyName: json['facultyName'] as String? ?? 'Faculty',
      facultyAvatarUrl: json['facultyAvatarUrl'] as String?,
      roomOrVenue: json['roomOrVenue'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      dayOfWeek: json['dayOfWeek'] as String? ?? 'TODAY',
      topic: json['topic'] as String?,
      sessionType: json['sessionType'] as String? ?? 'THEORY',
      status: json['status'] as String? ?? 'SCHEDULED',
    );
  }
}

class StudentSubjectAssessmentModel {
  final String id;
  final String subjectId;
  final String subjectCode;
  final String subjectName;
  final String facultyName;
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
  final StudentAssessmentResultDetail? result;

  const StudentSubjectAssessmentModel({
    required this.id,
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    required this.facultyName,
    required this.title,
    this.description,
    this.assessmentType = 'INTERNAL_EXAM',
    this.unit,
    this.topic,
    this.totalMarks = 50,
    this.passingMarks = 20,
    this.durationMinutes,
    this.scheduledAt,
    this.status = 'SCHEDULED',
    this.result,
  });

  factory StudentSubjectAssessmentModel.fromJson(Map<String, dynamic> json) {
    return StudentSubjectAssessmentModel(
      id: json['id'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      subjectCode: json['subjectCode'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      facultyName: json['facultyName'] as String? ?? 'Faculty',
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
      result: json['result'] != null
          ? StudentAssessmentResultDetail.fromJson(
              json['result'] as Map<String, dynamic>)
          : null,
    );
  }
}

class StudentAssessmentResultDetail {
  final double? marksObtained;
  final String? grade;
  final String? remarks;
  final String status;
  final DateTime? evaluatedAt;

  const StudentAssessmentResultDetail({
    this.marksObtained,
    this.grade,
    this.remarks,
    this.status = 'EVALUATED',
    this.evaluatedAt,
  });

  factory StudentAssessmentResultDetail.fromJson(Map<String, dynamic> json) {
    return StudentAssessmentResultDetail(
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

class StudentAssessmentSummaryModel {
  final String subjectId;
  final String subjectCode;
  final String subjectName;
  final int totalAssessments;
  final int evaluatedAssessments;
  final double totalScored;
  final int totalMax;
  final int percentage;
  final List<StudentSubjectAssessmentModel> assessments;

  const StudentAssessmentSummaryModel({
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    required this.totalAssessments,
    required this.evaluatedAssessments,
    required this.totalScored,
    required this.totalMax,
    required this.percentage,
    this.assessments = const [],
  });

  factory StudentAssessmentSummaryModel.fromJson(Map<String, dynamic> json) {
    return StudentAssessmentSummaryModel(
      subjectId: json['subjectId'] as String? ?? '',
      subjectCode: json['subjectCode'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      totalAssessments: (json['totalAssessments'] as num?)?.toInt() ?? 0,
      evaluatedAssessments:
          (json['evaluatedAssessments'] as num?)?.toInt() ?? 0,
      totalScored: (json['totalScored'] as num?)?.toDouble() ?? 0.0,
      totalMax: (json['totalMax'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toInt() ?? 0,
      assessments: (json['assessments'] as List<dynamic>? ?? [])
          .map((e) =>
              StudentSubjectAssessmentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AcademicTermModel {
  final String academicYearId;
  final String academicYear;
  final String termId;
  final String termName;
  final String termType;
  final int semesterNumber;
  final String startDate;
  final String endDate;
  final String status;

  const AcademicTermModel({
    required this.academicYearId,
    required this.academicYear,
    required this.termId,
    required this.termName,
    required this.termType,
    required this.semesterNumber,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory AcademicTermModel.fromJson(Map<String, dynamic> json) {
    return AcademicTermModel(
      academicYearId: json['academicYearId'] as String? ?? '',
      academicYear: json['academicYear'] as String? ?? '2026-27',
      termId: json['termId'] as String? ?? '',
      termName: json['termName'] as String? ?? 'Semester 1',
      termType: json['termType'] as String? ?? 'ODD',
      semesterNumber: (json['semesterNumber'] as num?)?.toInt() ?? 1,
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }
}

class StudentAcademicContextModel {
  final String academicYear;
  final String academicTerm;
  final String termType;
  final int semester;
  final String semesterRoman;
  final String semesterLabel;
  final int yearOfStudy;
  final String yearRoman;
  final String yearLabel;
  final int admissionYear;
  final String batchName;
  final String department;
  final String departmentName;
  final String program;
  final String section;
  final String className;
  final String academicHeader;
  final String status;
  final bool hasOverride;
  final String? overrideReason;
  final List<AcademicSubjectModel> subjects;

  const StudentAcademicContextModel({
    required this.academicYear,
    required this.academicTerm,
    required this.termType,
    required this.semester,
    required this.semesterRoman,
    required this.semesterLabel,
    required this.yearOfStudy,
    required this.yearRoman,
    required this.yearLabel,
    required this.admissionYear,
    required this.batchName,
    required this.department,
    required this.departmentName,
    required this.program,
    required this.section,
    required this.className,
    required this.academicHeader,
    required this.status,
    required this.hasOverride,
    this.overrideReason,
    this.subjects = const [],
  });

  factory StudentAcademicContextModel.fromJson(Map<String, dynamic> json) {
    return StudentAcademicContextModel(
      academicYear: json['academicYear'] as String? ?? '2026-27',
      academicTerm: json['academicTerm'] as String? ?? 'Semester 1',
      termType: json['termType'] as String? ?? 'ODD',
      semester: (json['semester'] as num?)?.toInt() ?? 7,
      semesterRoman: json['semesterRoman'] as String? ?? 'VII',
      semesterLabel: json['semesterLabel'] as String? ?? 'VII Semester',
      yearOfStudy: (json['yearOfStudy'] as num?)?.toInt() ?? 4,
      yearRoman: json['yearRoman'] as String? ?? 'IV',
      yearLabel: json['yearLabel'] as String? ?? 'IV Year',
      admissionYear: (json['admissionYear'] as num?)?.toInt() ?? 2023,
      batchName: json['batchName'] as String? ?? '2023-2027',
      department: json['department'] as String? ?? 'CSE',
      departmentName: json['departmentName'] as String? ??
          'Computer Science and Engineering',
      program: json['program'] as String? ?? 'B.Tech CSE',
      section: json['section'] as String? ?? 'A',
      className: json['class'] as String? ?? 'IV CSE A',
      academicHeader: json['academicHeader'] as String? ??
          'IV Year • VII Semester | 2026–27 | CSE • Section A',
      status: json['status'] as String? ?? 'ACTIVE',
      hasOverride: json['hasOverride'] as bool? ?? false,
      overrideReason: json['overrideReason'] as String?,
      subjects: (json['subjects'] as List<dynamic>? ?? [])
          .map((e) => AcademicSubjectModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
