import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_status_badge.dart';
import '../../../../core/widgets/campus_loading_state.dart';
import '../../../../core/widgets/campus_error_state.dart';
import '../../../../core/widgets/campus_button.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../../../../core/widgets/campus_dialog.dart';
import '../../../../core/widgets/campus_text_field.dart';
import '../providers/placement_provider.dart';
import '../../data/placement_repository.dart';
import '../../domain/placement_models.dart';

class ApplicationDetailView extends ConsumerStatefulWidget {
  final String applicationId;

  const ApplicationDetailView({super.key, required this.applicationId});

  @override
  ConsumerState<ApplicationDetailView> createState() => _ApplicationDetailViewState();
}

class _ApplicationDetailViewState extends ConsumerState<ApplicationDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isUpdating = false;

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

  Future<void> _updateStatus(String newStatus, [String? offerCtc]) async {
    setState(() => _isUpdating = true);
    try {
      final repo = ref.read(placementRepositoryProvider);
      await repo.updateApplicationStatus(widget.applicationId, newStatus, offerCtc: offerCtc);
      ref.invalidate(applicationDetailsProvider(widget.applicationId));
      ref.invalidate(officerDashboardProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application status updated to ${newStatus.replaceAll('_', ' ')}! Student notified.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showScheduleDialog(PlacementApplicationModel app) {
    final roundCtrl = TextEditingController(text: 'Technical Round 1');
    final venueCtrl = TextEditingController(text: 'Seminar Hall A / Google Meet');
    DateTime scheduledDate = DateTime.now().add(const Duration(days: 2));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => CampusDialog(
          title: 'Schedule Interview',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CampusTextField(
                controller: roundCtrl,
                label: 'Round Name *',
                prefixIcon: Icons.badge_outlined,
              ),
              const SizedBox(height: 12),
              CampusTextField(
                controller: venueCtrl,
                label: 'Venue / Meeting Link',
                prefixIcon: Icons.location_on_outlined,
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
              label: 'Schedule Round',
              type: CampusButtonType.primary,
              onPressed: () async {
                Navigator.of(ctx).pop();
                setState(() => _isUpdating = true);
                try {
                  final repo = ref.read(placementRepositoryProvider);
                  await repo.scheduleInterview(
                    applicationId: app.id,
                    roundName: roundCtrl.text.trim(),
                    scheduledAt: scheduledDate.toUtc().toIso8601String(),
                    locationOrLink: venueCtrl.text.trim().isNotEmpty ? venueCtrl.text.trim() : null,
                  );
                  ref.invalidate(applicationDetailsProvider(widget.applicationId));
                  ref.invalidate(officerDashboardProvider);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Interview round scheduled! Notification sent to student.'), backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isUpdating = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appAsync = ref.watch(applicationDetailsProvider(widget.applicationId));

    return Scaffold(
      body: AtmosphericBackground(
        child: SafeArea(
          child: appAsync.when(
            loading: () => const CampusLoadingState(),
            error: (err, _) => CampusErrorState(
              message: 'Failed to load application details',
              onRetry: () => ref.refresh(applicationDetailsProvider(widget.applicationId)),
            ),
            data: (app) {
              return Column(
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
                                'Application Details',
                                style: AppTypography.pageTitle.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkText : AppColors.primaryText,
                                ),
                              ),
                              Text(
                                app.drive?.companyName ?? 'Recruitment Application',
                                style: AppTypography.micro.copyWith(
                                  color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CampusStatusBadge(
                          label: app.status.replaceAll('_', ' '),
                          type: app.status == 'OFFERED'
                              ? StatusBadgeType.success
                              : (app.status == 'REJECTED'
                                  ? StatusBadgeType.danger
                                  : StatusBadgeType.info),
                        ),
                      ],
                    ),
                  ),

                  // Candidate Profile Card (Image 10)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: CampusGlassCard(
                      intensity: GlassIntensity.medium,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CampusAvatar(
                            imageUrl: app.studentAvatar,
                            name: app.studentName ?? app.studentEmail ?? 'Student',
                            radius: 30,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  app.studentName ?? app.studentEmail ?? 'Student Candidate',
                                  style: AppTypography.pageTitle.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.darkText : AppColors.primaryText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${app.studentRoll ?? 'Roll N/A'} • ${app.departmentCode ?? 'Branch N/A'}',
                                  style: AppTypography.captionMedium.copyWith(
                                    color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  app.studentEmail ?? '',
                                  style: AppTypography.micro.copyWith(
                                    color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4 Tabs: Profile, Resume, Status, Interview (Image 10)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                        Tab(text: 'Profile'),
                        Tab(text: 'Resume'),
                        Tab(text: 'Status'),
                        Tab(text: 'Interview'),
                      ],
                    ),
                  ),

                  // Tabs Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildProfileTab(app, isDark),
                        _buildResumeTab(app, isDark),
                        _buildStatusTab(app, isDark),
                        _buildInterviewTab(app, isDark),
                      ],
                    ),
                  ),

                  // Dual Action Buttons: Reject & Shortlist (Image 10)
                  Container(
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
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isUpdating ? null : () => _updateStatus('REJECTED'),
                            child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isUpdating
                                ? null
                                : () {
                                    if (app.status == 'SHORTLISTED') {
                                      _showScheduleDialog(app);
                                    } else {
                                      _updateStatus('SHORTLISTED');
                                    }
                                  },
                            child: Text(
                              app.status == 'SHORTLISTED' ? 'Schedule Interview' : 'Shortlist Candidate',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab(PlacementApplicationModel app, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 4-Metric Academic Card (Image 10)
        CampusGlassCard(
          intensity: GlassIntensity.medium,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Academic Credentials',
                style: AppTypography.captionMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: isDark ? AppColors.darkText : AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildMetricCell('Cumulative CGPA', '${app.studentCgpa > 0 ? app.studentCgpa : 8.4}', const Color(0xFF10B981), isDark),
                  _buildMetricCell('Current Year', '4th Year', isDark ? AppColors.secondaryCyan : AppColors.primaryBlue, isDark),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMetricCell('Active Backlogs', '0 Backlogs', const Color(0xFF10B981), isDark),
                  _buildMetricCell('Department', app.departmentCode ?? 'CSE', const Color(0xFF8B5CF6), isDark),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Technical Skills Tags (Image 10)
        Text(
          'Technical Skills',
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
          children: ['Python', 'Flutter', 'Data Structures', 'SQL', 'Git', 'System Design'].map((skill) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                skill,
                style: TextStyle(
                  color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMetricCell(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumeTab(PlacementApplicationModel app, bool isDark) {
    final resumeUrl = app.resumeUrl;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: CampusGlassCard(
          intensity: GlassIntensity.medium,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444), size: 64),
              const SizedBox(height: 16),
              Text(
                'Student Resume PDF',
                style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 6),
              Text(
                resumeUrl != null && resumeUrl.isNotEmpty ? resumeUrl : 'Official resume attached from Student Portfolio',
                style: AppTypography.micro.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              CampusButton(
                label: 'View / Download Resume',
                icon: const Icon(Icons.launch),
                type: CampusButtonType.primary,
                onPressed: () {
                  if (resumeUrl != null && resumeUrl.isNotEmpty) {
                    launchUrlString(resumeUrl, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No resume link provided by candidate.')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTab(PlacementApplicationModel app, bool isDark) {
    final steps = ['APPLIED', 'SHORTLISTED', 'INTERVIEW_SCHEDULED', 'OFFERED'];
    final currentIdx = steps.indexOf(app.status);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Recruitment Pipeline Stage',
          style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 16),
        ...steps.map((step) {
          final idx = steps.indexOf(step);
          final isPastOrCurrent = currentIdx >= idx;
          final isCurrent = app.status == step;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isPastOrCurrent ? const Color(0xFF10B981) : Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPastOrCurrent ? Icons.check : Icons.circle,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  if (idx < steps.length - 1)
                    Container(
                      width: 2,
                      height: 40,
                      color: isPastOrCurrent ? const Color(0xFF10B981) : Colors.grey.shade300,
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.replaceAll('_', ' '),
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 15,
                          color: isCurrent
                              ? (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue)
                              : (isDark ? AppColors.darkText : AppColors.primaryText),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPastOrCurrent ? 'Completed / In Progress' : 'Pending',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildInterviewTab(PlacementApplicationModel app, bool isDark) {
    final interviews = app.interviews;
    if (interviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined, size: 48, color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
            const SizedBox(height: 12),
            Text(
              'No Interview Rounds Scheduled Yet',
              style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            CampusButton(
              label: 'Schedule First Round',
              icon: const Icon(Icons.add_circle_outline),
              type: CampusButtonType.secondary,
              onPressed: () => _showScheduleDialog(app),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: interviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final round = interviews[index];
        return CampusGlassCard(
          intensity: GlassIntensity.medium,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    round.roundName,
                    style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  CampusStatusBadge(
                    label: round.status,
                    type: round.status == 'COMPLETED' ? StatusBadgeType.success : StatusBadgeType.info,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14),
                  const SizedBox(width: 6),
                  Text(round.scheduledAt.toLocal().toString().substring(0, 16)),
                ],
              ),
              if (round.locationOrLink != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.link, size: 14),
                    const SizedBox(width: 6),
                    Expanded(child: Text(round.locationOrLink!, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
