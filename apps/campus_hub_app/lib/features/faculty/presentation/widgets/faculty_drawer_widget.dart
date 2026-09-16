import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../../features/notifications/presentation/providers/notifications_provider.dart';
import '../../../../features/chat/presentation/providers/chat_provider.dart';

class FacultyDrawerWidget extends ConsumerWidget {
  const FacultyDrawerWidget({super.key});

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    int? badgeCount,
    bool isSelected = false,
    Color? iconColor,
    Color? textColor,
  }) {
    final theme = Theme.of(context);
    final activeBg = theme.colorScheme.primary.withValues(alpha: 0.1);

    return ListTile(
      dense: true,
      selected: isSelected,
      selectedTileColor: activeBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Icon(icon, color: iconColor ?? (isSelected ? theme.colorScheme.primary : Colors.grey.shade700), size: 20),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: textColor ?? (isSelected ? theme.colorScheme.primary : null),
        ),
      ),
      trailing: badgeCount != null && badgeCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final theme = Theme.of(context);
    final currentRoute = GoRouterState.of(context).uri.toString();

    final unreadChats = ref.watch(unreadChatsCountProvider);
    final unreadNotifications = ref.watch(unreadNotificationsCountProvider);

    final facultyName = user != null ? '${user.firstName} ${user.lastName}' : 'Dr. Robert Taylor';
    const facultyDept = 'Associate Professor • Computer Science';

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Faculty Header Profile Box
            InkWell(
              onTap: () {
                Navigator.pop(context);
                context.go('/faculty/profile');
              },
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        facultyName.isNotEmpty ? facultyName[0].toUpperCase() : 'F',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            facultyName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            facultyDept,
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),

            // Navigation Links Scrollable List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.dashboard_outlined,
                    label: 'Faculty Dashboard',
                    isSelected: currentRoute == '/faculty',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/faculty');
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.school_outlined,
                    label: 'Teaching & Subjects',
                    isSelected: currentRoute == '/teaching',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/teaching');
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.hub_outlined,
                    label: 'Campus Collaboration',
                    isSelected: currentRoute == '/faculty/campus',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/faculty/campus');
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.person_outline,
                    label: 'Faculty Profile',
                    isSelected: currentRoute == '/faculty/profile',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/faculty/profile');
                    },
                  ),
                  const Divider(height: 16),
                  _buildMenuItem(
                    context,
                    icon: Icons.menu_book_outlined,
                    label: 'Subject Hub Discovery',
                    isSelected: currentRoute == '/academics',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute == '/academics') return;
                      context.push('/academics');
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    badgeCount: unreadNotifications,
                    isSelected: currentRoute == '/notifications',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute == '/notifications') return;
                      context.push('/notifications');
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.chat_bubble_outline,
                    label: 'Messages & Chats',
                    badgeCount: unreadChats,
                    isSelected: currentRoute == '/chat',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute == '/chat') return;
                      context.push('/chat');
                    },
                  ),
                  const Divider(height: 16),
                  _buildMenuItem(
                    context,
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    isSelected: currentRoute == '/settings',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute == '/settings') return;
                      context.push('/settings');
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline,
                    label: 'Help & Support',
                    isSelected: currentRoute == '/help',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute == '/help') return;
                      context.push('/help');
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    context,
                    icon: Icons.logout,
                    label: 'Log Out',
                    iconColor: Colors.red,
                    textColor: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(authControllerProvider.notifier).logout();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
