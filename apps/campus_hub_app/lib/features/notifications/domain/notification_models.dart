class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String
      type; // SYSTEM, ANNOUNCEMENT, EVENT_REMINDER, CHAT_MESSAGE, PLACEMENT_UPDATE, LIKE, COMMENT
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
    DateTime parseDate(dynamic d) {
      if (d is DateTime) return d;
      if (d is String && d.isNotEmpty) {
        try {
          return DateTime.parse(d);
        } catch (_) {}
      }
      return DateTime.now();
    }

    return NotificationModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      type: (json['type'] ?? 'SYSTEM').toString(),
      category: (json['category'] ?? 'General').toString(),
      deepLink: json['deep_link']?.toString() ?? json['deepLink']?.toString(),
      isRead: json['is_read'] == true || json['isRead'] == true,
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : null,
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
    );
  }
}
