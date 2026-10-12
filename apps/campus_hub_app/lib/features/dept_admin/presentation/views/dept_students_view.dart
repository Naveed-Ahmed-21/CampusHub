import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_loading_state.dart';
import '../../../../core/widgets/campus_error_state.dart';
import '../../../../core/widgets/campus_empty_state.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../providers/dept_admin_provider.dart';
import '../../domain/models/dept_admin_models.dart';
import '../widgets/dept_admin_drawer.dart';

class DeptStudentsView extends ConsumerStatefulWidget {
  const DeptStudentsView({super.key});

  @override
  ConsumerState<DeptStudentsView> createState() => _DeptStudentsViewState();
}

class _DeptStudentsViewState extends ConsumerState<DeptStudentsView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedYear = 'All';
  String _selectedPlacement = 'All';

  final List<String> _yearOptions = ['All', '1st Year', '2nd Year', '3rd Year', '4th Year'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilter() {
    String? yearParam;
    if (_selectedYear == '1st Year') yearParam = '1';
    if (_selectedYear == '2nd Year') yearParam = '2';
    if (_selectedYear == '3rd Year') yearParam = '3';
    if (_selectedYear == '4th Year') yearParam = '4';

    ref.read(deptStudentsFilterProvider.notifier).state = DeptStudentsFilter(
      year: yearParam,
      search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
      placementStatus: _selectedPlacement != 'All' ? _selectedPlacement : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(deptStudentsListProvider);
    final dashboardAsync = ref.watch(deptDashboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deptName = dashboardAsync.valueOrNull?.department.name ?? 'Department Students';

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
                            'Students Directory',
                            style: AppTypography.cardTitle.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: isDark ? AppColors.darkText : AppColors.primaryText,
                            ),
                          ),
                          Text(
                            deptName,
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

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _updateFilter(),
                    decoration: InputDecoration(
                      hintText: 'Search by student name, roll number...',
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
                                _updateFilter();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Filter Chips Row (Year)
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                  itemCount: _yearOptions.length,
                  itemBuilder: (context, index) {
                    final year = _yearOptions[index];
                    final isSelected = _selectedYear == year;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(year),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.darkSecondaryText : AppColors.primaryText),
                        ),
                        selected: isSelected,
                        selectedColor: isDark ? AppColors.electricBlue : AppColors.primaryBlue,
                        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark ? AppColors.darkBorder : AppColors.border),
                        ),
                        onSelected: (val) {
                          setState(() => _selectedYear = year);
                          _updateFilter();
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Students List Content
              Expanded(
                child: studentsAsync.when(
                  loading: () => const CampusLoadingState(),
                  error: (err, _) => CampusErrorState(
                    title: 'Failed to load students',
                    message: err.toString(),
                    onRetry: () => ref.refresh(deptStudentsListProvider),
                  ),
                  data: (students) {
                    if (students.isEmpty) {
                      return CampusEmptyState(
                        title: 'No Students Found',
                        description: 'No students matched the selected search or filters.',
                        icon: Icons.people_outline,
                        actionLabel: 'Reset Filters',
                        onAction: () {
                          _searchController.clear();
                          setState(() {
                            _selectedYear = 'All';
                            _selectedPlacement = 'All';
                          });
                          _updateFilter();
                        },
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => ref.refresh(deptStudentsListProvider.future),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.s16),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          return _buildStudentCard(context, student, isDark);
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

  Widget _buildStudentCard(BuildContext context, DeptStudent student, bool isDark) {
    Color statusColor = const Color(0xFF3B82F6);
    if (student.placementStatus == 'PLACED') {
      statusColor = const Color(0xFF10B981);
    } else if (student.placementStatus == 'SHORTLISTED') {
      statusColor = const Color(0xFFF59E0B);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CampusGlassCard(
        padding: const EdgeInsets.all(AppSpacing.s16),
        onTap: () => context.push('/dept-admin/students/${student.id}'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CampusAvatar(
              imageUrl: student.avatarUrl,
              name: student.name,
              radius: 24,
            ),
            const SizedBox(width: AppSpacing.s12),
            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          student.name,
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkText : AppColors.primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          student.placementStatus,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${student.rollNumber} • ${student.section}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Pills: CGPA & Attendance
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.grade_outlined, size: 12, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              '${student.cgpa.toStringAsFixed(2)} CGPA',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: student.attendance >= 75
                              ? Colors.green.withValues(alpha: 0.08)
                              : Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.how_to_reg_outlined,
                              size: 12,
                              color: student.attendance >= 75 ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${student.attendance}% Attendance',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: student.attendance >= 75 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
