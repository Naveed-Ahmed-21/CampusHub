import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/chat_models.dart';
import '../utils/chat_navigation_helper.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../../../../core/widgets/campus_app_bar.dart';

import '../../../profile/presentation/widgets/profile_story_avatar.dart';
import '../../../../shared/widgets/full_screen_image_viewer.dart';

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
      appBar: const CampusAppBar(
        leading: CampusBackButton(),
        title: 'Contact Details',
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
                      ProfileStoryAvatar(
                        userId: user.id,
                        avatarUrl: user.avatarUrl,
                        name: user.fullName,
                        radius: 54,
                        heroTag: 'chat_user_avatar_${user.id}',
                        fallbackOnTap: () {
                          final hasAvatar = user.avatarUrl != null && user.avatarUrl!.trim().isNotEmpty;
                          final resolvedAvatarUrl = hasAvatar ? ApiEndpoints.resolveUrl(user.avatarUrl!.trim()) : null;
                          if (resolvedAvatarUrl != null) {
                            FullScreenImageViewer.openSingle(
                              context,
                              imageUrl: resolvedAvatarUrl,
                              heroTag: 'chat_user_avatar_${user.id}',
                              title: user.fullName,
                              subtitle: user.role,
                            );
                          }
                        },
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
                  await ChatNavigationHelper.startOrOpenDirectChat(
                    context,
                    ref,
                    targetUserId: user.id,
                    targetUserName: user.fullName,
                    targetUserAvatar: user.avatarUrl,
                  );
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
