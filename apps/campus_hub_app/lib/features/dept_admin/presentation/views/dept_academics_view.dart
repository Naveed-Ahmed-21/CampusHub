import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_loading_state.dart';
import '../../../../core/widgets/campus_error_state.dart';
import '../providers/dept_admin_provider.dart';
import '../widgets/dept_admin_drawer.dart';

class DeptAcademicsView extends ConsumerWidget {
  const DeptAcademicsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academicsAsync = ref.watch(deptAcademicsProvider);
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
                            'Academics & Batches',
                            style: AppTypography.cardTitle.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: isDark ? AppColors.darkText : AppColors.primaryText,
                            ),
                          ),
                          Text(
                            'Curriculum & Program Hierarchy',
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
                child: academicsAsync.when(
                  loading: () => const CampusLoadingState(),
                  error: (err, _) => CampusErrorState(
                    title: 'Error loading academics',
                    message: err.toString(),
                    onRetry: () => ref.refresh(deptAcademicsProvider),
                  ),
                  data: (academics) {
                    final dept = academics.department;

                    return RefreshIndicator(
                      onRefresh: () async => ref.refresh(deptAcademicsProvider.future),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.s16),
                        children: [
                          // Academic Banner
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.s16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [const Color(0xFF1E3A5F), const Color(0xFF0F2747)]
                                    : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.school, color: Colors.white, size: 32),
                                const SizedBox(width: AppSpacing.s12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${dept.degree} • ${dept.name}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Academic Year ${academics.academicYear} • ${academics.semester}',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.85),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.s20),

                          // Batches Section
                          Text(
                            'Active Academic Batches',
                            style: AppTypography.cardTitle.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 10),

                          SizedBox(
                            height: 110,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: academics.batches.length,
                              itemBuilder: (context, index) {
                                final batch = academics.batches[index];
                                return Container(
                                  width: 150,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: CampusGlassCard(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          batch.yearLabel,
                                          style: const TextStyle(
                                            color: AppColors.primaryBlue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          batch.name,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${batch.admissionYear} - ${batch.graduationYear}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: AppSpacing.s20),

                          // Classes & Sections
                          Text(
                            'Classes & Sections',
                            style: AppTypography.cardTitle.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 10),

                          ...academics.classes.map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: CampusGlassCard(
                                padding: const EdgeInsets.all(AppSpacing.s16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        c.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.s12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Section ${c.section} • Year ${c.yearOfStudy}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${c.studentCount} Students Enrolled',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.s20),

                          // Subjects List
                          Text(
                            'Department Curriculum Subjects',
                            style: AppTypography.cardTitle.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 10),

                          ...academics.subjects.map(
                            (sub) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: CampusGlassCard(
                                padding: const EdgeInsets.all(AppSpacing.s16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue)
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        sub.code,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.s12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sub.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Incharge: ${sub.facultyName} • ${sub.credits} Credits',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                            ),
                                          ),
                                        ],
                                      ),
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
}
