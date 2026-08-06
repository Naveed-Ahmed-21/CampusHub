class Club {
  final String id;
  final String collegeId;
  final String name;
  final String category;
  final String? description;
  final String? logoUrl;
  final String status; // PENDING, APPROVED, REJECTED
  final bool isCrossDepartment;
  final bool isActive;
  final String? createdById;
  final String? verifierId;
  final String? rejectionReason;
  final DateTime createdAt;
  final int memberCount;
  final int eventCount;
  final int postCount;
  final int resourceCount;
  final String? creatorName;

  Club({
    required this.id,
    required this.collegeId,
    required this.name,
    required this.category,
    this.description,
    this.logoUrl,
    required this.status,
    this.isCrossDepartment = true,
    this.isActive = true,
    this.createdById,
    this.verifierId,
    this.rejectionReason,
    required this.createdAt,
    this.memberCount = 0,
    this.eventCount = 0,
    this.postCount = 0,
    this.resourceCount = 0,
    this.creatorName,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    final count = json['_count'] as Map<String, dynamic>?;
    final creator = json['creator'] as Map<String, dynamic>?;
    final creatorName = creator != null
        ? '${creator['first_name'] ?? ''} ${creator['last_name'] ?? ''}'.trim()
        : null;

    return Club(
      id: json['id'] ?? '',
      collegeId: json['college_id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'General',
      description: json['description'],
      logoUrl: json['logo_url'],
      status: json['status'] ?? 'PENDING',
      isCrossDepartment: json['is_cross_department'] ?? true,
      isActive: json['is_active'] ?? true,
      createdById: json['created_by_id'],
      verifierId: json['verified_by_id'],
      rejectionReason: json['rejection_reason'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      memberCount: count?['members'] ?? 0,
      eventCount: count?['events'] ?? 0,
      postCount: count?['posts'] ?? 0,
      resourceCount: count?['resources'] ?? 0,
      creatorName: creatorName,
    );
  }
}

class ClubMember {
  final String id;
  final String clubId;
  final String userId;
  final String role; // MEMBER, LEAD, FACULTY_ADVISOR
  final DateTime joinedAt;
  final String firstName;
  final String lastName;
  final String email;
  final String? avatarUrl;
  final String? userRole;
  final String? departmentName;

  ClubMember({
    required this.id,
    required this.clubId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.avatarUrl,
    this.userRole,
    this.departmentName,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ClubMember.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final dept = user['department'] as Map<String, dynamic>?;

    return ClubMember(
      id: json['id'] ?? '',
      clubId: json['club_id'] ?? '',
      userId: json['user_id'] ?? user['id'] ?? '',
      role: json['role'] ?? 'MEMBER',
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'])
          : DateTime.now(),
      firstName: user['first_name'] ?? '',
      lastName: user['last_name'] ?? '',
      email: user['email'] ?? '',
      avatarUrl: user['avatar_url'],
      userRole: user['role'],
      departmentName: dept?['name'],
    );
  }
}

class ClubPost {
  final String id;
  final String clubId;
  final String authorId;
  final String title;
  final String content;
  final String type;
  final DateTime createdAt;
  final String authorName;
  final String? authorAvatarUrl;
  final int likeCount;
  final int commentCount;
  final bool isLikedByMe;

  ClubPost({
    required this.id,
    required this.clubId,
    required this.authorId,
    required this.title,
    required this.content,
    this.type = 'GENERAL',
    required this.createdAt,
    required this.authorName,
    this.authorAvatarUrl,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLikedByMe = false,
  });

  factory ClubPost.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>? ?? {};
    final count = json['_count'] as Map<String, dynamic>?;
    final likes = json['likes'] as List<dynamic>?;

    return ClubPost(
      id: json['id'] ?? '',
      clubId: json['club_id'] ?? '',
      authorId: json['author_id'] ?? author['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'GENERAL',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      authorName: '${author['first_name'] ?? ''} ${author['last_name'] ?? ''}'.trim(),
      authorAvatarUrl: author['avatar_url'],
      likeCount: count?['likes'] ?? 0,
      commentCount: count?['comments'] ?? 0,
      isLikedByMe: likes != null && likes.isNotEmpty,
    );
  }
}

class ClubEvent {
  final String id;
  final String clubId;
  final String organizerId;
  final String title;
  final String? description;
  final String? venue;
  final DateTime startTime;
  final DateTime endTime;
  final String? bannerUrl;
  final String organizerName;
  final int registrationCount;

  ClubEvent({
    required this.id,
    required this.clubId,
    required this.organizerId,
    required this.title,
    this.description,
    this.venue,
    required this.startTime,
    required this.endTime,
    this.bannerUrl,
    required this.organizerName,
    this.registrationCount = 0,
  });

  factory ClubEvent.fromJson(Map<String, dynamic> json) {
    final organizer = json['organizer'] as Map<String, dynamic>? ?? {};
    final count = json['_count'] as Map<String, dynamic>?;

    return ClubEvent(
      id: json['id'] ?? '',
      clubId: json['club_id'] ?? '',
      organizerId: json['organizer_id'] ?? organizer['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      venue: json['venue'],
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : DateTime.now(),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : DateTime.now().add(const Duration(hours: 2)),
      bannerUrl: json['banner_url'],
      organizerName: '${organizer['first_name'] ?? ''} ${organizer['last_name'] ?? ''}'.trim(),
      registrationCount: count?['registrations'] ?? 0,
    );
  }
}

class ClubResource {
  final String id;
  final String clubId;
  final String uploadedById;
  final String title;
  final String? description;
  final String fileUrl;
  final String fileName;
  final String fileType;
  final DateTime createdAt;
  final String uploaderName;

  ClubResource({
    required this.id,
    required this.clubId,
    required this.uploadedById,
    required this.title,
    this.description,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.createdAt,
    required this.uploaderName,
  });

  factory ClubResource.fromJson(Map<String, dynamic> json) {
    final uploader = json['uploaded_by'] as Map<String, dynamic>? ?? {};

    return ClubResource(
      id: json['id'] ?? '',
      clubId: json['club_id'] ?? '',
      uploadedById: json['uploaded_by_id'] ?? uploader['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      fileUrl: json['file_url'] ?? '',
      fileName: json['file_name'] ?? '',
      fileType: json['file_type'] ?? 'document',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      uploaderName: '${uploader['first_name'] ?? ''} ${uploader['last_name'] ?? ''}'.trim(),
    );
  }
}

class ClubChatMessage {
  final String id;
  final String senderId;
  final String message;
  final DateTime createdAt;
  final String senderName;
  final String? senderAvatarUrl;

  ClubChatMessage({
    required this.id,
    required this.senderId,
    required this.message,
    required this.createdAt,
    required this.senderName,
    this.senderAvatarUrl,
  });

  factory ClubChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>? ?? {};

    return ClubChatMessage(
      id: json['id'] ?? '',
      senderId: json['sender_id'] ?? sender['id'] ?? '',
      message: json['message'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      senderName: '${sender['first_name'] ?? ''} ${sender['last_name'] ?? ''}'.trim(),
      senderAvatarUrl: sender['avatar_url'],
    );
  }
}
