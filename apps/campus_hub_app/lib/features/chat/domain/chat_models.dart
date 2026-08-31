class ChatParticipantUser {
  final String id;
  final String? username;
  final String firstName;
  final String lastName;
  final String email;
  final String? avatarUrl;
  final String role;
  final String? departmentName;
  final bool isOnline;
  final DateTime? lastSeen;

  ChatParticipantUser({
    required this.id,
    this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.avatarUrl,
    this.role = 'STUDENT',
    this.departmentName,
    this.isOnline = false,
    this.lastSeen,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get displayUsername => username != null && username!.isNotEmpty
      ? (username!.startsWith('@') ? username! : '@$username')
      : (email.isNotEmpty ? '@${email.split('@').first}' : '@user');

  factory ChatParticipantUser.fromJson(Map<String, dynamic> json) {
    final dept = json['department'];
    final dName = dept is Map ? dept['name'] as String? : (dept is String ? dept : null);
    final emailStr = json['email'] as String? ?? '';
    final rawUsername = json['username'] as String?;
    final resolvedUsername = rawUsername ?? (emailStr.isNotEmpty ? '@${emailStr.split('@').first}' : null);

    return ChatParticipantUser(
      id: json['id'] ?? '',
      username: resolvedUsername,
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      email: emailStr,
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
      role: json['role'] ?? 'STUDENT',
      departmentName: dName,
      isOnline: json['is_online'] ?? json['isOnline'] ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTime.tryParse(json['last_seen'])?.toLocal()
          : (json['lastSeen'] != null ? DateTime.tryParse(json['lastSeen'])?.toLocal() : null),
    );
  }
}

class ChatRoomModel {
  final String id;
  final String collegeId;
  final String? clubId;
  final String? departmentId;
  final String? name;
  final String? description;
  final String? avatarUrl;
  final String type; // DIRECT, GROUP, ANNOUNCEMENT
  final bool isPrivate;
  final String? createdById;
  final int memberCount;
  final int onlineMemberCount;
  final bool isMember;
  final int unreadCount;
  final DateTime? lastMessageAt;
  final List<ChatParticipantUser> participants;
  final ChatMessageModel? lastMessage;

  ChatRoomModel({
    required this.id,
    required this.collegeId,
    this.clubId,
    this.departmentId,
    this.name,
    this.description,
    this.avatarUrl,
    required this.type,
    this.isPrivate = false,
    this.createdById,
    this.memberCount = 0,
    this.onlineMemberCount = 0,
    this.isMember = true,
    this.unreadCount = 0,
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

  ChatRoomModel copyWith({
    String? id,
    String? collegeId,
    String? clubId,
    String? departmentId,
    String? name,
    String? description,
    String? avatarUrl,
    String? type,
    bool? isPrivate,
    String? createdById,
    int? memberCount,
    int? onlineMemberCount,
    bool? isMember,
    int? unreadCount,
    DateTime? lastMessageAt,
    List<ChatParticipantUser>? participants,
    ChatMessageModel? lastMessage,
  }) {
    return ChatRoomModel(
      id: id ?? this.id,
      collegeId: collegeId ?? this.collegeId,
      clubId: clubId ?? this.clubId,
      departmentId: departmentId ?? this.departmentId,
      name: name ?? this.name,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      type: type ?? this.type,
      isPrivate: isPrivate ?? this.isPrivate,
      createdById: createdById ?? this.createdById,
      memberCount: memberCount ?? this.memberCount,
      onlineMemberCount: onlineMemberCount ?? this.onlineMemberCount,
      isMember: isMember ?? this.isMember,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    final rawParticipants = (json['participants'] as List<dynamic>? ?? []);
    final participantUsers = rawParticipants
        .map((p) {
          if (p is Map<String, dynamic>) {
            if (p.containsKey('user')) {
              return ChatParticipantUser.fromJson(p['user'] as Map<String, dynamic>);
            }
            return ChatParticipantUser.fromJson(p);
          }
          return null;
        })
        .whereType<ChatParticipantUser>()
        .toList();

    final rawMessages = json['messages'] as List<dynamic>? ?? [];
    final lastMsg = rawMessages.isNotEmpty
        ? ChatMessageModel.fromJson(rawMessages.first)
        : (json['lastMessage'] != null ? ChatMessageModel.fromJson(json['lastMessage']) : null);

    final onlineCount = json['onlineMemberCount'] as int? ??
        participantUsers.where((p) => p.isOnline).length;

    DateTime? parsedLastMsgAt;
    if (json['last_message_at'] != null) {
      parsedLastMsgAt = DateTime.tryParse(json['last_message_at'].toString())?.toLocal();
    } else if (json['lastMessageAt'] != null) {
      parsedLastMsgAt = DateTime.tryParse(json['lastMessageAt'].toString())?.toLocal();
    } else if (lastMsg != null) {
      parsedLastMsgAt = lastMsg.createdAt;
    }

    return ChatRoomModel(
      id: json['id'] ?? '',
      collegeId: json['college_id'] ?? json['collegeId'] ?? '',
      clubId: json['club_id'] ?? json['clubId'],
      departmentId: json['department_id'] ?? json['departmentId'],
      name: json['name'],
      description: json['description'],
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
      type: json['type'] ?? 'DIRECT',
      isPrivate: json['is_private'] ?? json['isPrivate'] ?? false,
      createdById: json['created_by_id'] ?? json['createdById'],
      memberCount: json['memberCount'] ?? json['member_count'] ?? participantUsers.length,
      onlineMemberCount: onlineCount,
      isMember: json['isMember'] ?? json['is_member'] ?? true,
      unreadCount: json['unreadCount'] ?? json['unread_count'] ?? 0,
      lastMessageAt: parsedLastMsgAt,
      participants: participantUsers,
      lastMessage: lastMsg,
    );
  }
}

class ChatReplyToModel {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final String? mediaType;
  final String? fileName;
  final bool isDeletedForEveryone;

  const ChatReplyToModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    this.mediaType,
    this.fileName,
    this.isDeletedForEveryone = false,
  });

  factory ChatReplyToModel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    final senderName = json['senderName'] ??
        (sender != null
            ? '${sender['first_name'] ?? ''} ${sender['last_name'] ?? ''}'.trim()
            : 'User');

    return ChatReplyToModel(
      id: json['id'] ?? '',
      senderId: json['sender_id'] ?? json['senderId'] ?? '',
      senderName: senderName.toString().trim().isNotEmpty ? senderName.toString().trim() : 'User',
      message: json['message'] ?? '',
      mediaType: json['media_type'] ?? json['mediaType'],
      fileName: json['file_name'] ?? json['fileName'],
      isDeletedForEveryone: json['is_deleted_for_everyone'] ?? json['isDeletedForEveryone'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_id': senderId,
        'senderName': senderName,
        'message': message,
        'media_type': mediaType,
        'file_name': fileName,
        'is_deleted_for_everyone': isDeletedForEveryone,
      };
}

class ChatMessageReactionModel {
  final String emoji;
  final int count;
  final List<String> userIds;
  final bool hasReacted;

  const ChatMessageReactionModel({
    required this.emoji,
    required this.count,
    this.userIds = const [],
    this.hasReacted = false,
  });

  factory ChatMessageReactionModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final userIds = (json['userIds'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final hasReacted = json['hasReacted'] as bool? ??
        (currentUserId != null && userIds.contains(currentUserId));

    return ChatMessageReactionModel(
      emoji: json['emoji'] ?? '',
      count: json['count'] as int? ?? (userIds.isNotEmpty ? userIds.length : 1),
      userIds: userIds,
      hasReacted: hasReacted,
    );
  }

  ChatMessageReactionModel copyWith({
    String? emoji,
    int? count,
    List<String>? userIds,
    bool? hasReacted,
  }) {
    return ChatMessageReactionModel(
      emoji: emoji ?? this.emoji,
      count: count ?? this.count,
      userIds: userIds ?? this.userIds,
      hasReacted: hasReacted ?? this.hasReacted,
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
  final String? replyToMessageId;
  final ChatReplyToModel? replyToMessage;
  final bool isDeletedForEveryone;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final List<String> readByUserIdList;
  final List<ChatMessageReactionModel> reactions;

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
    this.replyToMessageId,
    this.replyToMessage,
    this.isDeletedForEveryone = false,
    this.deletedAt,
    required this.createdAt,
    this.readByUserIdList = const [],
    this.reactions = const [],
  });

  bool isReadBy(String userId) => readByUserIdList.contains(userId);

  ChatMessageModel copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? senderName,
    String? senderAvatarUrl,
    String? message,
    String? mediaUrl,
    String? mediaType,
    String? fileName,
    int? fileSize,
    String? replyToMessageId,
    ChatReplyToModel? replyToMessage,
    bool? isDeletedForEveryone,
    DateTime? deletedAt,
    DateTime? createdAt,
    List<String>? readByUserIdList,
    List<ChatMessageReactionModel>? reactions,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      message: message ?? this.message,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      isDeletedForEveryone: isDeletedForEveryone ?? this.isDeletedForEveryone,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      readByUserIdList: readByUserIdList ?? this.readByUserIdList,
      reactions: reactions ?? this.reactions,
    );
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final sender = json['sender'] as Map<String, dynamic>? ?? {};
    final receipts = json['read_receipts'] as List<dynamic>? ?? [];
    final rawReactions = json['reactions'] as List<dynamic>? ?? [];

    final readUsers = receipts.map((r) => r['user_id'] as String? ?? '').where((id) => id.isNotEmpty).toList();

    // Parse grouped or raw reactions
    final Map<String, List<String>> reactionMap = {};
    for (final r in rawReactions) {
      if (r is Map<String, dynamic>) {
        final emoji = r['emoji'] as String? ?? '';
        if (emoji.isEmpty) continue;

        if (r.containsKey('userIds') && r['userIds'] is List) {
          final uids = (r['userIds'] as List).map((e) => e.toString()).toList();
          reactionMap[emoji] = uids;
        } else if (r.containsKey('user_id')) {
          final uid = r['user_id'] as String? ?? '';
          if (!reactionMap.containsKey(emoji)) {
            reactionMap[emoji] = [];
          }
          if (uid.isNotEmpty && !reactionMap[emoji]!.contains(uid)) {
            reactionMap[emoji]!.add(uid);
          }
        }
      }
    }

    final reactionsList = reactionMap.entries.map((entry) {
      return ChatMessageReactionModel(
        emoji: entry.key,
        count: entry.value.isNotEmpty ? entry.value.length : 1,
        userIds: entry.value,
        hasReacted: currentUserId != null && entry.value.contains(currentUserId),
      );
    }).toList();

    ChatReplyToModel? replyTo;
    if (json['reply_to_message'] != null && json['reply_to_message'] is Map<String, dynamic>) {
      replyTo = ChatReplyToModel.fromJson(json['reply_to_message'] as Map<String, dynamic>);
    } else if (json['replyToMessage'] != null && json['replyToMessage'] is Map<String, dynamic>) {
      replyTo = ChatReplyToModel.fromJson(json['replyToMessage'] as Map<String, dynamic>);
    }

    final isDeleted = json['is_deleted_for_everyone'] ?? json['isDeletedForEveryone'] ?? false;

    return ChatMessageModel(
      id: json['id'] ?? '',
      roomId: json['room_id'] ?? json['roomId'] ?? '',
      senderId: json['sender_id'] ?? json['senderId'] ?? sender['id'] ?? '',
      senderName: '${sender['first_name'] ?? ''} ${sender['last_name'] ?? ''}'.trim(),
      senderAvatarUrl: sender['avatar_url'] ?? sender['avatarUrl'],
      message: isDeleted ? 'This message was deleted' : (json['message'] ?? ''),
      mediaUrl: isDeleted ? null : (json['media_url'] ?? json['mediaUrl']),
      mediaType: isDeleted ? null : (json['media_type'] ?? json['mediaType']),
      fileName: isDeleted ? null : (json['file_name'] ?? json['fileName']),
      fileSize: isDeleted ? null : (json['file_size'] ?? json['fileSize']),
      replyToMessageId: json['reply_to_message_id'] ?? json['replyToMessageId'],
      replyToMessage: replyTo,
      isDeletedForEveryone: isDeleted,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now())
          : (json['createdAt'] != null
              ? (DateTime.tryParse(json['createdAt'].toString())?.toLocal() ?? DateTime.now())
              : DateTime.now()),
      readByUserIdList: readUsers,
      reactions: reactionsList,
    );
  }
}
