import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/chat_provider.dart';
import '../../domain/chat_models.dart';
import '../../data/chat_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'chat_user_profile_view.dart';

class GroupInfoView extends ConsumerStatefulWidget {
  final String roomId;

  const GroupInfoView({super.key, required this.roomId});

  @override
  ConsumerState<GroupInfoView> createState() => _GroupInfoViewState();
}

class _GroupInfoViewState extends ConsumerState<GroupInfoView> {
  final _addMemberController = TextEditingController();

  @override
  void dispose() {
    _addMemberController.dispose();
    super.dispose();
  }

  void _showAddMemberDialog(ChatRoomModel room) {
    String searchQuery = '';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final usersAsync = ref.watch(campusUsersProvider(searchQuery));
          final existingIds = room.participants.map((p) => p.id).toSet();

          return AlertDialog(
            title: const Text('Add Member to Group'),
            content: SizedBox(
              width: double.maxFinite,
              height: 350,
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search member by name/email',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (val) => setDialogState(() => searchQuery = val.trim()),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: usersAsync.when(
                      data: (users) {
                        final available = users.where((u) => !existingIds.contains(u.id)).toList();
                        if (available.isEmpty) {
                          return const Center(child: Text('No available users found'));
                        }
                        return ListView.builder(
                          itemCount: available.length,
                          itemBuilder: (context, index) {
                            final user = available[index];
                            return ListTile(
                              leading: CircleAvatar(child: Text(user.firstName[0].toUpperCase())),
                              title: Text(user.fullName),
                              subtitle: Text(user.email),
                              trailing: const Icon(Icons.person_add, color: Colors.green),
                              onTap: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                Navigator.pop(ctx);
                                final repo = ref.read(chatRepositoryProvider);
                                await repo.addRoomMember(room.id, user.id);
                                ref.invalidate(userChatRoomsProvider);
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Added ${user.fullName} to group')),
                                );
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ],
          );
        },
      ),
    );
  }

  Future<void> _leaveGroup(ChatRoomModel room, String currentUserId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Group?'),
        content: const Text('Are you sure you want to leave this group conversation?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final repo = ref.read(chatRepositoryProvider);
        await repo.removeRoomMember(room.id, currentUserId);
        ref.invalidate(userChatRoomsProvider);
        if (mounted) {
          context.go('/chat');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Left group conversation')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(userChatRoomsProvider);
    final currentUser = ref.watch(authControllerProvider).asData?.value;
    final currentUserId = currentUser?.id ?? '';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Info'),
      ),
      body: roomsAsync.when(
        data: (rooms) {
          final room = rooms.firstWhere(
            (r) => r.id == widget.roomId,
            orElse: () => ChatRoomModel(
              id: widget.roomId,
              collegeId: '',
              type: 'GROUP',
              name: 'Group Chat',
            ),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Group Header Tile
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(Icons.groups, size: 48, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          room.name ?? 'Group Chat',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${room.participants.length} members',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _showAddMemberDialog(room),
                              icon: const Icon(Icons.person_add),
                              label: const Text('Add Member'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Members Header
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Group Members (${room.participants.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Members List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: room.participants.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
                  itemBuilder: (context, index) {
                    final member = room.participants[index];
                    final isMe = member.id == currentUserId;

                    return ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => ChatUserProfileView(user: member, roomId: room.id),
                          ),
                        );
                      },
                      leading: CircleAvatar(
                        backgroundColor: isMe ? Colors.amber.shade100 : Colors.blue.shade100,
                        child: Text(
                          member.firstName.isNotEmpty ? member.firstName[0].toUpperCase() : 'M',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isMe ? Colors.amber.shade900 : Colors.blue.shade800,
                          ),
                        ),
                      ),
                      title: Text(
                        isMe ? '${member.fullName} (You)' : member.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(member.email),
                      trailing: isMe
                          ? const Chip(label: Text('You'), backgroundColor: Colors.amberAccent)
                          : const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Exit Group Button
                ListTile(
                  onTap: () => _leaveGroup(room, currentUserId),
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: const Text('Leave Group Conversation', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading room: $err')),
      ),
    );
  }
}
