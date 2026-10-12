import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../../../../core/branding/gcee_logo.dart';
import '../../../../core/branding/gcee_brand.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../../features/notifications/presentation/providers/notifications_provider.dart';
import '../../../../features/chat/presentation/providers/chat_provider.dart';
import '../../../../features/profile/presentation/controllers/profile_controller.dart';
import '../../../../features/profile/presentation/providers/student_profile_provider.dart';

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
      leading: Icon(
        icon,
        color: iconColor ??
            (isSelected ? theme.colorScheme.primary : Colors.grey.shade700),
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13.5,
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
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
    final detailed = ref.watch(studentDetailedProfileProvider).value;
    final profile = ref.watch(profileControllerProvider).value;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentRoute = GoRouterState.of(context).uri.toString();

    final unreadChats = ref.watch(unreadChatsCountProvider);
    final unreadNotifications = ref.watch(unreadNotificationsCountProvider);

    // Resolve unified student name matching profile screen
    final resolvedName = detailed?.overview.fullName.isNotEmpty == true
        ? detailed!.overview.fullName
        : (profile != null && profile.fullName.isNotEmpty
            ? profile.fullName
            : (user != null ? '${user.firstName} ${user.lastName}'.trim() : ''));
    final studentName = resolvedName.isNotEmpty ? resolvedName : 'Student';

    // Resolve department & batch matching profile screen
    final dept = detailed?.officialIdentity.departmentName ??
        profile?.department ??
        (user?.departmentId != null ? 'Information Technology' : '');

    final rawBatch = detailed?.officialIdentity.batchName ??
        (detailed?.officialIdentity.admissionYear != null
            ? '${detailed!.officialIdentity.admissionYear}'
            : '');
    final batchText = rawBatch.isNotEmpty
        ? (rawBatch.toLowerCase().contains('batch') ? rawBatch : '$rawBatch batch')
        : '';

    final avatarUrl = detailed?.overview.avatarUrl ?? profile?.avatarUrl ?? user?.avatarUrl;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Institutional Branding Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  const GceeLogo(size: 38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              GceeBrand.productName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                GceeBrand.institutionShort,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          GceeBrand.institutionName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
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
            Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.15)),

            // Dynamic User Profile Header Box (Unified with Profile Screen)
            InkWell(
              onTap: () {
                Navigator.pop(context);
                context.go('/profile');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.04),
                  border: Border(
                    bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15)),
                  ),
                ),
                child: Row(
                  children: [
                    CampusAvatar(
                      imageUrl: avatarUrl,
                      name: studentName,
                      radius: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (dept.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              dept,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (batchText.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              batchText,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'STUDENT • ACTIVE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                  ],
                ),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                children: [
                  // --- SECTION 1: ACADEMIC & CAREER ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    child: Text(
                      'ACADEMIC & CAREER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),

                  // Academic Detailed Links
                  _buildMenuItem(
                    context,
                    icon: Icons.calendar_today_outlined,
                    label: 'Class Timetable & Schedule',
                    onTap: () => _navigate(context, '/academics/timetable', isPush: true),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.menu_book_outlined,
                    label: 'Academic Subjects & Syllabus',
                    onTap: () => _navigate(context, '/academics', isPush: true),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.badge_outlined,
                    label: 'Faculty & Mentors Directory',
                    onTap: () => _navigate(context, '/academics/faculty', isPush: true),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.business_center_outlined,
                    label: 'Placement Corner',
                    onTap: () => _navigate(context, '/placement', isPush: true),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.school_outlined,
                    label: 'Roadmap & Career Resources',
                    onTap: () => _navigate(context, '/career', isPush: true),
                  ),

                  Divider(height: 24, color: theme.dividerColor.withValues(alpha: 0.15)),

                  // --- SECTION 2: COMMUNITY & SOCIAL ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                    child: Text(
                      'COMMUNITY & SOCIAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.home_outlined,
                    label: 'Campus Feed',
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
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    badgeCount: unreadNotifications,
                    onTap: () => _navigate(context, '/notifications', isPush: true),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.chat_bubble_outline,
                    label: 'Messages',
                    badgeCount: unreadChats,
                    onTap: () => _navigate(context, '/chat'),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.groups_outlined,
                    label: 'My Clubs & Communities',
                    onTap: () => _navigate(context, '/clubs'),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.event_outlined,
                    label: 'Campus Events',
                    onTap: () => _navigate(context, '/events', isPush: true),
                  ),

                  Divider(height: 24, color: theme.dividerColor.withValues(alpha: 0.15)),

                  // --- SECTION 3: SYSTEM & ACCOUNT ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                    child: Text(
                      'SETTINGS & ACCOUNT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
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
