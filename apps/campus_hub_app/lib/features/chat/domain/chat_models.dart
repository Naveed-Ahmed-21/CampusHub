class ChatParticipantUser {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeen;

  ChatParticipantUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeen,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ChatParticipantUser.fromJson(Map<String, dynamic> json) {
    return ChatParticipantUser(
      id: json['id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatar_url'],
      isOnline: json['is_online'] ?? false,
      lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen']) : null,
    );
  }
}

class ChatRoomModel {
  final String id;
  final String collegeId;
  final String? clubId;
  final String? departmentId;
  final String? name;
  final String type; // DIRECT, GROUP, ANNOUNCEMENT
  final DateTime? lastMessageAt;
  final List<ChatParticipantUser> participants;
  final ChatMessageModel? lastMessage;

  ChatRoomModel({
    required this.id,
    required this.collegeId,
    this.clubId,
    this.departmentId,
    this.name,
    required this.type,
    this.lastMessageAt,
    this.participants = const [],
    this.lastMessage,
  });

  String getDisplayName(String currentUserId) {
    if (type == 'DIRECT') {
      final other = participants.firstWhere(
        (p) => p.id != currentUserId,
        orElse: () => participants.isNotEmpty
            ? participants.first
            : ChatParticipantUser(id: '', firstName: 'User', lastName: '', email: ''),
      );
      return other.fullName;
    }
    return name ?? (type == 'GROUP' ? 'Group Chat' : 'Announcement Room');
  }

  ChatParticipantUser? getOtherParticipant(String currentUserId) {
    if (type != 'DIRECT') return null;
    try {
      return participants.firstWhere((p) => p.id != currentUserId);
    } catch (_) {
      return null;
    }
  }

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    final rawParticipants = json['participants'] as List<dynamic>? ?? [];
    final participantUsers = rawParticipants
        .map((p) => ChatParticipantUser.fromJson(p['user'] ?? p))
        .toList();

    final rawMessages = json['messages'] as List<dynamic>? ?? [];
    final lastMsg = rawMessages.isNotEmpty ? ChatMessageModel.fromJson(rawMessages.first) : null;

    return ChatRoomModel(
      id: json['id'] ?? '',
      collegeId: json['college_id'] ?? '',
      clubId: json['club_id'],
      departmentId: json['department_id'],
      name: json['name'],
      type: json['type'] ?? 'DIRECT',
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      participants: participantUsers,
      lastMessage: lastMsg,
    );
  }
}

class ChatMessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String message;
  final String? mediaUrl;
  final String? mediaType; // IMAGE, DOCUMENT, AUDIO
  final String? fileName;
  final int? fileSize;
  final DateTime createdAt;
  final List<String> readByUserIdList;

  ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.message,
    this.mediaUrl,
    this.mediaType,
    this.fileName,
    this.fileSize,
    required this.createdAt,
    this.readByUserIdList = const [],
  });

  bool isReadBy(String userId) => readByUserIdList.contains(userId);

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>? ?? {};
    final receipts = json['read_receipts'] as List<dynamic>? ?? [];

    final readUsers = receipts.map((r) => r['user_id'] as String? ?? '').where((id) => id.isNotEmpty).toList();

    return ChatMessageModel(
      id: json['id'] ?? '',
      roomId: json['room_id'] ?? '',
      senderId: json['sender_id'] ?? sender['id'] ?? '',
      senderName: '${sender['first_name'] ?? ''} ${sender['last_name'] ?? ''}'.trim(),
      senderAvatarUrl: sender['avatar_url'],
      message: json['message'] ?? '',
      mediaUrl: json['media_url'],
      mediaType: json['media_type'],
      fileName: json['file_name'],
      fileSize: json['file_size'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      readByUserIdList: readUsers,
    );
  }
}
