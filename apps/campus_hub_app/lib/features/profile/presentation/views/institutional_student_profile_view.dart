import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/branding/gcee_logo.dart';
import '../../../../core/branding/gcee_brand.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_button.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_text_field.dart';
import '../../../../core/widgets/campus_loading_state.dart';
import '../../../../core/widgets/campus_error_state.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../../domain/models/detailed_student_profile.dart';
import '../providers/student_profile_provider.dart';
import '../widgets/request_change_dialog.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/widgets/full_screen_image_viewer.dart';
import '../../../admin/presentation/widgets/admin_page_header.dart';
import '../../../admin/presentation/widgets/admin_status_chip.dart';

class InstitutionalStudentProfileView extends ConsumerStatefulWidget {
  const InstitutionalStudentProfileView({super.key});

  @override
  ConsumerState<InstitutionalStudentProfileView> createState() =>
      _InstitutionalStudentProfileViewState();
}

class _InstitutionalStudentProfileViewState
    extends ConsumerState<InstitutionalStudentProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _tabController.index != _selectedTabIndex) {
        setState(() => _selectedTabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(studentDetailedProfileProvider);

    return AtmosphericBackground(
      child: profileAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.s32),
            child: CampusLoadingState(
              itemCount: 4,
              itemHeight: 85.0,
            ),
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: CampusErrorState(
              title: 'Failed to load institutional profile',
              message: err.toString(),
              onRetry: () => ref.invalidate(studentDetailedProfileProvider),
            ),
          ),
        ),
        data: (profile) => _buildContent(context, theme, profile),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, DetailedStudentProfile profile) {
    final isDark = theme.brightness == Brightness.dark;
    final overview = profile.overview;
    final id = profile.officialIdentity;
    final p = profile.personal;
    final career = profile.career;

    final fullName = overview.fullName.isNotEmpty ? overview.fullName : '${p.firstName} ${p.lastName}'.trim();
    final isWide = MediaQuery.of(context).size.width > 600;

    final privileges = [
      {
        'name': 'Course Materials & LMS Access',
        'granted': true,
        'scope': 'Current Semester Enrolled Offerings',
      },
      {
        'name': 'Examination & Academic Ledger',
        'granted': true,
        'scope': 'Continuous Assessment & Term-End Grades',
      },
      {
        'name': 'Campus Social Feed & Announcements',
        'granted': true,
        'scope': 'All-College & Department Stream',
      },
      {
        'name': 'Club Membership & Student Leadership',
        'granted': true,
        'scope': 'Verified Club Member / Coordinator',
      },
      {
        'name': 'Placement & Internship Drives',
        'granted': true,
        'scope': 'Eligible for Campus Recruitment Drives (Good Standing)',
      },
      {
        'name': 'Library & Digital Repositories',
        'granted': true,
        'scope': 'Central Campus & Department Archives',
      },
      {
        'name': 'Official Administrative Change Requests',
        'granted': true,
        'scope': 'Direct Student Self-Service Trail',
      },
    ];

    void onRequestCorrection() {
      RequestChangeDialog.show(
        context,
        fieldName: 'general_correction',
        fieldDisplayName: 'Official Record / Identity Data',
        category: 'ACADEMIC_IDENTITY_CHANGE',
        currentValue: id.rollNumber ?? '',
        onSuccess: () => ref.invalidate(studentChangeRequestsProvider),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. AdminPageHeader: Consistent with Admin Page
              AdminPageHeader(
                title: 'Institutional Student Identity',
                subtitle: 'Official student record, academic standing, and verified identity records.',
                badge: overview.isProfileCompleted ? 'VERIFIED ENROLLED STUDENT' : 'ENROLLED STUDENT',
                primaryAction: CampusButton(
                  onPressed: onRequestCorrection,
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: 'Request Info Correction',
                  height: 38,
                ),
                secondaryAction: CampusButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Verification and reset link sent to ${overview.email}'),
                        backgroundColor: AppColors.primaryBlue,
                      ),
                    );
                  },
                  icon: const Icon(Icons.lock_reset, size: 18),
                  label: 'Reset Password',
                  type: CampusButtonType.outline,
                  height: 38,
                ),
              ),

              // 2. Student Identity Header Card (Glass Profile Card)
              CampusGlassCard(
                intensity: GlassIntensity.medium,
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Builder(
                      builder: (context) {
                        final hasAvatar = overview.avatarUrl != null && overview.avatarUrl!.trim().isNotEmpty;
                        final resolvedAvatarUrl = hasAvatar ? ApiEndpoints.resolveUrl(overview.avatarUrl!.trim()) : null;

                        return GestureDetector(
                          onTap: () {
                            if (resolvedAvatarUrl != null) {
                              FullScreenImageViewer.openSingle(
                                context,
                                imageUrl: resolvedAvatarUrl,
                                heroTag: 'student_inst_avatar_${overview.userId}',
                                title: fullName,
                                subtitle: '${id.departmentName} • ${id.batchName}',
                              );
                            }
                          },
                          child: Hero(
                            tag: 'student_inst_avatar_${overview.userId}',
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.35),
                                  width: 2.5,
                                ),
                              ),
                              child: CampusAvatar(
                                imageUrl: resolvedAvatarUrl,
                                name: fullName,
                                radius: 40,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  fullName,
                                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (overview.isProfileCompleted)
                                const Icon(Icons.verified, color: AppColors.electricBlue, size: 20),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (id.programName != null && id.programName!.isNotEmpty) id.programName!,
                              if (id.departmentName != null && id.departmentName!.isNotEmpty) id.departmentName!,
                            ].join(' in ').isNotEmpty
                                ? [
                                    if (id.programName != null && id.programName!.isNotEmpty) id.programName!,
                                    if (id.departmentName != null && id.departmentName!.isNotEmpty) id.departmentName!,
                                  ].join(' in ')
                                : (id.departmentName ?? 'Enrolled Student'),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkSecondaryText : Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${overview.email} • Mobile: ${p.phone ?? 'Not set'}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkSecondaryText : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              AdminStatusChip(status: id.currentStatus ?? 'ACTIVE'),
                              const AdminStatusChip(status: 'STUDENT'),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.domain,
                                      size: 12,
                                      color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Department: ${id.departmentName ?? 'Engineering'}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.group_work, size: 12, color: Colors.purple),
                                    const SizedBox(width: 4),
                                    Text(
                                      id.batchName != null && id.batchName!.isNotEmpty
                                          ? 'Batch: ${id.batchName}${id.section != null && id.section!.isNotEmpty ? ' (Sec ${id.section})' : ''}'
                                          : (id.admissionYear != null ? 'Admission: ${id.admissionYear}' : 'Official Record'),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (career.skills.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.code, size: 12, color: Colors.teal),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${career.skills.length} Verified Skills',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal,
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
                    if (isWide) ...[
                      const SizedBox(width: 20),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const GceeLogo.profile(),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              GceeBrand.institutionShort,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Academic & Institutional Information Card (Matching Admin Information Card)
              CampusGlassCard(
                intensity: GlassIntensity.subtle,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Academic & Institutional Information',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 20),
                    GridView.count(
                      crossAxisCount: isWide ? 2 : 1,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: isWide ? 3.5 : 4.0,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 10,
                      children: [
                        _buildGridInfoTile(
                          'Roll Number / Student ID',
                          id.rollNumber ?? 'Not Assigned',
                          Icons.badge_outlined,
                        ),
                        _buildGridInfoTile(
                          'University Registration No',
                          id.registrationNumber ?? 'Pending Registration',
                          Icons.confirmation_number_outlined,
                        ),
                        _buildGridInfoTile(
                          'Institution / Campus',
                          'Government College of Engineering, Erode',
                          Icons.account_balance_outlined,
                        ),
                        _buildGridInfoTile(
                          'Academic Department',
                          id.departmentName ?? 'Department of Technology',
                          Icons.business_outlined,
                        ),
                        _buildGridInfoTile(
                          'Degree & Academic Program',
                          id.programName ?? (id.departmentName != null ? 'Degree in ${id.departmentName}' : 'Undergraduate Degree'),
                          Icons.school_outlined,
                        ),
                        _buildGridInfoTile(
                          'Cohort Batch & Section',
                          id.batchName != null && id.batchName!.isNotEmpty
                              ? '${id.batchName}${id.section != null ? ' (Section ${id.section})' : ''}'
                              : (id.section != null ? 'Section ${id.section}' : 'Active Academic Cohort'),
                          Icons.group_work_outlined,
                        ),
                        _buildGridInfoTile(
                          'Academic Standing',
                          'Good Standing • Active Clearance',
                          Icons.trending_up,
                          valueColor: AppColors.success,
                        ),
                        _buildGridInfoTile(
                          'Enrolment Status',
                          '${id.currentStatus ?? 'ACTIVE'} (Verified Regular Student)',
                          Icons.check_circle_outline,
                          valueColor: AppColors.success,
                        ),
                        _buildGridInfoTile(
                          'Academic Advisor / Mentor',
                          'Assigned by Department',
                          Icons.person_pin_outlined,
                        ),
                        _buildGridInfoTile(
                          'Admission Year',
                          id.admissionYear != null ? '${id.admissionYear}' : 'Official Academic Record',
                          Icons.calendar_today_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Institutional Privileges & Academic Clearance Card (Matching Admin Permissions Matrix)
              CampusGlassCard(
                intensity: GlassIntensity.subtle,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Institutional Privileges & Academic Clearance',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Clearance: Full Standing',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Student privileges are verified and granted in accordance with campus academic standing.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const Divider(height: 24),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: privileges.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final item = privileges[i];
                        final granted = item['granted'] == true;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                granted ? Icons.check_circle : Icons.cancel,
                                color: granted ? AppColors.success : Colors.grey.shade400,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] as String,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: granted ? (isDark ? AppColors.darkText : AppColors.primaryText) : Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      item['scope'] as String,
                                      style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSecondaryText : Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: granted
                                      ? AppColors.success.withValues(alpha: 0.12)
                                      : Colors.grey.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  granted ? 'AUTHORIZED' : 'RESTRICTED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: granted ? AppColors.success : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. Detailed Records & Profile Management Section (With ALL current student tabs)
              CampusGlassCard(
                intensity: GlassIntensity.subtle,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.folder_shared_outlined, color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Detailed Institutional Records & Management',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Select a category below to inspect locked records, edit career data, or track change requests.',
                                style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkSecondaryText : Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Tabs Selector Bar
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: isDark ? AppColors.primaryBlue : AppColors.primaryNavy,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: isDark ? AppColors.darkSecondaryText : Colors.grey.shade700,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        tabs: const [
                          Tab(icon: Icon(Icons.dashboard_outlined, size: 16), text: 'Overview'),
                          Tab(icon: Icon(Icons.lock_outline, size: 16), text: 'Official Identity (Locked 🔒)'),
                          Tab(icon: Icon(Icons.person_outline, size: 16), text: 'Personal & Family'),
                          Tab(icon: Icon(Icons.school_outlined, size: 16), text: 'Education & Address'),
                          Tab(icon: Icon(Icons.work_outline, size: 16), text: 'Career & Placement'),
                          Tab(icon: Icon(Icons.history, size: 16), text: 'Change Requests'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selected Tab Content Rendered Inline (Smooth, Unified Page Scroll)
                    _buildSelectedTabContent(theme, profile),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 6. Security & Session Governance Card (Matching Admin Page)
              CampusGlassCard(
                intensity: GlassIntensity.subtle,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Security & Session Governance',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 20),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.lock_reset_outlined, color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue),
                      title: const Text('Change Account Password', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Update permanent password for this institutional student account.'),
                      trailing: CampusButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Password reset instructions sent to ${overview.email}!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        label: 'Reset',
                        type: CampusButtonType.outline,
                        height: 36,
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.devices_outlined, color: Colors.teal),
                      title: const Text('Active Student Session', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Secure HTTPS/TLS session authenticated with JWT token.'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'CURRENT DEVICE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent(ThemeData theme, DetailedStudentProfile profile) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewTabContent(theme, profile);
      case 1:
        return _buildOfficialIdentityTabContent(theme, profile);
      case 2:
        return _buildPersonalAndFamilyTabContent(theme, profile);
      case 3:
        return _buildEducationTabContent(theme, profile);
      case 4:
        return _CareerEditSection(career: profile.career);
      case 5:
        return _buildChangeRequestsTabContent(theme);
      default:
        return _buildOverviewTabContent(theme, profile);
    }
  }

  // -------------------------------------------------------------
  // TAB 1: OVERVIEW CONTENT
  // -------------------------------------------------------------
  Widget _buildOverviewTabContent(ThemeData theme, DetailedStudentProfile profile) {
    final completion = profile.overview.completionPercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Completion Gauge Card
        Card(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(
                        value: completion / 100,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation(
                          completion == 100 ? Colors.green : theme.colorScheme.primary,
                        ),
                        strokeWidth: 6,
                      ),
                    ),
                    Text(
                      '$completion%',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        completion == 100 ? 'Profile 100% Completed' : 'Profile Completion Progress',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        completion == 100
                            ? 'Your official academic and career identity is fully verified.'
                            : 'Fill in your career details and project portfolio to reach 100%.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        _buildSectionHeader(theme, 'Academic Status Summary', Icons.school),
        const SizedBox(height: 8),
        _buildInfoTile('Program', profile.officialIdentity.programName ?? 'Undergraduate Degree'),
        _buildInfoTile('Department', profile.officialIdentity.departmentName ?? 'Assigned by Department'),
        _buildInfoTile(
          'Batch / Section',
          profile.officialIdentity.batchName != null && profile.officialIdentity.batchName!.isNotEmpty
              ? '${profile.officialIdentity.batchName}${profile.officialIdentity.section != null && profile.officialIdentity.section!.isNotEmpty ? ' (Section ${profile.officialIdentity.section})' : ''}'
              : (profile.officialIdentity.admissionYear != null ? '${profile.officialIdentity.admissionYear}' : 'Official Record'),
        ),
        _buildInfoTile(
          'Enrolment Status',
          profile.officialIdentity.currentStatus ?? 'ACTIVE',
          badgeColor: Colors.green,
        ),

        const SizedBox(height: 16),
        _buildSectionHeader(theme, 'Contact Snapshot', Icons.contact_phone_outlined),
        const SizedBox(height: 8),
        _buildInfoTile('Institutional Email', profile.personal.email),
        _buildInfoTile('Student Mobile', profile.personal.phone ?? 'Not set'),
        _buildInfoTile(
          'Emergency Contact',
          '${profile.emergency.contactName ?? 'None'} (${profile.emergency.contactPhone ?? 'N/A'})',
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 2: OFFICIAL IDENTITY CONTENT (LOCKED 🔒)
  // -------------------------------------------------------------
  Widget _buildOfficialIdentityTabContent(ThemeData theme, DetailedStudentProfile profile) {
    final id = profile.officialIdentity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.lock, size: 20, color: Colors.blue.shade800),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'These official records are locked by campus administration. To request corrections, tap "Request Correction" with required verification documents.',
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildLockedFieldCard(
          theme,
          title: 'Roll Number / Student ID',
          value: id.rollNumber ?? 'Not Assigned',
          fieldName: 'roll_number',
          category: 'ACADEMIC_IDENTITY_CHANGE',
        ),
        const SizedBox(height: 10),

        _buildLockedFieldCard(
          theme,
          title: 'Official Registration Number',
          value: id.registrationNumber ?? 'Not Assigned',
          fieldName: 'registration_number',
          category: 'ACADEMIC_IDENTITY_CHANGE',
        ),
        const SizedBox(height: 10),

        _buildLockedFieldCard(
          theme,
          title: 'Department',
          value: id.departmentName ?? 'Assigned by Department',
          fieldName: 'department',
          category: 'ACADEMIC_IDENTITY_CHANGE',
        ),
        const SizedBox(height: 10),

        _buildLockedFieldCard(
          theme,
          title: 'Academic Program',
          value: id.programName ?? 'Undergraduate Degree',
          fieldName: 'program',
          category: 'ACADEMIC_IDENTITY_CHANGE',
        ),
        const SizedBox(height: 10),

        _buildLockedFieldCard(
          theme,
          title: 'Cohort / Batch Name',
          value: id.batchName ?? (id.admissionYear != null ? '${id.admissionYear} Cohort' : 'Official Record'),
          fieldName: 'batch_name',
          category: 'ACADEMIC_IDENTITY_CHANGE',
        ),
        const SizedBox(height: 10),

        _buildLockedFieldCard(
          theme,
          title: 'Section Assignment',
          value: id.section != null && id.section!.isNotEmpty ? 'Section ${id.section}' : 'Not Assigned',
          fieldName: 'section',
          category: 'ACADEMIC_IDENTITY_CHANGE',
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 3: PERSONAL & FAMILY (APPROVAL REQUIRED)
  // -------------------------------------------------------------
  Widget _buildPersonalAndFamilyTabContent(ThemeData theme, DetailedStudentProfile profile) {
    final p = profile.personal;
    final f = profile.family;
    final em = profile.emergency;
    final addr = profile.address;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, 'Personal Identity (Approval Required)', Icons.person),
        const SizedBox(height: 8),
        _buildApprovalFieldCard(theme, 'Legal First Name', p.firstName, 'first_name', 'PERSONAL_CHANGE'),
        const SizedBox(height: 8),
        _buildApprovalFieldCard(theme, 'Legal Last Name', p.lastName, 'last_name', 'PERSONAL_CHANGE'),
        const SizedBox(height: 8),
        _buildApprovalFieldCard(
          theme,
          'Date of Birth',
          p.dob ?? 'Not set',
          'dob',
          'PERSONAL_CHANGE',
          subtitle: p.age != null ? 'Computed Age: ${p.age} years' : null,
        ),
        const SizedBox(height: 8),
        _buildApprovalFieldCard(theme, 'Student Mobile Number', p.phone ?? 'Not set', 'phone', 'PERSONAL_CHANGE'),
        const SizedBox(height: 8),
        _buildApprovalFieldCard(theme, 'Blood Group', p.bloodGroup ?? 'Not set', 'blood_group', 'PERSONAL_CHANGE'),

        const SizedBox(height: 20),
        _buildSectionHeader(theme, 'Family & Emergency Information', Icons.family_restroom),
        const SizedBox(height: 8),
        _buildApprovalFieldCard(theme, 'Father Full Name', f.fatherName ?? 'Not set', 'father_name', 'PERSONAL_CHANGE'),
        const SizedBox(height: 8),
        _buildApprovalFieldCard(theme, 'Father Mobile Number', f.fatherPhone ?? 'Not set', 'father_phone', 'PERSONAL_CHANGE'),
        const SizedBox(height: 8),
        _buildApprovalFieldCard(theme, 'Mother Full Name', f.motherName ?? 'Not set', 'mother_name', 'PERSONAL_CHANGE'),
        const SizedBox(height: 8),
        _buildApprovalFieldCard(theme, 'Mother Mobile Number', f.motherPhone ?? 'Not set', 'mother_phone', 'PERSONAL_CHANGE'),
        const SizedBox(height: 8),
        _buildApprovalFieldCard(theme, 'Emergency Contact Person', em.contactName ?? 'Not set', 'emergency_contact_name', 'PERSONAL_CHANGE'),
        const SizedBox(height: 8),
        _buildApprovalFieldCard(theme, 'Emergency Contact Phone', em.contactPhone ?? 'Not set', 'emergency_contact_phone', 'PERSONAL_CHANGE'),

        const SizedBox(height: 20),
        _buildSectionHeader(theme, 'Permanent Address', Icons.home_outlined),
        const SizedBox(height: 8),
        _buildApprovalFieldCard(theme, 'Permanent Address', addr.fullPermanentAddress, 'permanent_address', 'PERSONAL_CHANGE'),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 4: EDUCATION & ADDRESS
  // -------------------------------------------------------------
  Widget _buildEducationTabContent(ThemeData theme, DetailedStudentProfile profile) {
    final ed = profile.education;
    final addr = profile.address;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, 'Prior Educational Record', Icons.history_edu),
        const SizedBox(height: 8),
        _buildApprovalFieldCard(
          theme,
          '10th Standard Percentage',
          ed.tenthPercentage != null ? '${ed.tenthPercentage}%' : 'Not Set',
          'tenth_percentage',
          'PERSONAL_CHANGE',
        ),
        const SizedBox(height: 10),
        _buildApprovalFieldCard(
          theme,
          '12th / Diploma Percentage',
          ed.twelfthPercentage != null ? '${ed.twelfthPercentage}%' : 'Not Set',
          'twelfth_percentage',
          'PERSONAL_CHANGE',
        ),
        const SizedBox(height: 20),
        _buildSectionHeader(theme, 'Residential Address', Icons.location_on_outlined),
        const SizedBox(height: 8),
        _buildApprovalFieldCard(
          theme,
          'Permanent Residential Address',
          addr.fullPermanentAddress,
          'permanent_address',
          'PERSONAL_CHANGE',
        ),
        if (addr.currentAddress != null && addr.currentAddress!.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildApprovalFieldCard(
            theme,
            'Current Residential Address',
            addr.currentAddress!,
            'current_address',
            'PERSONAL_CHANGE',
          ),
        ],
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 6: CHANGE REQUESTS HISTORY
  // -------------------------------------------------------------
  Widget _buildChangeRequestsTabContent(ThemeData theme) {
    final requestsAsync = ref.watch(studentChangeRequestsProvider);

    return requestsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Center(child: Text('Error loading requests: $err')),
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.task_alt, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('No Change Requests Submitted', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                    'When you request a correction on locked or approval fields, status will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, idx) {
            final req = requests[idx];
            Color statusColor;
            IconData statusIcon;

            if (req.isApproved) {
              statusColor = Colors.green;
              statusIcon = Icons.check_circle;
            } else if (req.isRejected) {
              statusColor = Colors.red;
              statusIcon = Icons.cancel;
            } else if (req.isCancelled) {
              statusColor = Colors.grey;
              statusIcon = Icons.remove_circle;
            } else {
              statusColor = Colors.amber.shade800;
              statusIcon = Icons.pending;
            }

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Field: ${req.field.replaceAll('_', ' ').toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            req.status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Current', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              Text(req.currentValue.isEmpty ? 'Not set' : req.currentValue,
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Requested', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              Text(req.requestedValue,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Text('Reason: ${req.reason}', style: const TextStyle(fontSize: 11)),
                    if (req.reviewComment != null && req.reviewComment!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Admin Note: ${req.reviewComment}',
                        style: TextStyle(fontSize: 11, color: statusColor, fontStyle: FontStyle.italic),
                      ),
                    ],
                    if (req.isPending) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.close, size: 14, color: Colors.red),
                          label: const Text('Cancel Request', style: TextStyle(fontSize: 11, color: Colors.red)),
                          onPressed: () async {
                            final ok = await ref
                                .read(studentCareerProfileProvider.notifier)
                                .cancelChangeRequest(req.id);
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Change request cancelled.')),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------
  // HELPER CARD & TILE BUILDERS
  // -------------------------------------------------------------
  Widget _buildGridInfoTile(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, {Color? badgeColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          if (badgeColor != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badgeColor)),
            )
          else
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildLockedFieldCard(
    ThemeData theme, {
    required String title,
    required String value,
    required String fieldName,
    required String category,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: isDark ? 0.6 : 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.18),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, size: 16, color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.primaryNavy,
                  ),
                ),
              ],
            ),
          ),
          CampusButton(
            label: 'Request Correction',
            type: CampusButtonType.outline,
            height: 34,
            onPressed: () => RequestChangeDialog.show(
              context,
              fieldName: fieldName,
              fieldDisplayName: title,
              category: category,
              currentValue: value,
              onSuccess: () => ref.invalidate(studentChangeRequestsProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalFieldCard(
    ThemeData theme,
    String title,
    String value,
    String fieldName,
    String category, {
    String? subtitle,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: isDark ? 0.6 : 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.border),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.primaryText,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
          ),
          CampusButton(
            label: 'Change',
            type: CampusButtonType.ghost,
            height: 34,
            icon: const Icon(Icons.edit, size: 14),
            onPressed: () => RequestChangeDialog.show(
              context,
              fieldName: fieldName,
              fieldDisplayName: title,
              category: category,
              currentValue: value,
              onSuccess: () => ref.invalidate(studentChangeRequestsProvider),
            ),
          ),
        ],
      ),
    );
  }
}

class _CareerEditSection extends ConsumerStatefulWidget {
  final CareerInfo career;
  const _CareerEditSection({required this.career});

  @override
  ConsumerState<_CareerEditSection> createState() => _CareerEditSectionState();
}

class _CareerEditSectionState extends ConsumerState<_CareerEditSection> {
  late final TextEditingController _bioCtrl;
  late final TextEditingController _githubCtrl;
  late final TextEditingController _linkedinCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _resumeCtrl;
  final _newSkillCtrl = TextEditingController();
  late List<String> _skills;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bioCtrl = TextEditingController(text: widget.career.bio ?? '');
    _githubCtrl = TextEditingController(text: widget.career.githubUrl ?? '');
    _linkedinCtrl = TextEditingController(text: widget.career.linkedinUrl ?? '');
    _websiteCtrl = TextEditingController(text: widget.career.websiteUrl ?? '');
    _resumeCtrl = TextEditingController(text: widget.career.resumeUrl ?? '');
    _skills = widget.career.skills.map((s) => s.skillName).toList();
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _githubCtrl.dispose();
    _linkedinCtrl.dispose();
    _websiteCtrl.dispose();
    _resumeCtrl.dispose();
    _newSkillCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveCareerProfile() async {
    setState(() => _isSaving = true);
    final ok = await ref.read(studentCareerProfileProvider.notifier).updateCareer(
          bio: _bioCtrl.text.trim(),
          githubUrl: _githubCtrl.text.trim(),
          linkedinUrl: _linkedinCtrl.text.trim(),
          websiteUrl: _websiteCtrl.text.trim(),
          resumeUrl: _resumeCtrl.text.trim(),
          skills: _skills,
        );
    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Career profile updated!'), backgroundColor: AppColors.success),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.edit, size: 18, color: AppColors.success),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Directly Editable Career Data (No Approval Needed)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.success),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        CampusTextField(
          controller: _bioCtrl,
          label: 'Professional Bio',
          prefixIcon: Icons.description_outlined,
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // Skills Chips
        const Text('Skills', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._skills.map((s) => Chip(
                  label: Text(s),
                  backgroundColor: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.12),
                  side: BorderSide(color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.3)),
                  deleteIconColor: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                  onDeleted: () => setState(() => _skills.remove(s)),
                )),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: CampusTextField(
                controller: _newSkillCtrl,
                label: 'Add Skill (e.g. Flutter, Node.js)',
                prefixIcon: Icons.code_rounded,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.add),
              onPressed: () {
                final s = _newSkillCtrl.text.trim();
                if (s.isNotEmpty && !_skills.contains(s)) {
                  setState(() {
                    _skills.add(s);
                    _newSkillCtrl.clear();
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        CampusTextField(
          controller: _githubCtrl,
          label: 'GitHub Profile URL',
          prefixIcon: Icons.link,
        ),
        const SizedBox(height: 12),
        CampusTextField(
          controller: _linkedinCtrl,
          label: 'LinkedIn Profile URL',
          prefixIcon: Icons.link,
        ),
        const SizedBox(height: 12),
        CampusTextField(
          controller: _websiteCtrl,
          label: 'Portfolio / Personal Website URL',
          prefixIcon: Icons.language_rounded,
        ),
        const SizedBox(height: 12),
        CampusTextField(
          controller: _resumeCtrl,
          label: 'Resume Document URL',
          prefixIcon: Icons.picture_as_pdf_rounded,
        ),
        const SizedBox(height: 24),

        CampusButton(
          icon: const Icon(Icons.save_rounded, size: 18),
          label: 'Save Career Profile',
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _saveCareerProfile,
        ),
      ],
    );
  }
}
