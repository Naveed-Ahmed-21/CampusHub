import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../../features/chat/presentation/providers/chat_provider.dart';
import '../../../../features/notifications/presentation/providers/notifications_provider.dart';
import 'create_post_sheet.dart';

class CampusTopAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback onOpenDrawer;

  const CampusTopAppBar({
    super.key,
    required this.onOpenDrawer,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final theme = Theme.of(context);
    final campusName = user?.collegeId != null ? 'GCEE Campus' : 'CampusHub';

    final unreadChats = ref.watch(unreadChatsCountProvider);

    final unreadNotifications = ref.watch(unreadNotificationsCountProvider);

    return AppBar(
      elevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.menu, size: 26),
        onPressed: onOpenDrawer,
      ),
      titleSpacing: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            campusName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 20),
        ],
      ),
      actions: [
        // New Post Button (With hover tooltip)
        IconButton(
          icon: const Icon(Icons.add_box_outlined, size: 24),
          tooltip: 'New Post',
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => const CreatePostSheet(),
            );
          },
        ),
        // Activity / Notifications (Heart) Button
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.favorite_border, size: 24),
              tooltip: 'Notifications',
              onPressed: () => context.push('/notifications'),
            ),
            if (unreadNotifications > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$unreadNotifications',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),

        // Messages (Chat) Button
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, size: 24),
              tooltip: 'Messages',
              onPressed: () => context.push('/chat'),
            ),
            if (unreadChats > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$unreadChats',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
