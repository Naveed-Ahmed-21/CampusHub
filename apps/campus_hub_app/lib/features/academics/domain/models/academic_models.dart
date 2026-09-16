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
      faculty: AcademicFacultySummary.fromJson(json['faculty'] as Map<String, dynamic>? ?? {}),
      resourcesCount: (json['resourcesCount'] as num?)?.toInt() ?? 0,
      unitsCount: (json['unitsCount'] as num?)?.toInt() ?? 0,
      units: (json['units'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
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
        parsedByUnit[key] = list.map((e) => SubjectResource.fromJson(e as Map<String, dynamic>)).toList();
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
      faculty: AcademicFacultyFull.fromJson(json['faculty'] as Map<String, dynamic>? ?? {}),
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
      department: json['department'] as String? ?? 'Department of Computer Science',
      specialization: json['specialization'] as String? ?? 'Distributed Systems',
      officeRoom: json['officeRoom'] as String? ?? 'Room 304, Block B',
      officeHours: json['officeHours'] as String? ?? 'Mon - Thu: 2:00 PM - 4:00 PM',
      bio: json['bio'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      expertise: (json['expertise'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      publications: (json['publications'] as List<dynamic>? ?? []).map((e) => e as Map<String, dynamic>).toList(),
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
