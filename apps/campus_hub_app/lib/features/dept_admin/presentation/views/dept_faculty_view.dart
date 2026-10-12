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
import '../../../../core/widgets/campus_avatar.dart';
import '../../../../core/widgets/campus_bottom_sheet.dart';
import '../providers/dept_admin_provider.dart';
import '../../domain/models/dept_admin_models.dart';

class DeptFacultyView extends ConsumerStatefulWidget {
  const DeptFacultyView({super.key});

  @override
  ConsumerState<DeptFacultyView> createState() => _DeptFacultyViewState();
}

class _DeptFacultyViewState extends ConsumerState<DeptFacultyView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final facultyAsync = ref.watch(deptFacultyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const CampusAppBar(
        title: 'Faculty Directory',
        subtitle: 'Department Teaching Staff & Course Allocations',
      ),
      body: AtmosphericBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      ref.read(deptFacultySearchProvider.notifier).state = val.trim();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search faculty by name...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(deptFacultySearchProvider.notifier).state = '';
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              // Faculty List
              Expanded(
                child: facultyAsync.when(
                  loading: () => const CampusLoadingState(),
                  error: (err, _) => CampusErrorState(
                    title: 'Error loading faculty',
                    message: err.toString(),
                    onRetry: () => ref.refresh(deptFacultyProvider),
                  ),
                  data: (facultyList) {
                    if (facultyList.isEmpty) {
                      return CampusEmptyState(
                        title: 'No Faculty Members Found',
                        description: 'Try adjusting your search query.',
                        icon: Icons.groups_outlined,
                        actionLabel: 'Clear Search',
                        onAction: () {
                          _searchController.clear();
                          ref.read(deptFacultySearchProvider.notifier).state = '';
                        },
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => ref.refresh(deptFacultyProvider.future),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                        itemCount: facultyList.length,
                        itemBuilder: (context, index) {
                          final faculty = facultyList[index];
                          return _buildFacultyCard(context, faculty, isDark);
                        },
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

  Widget _buildFacultyCard(BuildContext context, DeptFaculty faculty, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CampusGlassCard(
        padding: const EdgeInsets.all(AppSpacing.s16),
        onTap: () => _showFacultyDetails(context, faculty, isDark),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CampusAvatar(
                  imageUrl: faculty.avatarUrl,
                  name: faculty.name,
                  radius: 24,
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        faculty.name,
                        style: AppTypography.cardTitle.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkText : AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        faculty.designation,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${faculty.workloadHours} hrs/wk',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.menu_book_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                const Text('Assigned: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: faculty.assignedSubjects
                        .map(
                          (sub) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              sub,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFacultyDetails(BuildContext context, DeptFaculty faculty, bool isDark) {
    CampusBottomSheet.show(
      context: context,
      title: 'Faculty Details',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CampusAvatar(
                imageUrl: faculty.avatarUrl,
                name: faculty.name,
                radius: 32,
              ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      faculty.name,
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkText : AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      faculty.designation,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      faculty.email,
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
          const SizedBox(height: 16),
          Divider(color: isDark ? AppColors.darkBorder : AppColors.border),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${faculty.workloadHours} hrs',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const SizedBox(height: 2),
                      Text('Weekly Workload', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${faculty.assignedSubjects.length}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const SizedBox(height: 2),
                      Text('Subjects', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Teaching Subjects',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkText : AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: faculty.assignedSubjects
                .map(
                  (sub) => Chip(
                    label: Text(sub),
                    backgroundColor: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue)
                        .withValues(alpha: 0.1),
                    side: BorderSide(
                      color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.3),
                    ),
                  ),
                )
                .toList(),
          ),
          if (faculty.classes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Class Allocations',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkText : AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: faculty.classes
                  .map(
                    (cls) => Chip(
                      label: Text(cls),
                      backgroundColor: Colors.purple.withValues(alpha: 0.1),
                      side: BorderSide(color: Colors.purple.withValues(alpha: 0.3)),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
