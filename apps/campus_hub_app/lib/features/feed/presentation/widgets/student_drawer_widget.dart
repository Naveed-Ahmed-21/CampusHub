import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../../features/notifications/presentation/providers/notifications_provider.dart';
import '../../../../features/chat/presentation/providers/chat_provider.dart';

class StudentDrawerWidget extends ConsumerWidget {
  const StudentDrawerWidget({super.key});

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

  void _navigate(BuildContext context, String path, {bool isPush = false}) {
    Navigator.pop(context);
    try {
      final currentRoute = GoRouterState.of(context).uri.path;
      if (currentRoute == path) return;
    } catch (_) {}
    if (isPush) {
      context.push(path);
    } else {
      context.go(path);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final theme = Theme.of(context);
    final currentRoute = GoRouterState.of(context).uri.toString();

    final unreadChats = ref.watch(unreadChatsCountProvider);

    final unreadNotifications = ref.watch(unreadNotificationsCountProvider);

    final studentName = user != null ? '${user.firstName} ${user.lastName}' : 'Naveed Ahmed';
    final studentDept = 'B.Tech IT • 4th Year';

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // User Header Profile Box
            InkWell(
              onTap: () {
                Navigator.pop(context);
                context.go('/profile');
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
                        studentName.isNotEmpty ? studentName[0].toUpperCase() : 'N',
                        style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(studentDept, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
                    icon: Icons.home_outlined,
                    label: 'Home',
                    isSelected: currentRoute == '/feed',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/feed');
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.person_outline,
                    label: 'My Profile',
                    isSelected: currentRoute == '/profile',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/profile');
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.dynamic_feed_outlined,
                    label: 'My Posts',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/profile');
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.bookmark_border,
                    label: 'Saved Posts',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/profile');
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    badgeCount: unreadNotifications,
                    onTap: () => _navigate(context, '/notifications'),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.chat_bubble_outline,
                    label: 'Messages',
                    badgeCount: unreadChats,
                    onTap: () => _navigate(context, '/chat'),
                  ),
                  const Divider(height: 16),
                  _buildMenuItem(
                    context,
                    icon: Icons.groups_outlined,
                    label: 'My Clubs',
                    onTap: () => _navigate(context, '/clubs'),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.event_outlined,
                    label: 'Events',
                    onTap: () => _navigate(context, '/events'),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.menu_book_outlined,
                    label: 'Roadmap & Resources',
                    onTap: () => _navigate(context, '/career'),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.business_center_outlined,
                    label: 'Placement Corner',
                    onTap: () => _navigate(context, '/placement'),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.menu_book_outlined,
                    label: 'Academic Subjects & Resources',
                    onTap: () => _navigate(context, '/academics'),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.badge_outlined,
                    label: 'Faculty & Mentors Directory',
                    onTap: () => _navigate(context, '/academics/faculty', isPush: true),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.explore_outlined,
                    label: 'Career Guidance',
                    onTap: () => _navigate(context, '/career'),
                  ),
                  const Divider(height: 16),
                  _buildMenuItem(
                    context,
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => _navigate(context, '/settings', isPush: true),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline,
                    label: 'Help & Support',
                    onTap: () => _navigate(context, '/help', isPush: true),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.info_outline,
                    label: 'About CampusHub',
                    onTap: () => _navigate(context, '/about', isPush: true),
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
