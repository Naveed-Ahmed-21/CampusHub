class DetailedStudentProfile {
  final ProfileOverview overview;
  final OfficialIdentity officialIdentity;
  final PersonalInfo personal;
  final FamilyInfo family;
  final AddressInfo address;
  final EmergencyInfo emergency;
  final EducationInfo education;
  final CareerInfo career;
  final Map<String, String> fieldPolicies;

  const DetailedStudentProfile({
    required this.overview,
    required this.officialIdentity,
    required this.personal,
    required this.family,
    required this.address,
    required this.emergency,
    required this.education,
    required this.career,
    required this.fieldPolicies,
  });

  factory DetailedStudentProfile.fromJson(Map<String, dynamic> json) {
    return DetailedStudentProfile(
      overview: ProfileOverview.fromJson(json['overview'] as Map<String, dynamic>? ?? {}),
      officialIdentity: OfficialIdentity.fromJson(json['officialIdentity'] as Map<String, dynamic>? ?? {}),
      personal: PersonalInfo.fromJson(json['personal'] as Map<String, dynamic>? ?? {}),
      family: FamilyInfo.fromJson(json['family'] as Map<String, dynamic>? ?? {}),
      address: AddressInfo.fromJson(json['address'] as Map<String, dynamic>? ?? {}),
      emergency: EmergencyInfo.fromJson(json['emergency'] as Map<String, dynamic>? ?? {}),
      education: EducationInfo.fromJson(json['education'] as Map<String, dynamic>? ?? {}),
      career: CareerInfo.fromJson(json['career'] as Map<String, dynamic>? ?? {}),
      fieldPolicies: Map<String, String>.from(json['fieldPolicies'] as Map? ?? {}),
    );
  }
}

class ProfileOverview {
  final String userId;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String role;
  final String status;
  final bool isProfileCompleted;
  final int completionPercentage;
  final List<String> badges;

  const ProfileOverview({
    required this.userId,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    required this.role,
    required this.status,
    required this.isProfileCompleted,
    required this.completionPercentage,
    required this.badges,
  });

  factory ProfileOverview.fromJson(Map<String, dynamic> json) {
    return ProfileOverview(
      userId: json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String? ?? 'STUDENT',
      status: json['status'] as String? ?? 'ACTIVE',
      isProfileCompleted: json['isProfileCompleted'] as bool? ?? false,
      completionPercentage: (json['completionPercentage'] as num?)?.toInt() ?? 0,
      badges: (json['badges'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class OfficialIdentity {
  final String? rollNumber;
  final String? registrationNumber;
  final String? departmentName;
  final String? departmentCode;
  final String? programName;
  final String? batchName;
  final String? section;
  final String? currentStatus;
  final int? admissionYear;

  const OfficialIdentity({
    this.rollNumber,
    this.registrationNumber,
    this.departmentName,
    this.departmentCode,
    this.programName,
    this.batchName,
    this.section,
    this.currentStatus,
    this.admissionYear,
  });

  factory OfficialIdentity.fromJson(Map<String, dynamic> json) {
    return OfficialIdentity(
      rollNumber: json['rollNumber'] as String?,
      registrationNumber: json['registrationNumber'] as String?,
      departmentName: json['departmentName'] as String?,
      departmentCode: json['departmentCode'] as String?,
      programName: json['programName'] as String?,
      batchName: json['batchName'] as String?,
      section: json['section'] as String?,
      currentStatus: json['currentStatus'] as String?,
      admissionYear: (json['admissionYear'] as num?)?.toInt(),
    );
  }
}

class PersonalInfo {
  final String firstName;
  final String lastName;
  final String? dob;
  final int? age;
  final String? bloodGroup;
  final String? phone;
  final String email;

  const PersonalInfo({
    required this.firstName,
    required this.lastName,
    this.dob,
    this.age,
    this.bloodGroup,
    this.phone,
    required this.email,
  });

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      dob: json['dob'] as String?,
      age: (json['age'] as num?)?.toInt(),
      bloodGroup: json['bloodGroup'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String? ?? '',
    );
  }
}

class FamilyInfo {
  final String? fatherName;
  final String? fatherPhone;
  final String? motherName;
  final String? motherPhone;
  final String? guardianName;
  final String? guardianPhone;

  const FamilyInfo({
    this.fatherName,
    this.fatherPhone,
    this.motherName,
    this.motherPhone,
    this.guardianName,
    this.guardianPhone,
  });

  factory FamilyInfo.fromJson(Map<String, dynamic> json) {
    return FamilyInfo(
      fatherName: json['fatherName'] as String?,
      fatherPhone: json['fatherPhone'] as String?,
      motherName: json['motherName'] as String?,
      motherPhone: json['motherPhone'] as String?,
      guardianName: json['guardianName'] as String?,
      guardianPhone: json['guardianPhone'] as String?,
    );
  }
}

class AddressInfo {
  final String? permanentAddress;
  final String? permanentCity;
  final String? permanentState;
  final String? permanentPincode;
  final String? currentAddress;

  const AddressInfo({
    this.permanentAddress,
    this.permanentCity,
    this.permanentState,
    this.permanentPincode,
    this.currentAddress,
  });

  factory AddressInfo.fromJson(Map<String, dynamic> json) {
    return AddressInfo(
      permanentAddress: json['permanentAddress'] as String?,
      permanentCity: json['permanentCity'] as String?,
      permanentState: json['permanentState'] as String?,
      permanentPincode: json['permanentPincode'] as String?,
      currentAddress: json['currentAddress'] as String?,
    );
  }

  String get fullPermanentAddress {
    final parts = [permanentAddress, permanentCity, permanentState, permanentPincode]
        .where((p) => p != null && p.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? 'Not set' : parts.join(', ');
  }
}

class EmergencyInfo {
  final String? contactName;
  final String? contactRelation;
  final String? contactPhone;

  const EmergencyInfo({
    this.contactName,
    this.contactRelation,
    this.contactPhone,
  });

  factory EmergencyInfo.fromJson(Map<String, dynamic> json) {
    return EmergencyInfo(
      contactName: json['contactName'] as String?,
      contactRelation: json['contactRelation'] as String?,
      contactPhone: json['contactPhone'] as String?,
    );
  }
}

class EducationInfo {
  final double? tenthPercentage;
  final double? twelfthPercentage;

  const EducationInfo({
    this.tenthPercentage,
    this.twelfthPercentage,
  });

  factory EducationInfo.fromJson(Map<String, dynamic> json) {
    return EducationInfo(
      tenthPercentage: (json['tenthPercentage'] as num?)?.toDouble(),
      twelfthPercentage: (json['twelfthPercentage'] as num?)?.toDouble(),
    );
  }
}

class CareerInfo {
  final String? bio;
  final List<CareerSkill> skills;
  final List<CareerProject> projects;
  final String? githubUrl;
  final String? linkedinUrl;
  final String? websiteUrl;
  final String? resumeUrl;

  const CareerInfo({
    this.bio,
    required this.skills,
    required this.projects,
    this.githubUrl,
    this.linkedinUrl,
    this.websiteUrl,
    this.resumeUrl,
  });

  factory CareerInfo.fromJson(Map<String, dynamic> json) {
    return CareerInfo(
      bio: json['bio'] as String?,
      skills: (json['skills'] as List?)
              ?.map((s) => CareerSkill.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      projects: (json['projects'] as List?)
              ?.map((p) => CareerProject.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      githubUrl: json['githubUrl'] as String?,
      linkedinUrl: json['linkedinUrl'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      resumeUrl: json['resumeUrl'] as String?,
    );
  }
}

class CareerSkill {
  final String id;
  final String skillName;
  final String? proficiency;

  const CareerSkill({
    required this.id,
    required this.skillName,
    this.proficiency,
  });

  factory CareerSkill.fromJson(Map<String, dynamic> json) {
    return CareerSkill(
      id: json['id'] as String? ?? '',
      skillName: json['skillName'] as String? ?? '',
      proficiency: json['proficiency'] as String?,
    );
  }
}

class CareerProject {
  final String id;
  final String title;
  final String? description;
  final String? projectUrl;
  final String? repoUrl;

  const CareerProject({
    required this.id,
    required this.title,
    this.description,
    this.projectUrl,
    this.repoUrl,
  });

  factory CareerProject.fromJson(Map<String, dynamic> json) {
    return CareerProject(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      projectUrl: json['projectUrl'] as String?,
      repoUrl: json['repoUrl'] as String?,
    );
  }
}

class ProfileChangeRequestItem {
  final String id;
  final String field;
  final String category;
  final String currentValue;
  final String requestedValue;
  final String reason;
  final String? supportingDocument;
  final String status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewComment;
  final String? reviewerName;

  const ProfileChangeRequestItem({
    required this.id,
    required this.field,
    required this.category,
    required this.currentValue,
    required this.requestedValue,
    required this.reason,
    this.supportingDocument,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewComment,
    this.reviewerName,
  });

  factory ProfileChangeRequestItem.fromJson(Map<String, dynamic> json) {
    final reviewer = json['reviewer'] as Map<String, dynamic>?;
    final rName = reviewer != null
        ? '${reviewer['first_name'] ?? ''} ${reviewer['last_name'] ?? ''}'.trim()
        : null;

    return ProfileChangeRequestItem(
      id: json['id'] as String? ?? '',
      field: json['field'] as String? ?? '',
      category: json['category'] as String? ?? 'PERSONAL_CHANGE',
      currentValue: json['current_value'] as String? ?? json['currentValue'] as String? ?? '',
      requestedValue: json['requested_value'] as String? ?? json['requestedValue'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      supportingDocument: json['supporting_document'] as String? ?? json['supportingDocument'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      submittedAt: DateTime.tryParse(json['submitted_at']?.toString() ?? '') ?? DateTime.now(),
      reviewedAt: json['reviewed_at'] != null ? DateTime.tryParse(json['reviewed_at'].toString()) : null,
      reviewComment: json['review_comment'] as String? ?? json['reviewComment'] as String?,
      reviewerName: rName,
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';
  bool get isCancelled => status == 'CANCELLED';
}
