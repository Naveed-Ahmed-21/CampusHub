import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/branding/gcee_brand.dart';
import '../../../../core/branding/gcee_logo.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../core/widgets/atmospheric_background.dart';

import '../../../profile/presentation/widgets/profile_story_avatar.dart';
import '../../../admin/presentation/widgets/admin_profile_dialogs.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../providers/dept_admin_provider.dart';
import '../widgets/dept_admin_drawer.dart';

class DeptAdminProfileView extends ConsumerWidget {
  const DeptAdminProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final dashboardAsync = ref.watch(deptDashboardProvider);
    final themeMode = ref.watch(themeNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final fullName = user != null && '${user.firstName} ${user.lastName}'.trim().isNotEmpty
        ? '${user.firstName} ${user.lastName}'.trim()
        : 'Department Administrator';
    final email = user?.email ?? 'deptadmin@gcee.ac.in';

    final deptData = dashboardAsync.value?.department;
    final deptName = deptData?.name ?? 'Department';
    final deptCode = deptData?.code ?? 'DEPT';
    final isIT = deptCode.toUpperCase() == 'IT' || deptName.toLowerCase().contains('information tech');
    final degree = isIT ? 'B.Tech' : 'B.E.';

    final surfaceCardColor = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.8)
        : Colors.white;
    final cardBorderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      drawer: const DeptAdminDrawer(),
      body: AtmosphericBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Builder(
                      builder: (innerContext) => IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => Scaffold.of(innerContext).openDrawer(),
                        tooltip: 'Department Menu',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: Text(
                        'Department HOD Profile',
                        style: AppTypography.pageTitle.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkText : AppColors.primaryText,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit Profile',
                      onPressed: () => AdminProfileDialogs.showEditProfile(
                        context,
                        ref,
                        user: user,
                        profile: null,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_outlined),
                      tooltip: 'Refresh Department Info',
                      onPressed: () {
                        ref.invalidate(deptDashboardProvider);
                        ref.invalidate(deptStudentsListProvider);
                        ref.invalidate(deptAcademicsProvider);
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  children: [
                    // 1. Department HOD Profile Hero Card
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceCardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cardBorderColor, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          ProfileStoryAvatar(
                            userId: user?.id ?? '',
                            avatarUrl: user?.avatarUrl,
                            name: fullName,
                            radius: 42,
                          ),

                          const SizedBox(height: 14),
                          Text(
                            fullName,
                            style: AppTypography.cardTitle.copyWith(fontSize: 19, fontWeight: FontWeight.w800),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Head of Department (HOD)',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$degree $deptName',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, size: 14, color: Colors.green),
                                SizedBox(width: 6),
                                Text(
                                  'Role: DEPT_ADMIN • Active Session',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit Profile'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => AdminProfileDialogs.showEditProfile(
                              context,
                              ref,
                              user: user,
                              profile: null,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 2. Department Overview Metrics
                    Text(
                      'Department Academic Scope',
                      style: AppTypography.captionMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDark ? AppColors.darkText : AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 10),

                    dashboardAsync.when(
                      loading: () => Container(
                        height: 90,
                        decoration: BoxDecoration(
                          color: surfaceCardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (dash) {
                        return Container(
                          decoration: BoxDecoration(
                            color: surfaceCardColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: cardBorderColor, width: 1),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPillarItem('Students', '${dash.kpis.totalStudents}', Icons.groups_outlined, isDark),
                              Container(height: 36, width: 1, color: cardBorderColor),
                              _buildPillarItem('Faculty', '${dash.kpis.totalFaculty}', Icons.school_outlined, isDark),
                              Container(height: 36, width: 1, color: cardBorderColor),
                              _buildPillarItem('Classes', '${dash.kpis.totalClasses}', Icons.class_outlined, isDark),
                              Container(height: 36, width: 1, color: cardBorderColor),
                              _buildPillarItem('Subjects', '${dash.kpis.totalSubjects}', Icons.menu_book_outlined, isDark),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // 3. Department Operations Management
                    Text(
                      'Administrative Operations',
                      style: AppTypography.captionMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDark ? AppColors.darkText : AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Material(
                      color: surfaceCardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: cardBorderColor, width: 1),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          _buildOpTile(
                            context,
                            icon: Icons.people_alt_outlined,
                            title: 'Department Students Roster',
                            subtitle: 'View batch-wise enrollment, sections, and records',
                            onTap: () => context.push('/dept-admin/students'),
                            isDark: isDark,
                          ),
                          const Divider(height: 1),
                          _buildOpTile(
                            context,
                            icon: Icons.assignment_ind_outlined,
                            title: 'Faculty & Curriculum Allocations',
                            subtitle: 'Subject mapping, syllabus coverage, and teaching staff',
                            onTap: () => context.push('/dept-admin/academics'),
                            isDark: isDark,
                          ),
                          const Divider(height: 1),
                          _buildOpTile(
                            context,
                            icon: Icons.work_outline,
                            title: 'Department Placement Performance',
                            subtitle: 'Student offers, drive participation, and eligibility',
                            onTap: () => context.push('/dept-admin/placement'),
                            isDark: isDark,
                          ),
                          const Divider(height: 1),
                          _buildOpTile(
                            context,
                            icon: Icons.description_outlined,
                            title: 'Accreditation & Department Reports',
                            subtitle: 'Generate NBA/NAAC dossiers and term summaries',
                            onTap: () => context.push('/dept-admin/reports'),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 4. Department Office Location & Contact
                    Text(
                      'Department Secretariat',
                      style: AppTypography.captionMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDark ? AppColors.darkText : AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(
                        color: surfaceCardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: cardBorderColor, width: 1),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const GceeLogo(size: 38),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      GceeBrand.institutionName,
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Department of $deptName',
                                      style: const TextStyle(fontSize: 11.5, color: AppColors.secondaryText),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          _buildSecretariatRow(
                            icon: Icons.meeting_room_outlined,
                            label: 'HOD Cabin',
                            value: 'Department Block, First Floor, Room D-101',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 8),
                          _buildSecretariatRow(
                            icon: Icons.alternate_email,
                            label: 'Official Dept Email',
                            value: 'hod.${deptCode.toLowerCase()}@gcee.ac.in',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 8),
                          _buildSecretariatRow(
                            icon: Icons.phone_in_talk_outlined,
                            label: 'Intercom Ext.',
                            value: '0424-2533374 Ext: 201',
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 5. System Preferences
                    Text(
                      'Preferences & Support',
                      style: AppTypography.captionMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDark ? AppColors.darkText : AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Material(
                      color: surfaceCardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: cardBorderColor, width: 1),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(
                              themeMode == ThemeMode.dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                              color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                            ),
                            title: const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text(
                              themeMode == ThemeMode.dark ? 'Dark Theme Active' : 'Light Theme Active',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Switch(
                              value: themeMode == ThemeMode.dark,
                              onChanged: (val) {
                                ref
                                    .read(themeNotifierProvider.notifier)
                                    .setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                              },
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Icon(Icons.notifications_active_outlined,
                                color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue),
                            title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            trailing: const Icon(Icons.chevron_right, size: 20),
                            onTap: () => context.push('/notifications'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Icon(Icons.help_outline,
                                color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue),
                            title: const Text('Help & Institutional Support', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            trailing: const Icon(Icons.chevron_right, size: 20),
                            onTap: () => context.push('/settings/help'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 6. Sign Out Button (Small & Simple)
                    Center(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.logout_rounded, size: 16, color: theme.colorScheme.error),
                        label: Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.error,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.35)),
                          backgroundColor: theme.colorScheme.error.withValues(alpha: 0.06),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          minimumSize: const Size(0, 36),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text('Confirm Sign Out'),
                              content: const Text(
                                'Are you sure you want to sign out of the Department Administrator account?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Sign Out'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            await ref.read(authControllerProvider.notifier).logout();
                            if (context.mounted) context.go('/login');
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillarItem(String label, String value, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(icon, size: 20, color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildOpTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 13),
      onTap: onTap,
    );
  }

  Widget _buildSecretariatRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10.5, color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
