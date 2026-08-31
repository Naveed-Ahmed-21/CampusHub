import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../core/constants/api_endpoints.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/chat_models.dart';

class SocketChatService {
  io.Socket? _socket;
  final SecureStorageService _storage;

  final _messageStreamController = StreamController<ChatMessageModel>.broadcast();
  final _typingStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _presenceStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _readReceiptStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _reactionStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _deletedMessageStreamController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<ChatMessageModel> get onNewMessage => _messageStreamController.stream;
  Stream<Map<String, dynamic>> get onTypingChange => _typingStreamController.stream;
  Stream<Map<String, dynamic>> get onPresenceChange => _presenceStreamController.stream;
  Stream<Map<String, dynamic>> get onMessagesRead => _readReceiptStreamController.stream;
  Stream<Map<String, dynamic>> get onReactionUpdated => _reactionStreamController.stream;
  Stream<Map<String, dynamic>> get onMessageDeleted => _deletedMessageStreamController.stream;

  SocketChatService(this._storage);

  Future<void> connect() async {
    final token = await _storage.getAccessToken();
    if (token == null) return;

    if (_socket != null && _socket!.connected) return;

    _socket = io.io(
      ApiEndpoints.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('⚡ Socket Connected: ${_socket!.id}');
    });

    _socket!.on('new_message', (data) {
      if (data != null && data is Map<String, dynamic>) {
        _messageStreamController.add(ChatMessageModel.fromJson(data));
      }
    });

    _socket!.on('message_reaction_updated', (data) {
      if (data != null && data is Map<String, dynamic>) {
        _reactionStreamController.add(data);
      }
    });

    _socket!.on('message_deleted_everyone', (data) {
      if (data != null && data is Map<String, dynamic>) {
        _deletedMessageStreamController.add(data);
      }
    });

    _socket!.on('user_typing', (data) {
      if (data != null && data is Map<String, dynamic>) {
        _typingStreamController.add({'isTyping': true, ...data});
      }
    });

    _socket!.on('user_stop_typing', (data) {
      if (data != null && data is Map<String, dynamic>) {
        _typingStreamController.add({'isTyping': false, ...data});
      }
    });

    _socket!.on('presence_change', (data) {
      if (data != null && data is Map<String, dynamic>) {
        _presenceStreamController.add(data);
      }
    });

    _socket!.on('messages_read', (data) {
      if (data != null && data is Map<String, dynamic>) {
        _readReceiptStreamController.add(data);
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('⚡ Socket Disconnected');
    });
  }

  void joinRoom(String roomId) {
    _socket?.emit('join_room', roomId);
  }

  void leaveRoom(String roomId) {
    _socket?.emit('leave_room', roomId);
  }

  void sendTypingStart(String roomId, String userName) {
    _socket?.emit('typing_start', {'roomId': roomId, 'userName': userName});
  }

  void sendTypingStop(String roomId) {
    _socket?.emit('typing_stop', {'roomId': roomId});
  }

  void sendSocketMessage(
    String roomId,
    String message, {
    String? mediaUrl,
    String? mediaType,
    String? fileName,
    int? fileSize,
    String? replyToMessageId,
  }) {
    _socket?.emit('send_message', {
      'roomId': roomId,
      'message': message,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'file_name': fileName,
      'file_size': fileSize,
      'reply_to_message_id': replyToMessageId,
    });
  }

  void addReaction(String messageId, String emoji) {
    _socket?.emit('add_reaction', {'messageId': messageId, 'emoji': emoji});
  }

  void removeReaction(String messageId, String emoji) {
    _socket?.emit('remove_reaction', {'messageId': messageId, 'emoji': emoji});
  }

  void markRead(String roomId, List<String> messageIds) {
    _socket?.emit('mark_read', {
      'roomId': roomId,
      'messageIds': messageIds,
    });
  }

  void sendPresencePing() {
    _socket?.emit('presence_ping');
  }

  void sendPresenceSet(bool isOnline) {
    _socket?.emit('presence_set', {'isOnline': isOnline});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _messageStreamController.close();
    _typingStreamController.close();
    _presenceStreamController.close();
    _readReceiptStreamController.close();
    _reactionStreamController.close();
    _deletedMessageStreamController.close();
  }
}

final socketChatServiceProvider = Provider<SocketChatService>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  final service = SocketChatService(storage);
  service.connect();
  ref.onDispose(() => service.dispose());
  return service;
});
