class PostAttachmentItem {
  final String id;
  final String fileName;
  final String fileUrl;
  final String fileType;

  const PostAttachmentItem({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
  });

  factory PostAttachmentItem.fromJson(Map<String, dynamic> json) {
    return PostAttachmentItem(
      id: json['id'] as String? ?? '',
      fileName: json['fileName'] as String? ?? json['file_name'] as String? ?? '',
      fileUrl: json['fileUrl'] as String? ?? json['file_url'] as String? ?? '',
      fileType: json['fileType'] as String? ?? json['file_type'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'fileUrl': fileUrl,
        'fileType': fileType,
      };
}

class PostAuthorItem {
  final String id;
  final String name;
  final String? avatarUrl;
  final String role;

  const PostAuthorItem({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.role,
  });

  factory PostAuthorItem.fromJson(Map<String, dynamic> json) {
    return PostAuthorItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ??
          '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'STUDENT',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarUrl': avatarUrl,
        'role': role,
      };
}

class PostCommentItem {
  final String id;
  final String? parentCommentId;
  final String content;
  final String createdAt;
  final PostAuthorItem author;
  final int likesCount;
  final bool isLiked;
  final int repliesCount;
  final List<PostCommentItem> replies;

  const PostCommentItem({
    required this.id,
    this.parentCommentId,
    required this.content,
    required this.createdAt,
    required this.author,
    this.likesCount = 0,
    this.isLiked = false,
    this.repliesCount = 0,
    this.replies = const [],
  });

  factory PostCommentItem.fromJson(Map<String, dynamic> json) {
    final rawReplies = json['replies'] as List<dynamic>? ?? [];
    return PostCommentItem(
      id: json['id'] as String? ?? '',
      parentCommentId: json['parentCommentId'] as String? ?? json['parent_id'] as String?,
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String? ?? '',
      author: json['author'] != null
          ? PostAuthorItem.fromJson(json['author'] as Map<String, dynamic>)
          : (json['user'] != null
              ? PostAuthorItem.fromJson(json['user'] as Map<String, dynamic>)
              : const PostAuthorItem(id: '', name: 'Anonymous', role: 'STUDENT')),
      likesCount: json['likesCount'] as int? ?? json['likes_count'] as int? ?? (json['_count']?['likes'] as int? ?? 0),
      isLiked: json['isLiked'] as bool? ?? json['is_liked'] as bool? ?? false,
      repliesCount: json['repliesCount'] as int? ?? json['replies_count'] as int? ?? (json['_count']?['replies'] as int? ?? 0),
      replies: rawReplies
          .map((r) => PostCommentItem.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  PostCommentItem copyWith({
    String? id,
    String? parentCommentId,
    String? content,
    String? createdAt,
    PostAuthorItem? author,
    int? likesCount,
    bool? isLiked,
    int? repliesCount,
    List<PostCommentItem>? replies,
  }) {
    return PostCommentItem(
      id: id ?? this.id,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      author: author ?? this.author,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      repliesCount: repliesCount ?? this.repliesCount,
      replies: replies ?? this.replies,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'parentCommentId': parentCommentId,
        'content': content,
        'createdAt': createdAt,
        'author': author.toJson(),
        'likesCount': likesCount,
        'isLiked': isLiked,
        'repliesCount': repliesCount,
        'replies': replies.map((r) => r.toJson()).toList(),
      };
}

class PostItem {
  final String id;
  final String title;
  final String content;
  final String type;
  final bool isPinned;
  final String createdAt;
  final PostAuthorItem author;
  final List<PostAttachmentItem> attachments;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isSaved;
  final String? departmentId;
  final bool isCrossDepartment;
  final String? clubId;
  final String? clubName;
  final String? clubLogoUrl;
  final String? clubCategory;

  const PostItem({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.isPinned = false,
    required this.createdAt,
    required this.author,
    this.attachments = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.departmentId,
    this.isCrossDepartment = false,
    this.clubId,
    this.clubName,
    this.clubLogoUrl,
    this.clubCategory,
  });

  factory PostItem.fromJson(Map<String, dynamic> json) {
    final rawAttachments = json['attachments'] as List<dynamic>? ?? [];
    final deptId = json['departmentId'] as String? ?? json['department_id'] as String?;
    final club = json['club'] as Map<String, dynamic>?;
    final cId = json['clubId'] as String? ?? json['club_id'] as String? ?? club?['id'] as String?;
    final cName = json['clubName'] as String? ?? json['club_name'] as String? ?? club?['name'] as String?;
    final cLogo = json['clubLogoUrl'] as String? ?? json['club_logo_url'] as String? ?? club?['logo_url'] as String?;
    final cCat = json['clubCategory'] as String? ?? json['club_category'] as String? ?? club?['category'] as String?;

    final isCross = json['isCrossDepartment'] as bool? ??
        json['is_cross_department'] as bool? ??
        (deptId == null && cId == null);

    return PostItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      type: json['type'] as String? ?? 'GENERAL',
      isPinned: json['isPinned'] as bool? ?? json['is_pinned'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String? ?? '',
      author: json['author'] != null
          ? PostAuthorItem.fromJson(json['author'] as Map<String, dynamic>)
          : (json['user'] != null
              ? PostAuthorItem.fromJson(json['user'] as Map<String, dynamic>)
              : const PostAuthorItem(id: '', name: 'CampusHub User', role: 'STUDENT')),
      attachments: rawAttachments
          .map((a) => PostAttachmentItem.fromJson(a as Map<String, dynamic>))
          .toList(),
      likesCount: json['likesCount'] as int? ?? json['likes_count'] as int? ?? (json['_count']?['likes'] as int? ?? 0),
      commentsCount: json['commentsCount'] as int? ?? json['comments_count'] as int? ?? (json['_count']?['comments'] as int? ?? 0),
      isLiked: json['isLiked'] as bool? ?? json['is_liked'] as bool? ?? false,
      isSaved: json['isSaved'] as bool? ?? json['is_saved'] as bool? ?? false,
      departmentId: deptId,
      isCrossDepartment: isCross,
      clubId: cId,
      clubName: cName,
      clubLogoUrl: cLogo,
      clubCategory: cCat,
    );
  }

  PostItem copyWith({
    String? id,
    String? title,
    String? content,
    String? type,
    bool? isPinned,
    String? createdAt,
    PostAuthorItem? author,
    List<PostAttachmentItem>? attachments,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    bool? isSaved,
    String? departmentId,
    bool? isCrossDepartment,
    String? clubId,
    String? clubName,
    String? clubLogoUrl,
    String? clubCategory,
  }) {
    return PostItem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      author: author ?? this.author,
      attachments: attachments ?? this.attachments,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      departmentId: departmentId ?? this.departmentId,
      isCrossDepartment: isCrossDepartment ?? this.isCrossDepartment,
      clubId: clubId ?? this.clubId,
      clubName: clubName ?? this.clubName,
      clubLogoUrl: clubLogoUrl ?? this.clubLogoUrl,
      clubCategory: clubCategory ?? this.clubCategory,
    );
  }
}
