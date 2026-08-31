import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/chat_models.dart';

class ChatRepository {
  final Dio _dio;

  ChatRepository(this._dio);

  Future<List<ChatRoomModel>> getUserRooms() async {
    final response = await _dio.get('/api/v1/chat/rooms');
    final List list = response.data['data'] ?? [];
    return list.map((json) => ChatRoomModel.fromJson(json)).toList();
  }

  Future<ChatRoomModel> getOrCreateDirectChat(String targetUserId) async {
    final response = await _dio.post(
      '/api/v1/chat/direct',
      data: {'targetUserId': targetUserId},
    );
    return ChatRoomModel.fromJson(response.data['data']);
  }

  Future<ChatRoomModel> getDepartmentChat() async {
    final response = await _dio.get('/api/v1/chat/department');
    return ChatRoomModel.fromJson(response.data['data']);
  }

  Future<ChatRoomModel> getOrCreateClubChat(String clubId) async {
    final response = await _dio.get('/api/v1/chat/rooms/club/$clubId');
    return ChatRoomModel.fromJson(response.data['data']);
  }

  Future<List<ChatMessageModel>> getRoomMessages(String roomId, {int page = 1, int limit = 50}) async {
    final response = await _dio.get(
      '/api/v1/chat/rooms/$roomId/messages',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data['data'];
    final List list = data is Map ? (data['messages'] ?? []) : (data ?? []);
    return list.map((json) => ChatMessageModel.fromJson(json)).toList();
  }

  Future<ChatMessageModel> sendMessage({
    required String roomId,
    required String message,
    String? mediaUrl,
    String? mediaType,
    String? fileName,
    int? fileSize,
    String? replyToMessageId,
  }) async {
    final response = await _dio.post(
      '/api/v1/chat/messages',
      data: {
        'roomId': roomId,
        'message': message,
        'media_url': mediaUrl,
        'media_type': mediaType,
        'file_name': fileName,
        'file_size': fileSize,
        'reply_to_message_id': replyToMessageId,
      },
    );
    return ChatMessageModel.fromJson(response.data['data']);
  }

  Future<ChatMessageModel> addReaction(String messageId, String emoji) async {
    final response = await _dio.post(
      '/api/v1/chat/messages/$messageId/reactions',
      data: {'emoji': emoji},
    );
    return ChatMessageModel.fromJson(response.data['data']);
  }

  Future<ChatMessageModel> removeReaction(String messageId, String emoji) async {
    final response = await _dio.delete(
      '/api/v1/chat/messages/$messageId/reactions/${Uri.encodeComponent(emoji)}',
    );
    return ChatMessageModel.fromJson(response.data['data']);
  }

  Future<void> deleteMessageForMe(String messageId) async {
    await _dio.delete('/api/v1/chat/messages/$messageId/for-me');
  }

  Future<ChatMessageModel> deleteMessageForEveryone(String messageId) async {
    final response = await _dio.delete('/api/v1/chat/messages/$messageId/for-everyone');
    return ChatMessageModel.fromJson(response.data['data']);
  }

  Future<ChatRoomModel> createGroupChat({
    required String name,
    String? description,
    String? avatarUrl,
    bool isPrivate = false,
    required List<String> memberIds,
  }) async {
    final response = await _dio.post(
      '/api/v1/chat/group',
      data: {
        'name': name,
        'description': description,
        'avatarUrl': avatarUrl,
        'isPrivate': isPrivate,
        'memberIds': memberIds,
      },
    );
    return ChatRoomModel.fromJson(response.data['data']);
  }

  Future<ChatRoomModel> updateGroupAvatar(String roomId, String? avatarUrl) async {
    final response = await _dio.patch(
      '/api/v1/chat/rooms/$roomId/avatar',
      data: {'avatarUrl': avatarUrl},
    );
    return ChatRoomModel.fromJson(response.data['data']);
  }

  Future<List<ChatRoomModel>> getPublicGroups({String? query}) async {
    final response = await _dio.get(
      '/api/v1/chat/groups/public',
      queryParameters: query != null && query.isNotEmpty ? {'query': query} : null,
    );
    final List list = response.data['data'] ?? [];
    return list.map((json) => ChatRoomModel.fromJson(json)).toList();
  }

  Future<ChatRoomModel> getRoomDetails(String roomId) async {
    final response = await _dio.get('/api/v1/chat/rooms/$roomId');
    return ChatRoomModel.fromJson(response.data['data']);
  }

  Future<void> joinGroup(String roomId) async {
    await _dio.post('/api/v1/chat/rooms/$roomId/join');
  }

  Future<void> leaveGroup(String roomId) async {
    await _dio.post('/api/v1/chat/rooms/$roomId/leave');
  }

  Future<List<ChatParticipantUser>> searchCampusUsers({String? query}) async {
    final response = await _dio.get(
      '/api/v1/chat/users',
      queryParameters: query != null && query.isNotEmpty ? {'query': query} : null,
    );
    final List list = response.data['data'] ?? [];
    return list.map((json) => ChatParticipantUser.fromJson(json)).toList();
  }

  Future<void> addRoomMember(String roomId, String userId) async {
    await _dio.post(
      '/api/v1/chat/rooms/$roomId/members',
      data: {'userId': userId},
    );
  }

  Future<void> removeRoomMember(String roomId, String userId) async {
    await _dio.delete('/api/v1/chat/rooms/$roomId/members/$userId');
  }

  Future<void> markRead(String roomId, List<String> messageIds) async {
    if (messageIds.isEmpty) return;
    await _dio.post(
      '/api/v1/chat/read',
      data: {
        'roomId': roomId,
        'messageIds': messageIds,
      },
    );
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ChatRepository(dio);
});
