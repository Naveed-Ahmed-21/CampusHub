import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_stat_card.dart';
import '../../../../core/widgets/campus_loading_state.dart';
import '../../../../core/widgets/campus_error_state.dart';
import '../../domain/models/dept_admin_models.dart';
import '../providers/dept_admin_provider.dart';
import '../../services/dept_accreditation_pdf_service.dart';

class DeptReportsView extends ConsumerStatefulWidget {
  const DeptReportsView({super.key});

  @override
  ConsumerState<DeptReportsView> createState() => _DeptReportsViewState();
}

class _DeptReportsViewState extends ConsumerState<DeptReportsView> {
  final List<String> _yearOptions = ['2026 - 2027', '2025 - 2026', '2024 - 2025'];

  @override
  Widget build(BuildContext context) {
    final selectedYear = ref.watch(deptReportsYearProvider);
    final reportsAsync = ref.watch(deptReportsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CampusAppBar(
        title: 'Reports & Analytics',
        subtitle: 'Department KPI Reports & Accreditations',
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedYear,
                isDense: true,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkText : AppColors.primaryText,
                ),
                items: _yearOptions
                    .map((yr) => DropdownMenuItem(value: yr, child: Text(yr)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(deptReportsYearProvider.notifier).state = val;
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: AtmosphericBackground(
        child: SafeArea(
          child: reportsAsync.when(
            loading: () => const CampusLoadingState(),
            error: (err, _) => CampusErrorState(
              title: 'Error loading reports',
              message: err.toString(),
              onRetry: () => ref.refresh(deptReportsProvider),
            ),
            data: (report) {
              final metrics = report.metrics;
              final placement = report.placementStatus;

              final deptInfo = ref.watch(deptDashboardProvider).valueOrNull?.department ??
                  const DeptInfo(
                    id: '',
                    name: 'Information Technology',
                    code: 'IT',
                    degree: 'B.Tech',
                    collegeName: 'Government College of Engineering, Erode',
                  );
              final deptCode = deptInfo.code;

              return RefreshIndicator(
                onRefresh: () async => ref.refresh(deptReportsProvider.future),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  children: [
                    // 4 Metrics Tiles (Screen 13)
                    Row(
                      children: [
                        Expanded(
                          child: CampusStatCard(
                            title: 'Total Students',
                            value: '${metrics.students}',
                            subtitle: 'Enrolled in $deptCode',
                            icon: Icons.people_alt_outlined,
                            accentColor: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: CampusStatCard(
                            title: 'Active Faculty',
                            value: '${metrics.faculty}',
                            subtitle: 'Teaching staff',
                            icon: Icons.badge_outlined,
                            accentColor: const Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    Row(
                      children: [
                        Expanded(
                          child: CampusStatCard(
                            title: 'Average CGPA',
                            value: metrics.avgCgpa.toStringAsFixed(2),
                            subtitle: 'Academic mean',
                            icon: Icons.auto_awesome_outlined,
                            accentColor: const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: CampusStatCard(
                            title: 'Attendance Rate',
                            value: '${metrics.attendance}%',
                            subtitle: 'Semester average',
                            icon: Icons.how_to_reg_outlined,
                            accentColor: const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.s24),

                    // "Students by Year" Bar Chart (Screen 13)
                    Text(
                      'Students by Year',
                      style: AppTypography.cardTitle.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),

                    CampusGlassCard(
                      intensity: GlassIntensity.medium,
                      padding: const EdgeInsets.all(AppSpacing.s16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enrollment distribution across 4 academic years',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 160,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: report.studentsByYear.map((item) {
                                return _buildBar(item.year, item.count, 130, isDark);
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Total IT Enrollment: ${metrics.students} Students',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.s24),

                    // "Placement Status" Breakdown Card (Screen 13)
                    Text(
                      'Placement Status (Final Year)',
                      style: AppTypography.cardTitle.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),

                    CampusGlassCard(
                      intensity: GlassIntensity.medium,
                      padding: const EdgeInsets.all(AppSpacing.s16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Cohort Placement Distribution',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                ),
                              ),
                              Text(
                                '${placement.total} Eligible',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildPlacementProgressBar('Placed Students', placement.placed, placement.total, Colors.green),
                          const SizedBox(height: 12),
                          _buildPlacementProgressBar('Shortlisted in Interviews', placement.shortlisted, placement.total, Colors.amber),
                          const SizedBox(height: 12),
                          _buildPlacementProgressBar('Applied to Drives', placement.applied, placement.total, Colors.blue),
                          const SizedBox(height: 12),
                          _buildPlacementProgressBar('Yet to Apply', placement.eligible, placement.total, Colors.grey),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.s24),

                    // Export Report Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.electricBlue : AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Export Accreditation PDF Report', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        await DeptAccreditationPdfService.generateAndDownloadReport(
                          context: context,
                          reportData: report,
                          deptInfo: deptInfo,
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.s24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBar(String label, int count, int max, bool isDark) {
    final heightRatio = (count / max).clamp(0.1, 1.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$count',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          width: 38,
          height: 120 * heightRatio,
          decoration: BoxDecoration(
            color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildPlacementProgressBar(String title, int count, int total, Color color) {
    final ratio = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
    final percentage = (ratio * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('$count ($percentage%)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: Colors.grey.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
