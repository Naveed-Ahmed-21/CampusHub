class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // SYSTEM, ANNOUNCEMENT, EVENT_REMINDER, CHAT_MESSAGE, PLACEMENT_UPDATE, LIKE, COMMENT
  final String category;
  final String? deepLink;
  final bool isRead;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.category = 'General',
    this.deepLink,
    this.isRead = false,
    this.metadata,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'SYSTEM',
      category: json['category'] ?? 'General',
      deepLink: json['deep_link'],
      isRead: json['is_read'] ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}
