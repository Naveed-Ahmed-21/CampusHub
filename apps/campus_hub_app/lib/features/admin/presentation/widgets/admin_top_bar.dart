import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/navigation/navigation_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/widgets/campus_avatar.dart';

class AdminTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onOpenDrawer;

  const AdminTopBar({
    super.key,
    this.title = 'Institutional Administration',
    this.onOpenDrawer,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 1100;

    final adminName = user != null
        ? '${user.firstName} ${user.lastName}'.trim()
        : 'Administrator';
    final role = user?.role ?? 'ADMIN';

    final surfaceColor = isDark
        ? const Color(0x990B1B30) // 60% dark surface
        : const Color(0xBFFAFBFD); // 75% light surface
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final primary = isDark ? AppColors.darkText : AppColors.primaryText;
    final secondary = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppGlassTheme.blurStrong,
          sigmaY: AppGlassTheme.blurStrong,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(bottom: BorderSide(color: borderColor, width: 1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  // Drawer trigger (mobile only)
                  if (!isDesktop)
                    IconButton(
                      icon: Icon(Icons.menu, color: primary),
                      onPressed: onOpenDrawer ?? () => Scaffold.of(context).openDrawer(),
                      tooltip: 'Open Menu',
                    ),
                  if (!isDesktop) const SizedBox(width: 4),

                  // Brand pill (desktop only to prevent mobile overflow)
                  if (isDesktop) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.account_balance, size: 16, color: AppColors.primaryBlue),
                          const SizedBox(width: 6),
                          Text(
                            'CampusHub OS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  if (title.isNotEmpty)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: isDesktop ? 16 : 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                              color: primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Institutional Admin',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.accentCyan : AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Spacer(),

                  // Academic session chip (desktop)
                  if (isDesktop) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_month, size: 12, color: AppColors.primaryBlue),
                          const SizedBox(width: 4),
                          Text(
                            '2026–27 • Odd Semester',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Action buttons
                  IconButton(
                    icon: Icon(Icons.search, size: 21, color: primary),
                    tooltip: 'Quick Search',
                    onPressed: () => context.push(NavigationConfig.searchRoute),
                  ),
                  IconButton(
                    icon: Icon(Icons.notifications_outlined, size: 21, color: primary),
                    tooltip: 'Notifications',
                    onPressed: () => context.push(NavigationConfig.notificationsRoute),
                  ),
                  const SizedBox(width: 4),

                // Admin profile dropdown with Full Name and Profile Pic
                PopupMenuButton<String>(
                  tooltip: 'Admin Account',
                  offset: const Offset(0, 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: isDesktop ? 160 : 90),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                adminName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: primary,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                role == 'DEPT_ADMIN' ? 'Dept Admin' : 'Admin',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        CampusAvatar(
                          imageUrl: user?.avatarUrl,
                          name: adminName,
                          radius: 17,
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_drop_down, size: 16, color: secondary),
                      ],
                    ),
                  ),
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.badge_outlined, size: 18, color: AppColors.primaryBlue),
                          const SizedBox(width: 10),
                          const Text('Staff Identity / Profile'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings_outlined, size: 18),
                          SizedBox(width: 10),
                          Text('System Settings'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'feed',
                      child: Row(
                        children: [
                          Icon(Icons.dynamic_feed_outlined, size: 18),
                          SizedBox(width: 10),
                          Text('Campus Feed'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 18, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Sign Out', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (val) {
                    if (val == 'profile') {
                      context.push(NavigationConfig.adminProfileRoute);
                    } else if (val == 'settings') {
                      context.push(NavigationConfig.settingsRoute);
                    } else if (val == 'feed') {
                      context.push(NavigationConfig.feedRoute);
                    } else if (val == 'logout') {
                      ref.read(authControllerProvider.notifier).logout();
                    }
                  },
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}
