import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_loading_state.dart';
import '../../../../core/widgets/campus_error_state.dart';
import '../../../../core/widgets/campus_empty_state.dart';
import '../providers/dept_admin_provider.dart';

class DeptAssessmentsView extends ConsumerWidget {
  const DeptAssessmentsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessmentsAsync = ref.watch(deptAssessmentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const CampusAppBar(
        title: 'Internal Assessments',
        subtitle: 'Continuous Assessment & Examination Records',
      ),
      body: AtmosphericBackground(
        child: SafeArea(
          child: assessmentsAsync.when(
            loading: () => const CampusLoadingState(),
            error: (err, _) => CampusErrorState(
              title: 'Error loading assessments',
              message: err.toString(),
              onRetry: () => ref.refresh(deptAssessmentsProvider),
            ),
            data: (assessments) {
              if (assessments.isEmpty) {
                return const CampusEmptyState(
                  title: 'No Assessments Scheduled',
                  description: 'No examination evaluations recorded yet.',
                  icon: Icons.fact_check_outlined,
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.refresh(deptAssessmentsProvider.future),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  itemCount: assessments.length,
                  itemBuilder: (context, index) {
                    final ass = assessments[index];
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
                                Expanded(
                                  child: Text(
                                    ass.name,
                                    style: AppTypography.cardTitle.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    ass.className,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${ass.subjectName} • Incharge: ${ass.facultyName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      ass.averageScore > 0 ? '${ass.averageScore}' : 'Pending',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text('Average Score', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      ass.passPercentage > 0 ? '${ass.passPercentage}%' : 'Pending',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text('Pass Percentage', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      ass.date,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text('Date', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
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
