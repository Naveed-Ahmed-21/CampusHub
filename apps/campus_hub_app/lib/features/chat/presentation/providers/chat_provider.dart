import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/chat_repository.dart';
import '../../data/socket_chat_service.dart';
import '../../domain/chat_models.dart';

class UserChatRoomsNotifier extends AsyncNotifier<List<ChatRoomModel>> {
  StreamSubscription<ChatMessageModel>? _messageSub;

  @override
  Future<List<ChatRoomModel>> build() async {
    final repo = ref.watch(chatRepositoryProvider);
    final socket = ref.watch(socketChatServiceProvider);
    final authUser = ref.watch(authControllerProvider).asData?.value;
    final currentUserId = authUser?.id;

    if (currentUserId == null || currentUserId.isEmpty) {
      return const [];
    }

    _messageSub?.cancel();
    _messageSub = socket.onNewMessage.listen((msg) {
      _handleIncomingMessage(msg, currentUserId);
    });

    ref.onDispose(() {
      _messageSub?.cancel();
    });

    final rooms = await repo.getUserRooms();
    return _filterAndSortRooms(rooms);
  }

  List<ChatRoomModel> _filterAndSortRooms(List<ChatRoomModel> list) {
    // Only show direct chats that actually have messages or activity
    final activeOnly = list.where((r) {
      if (r.type == 'DIRECT') {
        return r.lastMessage != null || r.lastMessageAt != null;
      }
      return true;
    }).toList();

    activeOnly.sort((a, b) {
      final timeA = a.lastMessage?.createdAt ?? a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final timeB = b.lastMessage?.createdAt ?? b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return timeB.compareTo(timeA);
    });
    return activeOnly;
  }

  void _handleIncomingMessage(ChatMessageModel msg, String? currentUserId) {
    final currentList = state.value;
    if (currentList == null) return;

    final index = currentList.indexWhere((r) => r.id == msg.roomId);
    if (index != -1) {
      final existingRoom = currentList[index];
      final isIncoming = currentUserId != null && msg.senderId != currentUserId;
      final updatedRoom = existingRoom.copyWith(
        lastMessage: msg,
        lastMessageAt: msg.createdAt,
        unreadCount: isIncoming ? existingRoom.unreadCount + 1 : 0,
      );

      final updatedList = List<ChatRoomModel>.from(currentList);
      updatedList.removeAt(index);
      updatedList.insert(0, updatedRoom);
      state = AsyncValue.data(updatedList);
    } else {
      // Room was not previously in active list (e.g. newly activated direct chat), reload rooms
      ref.read(chatRepositoryProvider).getUserRooms().then((rooms) {
        state = AsyncValue.data(_filterAndSortRooms(rooms));
      }).catchError((_) {});
    }
  }

  void markRoomAsRead(String roomId) {
    final currentList = state.value;
    if (currentList == null) return;

    final index = currentList.indexWhere((r) => r.id == roomId);
    if (index != -1) {
      final room = currentList[index];
      if (room.unreadCount > 0) {
        final updatedRoom = room.copyWith(unreadCount: 0);
        final updatedList = List<ChatRoomModel>.from(currentList);
        updatedList[index] = updatedRoom;
        state = AsyncValue.data(updatedList);
      }
    }
  }

  Future<void> refresh() async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      final rooms = await repo.getUserRooms();
      state = AsyncValue.data(_filterAndSortRooms(rooms));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final userChatRoomsProvider = AsyncNotifierProvider<UserChatRoomsNotifier, List<ChatRoomModel>>(
  UserChatRoomsNotifier.new,
);

final unreadChatsCountProvider = Provider.autoDispose<int>((ref) {
  final currentUserId = ref.watch(authControllerProvider).asData?.value?.id;
  final roomsAsync = ref.watch(userChatRoomsProvider);

  return roomsAsync.maybeWhen(
    data: (rooms) {
      if (currentUserId == null || currentUserId.isEmpty) return 0;
      int total = 0;
      for (final room in rooms) {
        final lastMsg = room.lastMessage;
        // Never count outgoing messages sent by the user as unread incoming notifications
        if (lastMsg != null && lastMsg.senderId == currentUserId) {
          continue;
        }

        if (room.unreadCount > 0) {
          total += room.unreadCount;
        } else if (lastMsg != null) {
          final isIncoming = lastMsg.senderId != currentUserId;
          final isRead = lastMsg.readByUserIdList.contains(currentUserId);
          if (isIncoming && !isRead) {
            total += 1;
          }
        }
      }
      return total;
    },
    orElse: () => 0,
  );
});

final chatRoomDetailsProvider = FutureProvider.family<ChatRoomModel, String>((ref, roomId) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getRoomDetails(roomId);
});

class ChatMessagesNotifier extends FamilyAsyncNotifier<List<ChatMessageModel>, String> {
  @override
  Future<List<ChatMessageModel>> build(String arg) async {
    final roomId = arg;
    final repo = ref.watch(chatRepositoryProvider);
    final socket = ref.watch(socketChatServiceProvider);
    final authUser = ref.watch(authControllerProvider).asData?.value;
    final currentUserId = authUser?.id;

    if (currentUserId == null || currentUserId.isEmpty) {
      return const [];
    }

    socket.joinRoom(roomId);

    // Listen to real-time incoming messages for this room
    final messageSub = socket.onNewMessage.listen((msg) {
      if (msg.roomId == roomId) {
        final current = state.value ?? [];
        // Deduplicate message by ID
        if (!current.any((m) => m.id == msg.id)) {
          final updated = [...current, msg]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          state = AsyncValue.data(updated);
        }
        if (msg.senderId != currentUserId) {
          repo.markRead(roomId, [msg.id]).then((_) {
            ref.read(userChatRoomsProvider.notifier).refresh();
          }).catchError((_) {});
        }
      }
    });

    // Listen to real-time reaction updates
    final reactionSub = socket.onReactionUpdated.listen((data) {
      final msgId = data['messageId'] as String?;
      final reactionsRaw = data['reactions'] as List<dynamic>?;
      if (msgId != null && reactionsRaw != null) {
        final current = state.value ?? [];
        final idx = current.indexWhere((m) => m.id == msgId);
        if (idx != -1) {
          final updatedMsg = current[idx].copyWith(
            reactions: reactionsRaw
                .map((r) => ChatMessageReactionModel.fromJson(r as Map<String, dynamic>, currentUserId: currentUserId))
                .toList(),
          );
          final updatedList = List<ChatMessageModel>.from(current);
          updatedList[idx] = updatedMsg;
          state = AsyncValue.data(updatedList);
        }
      }
    });

    // Listen to real-time message deletions (delete for everyone)
    final deleteSub = socket.onMessageDeleted.listen((data) {
      final msgId = data['messageId'] as String?;
      if (msgId != null) {
        final current = state.value ?? [];
        final idx = current.indexWhere((m) => m.id == msgId);
        if (idx != -1) {
          final updatedMsg = current[idx].copyWith(
            isDeletedForEveryone: true,
            message: 'This message was deleted',
            mediaUrl: null,
            fileName: null,
            fileSize: null,
          );
          final updatedList = List<ChatMessageModel>.from(current);
          updatedList[idx] = updatedMsg;
          state = AsyncValue.data(updatedList);
        }
      }
    });

    ref.onDispose(() {
      messageSub.cancel();
      reactionSub.cancel();
      deleteSub.cancel();
      socket.leaveRoom(roomId);
    });

    final messages = await repo.getRoomMessages(roomId);

    if (messages.isNotEmpty) {
      final unreadIncomingIds = messages
          .where((m) => m.senderId != currentUserId && !m.readByUserIdList.contains(currentUserId))
          .map((m) => m.id)
          .toList();
      if (unreadIncomingIds.isNotEmpty) {
        repo.markRead(roomId, unreadIncomingIds).then((_) {
          ref.read(userChatRoomsProvider.notifier).refresh();
        }).catchError((_) {});
      }
    }

    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  Future<void> sendMessage({
    required String message,
    String? mediaUrl,
    String? mediaType,
    String? fileName,
    int? fileSize,
    String? replyToMessageId,
  }) async {
    final roomId = arg;
    final repo = ref.read(chatRepositoryProvider);

    final newMsg = await repo.sendMessage(
      roomId: roomId,
      message: message,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      fileName: fileName,
      fileSize: fileSize,
      replyToMessageId: replyToMessageId,
    );

    final current = state.value ?? [];
    // Deduplicate in case socket event arrived before HTTP response
    if (!current.any((m) => m.id == newMsg.id)) {
      final updated = [...current, newMsg]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      state = AsyncValue.data(updated);
    }
    try {
      ref.read(userChatRoomsProvider.notifier).refresh();
    } catch (_) {}
  }

  Future<void> toggleReaction(String messageId, String emoji) async {
    final currentUserId = ref.read(authControllerProvider).asData?.value?.id;
    final current = state.value ?? [];
    final idx = current.indexWhere((m) => m.id == messageId);

    // Optimistic UI update
    if (idx != -1) {
      final msg = current[idx];
      final reactions = List<ChatMessageReactionModel>.from(msg.reactions);
      final rIdx = reactions.indexWhere((r) => r.emoji == emoji);

      if (rIdx != -1) {
        final existing = reactions[rIdx];
        if (existing.hasReacted) {
          // Remove own reaction
          final newCount = existing.count - 1;
          if (newCount <= 0) {
            reactions.removeAt(rIdx);
          } else {
            reactions[rIdx] = existing.copyWith(
              count: newCount,
              hasReacted: false,
              userIds: existing.userIds.where((id) => id != currentUserId).toList(),
            );
          }
        } else {
          // Add own reaction
          reactions[rIdx] = existing.copyWith(
            count: existing.count + 1,
            hasReacted: true,
            userIds: [...existing.userIds, if (currentUserId != null) currentUserId],
          );
        }
      } else {
        reactions.add(
          ChatMessageReactionModel(
            emoji: emoji,
            count: 1,
            hasReacted: true,
            userIds: [if (currentUserId != null) currentUserId],
          ),
        );
      }

      final updatedList = List<ChatMessageModel>.from(current);
      updatedList[idx] = msg.copyWith(reactions: reactions);
      state = AsyncValue.data(updatedList);
    }

    try {
      final repo = ref.read(chatRepositoryProvider);
      final updated = await repo.addReaction(messageId, emoji);
      if (idx != -1) {
        final currentNow = state.value ?? [];
        final nowIdx = currentNow.indexWhere((m) => m.id == messageId);
        if (nowIdx != -1) {
          final updatedList = List<ChatMessageModel>.from(currentNow);
          updatedList[nowIdx] = updated;
          state = AsyncValue.data(updatedList);
        }
      }
    } catch (e) {
      // Revert on error
      ref.invalidateSelf();
      rethrow;
    }
  }

  Future<void> deleteForMe(String messageId) async {
    final current = state.value ?? [];
    // Optimistically remove message from user view
    state = AsyncValue.data(current.where((m) => m.id != messageId).toList());

    try {
      final repo = ref.read(chatRepositoryProvider);
      await repo.deleteMessageForMe(messageId);
    } catch (e) {
      ref.invalidateSelf();
      rethrow;
    }
  }

  Future<void> deleteForEveryone(String messageId) async {
    final current = state.value ?? [];
    final idx = current.indexWhere((m) => m.id == messageId);

    if (idx != -1) {
      final updated = current[idx].copyWith(
        isDeletedForEveryone: true,
        message: 'This message was deleted',
        mediaUrl: null,
        fileName: null,
        fileSize: null,
      );
      final updatedList = List<ChatMessageModel>.from(current);
      updatedList[idx] = updated;
      state = AsyncValue.data(updatedList);
    }

    try {
      final repo = ref.read(chatRepositoryProvider);
      await repo.deleteMessageForEveryone(messageId);
    } catch (e) {
      ref.invalidateSelf();
      rethrow;
    }
  }
}

final chatRoomMessagesProvider = AsyncNotifierProvider.family<ChatMessagesNotifier, List<ChatMessageModel>, String>(
  ChatMessagesNotifier.new,
);

final roomTypingUserProvider = StreamProvider.family.autoDispose<String?, String>((ref, roomId) {
  final socket = ref.watch(socketChatServiceProvider);
  return socket.onTypingChange
      .where((event) => event['roomId'] == roomId)
      .map((event) => event['isTyping'] == true ? (event['userName'] as String? ?? 'Someone') : null);
});

final userPresenceProvider = StreamProvider.family.autoDispose<Map<String, dynamic>, String>((ref, userId) {
  final socket = ref.watch(socketChatServiceProvider);
  return socket.onPresenceChange.where((event) => event['userId'] == userId);
});

final campusUsersProvider = FutureProvider.autoDispose.family<List<ChatParticipantUser>, String?>((ref, query) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.searchCampusUsers(query: query);
});

final publicGroupsProvider = FutureProvider.autoDispose.family<List<ChatRoomModel>, String?>((ref, query) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getPublicGroups(query: query);
});

// ==========================================
// Student Chat Settings Provider
// ==========================================
class StudentChatSettingsNotifier extends AsyncNotifier<StudentChatSettingsModel> {
  @override
  Future<StudentChatSettingsModel> build() async {
    final user = ref.watch(authControllerProvider).asData?.value;
    if (user == null || user.role != 'STUDENT') {
      return StudentChatSettingsModel(requireStudentConversationApproval: false, isEligible: false);
    }
    final repo = ref.watch(chatRepositoryProvider);
    return repo.getChatSettings();
  }

  Future<void> updateApprovalSetting(bool requireApproval) async {
    final prev = state.value;
    state = AsyncValue.data(StudentChatSettingsModel(
      requireStudentConversationApproval: requireApproval,
      isEligible: true,
    ));

    try {
      final repo = ref.read(chatRepositoryProvider);
      final updated = await repo.updateChatSettings(requireApproval);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      if (prev != null) {
        state = AsyncValue.data(prev);
      } else {
        state = AsyncValue.error(e, st);
      }
      rethrow;
    }
  }
}

final studentChatSettingsProvider =
    AsyncNotifierProvider<StudentChatSettingsNotifier, StudentChatSettingsModel>(
  StudentChatSettingsNotifier.new,
);

// ==========================================
// Incoming Chat Requests Provider
// ==========================================
class IncomingChatRequestsNotifier extends AutoDisposeAsyncNotifier<List<ChatRequestModel>> {
  StreamSubscription? _createdSub;
  StreamSubscription? _declinedSub;
  StreamSubscription? _acceptedSub;
  StreamSubscription? _cancelledSub;

  @override
  Future<List<ChatRequestModel>> build() async {
    final repo = ref.watch(chatRepositoryProvider);
    final socket = ref.watch(socketChatServiceProvider);

    _createdSub?.cancel();
    _declinedSub?.cancel();
    _acceptedSub?.cancel();
    _cancelledSub?.cancel();

    _createdSub = socket.onChatRequestCreated.listen((req) {
      final current = state.value ?? [];
      if (!current.any((r) => r.id == req.id)) {
        state = AsyncValue.data([req, ...current]);
      }
    });

    _declinedSub = socket.onChatRequestDeclined.listen((data) {
      final reqId = data['requestId'] as String?;
      if (reqId != null) {
        final current = state.value ?? [];
        state = AsyncValue.data(current.where((r) => r.id != reqId).toList());
      }
    });

    _acceptedSub = socket.onChatRequestAccepted.listen((data) {
      final reqId = data['requestId'] as String?;
      if (reqId != null) {
        final current = state.value ?? [];
        state = AsyncValue.data(current.where((r) => r.id != reqId).toList());
      }
    });

    _cancelledSub = socket.onChatRequestCancelled.listen((data) {
      final reqId = data['requestId'] as String?;
      if (reqId != null) {
        final current = state.value ?? [];
        state = AsyncValue.data(current.where((r) => r.id != reqId).toList());
      }
    });

    ref.onDispose(() {
      _createdSub?.cancel();
      _declinedSub?.cancel();
      _acceptedSub?.cancel();
      _cancelledSub?.cancel();
    });

    return repo.getIncomingChatRequests();
  }

  Future<void> refresh() async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      final list = await repo.getIncomingChatRequests();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Map<String, dynamic>> acceptRequest(String requestId) async {
    final repo = ref.read(chatRepositoryProvider);
    final result = await repo.acceptChatRequest(requestId);

    final current = state.value ?? [];
    state = AsyncValue.data(current.where((r) => r.id != requestId).toList());

    ref.invalidate(userChatRoomsProvider);

    return result;
  }

  Future<void> declineRequest(String requestId) async {
    final repo = ref.read(chatRepositoryProvider);
    await repo.declineChatRequest(requestId);

    final current = state.value ?? [];
    state = AsyncValue.data(current.where((r) => r.id != requestId).toList());
  }
}

final incomingChatRequestsProvider =
    AutoDisposeAsyncNotifierProvider<IncomingChatRequestsNotifier, List<ChatRequestModel>>(
  IncomingChatRequestsNotifier.new,
);

// ==========================================
// Sent Chat Requests Provider
// ==========================================
class SentChatRequestsNotifier extends AutoDisposeAsyncNotifier<List<ChatRequestModel>> {
  @override
  Future<List<ChatRequestModel>> build() async {
    final repo = ref.watch(chatRepositoryProvider);
    return repo.getSentChatRequests();
  }

  Future<void> refresh() async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      final list = await repo.getSentChatRequests();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> cancelRequest(String requestId) async {
    final repo = ref.read(chatRepositoryProvider);
    await repo.cancelChatRequest(requestId);

    final current = state.value ?? [];
    state = AsyncValue.data(current.map((r) {
      if (r.id == requestId) {
        return ChatRequestModel(
          id: r.id,
          senderId: r.senderId,
          recipientId: r.recipientId,
          introductoryMessage: r.introductoryMessage,
          status: ChatRequestStatus.cancelled,
          conversationId: r.conversationId,
          createdAt: r.createdAt,
          respondedAt: DateTime.now(),
          sender: r.sender,
          recipient: r.recipient,
        );
      }
      return r;
    }).toList());
  }
}

final sentChatRequestsProvider =
    AutoDisposeAsyncNotifierProvider<SentChatRequestsNotifier, List<ChatRequestModel>>(
  SentChatRequestsNotifier.new,
);

// ==========================================
// Pending Requests Count Provider
// ==========================================
final pendingRequestsCountProvider = Provider.autoDispose<int>((ref) {
  final requestsAsync = ref.watch(incomingChatRequestsProvider);
  return requestsAsync.maybeWhen(
    data: (requests) => requests.where((r) => r.status == ChatRequestStatus.pending).length,
    orElse: () => 0,
  );
});

// ==========================================
// Chat Permission Provider
// ==========================================
final chatPermissionProvider =
    FutureProvider.autoDispose.family<ChatPermissionResult, String>((ref, targetUserId) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.checkChatPermission(targetUserId);
});

// ==========================================
// Blocked Users Provider
// ==========================================
final blockedUsersProvider =
    FutureProvider.autoDispose<List<BlockedUserModel>>((ref) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getBlockedUsers();
});

