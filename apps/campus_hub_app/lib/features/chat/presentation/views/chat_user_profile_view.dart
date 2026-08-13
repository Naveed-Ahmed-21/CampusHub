import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/chat_models.dart';
import '../../data/chat_repository.dart';
import '../providers/chat_provider.dart';

class ChatUserProfileView extends ConsumerWidget {
  final ChatParticipantUser user;
  final String? roomId;

  const ChatUserProfileView({
    super.key,
    required this.user,
    this.roomId,
  });

  Widget _buildInfoCard(BuildContext context, String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Contact Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // User Header Profile Card
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
                          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),
                      ),
                      if (user.isOnline)
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(user.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    user.isOnline ? 'Online Now' : (user.lastSeen != null ? 'Last seen recently' : 'Campus Member'),
                    style: TextStyle(color: user.isOnline ? Colors.green : Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionItem(context, Icons.message, 'Message', theme.colorScheme.primary, () async {
                  if (roomId != null) {
                    context.push('/chat/room/$roomId');
                  } else {
                    final repo = ref.read(chatRepositoryProvider);
                    final room = await repo.getOrCreateDirectChat(user.id);
                    ref.invalidate(userChatRoomsProvider);
                    if (context.mounted) {
                      context.push('/chat/room/${room.id}');
                    }
                  }
                }),
                _buildActionItem(context, Icons.phone, 'Call', Colors.green, () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Calling ${user.fullName}...')),
                  );
                }),
                _buildActionItem(context, Icons.videocam, 'Video', Colors.orange, () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Starting video call with ${user.fullName}...')),
                  );
                }),
              ],
            ),

            const SizedBox(height: 24),

            // Contact Info Cards
            _buildInfoCard(context, 'Email Address', user.email, Icons.email),
            _buildInfoCard(context, 'User ID', user.id, Icons.badge),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
