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
import '../providers/dept_admin_provider.dart';
import '../../domain/models/dept_admin_models.dart';
import '../widgets/dept_admin_drawer.dart';

class DeptPlacementView extends ConsumerWidget {
  const DeptPlacementView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placementAsync = ref.watch(deptPlacementProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const DeptAdminDrawer(),
      body: AtmosphericBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Placement Operations',
                            style: AppTypography.cardTitle.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: isDark ? AppColors.darkText : AppColors.primaryText,
                            ),
                          ),
                          Text(
                            'Department Drive Tracking & Status',
                            style: AppTypography.micro.copyWith(
                              color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: placementAsync.when(
                  loading: () => const CampusLoadingState(),
                  error: (err, _) => CampusErrorState(
                    title: 'Error loading placement data',
                    message: err.toString(),
                    onRetry: () => ref.refresh(deptPlacementProvider),
                  ),
                  data: (placement) {
                    return RefreshIndicator(
                      onRefresh: () async => ref.refresh(deptPlacementProvider.future),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.s16),
                        children: [
                          // 4 Metric Tiles (Screen 11)
                          Row(
                            children: [
                              Expanded(
                                child: CampusStatCard(
                                  title: 'Active Drives',
                                  value: '${placement.activeDrives}',
                                  subtitle: 'Eligible for IT',
                                  icon: Icons.work_outline,
                                  accentColor: const Color(0xFFF59E0B),
                                  onTap: () => context.push('/placement/drives'),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s12),
                              Expanded(
                                child: CampusStatCard(
                                  title: 'Eligible Students',
                                  value: '${placement.eligibleStudents}',
                                  subtitle: 'Final year cohort',
                                  icon: Icons.how_to_reg_outlined,
                                  accentColor: AppColors.primaryBlue,
                                  onTap: () => context.push('/dept-admin/students'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s12),
                          Row(
                            children: [
                              Expanded(
                                child: CampusStatCard(
                                  title: 'Applications',
                                  value: '${placement.applications}',
                                  subtitle: 'Submitted by students',
                                  icon: Icons.description_outlined,
                                  accentColor: const Color(0xFF8B5CF6),
                                  onTap: () => _showApplicationsSummary(context, placement, isDark),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s12),
                              Expanded(
                                child: CampusStatCard(
                                  title: 'Offers Received',
                                  value: '${placement.selected}',
                                  subtitle: 'Students placed',
                                  icon: Icons.celebration_outlined,
                                  accentColor: AppColors.success,
                                  onTap: () => _showOffersSummary(context, placement, isDark),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.s24),

                          // Active Drives List Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Active Department Drives',
                                style: AppTypography.cardTitle.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                '${placement.recentDrives.length} Drives',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          ...placement.recentDrives.map(
                            (drive) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: CampusGlassCard(
                                padding: const EdgeInsets.all(AppSpacing.s16),
                                onTap: () => context.push('/placement/drives/${drive.id}'),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            drive.companyName,
                                            style: AppTypography.cardTitle
                                                .copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            drive.packageCtc,
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      drive.roleTitle,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.darkText : AppColors.primaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Deadline: ${drive.deadline}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Text(
                                              'View Details',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(Icons.chevron_right, size: 16, color: Colors.blue),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s24),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showApplicationsSummary(BuildContext context, DeptPlacementSummary data, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.s20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Department Applications Overview',
              style: AppTypography.cardTitle.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              'Total submissions across all recruitment drives',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CampusStatCard(
                    title: 'Total Submitted',
                    value: '${data.applications}',
                    subtitle: 'By department students',
                    icon: Icons.description_outlined,
                    accentColor: const Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: CampusStatCard(
                    title: 'Offers Secured',
                    value: '${data.selected}',
                    subtitle: 'Confirmed placements',
                    icon: Icons.check_circle_outline,
                    accentColor: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.people_alt_outlined),
                label: const Text('View Department Students Directory'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/dept-admin/students');
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showOffersSummary(BuildContext context, DeptPlacementSummary data, bool isDark) {
    final placementRate = data.eligibleStudents > 0
        ? ((data.selected / data.eligibleStudents) * 100).toStringAsFixed(1)
        : '0.0';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.s20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Placement Offers & Conversion',
              style: AppTypography.cardTitle.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              'Cohort recruitment conversion and results',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CampusStatCard(
                    title: 'Offers Received',
                    value: '${data.selected}',
                    subtitle: 'Placed candidates',
                    icon: Icons.celebration_outlined,
                    accentColor: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: CampusStatCard(
                    title: 'Placement Rate',
                    value: '$placementRate%',
                    subtitle: 'Of eligible students',
                    icon: Icons.trending_up,
                    accentColor: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.work_outline),
                label: const Text('Browse All Placement Drives'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/placement/drives');
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
