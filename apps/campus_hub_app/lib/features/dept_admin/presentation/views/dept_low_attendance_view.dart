import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_loading_state.dart';
import '../../../../core/widgets/campus_error_state.dart';
import '../../../../core/widgets/campus_empty_state.dart';
import '../providers/dept_admin_provider.dart';

class DeptLowAttendanceView extends ConsumerWidget {
  const DeptLowAttendanceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowAttendanceAsync = ref.watch(deptLowAttendanceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const CampusAppBar(
        title: 'Low Attendance Alert',
        subtitle: 'Students with Attendance Below 75%',
      ),
      body: AtmosphericBackground(
        child: SafeArea(
          child: lowAttendanceAsync.when(
            loading: () => const CampusLoadingState(),
            error: (err, _) => CampusErrorState(
              title: 'Error loading low attendance records',
              message: err.toString(),
              onRetry: () => ref.refresh(deptLowAttendanceProvider),
            ),
            data: (records) {
              if (records.isEmpty) {
                return const CampusEmptyState(
                  title: 'All Clear!',
                  description: 'No students currently fall below the 75% attendance threshold.',
                  icon: Icons.check_circle_outline,
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.refresh(deptLowAttendanceProvider.future),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final item = records[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CampusGlassCard(
                        padding: const EdgeInsets.all(AppSpacing.s16),
                        onTap: item.id.isNotEmpty ? () => context.push('/dept-admin/students/${item.id}') : null,
                        child: Row(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CampusAvatar(
                                  imageUrl: item.avatarUrl,
                                  name: item.name,
                                  radius: 22,
                                ),
                                Positioned(
                                  bottom: -4,
                                  right: -4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.white, width: 1),
                                    ),
                                    child: Text(
                                      '${item.attendancePercentage}%',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: AppSpacing.s12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.regNumber} • ${item.className}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Subject: ${item.subject}',
                                    style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
