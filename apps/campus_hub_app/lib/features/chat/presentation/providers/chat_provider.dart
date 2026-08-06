import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/chat_repository.dart';
import '../../data/socket_chat_service.dart';
import '../../domain/chat_models.dart';

final userChatRoomsProvider = FutureProvider.autoDispose<List<ChatRoomModel>>((ref) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getUserRooms();
});

class ChatMessagesNotifier extends FamilyAsyncNotifier<List<ChatMessageModel>, String> {
  @override
  Future<List<ChatMessageModel>> build(String arg) async {
    final roomId = arg;
    final repo = ref.watch(chatRepositoryProvider);
    final socket = ref.watch(socketChatServiceProvider);

    socket.joinRoom(roomId);

    // Listen to real-time incoming messages for this room
    final subscription = socket.onNewMessage.listen((msg) {
      if (msg.roomId == roomId) {
        state = AsyncValue.data([...?state.value, msg]);
      }
    });

    ref.onDispose(() {
      subscription.cancel();
      socket.leaveRoom(roomId);
    });

    return repo.getRoomMessages(roomId);
  }

  Future<void> sendMessage({
    required String message,
    String? mediaUrl,
    String? mediaType,
    String? fileName,
    int? fileSize,
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
    );

    state = AsyncValue.data([...?state.value, newMsg]);
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
