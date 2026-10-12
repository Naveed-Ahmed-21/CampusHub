import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../providers/dept_admin_provider.dart';

class DeptAdminDrawer extends ConsumerWidget {
  const DeptAdminDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final dashboardAsync = ref.watch(deptDashboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String deptName = dashboardAsync.value?.department.name ?? 'Department';
    final String degree = dashboardAsync.value?.department.degree ?? '';
    final String academicYear = dashboardAsync.value?.academicYear ?? '';
    final String semester = dashboardAsync.value?.semester ?? '';

    return Drawer(
      backgroundColor: isDark ? AppColors.darkBase : const Color(0xFF0F2747),
      child: SafeArea(
        child: Column(
          children: [
            // Header Profile Card
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s20, AppSpacing.s20, AppSpacing.s20, AppSpacing.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CampusAvatar(
                        imageUrl: user?.avatarUrl,
                        name: user != null ? '${user.firstName} ${user.lastName}'.trim() : 'Dept Admin',
                        radius: 26,
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user != null ? '${user.firstName} ${user.lastName}'.trim() : 'Department Administrator',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              degree.isNotEmpty ? 'HOD • $degree $deptName' : 'HOD • $deptName',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (user?.email != null && user!.email.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                user.email,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  // Academic Term Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school, size: 14, color: AppColors.secondaryCyan),
                        const SizedBox(width: 6),
                        Text(
                          '$academicYear • $semester',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // Navigation List Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.groups_outlined,
                    label: 'Faculty Directory',
                    route: '/dept-admin/faculty',
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.calendar_today_outlined,
                    label: 'Timetable Management',
                    route: '/dept-admin/timetable',
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.assessment_outlined,
                    label: 'Attendance Tracking',
                    route: '/dept-admin/attendance',
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.assignment_outlined,
                    label: 'Assignments & Submissions',
                    route: '/dept-admin/assignments',
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.fact_check_outlined,
                    label: 'Internal Assessments',
                    route: '/dept-admin/assessments',
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.folder_shared_outlined,
                    label: 'Subject Resources',
                    route: '/dept-admin/resources',
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.campaign_outlined,
                    label: 'Department Feed & Notices',
                    route: '/dept-admin/feed',
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.analytics_outlined,
                    label: 'Reports & Analytics',
                    route: '/dept-admin/reports',
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.notifications_none_outlined,
                    label: 'Department Notifications',
                    route: '/notifications',
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    route: '/dept-admin/settings',
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // Footer Logout
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: InkWell(
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.logout, color: Colors.redAccent, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Logout Account',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
  }) {
    final currentPath = GoRouterState.of(context).uri.toString();
    final isSelected = currentPath == route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: isSelected ? AppColors.secondaryCyan.withValues(alpha: 0.15) : Colors.transparent,
        leading: Icon(
          icon,
          color: isSelected ? AppColors.secondaryCyan : Colors.white70,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.85),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
        onTap: () {
          Navigator.of(context).pop();
          context.push(route);
        },
      ),
    );
  }
}
