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
    final currentUserId = ref.watch(authControllerProvider).asData?.value?.id;

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
    final currentUserId = ref.watch(authControllerProvider).asData?.value?.id;

    socket.joinRoom(roomId);

    // Listen to real-time incoming messages for this room
    final messageSub = socket.onNewMessage.listen((msg) {
      if (msg.roomId == roomId) {
        final current = state.value ?? [];
        // Deduplicate message by ID
        if (!current.any((m) => m.id == msg.id)) {
          state = AsyncValue.data([...current, msg]);
        }
        if (currentUserId != null && msg.senderId != currentUserId) {
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

    if (currentUserId != null && messages.isNotEmpty) {
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
      state = AsyncValue.data([...current, newMsg]);
    }
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
