import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_loading_state.dart';
import '../../../../core/widgets/campus_error_state.dart';
import '../../../../core/widgets/campus_empty_state.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../providers/dept_admin_provider.dart';
import '../../domain/models/dept_admin_models.dart';

class DeptStudentProfileView extends ConsumerStatefulWidget {
  final String studentId;

  const DeptStudentProfileView({super.key, required this.studentId});

  @override
  ConsumerState<DeptStudentProfileView> createState() => _DeptStudentProfileViewState();
}

class _DeptStudentProfileViewState extends ConsumerState<DeptStudentProfileView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentAsync = ref.watch(deptStudentDetailProvider(widget.studentId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const CampusAppBar(
        title: 'Student Profile',
        subtitle: 'Department Academic & Placement Record',
      ),
      body: AtmosphericBackground(
        child: SafeArea(
          child: studentAsync.when(
            loading: () => const CampusLoadingState(),
            error: (err, _) => CampusErrorState(
              title: 'Error loading student',
              message: err.toString(),
              onRetry: () => ref.refresh(deptStudentDetailProvider(widget.studentId)),
            ),
            data: (student) {
              return NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.s16),
                      child: Column(
                        children: [
                          // Hero Profile Card
                          CampusGlassCard(
                            intensity: GlassIntensity.medium,
                            padding: const EdgeInsets.all(AppSpacing.s20),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    CampusAvatar(
                                      imageUrl: student.avatarUrl,
                                      name: student.name,
                                      radius: 36,
                                    ),
                                    const SizedBox(width: AppSpacing.s16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student.name,
                                            style: AppTypography.cardTitle.copyWith(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? AppColors.darkText : AppColors.primaryText,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Roll No: ${student.rollNumber} • ${student.section}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${student.degree} ${student.department}',
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
                                const SizedBox(height: AppSpacing.s20),
                                // 4 Stat Pillars
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatPillar('CGPA', student.cgpa.toStringAsFixed(2), Colors.blue, isDark),
                                    _buildStatPillar(
                                      'Attendance',
                                      '${student.attendance}%',
                                      student.attendance >= 75 ? Colors.green : Colors.red,
                                      isDark,
                                    ),
                                    _buildStatPillar('Backlogs', '${student.backlogs}', Colors.orange, isDark),
                                    _buildStatPillar('Placement', student.placementStatus, Colors.purple, isDark),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s16),
                          // Tab Bar
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              isScrollable: false,
                              indicatorColor: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                              indicatorWeight: 3,
                              labelColor: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                              unselectedLabelColor: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              tabs: const [
                                Tab(text: 'Overview'),
                                Tab(text: 'Academics'),
                                Tab(text: 'Placement'),
                                Tab(text: 'Activity'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _KeepAliveTab(child: _buildOverviewTab(student, isDark)),
                    _KeepAliveTab(child: _buildAcademicsTab(student, isDark)),
                    _KeepAliveTab(child: _buildPlacementTab(student, isDark)),
                    _KeepAliveTab(child: _buildActivityTab(student, isDark)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatPillar(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
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

  Widget _buildOverviewTab(DeptStudentDetail student, bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      children: [
        CampusGlassCard(
          intensity: GlassIntensity.medium,
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contact Information',
                style: AppTypography.cardTitle.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.email_outlined, 'Institutional Email', student.email, isDark),
              const Divider(height: 20),
              _buildInfoRow(Icons.phone_outlined, 'Mobile Number', student.phone, isDark),
              const Divider(height: 20),
              _buildInfoRow(Icons.badge_outlined, 'Registration Number', student.regNumber, isDark),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CampusGlassCard(
          intensity: GlassIntensity.medium,
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verified Skills & Technical Competencies',
                style: AppTypography.cardTitle.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 12),
              if (student.skills.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: student.skills
                      .map(
                        (skill) => Chip(
                          label: Text(skill),
                          backgroundColor: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue)
                              .withValues(alpha: 0.1),
                          side: BorderSide(
                            color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.3),
                          ),
                        ),
                      )
                      .toList(),
                )
              else
                Text(
                  'No verified technical skills recorded yet.',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAcademicsTab(DeptStudentDetail student, bool isDark) {
    if (student.courses.isEmpty) {
      return const CampusEmptyState(
        title: 'No Course Enrollments',
        description: 'No active academic courses found for this student.',
        icon: Icons.menu_book_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      itemCount: student.courses.length,
      itemBuilder: (context, index) {
        final c = student.courses[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CampusGlassCard(
            intensity: GlassIntensity.medium,
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    c.code,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Attendance: ${c.attendance} • Internal: ${c.internal}',
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
        );
      },
    );
  }

  Widget _buildPlacementTab(DeptStudentDetail student, bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      children: [
        Row(
          children: [
            Expanded(
              child: CampusGlassCard(
                intensity: GlassIntensity.medium,
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Column(
                  children: [
                    Text('${student.applicationsCount}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 4),
                    const Text('Applications', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: CampusGlassCard(
                intensity: GlassIntensity.medium,
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Column(
                  children: [
                    Text('${student.offersCount}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 4),
                    const Text('Offers Received', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CampusGlassCard(
          intensity: GlassIntensity.medium,
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Campus Drive Participation',
                style: AppTypography.cardTitle.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 12),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    student.applicationsCount == 0
                        ? 'No campus drive participation recorded yet.'
                        : '${student.applicationsCount} application(s) submitted • ${student.offersCount} offer(s) received',
                    style: TextStyle(
                      color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTab(DeptStudentDetail student, bool isDark) {
    final activities = student.recentActivity;

    if (activities.isEmpty) {
      return const Center(
        child: CampusEmptyState(
          title: 'No Recent Activity',
          description: 'No academic or campus activity recorded yet.',
          icon: Icons.history_outlined,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final act = activities[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CampusGlassCard(
            intensity: GlassIntensity.medium,
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 22),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        act.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        act.date,
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
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue),
        const SizedBox(width: AppSpacing.s12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeepAliveTab extends StatefulWidget {
  final Widget child;
  const _KeepAliveTab({required this.child});

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
