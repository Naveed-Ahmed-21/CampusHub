import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/branding/gcee_logo.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';


class PlacementDrawer extends ConsumerWidget {
  const PlacementDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final currentPath = GoRouterState.of(context).uri.toString();

    // Dark navy theme colors matching Image 03
    const drawerBg = Color(0xFF0F172A); // Slate 900
    const activeBg = Color(0xFF1E293B); // Slate 800
    const activeText = Color(0xFF60A5FA); // Blue 400
    const inactiveText = Color(0xFF94A3B8); // Slate 400
    const borderColor = Color(0xFF334155); // Slate 700

    Widget buildDrawerItem({
      required IconData icon,
      required String title,
      required String route,
      bool isDanger = false,
      VoidCallback? onTap,
    }) {
      final isSelected = currentPath == route || (route != '/placement' && currentPath.startsWith(route));
      final color = isDanger
          ? const Color(0xFFEF4444)
          : (isSelected ? activeText : inactiveText);

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3), width: 1) : null,
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          leading: Icon(
            icon,
            color: color,
            size: 20,
          ),
          title: Text(
            title,
            style: AppTypography.captionMedium.copyWith(
              color: isDanger ? const Color(0xFFEF4444) : (isSelected ? Colors.white : inactiveText),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13.5,
            ),
          ),
          onTap: onTap ??
              () {
                Navigator.of(context).pop();
                context.push(route);
              },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    return Drawer(
      backgroundColor: drawerBg,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Top Brand Bar with Close 'X'
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const GceeLogo(size: 32),
                  const SizedBox(width: 10),
                  Text(
                    'CampusHub',
                    style: AppTypography.pageTitle.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: inactiveText, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // User Profile Card matching Image 03
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: activeBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Row(
                children: [
                  CampusAvatar(
                    imageUrl: user?.avatarUrl,
                    name: user?.fullName.isNotEmpty == true ? user!.fullName : 'Placement Officer',
                    radius: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user?.fullName.isNotEmpty == true ? user!.fullName : 'Placement Officer',
                                style: AppTypography.captionMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('👑', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Placement Officer',
                          style: TextStyle(
                            color: activeText,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          user?.email ?? 'placement@college.edu',
                          style: const TextStyle(
                            color: inactiveText,
                            fontSize: 10.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: borderColor, height: 16),

            // Navigation Menu List (matching Image 03)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  buildDrawerItem(
                    icon: Icons.dashboard_outlined,
                    title: 'Home',
                    route: '/placement',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/placement');
                    },
                  ),
                  buildDrawerItem(
                    icon: Icons.work_outline,
                    title: 'Opportunities',
                    route: '/placement/opportunities',
                  ),
                  buildDrawerItem(
                    icon: Icons.business_outlined,
                    title: 'Companies',
                    route: '/placement/companies',
                  ),
                  buildDrawerItem(
                    icon: Icons.assignment_outlined,
                    title: 'Applications',
                    route: '/placement/applications',
                  ),
                  buildDrawerItem(
                    icon: Icons.checklist_rtl_outlined,
                    title: 'Shortlist & Results',
                    route: '/placement/shortlist',
                  ),
                  buildDrawerItem(
                    icon: Icons.event_outlined,
                    title: 'Interviews',
                    route: '/placement/interviews',
                  ),
                  buildDrawerItem(
                    icon: Icons.menu_book_outlined,
                    title: 'Preparation Hub',
                    route: '/placement/preparation',
                  ),
                  buildDrawerItem(
                    icon: Icons.people_outline,
                    title: 'Students Directory',
                    route: '/placement/students',
                  ),
                  buildDrawerItem(
                    icon: Icons.bar_chart_outlined,
                    title: 'Analytics',
                    route: '/placement/analytics',
                  ),
                  buildDrawerItem(
                    icon: Icons.description_outlined,
                    title: 'Reports',
                    route: '/placement/reports',
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Divider(color: borderColor, height: 1),
                  ),

                  buildDrawerItem(
                    icon: Icons.dynamic_feed_outlined,
                    title: 'Campus Feed',
                    route: '/feed',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/feed');
                    },
                  ),
                  buildDrawerItem(
                    icon: Icons.chat_bubble_outline,
                    title: 'Messages & Chats',
                    route: '/chat',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/chat');
                    },
                  ),
                  buildDrawerItem(
                    icon: Icons.person_outline,
                    title: 'Profile & Settings',
                    route: '/placement/profile',
                  ),
                ],
              ),
            ),

            // Logout Button at bottom
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: borderColor, width: 0.8)),
              ),
              child: buildDrawerItem(
                icon: Icons.logout_outlined,
                title: 'Logout',
                route: '/login',
                isDanger: true,
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

