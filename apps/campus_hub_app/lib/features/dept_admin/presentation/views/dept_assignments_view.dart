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
import '../../domain/models/dept_admin_models.dart';

class DeptAssignmentsView extends ConsumerStatefulWidget {
  const DeptAssignmentsView({super.key});

  @override
  ConsumerState<DeptAssignmentsView> createState() => _DeptAssignmentsViewState();
}

class _DeptAssignmentsViewState extends ConsumerState<DeptAssignmentsView> {
  final List<String> _filters = ['All', 'Due', 'Published', 'Draft', 'Overdue'];
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(deptAssignmentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const CampusAppBar(
        title: 'Assignments & Submissions',
        subtitle: 'Department Coursework & Tracking',
      ),
      body: AtmosphericBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Filter Chips
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() => _selectedFilter = filter);
                          ref.read(deptAssignmentsStatusFilterProvider.notifier).state =
                              filter != 'All' ? filter : null;
                        },
                      ),
                    );
                  },
                ),
              ),

              // Assignments List
              Expanded(
                child: assignmentsAsync.when(
                  loading: () => const CampusLoadingState(),
                  error: (err, _) => CampusErrorState(
                    title: 'Error loading assignments',
                    message: err.toString(),
                    onRetry: () => ref.refresh(deptAssignmentsProvider),
                  ),
                  data: (assignments) {
                    if (assignments.isEmpty) {
                      return const CampusEmptyState(
                        title: 'No Assignments Found',
                        description: 'No coursework assignments recorded under this category.',
                        icon: Icons.assignment_outlined,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => ref.refresh(deptAssignmentsProvider.future),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.s16),
                        itemCount: assignments.length,
                        itemBuilder: (context, index) {
                          final asg = assignments[index];
                          return _buildAssignmentCard(context, asg, isDark);
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

  Widget _buildAssignmentCard(BuildContext context, DeptAssignment asg, bool isDark) {
    final progress = asg.totalCount > 0 ? (asg.submittedCount / asg.totalCount) : 0.0;
    Color statusColor = Colors.blue;
    if (asg.status == 'Published') statusColor = Colors.green;
    if (asg.status == 'Overdue') statusColor = Colors.red;
    if (asg.status == 'Draft') statusColor = Colors.grey;

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
                    asg.title,
                    style: AppTypography.cardTitle.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    asg.status,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${asg.subjectName} • ${asg.facultyName} • ${asg.className}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Submissions: ${asg.submittedCount} / ${asg.totalCount}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Due: ${asg.dueDate}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(progress > 0.8 ? Colors.green : Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
