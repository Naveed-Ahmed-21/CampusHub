import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_loading_state.dart';
import '../../../../core/widgets/campus_error_state.dart';
import '../providers/dept_admin_provider.dart';

class DeptAttendanceView extends ConsumerWidget {
  const DeptAttendanceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(deptAttendanceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const CampusAppBar(
        title: 'Attendance Tracking',
        subtitle: 'Cohort Monitoring & Shortage Alerts',
      ),
      body: AtmosphericBackground(
        child: SafeArea(
          child: attendanceAsync.when(
            loading: () => const CampusLoadingState(),
            error: (err, _) => CampusErrorState(
              title: 'Error loading attendance',
              message: err.toString(),
              onRetry: () => ref.refresh(deptAttendanceProvider),
            ),
            data: (att) {
              return RefreshIndicator(
                onRefresh: () async => ref.refresh(deptAttendanceProvider.future),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  children: [
                    // Main Gauge Card (Screen 9)
                    CampusGlassCard(
                      padding: const EdgeInsets.all(AppSpacing.s20),
                      child: Column(
                        children: [
                          Text(
                            'Department Overall Attendance',
                            style: AppTypography.cardTitle.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 140,
                            height: 140,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 130,
                                  height: 130,
                                  child: CircularProgressIndicator(
                                    value: att.averageAttendance / 100.0,
                                    strokeWidth: 12,
                                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${att.averageAttendance}%',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                    const Text('Average', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMetricTile('Present', '${att.breakdown['present'] ?? 0}%', Colors.green),
                              _buildMetricTile('Absent', '${att.breakdown['absent'] ?? 0}%', Colors.red),
                              _buildMetricTile('On Leave', '${att.breakdown['onLeave'] ?? 0}%', Colors.amber),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.s16),

                    // Attendance Shortage Alert Banner
                    CampusGlassCard(
                      padding: const EdgeInsets.all(AppSpacing.s16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (att.lowAttendanceCount > 0 ? Colors.red : Colors.green).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              att.lowAttendanceCount > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                              color: att.lowAttendanceCount > 0 ? Colors.red : Colors.green,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  att.lowAttendanceCount > 0
                                      ? '${att.lowAttendanceCount} Students < 75% Attendance'
                                      : 'All Students in Good Standing',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  att.lowAttendanceCount > 0
                                      ? 'Critical attendance shortage requires attention'
                                      : 'No attendance shortage alerts currently active',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (att.lowAttendanceCount > 0)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: () => context.push('/dept-admin/attendance/low'),
                              child: const Text('View List', style: TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.s20),

                    // Subject-wise Attendance Progress Bars
                    Text(
                      'Subject Attendance Distribution',
                      style: AppTypography.cardTitle.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),

                    if (att.subjectAttendance.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No subject attendance recorded yet',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                            ),
                          ),
                        ),
                      )
                    else
                      ...att.subjectAttendance.map((sub) {
                      final progress = sub.percentage / 100.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CampusGlassCard(
                          padding: const EdgeInsets.all(AppSpacing.s16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    sub.subject,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    '${sub.percentage}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: sub.percentage >= 75 ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.withValues(alpha: 0.15),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    sub.percentage >= 75 ? AppColors.primaryBlue : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
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

  Widget _buildMetricTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
