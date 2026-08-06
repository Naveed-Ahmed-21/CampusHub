import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/chat_provider.dart';
import 'start_direct_chat_dialog.dart';
import '../../data/chat_repository.dart';

class ChatInboxView extends ConsumerStatefulWidget {
  const ChatInboxView({super.key});

  @override
  ConsumerState<ChatInboxView> createState() => _ChatInboxViewState();
}

class _ChatInboxViewState extends ConsumerState<ChatInboxView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showStartDirectChatDialog() {
    showDialog(
      context: context,
      builder: (context) => const StartDirectChatDialog(),
    );
  }

  Future<void> _openDepartmentChat() async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      final room = await repo.getDepartmentChat();
      ref.invalidate(userChatRoomsProvider);
      if (mounted) {
        context.push('/chat/room/${room.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Department chat error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(userChatRoomsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.domain),
            tooltip: 'Open Department Chat',
            onPressed: _openDepartmentChat,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(userChatRoomsProvider),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Personal'),
            Tab(text: 'Dept'),
            Tab(text: 'Clubs'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showStartDirectChatDialog,
        icon: const Icon(Icons.message),
        label: const Text('New Chat'),
        backgroundColor: Colors.teal,
      ),
      body: roomsAsync.when(
        data: (rooms) {
          final personalRooms = rooms.where((r) => r.type == 'DIRECT').toList();
          final deptRooms = rooms.where((r) => r.departmentId != null).toList();
          final clubRooms = rooms.where((r) => r.clubId != null).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildRoomsList(rooms),
              _buildRoomsList(personalRooms),
              _buildRoomsList(deptRooms),
              _buildRoomsList(clubRooms),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading chats: $err'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(userChatRoomsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomsList(List rooms) {
    if (rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No conversations here yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _showStartDirectChatDialog,
              icon: const Icon(Icons.add),
              label: const Text('Start Personal Chat'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: rooms.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final room = rooms[index];
        final otherUser = room.getOtherParticipant('me');
        final isOnline = otherUser?.isOnline ?? false;
        final roomName = room.getDisplayName('me');
        final lastMsg = room.lastMessage;

        return ListTile(
          onTap: () => context.push('/chat/room/${room.id}'),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: room.type == 'DIRECT' ? Colors.teal.shade100 : Colors.blue.shade100,
                child: Text(
                  roomName.isNotEmpty ? roomName[0].toUpperCase() : 'C',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              if (room.type == 'DIRECT' && isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  roomName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (room.lastMessageAt != null)
                Text(
                  '${room.lastMessageAt.hour.toString().padLeft(2, '0')}:${room.lastMessageAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
          subtitle: Row(
            children: [
              if (room.type != 'DIRECT') ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: room.departmentId != null ? Colors.indigo.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    room.departmentId != null ? 'Dept' : 'Club',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: room.departmentId != null ? Colors.indigo : Colors.orange.shade800,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  lastMsg != null
                      ? (lastMsg.mediaType != null
                          ? '📎 ${lastMsg.mediaType}: ${lastMsg.fileName ?? lastMsg.message}'
                          : lastMsg.message)
                      : 'Tap to open chat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
