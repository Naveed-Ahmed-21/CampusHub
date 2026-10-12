import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/branding/gcee_logo.dart';
import '../../../../core/branding/gcee_brand.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../providers/admin_provider.dart';

class AdminDrawerWidget extends ConsumerWidget {
  final ValueChanged<int>? onSelectTab;

  const AdminDrawerWidget({
    super.key,
    this.onSelectTab,
  });

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
    final activeBg = theme.colorScheme.primary.withValues(alpha: 0.12);

    return ListTile(
      dense: true,
      selected: isSelected,
      selectedTileColor: activeBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Icon(
        icon,
        color: iconColor ?? (isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: textColor ?? (isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface),
        ),
      ),
      trailing: badgeCount != null && badgeCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
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
    final pendingCount = ref.watch(adminPendingChangeRequestsCountProvider).value ?? 0;

    final adminName = user != null ? '${user.firstName} ${user.lastName}'.trim() : 'Administrator';
    final adminRole = user?.role ?? 'ADMIN';
    final collegeName = user?.collegeId != null ? 'Campus Hub Institutional OS' : 'Campus Administration';

    void navigateToTab(int tabIndex) {
      Navigator.pop(context);
      if (onSelectTab != null) {
        onSelectTab!(tabIndex);
      } else {
        context.go('/admin');
      }
    }

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
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

            // Admin Profile Header
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2))),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
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
                          adminName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                adminRole,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          collegeName,
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Menu
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                    child: Text(
                      'CAMPUS FEED & NOTICES',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.dynamic_feed_rounded,
                    label: 'College Feed & Broadcasts',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/feed');
                    },
                  ),

                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                    child: Text(
                      'ADMINISTRATION CONSOLE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard Overview',
                    onTap: () => navigateToTab(0),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.people_rounded,
                    label: 'User Directory',
                    onTap: () => navigateToTab(1),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.business_rounded,
                    label: 'College Departments',
                    onTap: () => navigateToTab(2),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.account_balance_rounded,
                    label: 'Academic Structure',
                    onTap: () => navigateToTab(3),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.groups_rounded,
                    label: 'Clubs & Events Moderation',
                    onTap: () => navigateToTab(4),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.work_rounded,
                    label: 'Placements & Drives',
                    onTap: () => navigateToTab(5),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.bar_chart_rounded,
                    label: 'Analytics & Insights',
                    onTap: () => navigateToTab(6),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.settings_suggest_rounded,
                    label: 'Settings & Governance',
                    onTap: () => navigateToTab(7),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.pending_actions_rounded,
                    label: 'Profile Change Requests',
                    badgeCount: pendingCount,
                    onTap: () => navigateToTab(8),
                  ),

                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                    child: Text(
                      'ACCOUNT & GOVERNANCE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.person_outline,
                    label: 'My Profile',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/profile');
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.settings_outlined,
                    label: 'System Settings',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings');
                    },
                  ),
                ],
              ),
            ),

            // Logout Action
            Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.2)),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: _buildMenuItem(
                context,
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                iconColor: Colors.red.shade400,
                textColor: Colors.red.shade400,
                onTap: () async {
                  Navigator.pop(context);
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
