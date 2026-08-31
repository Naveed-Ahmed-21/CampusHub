class StoryItemModel {
  final String id;
  final String mediaUrl;
  final String mediaType;
  final String? caption;
  final int duration;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isViewed;
  final int viewsCount;

  const StoryItemModel({
    required this.id,
    required this.mediaUrl,
    this.mediaType = 'IMAGE',
    this.caption,
    this.duration = 5,
    required this.createdAt,
    required this.expiresAt,
    this.isViewed = false,
    this.viewsCount = 0,
  });

  factory StoryItemModel.fromJson(Map<String, dynamic> json) {
    return StoryItemModel(
      id: json['id'] as String? ?? '',
      mediaUrl: json['mediaUrl'] as String? ?? json['media_url'] as String? ?? '',
      mediaType: json['mediaType'] as String? ?? json['media_type'] as String? ?? 'IMAGE',
      caption: json['caption'] as String?,
      duration: json['duration'] as int? ?? 5,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now()),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString()) ?? DateTime.now().add(const Duration(hours: 24))
          : (json['expires_at'] != null ? DateTime.tryParse(json['expires_at'].toString()) ?? DateTime.now().add(const Duration(hours: 24)) : DateTime.now().add(const Duration(hours: 24))),
      isViewed: json['isViewed'] as bool? ?? json['is_viewed'] as bool? ?? false,
      viewsCount: json['viewsCount'] as int? ?? json['views_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'caption': caption,
        'duration': duration,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'isViewed': isViewed,
        'viewsCount': viewsCount,
      };

  StoryItemModel copyWith({
    String? id,
    String? mediaUrl,
    String? mediaType,
    String? caption,
    int? duration,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isViewed,
    int? viewsCount,
  }) {
    return StoryItemModel(
      id: id ?? this.id,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      caption: caption ?? this.caption,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isViewed: isViewed ?? this.isViewed,
      viewsCount: viewsCount ?? this.viewsCount,
    );
  }
}

class UserStoriesGroup {
  final String userId;
  final String userName;
  final String? userAvatar;
  final String userRole;
  final bool hasUnseenStories;
  final DateTime latestStoryCreatedAt;
  final List<StoryItemModel> stories;

  const UserStoriesGroup({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.userRole,
    this.hasUnseenStories = false,
    required this.latestStoryCreatedAt,
    required this.stories,
  });

  factory UserStoriesGroup.fromJson(Map<String, dynamic> json) {
    final rawStories = json['stories'] as List<dynamic>? ?? [];
    return UserStoriesGroup(
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      userName: json['userName'] as String? ?? json['user_name'] as String? ?? 'Campus Member',
      userAvatar: json['userAvatar'] as String? ?? json['user_avatar'] as String?,
      userRole: json['userRole'] as String? ?? json['user_role'] as String? ?? 'STUDENT',
      hasUnseenStories: json['hasUnseenStories'] as bool? ?? json['has_unseen_stories'] as bool? ?? false,
      latestStoryCreatedAt: json['latestStoryCreatedAt'] != null
          ? DateTime.tryParse(json['latestStoryCreatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      stories: rawStories.map((s) => StoryItemModel.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }

  UserStoriesGroup copyWith({
    String? userId,
    String? userName,
    String? userAvatar,
    String? userRole,
    bool? hasUnseenStories,
    DateTime? latestStoryCreatedAt,
    List<StoryItemModel>? stories,
  }) {
    return UserStoriesGroup(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      userRole: userRole ?? this.userRole,
      hasUnseenStories: hasUnseenStories ?? this.hasUnseenStories,
      latestStoryCreatedAt: latestStoryCreatedAt ?? this.latestStoryCreatedAt,
      stories: stories ?? this.stories,
    );
  }
}
