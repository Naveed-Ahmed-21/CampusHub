import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_status_badge.dart';
import '../../../../core/widgets/campus_loading_state.dart';
import '../../../../core/widgets/campus_empty_state.dart';
import '../../../../core/widgets/campus_error_state.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../providers/placement_provider.dart';

class StudentsDirectoryView extends ConsumerStatefulWidget {

  const StudentsDirectoryView({super.key});

  @override
  ConsumerState<StudentsDirectoryView> createState() => _StudentsDirectoryViewState();
}

class _StudentsDirectoryViewState extends ConsumerState<StudentsDirectoryView> {
  String _selectedStatus = 'ALL';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  final List<String> _statusFilters = ['ALL', 'PLACED', 'OFFERED', 'IN_PROCESS', 'ELIGIBLE'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studentsAsync = ref.watch(placementStudentsProvider(_selectedStatus));

    return Scaffold(
      body: AtmosphericBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const CampusBackButton(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Students Directory',
                            style: AppTypography.pageTitle.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkText : AppColors.primaryText,
                            ),
                          ),
                          Text(
                            'Search candidate profiles, CGPA, and placement readiness',
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, size: 20, color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
                      hintText: 'Search by student name or roll number...',
                      hintStyle: AppTypography.captionMedium.copyWith(
                        color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),

              // Status Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: _statusFilters.map((st) {
                    final isSelected = _selectedStatus == st;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(
                          st == 'ALL' ? 'All Students' : st.replaceAll('_', ' '),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.primaryText),
                          ),
                        ),
                        selectedColor: isDark ? AppColors.primaryBlue : AppColors.primaryBlue,
                        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                        onSelected: (val) {
                          if (val) setState(() => _selectedStatus = st);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Students List
              Expanded(
                child: studentsAsync.when(
                  loading: () => const CampusLoadingState(),
                  error: (err, _) => CampusErrorState(
                    message: 'Failed to load students',
                    onRetry: () => ref.refresh(placementStudentsProvider(_selectedStatus)),
                  ),
                  data: (students) {
                    final filtered = students.where((s) {
                      if (_searchQuery.isEmpty) return true;
                      final q = _searchQuery.toLowerCase();
                      return s.fullName.toLowerCase().contains(q) ||
                          (s.rollNumber?.toLowerCase().contains(q) ?? false) ||
                          s.email.toLowerCase().contains(q);
                    }).toList();

                    if (filtered.isEmpty) {
                      return CampusEmptyState(
                        title: 'No Students Found',
                        description: _searchQuery.isEmpty
                            ? 'No students found in this placement category.'
                            : 'No students match "$_searchQuery".',
                        icon: Icons.people_outline,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => ref.refresh(placementStudentsProvider(_selectedStatus)),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final student = filtered[index];
                          return CampusGlassCard(
                            intensity: GlassIntensity.medium,
                            onTap: () => context.push('/placement/students/${student.id}'),
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                CampusAvatar(
                                  imageUrl: student.avatarUrl,
                                  name: student.fullName,
                                  radius: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student.fullName,
                                        style: AppTypography.captionMedium.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: isDark ? AppColors.darkText : AppColors.primaryText,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${student.rollNumber ?? 'Roll N/A'} • ${student.departmentCode ?? 'Branch N/A'}',
                                        style: AppTypography.micro.copyWith(
                                          color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    CampusStatusBadge(
                                      label: student.placementStatus,
                                      type: student.placementStatus == 'PLACED'
                                          ? StatusBadgeType.success
                                          : (student.placementStatus == 'OFFERED' ? StatusBadgeType.warning : StatusBadgeType.info),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'CGPA: ${student.cgpa > 0 ? student.cgpa.toStringAsFixed(2) : 'N/A'}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
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
}
