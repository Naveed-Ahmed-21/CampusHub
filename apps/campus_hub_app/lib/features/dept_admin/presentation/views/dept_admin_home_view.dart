import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_stat_card.dart';
import '../../../../core/widgets/campus_loading_state.dart';
import '../../../../core/widgets/campus_error_state.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../../../../core/widgets/campus_bottom_nav.dart';
import 'package:flutter/services.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../providers/dept_admin_provider.dart';
import '../widgets/dept_admin_drawer.dart';

class DeptAdminHomeView extends ConsumerWidget {
  const DeptAdminHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final dashboardAsync = ref.watch(deptDashboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const DeptAdminDrawer(),
      body: AtmosphericBackground(
        child: SafeArea(
          child: dashboardAsync.when(
            loading: () => const CampusLoadingState(),
            error: (err, _) => CampusErrorState(
              title: 'Dashboard Error',
              message: err.toString(),
              onRetry: () => ref.refresh(deptDashboardProvider),
            ),
            data: (dashboard) {
              final dept = dashboard.department;
              final kpis = dashboard.kpis;
              final alerts = dashboard.alerts;

              return RefreshIndicator(
                onRefresh: () async => ref.refresh(deptDashboardProvider.future),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Top Bar with Drawer Trigger & Notification
                    Row(
                      children: [
                        Builder(
                          builder: (innerContext) => IconButton(
                            icon: const Icon(Icons.menu),
                            onPressed: () => Scaffold.of(innerContext).openDrawer(),
                            tooltip: 'Department Menu',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s4),
                        CampusAvatar(
                          imageUrl: user?.avatarUrl,
                          name: user != null ? '${user.firstName} ${user.lastName}'.trim() : 'Dept Admin',
                          radius: 18,
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user != null ? '${user.firstName} ${user.lastName}'.trim() : 'Department Administrator',
                                style: AppTypography.cardTitle.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: isDark ? AppColors.darkText : AppColors.primaryText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'HOD • ${dept.degree} ${dept.name}',
                                style: AppTypography.micro.copyWith(
                                  color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_none_outlined),
                          onPressed: () => context.push('/notifications'),
                          tooltip: 'Notifications',
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.s16),

                    // Hero Department Overview Card (Screen 2)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.s20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF0F2747), const Color(0xFF1E3A5F)]
                              : [const Color(0xFF0F2747), const Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F2747).withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${dept.degree} • ${dept.code}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                '${dashboard.academicYear} • ${_formatTermSemester(dashboard.semester)}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s16),
                          Text(
                            dept.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dept.collegeName,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.s20),

                    // 4 KPI Summary Cards (2x2 Grid)
                    Row(
                      children: [
                        Expanded(
                          child: CampusStatCard(
                            title: 'Total Students',
                            value: '${kpis.totalStudents}',
                            subtitle: 'Enrolled in ${dept.code}',
                            icon: Icons.people_alt_outlined,
                            accentColor: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                            onTap: () => context.go('/dept-admin/students'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: CampusStatCard(
                            title: 'Department Faculty',
                            value: '${kpis.totalFaculty}',
                            subtitle: 'Active educators',
                            icon: Icons.badge_outlined,
                            accentColor: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                            onTap: () => context.push('/dept-admin/faculty'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    Row(
                      children: [
                        Expanded(
                          child: CampusStatCard(
                            title: 'Avg Attendance',
                            value: '${kpis.avgAttendance}%',
                            subtitle: 'Semester cohort',
                            icon: Icons.how_to_reg_outlined,
                            accentColor: AppColors.success,
                            onTap: () => context.push('/dept-admin/attendance'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: CampusStatCard(
                            title: 'Active Drives',
                            value: '${kpis.activePlacementDrives}',
                            subtitle: 'For ${dept.code} students',
                            icon: Icons.work_outline,
                            accentColor: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                            onTap: () => context.go('/dept-admin/placement'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.s24),

                    // Quick Actions Grid (8 items)
                    Text(
                      'Department Operations',
                      style: AppTypography.cardTitle.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? AppColors.darkText : AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s12),

                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 12,
                      children: [
                        _buildQuickAction(
                          context,
                          icon: Icons.groups_outlined,
                          label: 'Faculty',
                          color: const Color(0xFF3B82F6),
                          onTap: () => context.push('/dept-admin/faculty'),
                        ),
                        _buildQuickAction(
                          context,
                          icon: Icons.calendar_month_outlined,
                          label: 'Timetable',
                          color: const Color(0xFFF59E0B),
                          onTap: () => context.push('/dept-admin/timetable'),
                        ),
                        _buildQuickAction(
                          context,
                          icon: Icons.insert_chart_outlined,
                          label: 'Attendance',
                          color: const Color(0xFF10B981),
                          onTap: () => context.push('/dept-admin/attendance'),
                        ),
                        _buildQuickAction(
                          context,
                          icon: Icons.assignment_outlined,
                          label: 'Assignments',
                          color: const Color(0xFF8B5CF6),
                          onTap: () => context.push('/dept-admin/assignments'),
                        ),
                        _buildQuickAction(
                          context,
                          icon: Icons.quiz_outlined,
                          label: 'Assessments',
                          color: const Color(0xFFEC4899),
                          onTap: () => context.push('/dept-admin/assessments'),
                        ),
                        _buildQuickAction(
                          context,
                          icon: Icons.folder_shared_outlined,
                          label: 'Resources',
                          color: const Color(0xFF06B6D4),
                          onTap: () => context.push('/dept-admin/resources'),
                        ),
                        _buildQuickAction(
                          context,
                          icon: Icons.campaign_outlined,
                          label: 'Feed',
                          color: const Color(0xFFF97316),
                          onTap: () => context.push('/dept-admin/feed'),
                        ),
                        _buildQuickAction(
                          context,
                          icon: Icons.bar_chart_outlined,
                          label: 'Reports',
                          color: const Color(0xFF64748B),
                          onTap: () => context.push('/dept-admin/reports'),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.s24),

                    // Important Alerts Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Important Alerts',
                          style: AppTypography.cardTitle.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? AppColors.darkText : AppColors.primaryText,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Action Required',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s12),

                    // Low Attendance Alert Card
                    CampusGlassCard(
                      padding: const EdgeInsets.all(AppSpacing.s16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                          ),
                          const SizedBox(width: AppSpacing.s12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${alerts.lowAttendanceCount} Students Below 75% Attendance',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Immediate parent intimation & counseling recommended',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/dept-admin/attendance/low'),
                            child: const Text('View List'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.s12),

                    // Active Placement Drives Alert
                    CampusGlassCard(
                      padding: const EdgeInsets.all(AppSpacing.s16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.business_center_outlined, color: Colors.amber, size: 24),
                          ),
                          const SizedBox(width: AppSpacing.s12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${alerts.activeDrivesCount} Active Placement Drives for ${dept.code}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${kpis.eligibleStudents} students eligible for current drives',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/dept-admin/placement'),
                            child: const Text('Monitor'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.s16),
                    const CampusBottomNavSpacer(),
                  ],
                ),
              ),
            );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return _QuickActionButton(
      icon: icon,
      label: label,
      onTap: onTap,
    );
  }

  String _formatTermSemester(String semester) {
    final s = semester.trim();
    final lower = s.toLowerCase();
    if (lower.contains('1') ||
        lower.contains('3') ||
        lower.contains('5') ||
        lower.contains('7') ||
        lower.contains('odd')) {
      return 'Odd Semester';
    }
    if (lower.contains('2') ||
        lower.contains('4') ||
        lower.contains('6') ||
        lower.contains('8') ||
        lower.contains('even')) {
      return 'Even Semester';
    }
    if (lower.contains('semester')) {
      return 'Odd Semester';
    }
    return s.isNotEmpty ? s : 'Odd Semester';
  }
}

class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.secondaryCyan : AppColors.primaryBlue;
    final containerBg = isDark
        ? AppColors.primaryBlue.withValues(alpha: 0.12)
        : AppColors.primaryBlue.withValues(alpha: 0.08);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.primaryBlue.withValues(alpha: 0.12);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: containerBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(widget.icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: isDark ? AppColors.darkText : AppColors.primaryText,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
