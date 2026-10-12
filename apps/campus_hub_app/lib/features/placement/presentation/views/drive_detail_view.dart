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
import '../../../../core/widgets/campus_error_state.dart';
import '../../../../core/widgets/campus_button.dart';
import '../../../../core/widgets/campus_dialog.dart';
import '../../../../core/widgets/campus_text_field.dart';
import '../providers/placement_provider.dart';
import '../../data/placement_repository.dart';
import '../../domain/placement_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class DriveDetailView extends ConsumerStatefulWidget {
  final String driveId;

  const DriveDetailView({super.key, required this.driveId});

  @override
  ConsumerState<DriveDetailView> createState() => _DriveDetailViewState();
}

class _DriveDetailViewState extends ConsumerState<DriveDetailView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isApplying = false;

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

  void _showApplyDialog(PlacementDriveModel drive, Map<String, dynamic> studentData) {
    final resumeCtrl = TextEditingController(text: studentData['studentProfile']?['resumeUrl'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => CampusDialog(
        title: 'Apply for ${drive.companyName}',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Role: ${drive.roleTitle}',
              style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            if (drive.packageCtc != null)
              Text(
                'Package: ${drive.packageCtc}',
                style: AppTypography.micro.copyWith(color: AppColors.success),
              ),
            const SizedBox(height: 16),
            CampusTextField(
              controller: resumeCtrl,
              label: 'Resume URL (Google Drive / LinkedIn / PDF)',
              prefixIcon: Icons.link,
              hint: 'https://...',
            ),
            const SizedBox(height: 8),
            Text(
              'Applying will automatically grant you access to the official Drive Chat Room for real-time updates and discussions.',
              style: AppTypography.micro.copyWith(
                color: Theme.of(ctx).brightness == Brightness.dark
                    ? AppColors.darkSecondaryText
                    : AppColors.secondaryText,
              ),
            ),
          ],
        ),
        actions: [
          CampusButton(
            label: 'Cancel',
            type: CampusButtonType.ghost,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CampusButton(
            label: 'Confirm & Apply',
            type: CampusButtonType.primary,
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() => _isApplying = true);
              try {
                final repo = ref.read(placementRepositoryProvider);
                await repo.applyForDrive(drive.id, resumeUrl: resumeCtrl.text.trim());
                ref.invalidate(driveDetailsProvider(drive.id));
                ref.invalidate(studentDashboardProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully applied for ${drive.companyName}! You have been added to the Drive Chat.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isApplying = false);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authControllerProvider).asData?.value;
    final isOfficer = user?.isPlacementOfficer == true || user?.isAdmin == true;
    final isStudent = user?.role == 'STUDENT';

    final driveAsync = ref.watch(driveDetailsProvider(widget.driveId));
    final studentAsync = isStudent
        ? ref.watch(studentDashboardProvider)
        : const AsyncValue.data(<String, dynamic>{});

    return Scaffold(
      body: AtmosphericBackground(
        child: SafeArea(
          child: driveAsync.when(
            loading: () => const CampusLoadingState(),
            error: (err, _) => CampusErrorState(
              message: 'Failed to load drive details',
              onRetry: () => ref.refresh(driveDetailsProvider(widget.driveId)),
            ),
            data: (drive) {
              final studentData = studentAsync.asData?.value ?? {};
              final applications = (studentData['myApplications'] as List?) ?? [];
              final hasApplied = applications.any((a) => (a as Map)['drive_id'] == drive.id);

              // Student eligibility evaluation
              final studentCgpa = (studentData['studentProfile']?['cgpa'] as num?)?.toDouble() ?? 0.0;
              final isCgpaEligible = drive.minCgpa <= 0 || studentCgpa >= drive.minCgpa;
              final isEligible = isCgpaEligible;

              return Column(
                children: [
                  // Hero Cover Building Photo + Overlapping Circular Logo (Image 05)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 185,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          image: (drive.bannerUrl != null && drive.bannerUrl!.isNotEmpty) ||
                                  (drive.companyCoverImage != null && drive.companyCoverImage!.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(
                                    (drive.bannerUrl != null && drive.bannerUrl!.isNotEmpty)
                                        ? drive.bannerUrl!
                                        : drive.companyCoverImage!,
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.55),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.45),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Overlaid Top Bar (Back, Share, Bookmark)
                      Positioned(
                        top: 10,
                        left: 12,
                        right: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildCircleIconButton(
                              icon: Icons.arrow_back_ios_new,
                              onTap: () => Navigator.of(context).pop(),
                            ),
                            Row(
                              children: [
                                _buildCircleIconButton(
                                  icon: Icons.share_outlined,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Drive details link copied to clipboard!')),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                _buildCircleIconButton(
                                  icon: Icons.bookmark_border_outlined,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Drive bookmarked!')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Overlapping Circular Company Logo positioned halfway over the bottom border
                      Positioned(
                        bottom: -28,
                        left: 20,
                        child: Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: (drive.companyLogo != null || drive.company?.logoUrl != null)
                              ? Image.network(
                                  drive.companyLogo ?? drive.company!.logoUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      drive.companyName.isNotEmpty ? drive.companyName[0].toUpperCase() : 'C',
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    drive.companyName.isNotEmpty ? drive.companyName[0].toUpperCase() : 'C',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                                  ),
                                ),
                        ),
                      ),

                      // Status Badge
                      Positioned(
                        bottom: 12,
                        right: 16,
                        child: CampusStatusBadge(
                          label: drive.status == 'ONGOING' ? 'OPEN' : drive.status,
                          type: drive.status == 'ONGOING' ? StatusBadgeType.success : StatusBadgeType.info,
                        ),
                      ),
                    ],
                  ),

                  // Below Hero: Title, Role, and Metadata Chips
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 36, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          drive.companyName,
                          style: AppTypography.pageTitle.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkText : AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          drive.roleTitle,
                          style: AppTypography.captionMedium.copyWith(
                            color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Metadata Chips row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildMetaChip(
                                icon: Icons.payments_outlined,
                                label: drive.packageCtc ?? 'Competitive CTC',
                                color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                                isDark: isDark,
                              ),
                              const SizedBox(width: 8),
                              _buildMetaChip(
                                icon: Icons.apartment_outlined,
                                label: drive.workMode.replaceAll('_', ' '),
                                color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 8),
                              _buildMetaChip(
                                icon: Icons.location_on_outlined,
                                label: drive.location ?? 'On-Site',
                                color: const Color(0xFF8B5CF6),
                                isDark: isDark,
                              ),
                              if (drive.targetBatch != null) ...[
                                const SizedBox(width: 8),
                                _buildMetaChip(
                                  icon: Icons.school_outlined,
                                  label: '${drive.targetBatch} Batch',
                                  color: const Color(0xFFF59E0B),
                                  isDark: isDark,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4 Tabs Bar (Overview, Eligibility, Prep, Chat)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                      labelColor: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                      unselectedLabelColor: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                      labelStyle: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Eligibility'),
                        Tab(text: 'Prep'),
                        Tab(text: 'Drive Chat'),
                      ],
                    ),
                  ),

                  // Tab Views Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(drive, isDark),
                        _buildEligibilityTab(drive, studentData, isDark, isStudent),
                        _buildPrepTab(drive, isDark),
                        _buildDriveChatTab(drive, isDark),
                      ],
                    ),
                  ),

                  // Bottom Action CTA
                  _buildBottomBar(drive, isOfficer, isStudent, hasApplied, isEligible, studentData, isDark),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(PlacementDriveModel drive, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Key Info Grid
        CampusGlassCard(
          intensity: GlassIntensity.medium,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildInfoRow('Employment Type', drive.employmentType.replaceAll('_', ' '), Icons.badge_outlined, isDark),
              const Divider(height: 16),
              _buildInfoRow('Work Mode', drive.workMode.replaceAll('_', ' '), Icons.apartment_outlined, isDark),
              const Divider(height: 16),
              _buildInfoRow(
                'Application Deadline',
                drive.deadline.toLocal().toString().split(' ')[0],
                Icons.event_outlined,
                isDark,
              ),
              if (drive.driveDate != null) ...[
                const Divider(height: 16),
                _buildInfoRow('Drive Date', drive.driveDate!.toLocal().toString().split(' ')[0], Icons.calendar_month_outlined, isDark),
              ],
              if (drive.venueOrLink != null && drive.venueOrLink!.isNotEmpty) ...[
                const Divider(height: 16),
                _buildInfoRow('Venue / Link', drive.venueOrLink!, Icons.link_outlined, isDark),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Job Description
        Text(
          'Job Description',
          style: AppTypography.captionMedium.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: isDark ? AppColors.darkText : AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        CampusGlassCard(
          intensity: GlassIntensity.medium,
          padding: const EdgeInsets.all(16),
          child: Text(
            drive.jobDescription ?? 'No specific job description provided. Contact Placement Cell for comprehensive brochure.',
            style: AppTypography.body.copyWith(
              color: isDark ? AppColors.darkText : AppColors.primaryText,
              height: 1.5,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Required Skills
        if (drive.requiredSkills.isNotEmpty) ...[
          Text(
            'Required Skills',
            style: AppTypography.captionMedium.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: isDark ? AppColors.darkText : AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: drive.requiredSkills.map((skill) {
              return Chip(
                label: Text(skill, style: AppTypography.micro.copyWith(fontWeight: FontWeight.w600)),
                backgroundColor: isDark
                    ? AppColors.darkSurface.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildEligibilityTab(
    PlacementDriveModel drive,
    Map<String, dynamic> studentData,
    bool isDark,
    bool isStudent,
  ) {
    final studentCgpa = (studentData['studentProfile']?['cgpa'] as num?)?.toDouble() ?? 0.0;
    final isCgpaEligible = drive.minCgpa <= 0 || studentCgpa >= drive.minCgpa;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Live Student Eligibility Card
        if (isStudent) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCgpaEligible
                  ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFDCFCE7))
                  : (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.4) : const Color(0xFFFEE2E2)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCgpaEligible
                    ? (isDark ? const Color(0xFF059669) : const Color(0xFF22C55E))
                    : (isDark ? const Color(0xFFDC2626) : const Color(0xFFEF4444)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCgpaEligible ? Icons.check_circle : Icons.cancel,
                  color: isCgpaEligible
                      ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
                      : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                  size: 32,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCgpaEligible ? 'You are Eligible to Apply' : 'Ineligible to Apply',
                        style: AppTypography.captionMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isCgpaEligible
                              ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
                              : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isCgpaEligible
                            ? 'Your CGPA ($studentCgpa) meets the cutoff of ${drive.minCgpa}.'
                            : 'Minimum required CGPA is ${drive.minCgpa} (Your CGPA: $studentCgpa).',
                        style: AppTypography.micro.copyWith(
                          color: isDark ? AppColors.darkText : AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Criteria Breakdown
        Text(
          'Eligibility Criteria',
          style: AppTypography.captionMedium.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: isDark ? AppColors.darkText : AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 8),

        CampusGlassCard(
          intensity: GlassIntensity.medium,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildInfoRow('Minimum CGPA', drive.minCgpa > 0 ? '${drive.minCgpa} / 10.0' : 'No Cutoff', Icons.grade_outlined, isDark),
              const Divider(height: 16),
              _buildInfoRow('Max Standing Backlogs', '${drive.maxBacklogs}', Icons.warning_amber_outlined, isDark),
              const Divider(height: 16),
              _buildInfoRow('Target Year', drive.targetYear != null ? '${drive.targetYear}th Year' : 'All Years', Icons.school_outlined, isDark),
              const Divider(height: 16),
              _buildInfoRow('Target Batch', drive.targetBatch ?? 'All Active Batches', Icons.group_outlined, isDark),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Allowed Branches
        Text(
          'Allowed Branches',
          style: AppTypography.captionMedium.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: isDark ? AppColors.darkText : AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: drive.allowedDepartments.isEmpty
              ? [
                  Chip(
                    label: const Text('All Branches Eligible'),
                    backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                  ),
                ]
              : drive.allowedDepartments.map((dept) {
                  return Chip(
                    avatar: const Icon(Icons.check, size: 14, color: AppColors.success),
                    label: Text(dept, style: AppTypography.micro.copyWith(fontWeight: FontWeight.w600)),
                    backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                  );
                }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrepTab(PlacementDriveModel drive, bool isDark) {
    final resources = drive.resources;

    if (resources.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, size: 48, color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
            const SizedBox(height: 12),
            Text(
              'No Company-Specific Prep Materials',
              style: AppTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check the Preparation Hub for general aptitude, DSA, and HR notes.',
              style: AppTypography.micro.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CampusButton(
              label: 'Explore Preparation Hub',
              type: CampusButtonType.secondary,
              onPressed: () => context.push('/placement/preparation'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: resources.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final res = resources[index];
        return CampusGlassCard(
          intensity: GlassIntensity.medium,
          onTap: () => context.push('/placement/resources/${res.id}'),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  res.resourceType == 'VIDEO' || res.resourceType == 'YOUTUBE_PLAYLIST'
                      ? Icons.play_circle_outline
                      : Icons.description_outlined,
                  color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      res.title,
                      style: AppTypography.captionMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkText : AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${res.category} • ${res.resourceType}',
                      style: AppTypography.micro.copyWith(
                        color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDriveChatTab(PlacementDriveModel drive, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.3),
                    (isDark ? AppColors.primaryBlue : AppColors.secondaryCyan).withValues(alpha: 0.3),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.forum_outlined,
                size: 36,
                color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${drive.companyName} Drive Chat',
              style: AppTypography.pageTitle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask queries directly to the Placement Cell, receive test links, interview schedules, and instant announcements in this official room.',
              style: AppTypography.body.copyWith(
                color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CampusButton(
              label: 'Open Drive Chat Room',
              icon: const Icon(Icons.chat),
              type: CampusButtonType.primary,
              onPressed: () {
                if (drive.chatRoomId != null && drive.chatRoomId!.isNotEmpty) {
                  context.push('/chat/room/${drive.chatRoomId}');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Drive chat room is being provisioned by the Placement Officer.')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    PlacementDriveModel drive,
    bool isOfficer,
    bool isStudent,
    bool hasApplied,
    bool isEligible,
    Map<String, dynamic> studentData,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: isOfficer
            ? Row(
                children: [
                  Expanded(
                    child: CampusButton(
                      label: 'Applications (${drive.applicationCount})',
                      icon: const Icon(Icons.people_outline),
                      type: CampusButtonType.secondary,
                      onPressed: () => context.push('/placement/applications?drive_id=${drive.id}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CampusButton(
                      label: 'Post Update',
                      icon: const Icon(Icons.notifications_active_outlined),
                      type: CampusButtonType.primary,
                      onPressed: () => context.push('/placement/shortlist?drive_id=${drive.id}'),
                    ),
                  ),
                ],
              )
            : hasApplied
                ? Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: AppColors.success, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Application Submitted',
                            style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  )
                : CampusButton(
                    label: isEligible ? 'Apply for Drive' : 'Ineligible for this Drive',
                    icon: const Icon(Icons.send_rounded),
                    type: isEligible ? CampusButtonType.primary : CampusButtonType.ghost,
                    isLoading: _isApplying,
                    onPressed: isEligible ? () => _showApplyDialog(drive, studentData) : null,
                  ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTypography.micro.copyWith(
            color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTypography.captionMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkText : AppColors.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildCircleIconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

