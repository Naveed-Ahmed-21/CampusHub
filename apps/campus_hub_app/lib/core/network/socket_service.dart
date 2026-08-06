import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return SocketService(storage);
});

class SocketService {
  final SecureStorageService _storage;
  socket_io.Socket? _socket;

  SocketService(this._storage);

  Future<void> connect() async {
    final token = await _storage.getAccessToken();
    
    _socket = socket_io.io(
      AppConfig.socketUrl,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({'Authorization': 'Bearer ${token ?? ""}'})
          .build(),
    );

    _socket?.connect();

    _socket?.onConnect((_) {
      debugPrint('🔌 Connected to CampusHub Socket Server');
    });

    _socket?.onDisconnect((_) {
      debugPrint('🔌 Disconnected from CampusHub Socket Server');
    });
  }

  void joinRoom(String room) {
    _socket?.emit('join_room', room);
  }

  void leaveRoom(String room) {
    _socket?.emit('leave_room', room);
  }

  void onEvent(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
