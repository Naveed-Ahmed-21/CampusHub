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
import '../../../../core/widgets/campus_empty_state.dart';
import '../../../../core/widgets/campus_error_state.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../providers/placement_provider.dart';
import '../../domain/placement_models.dart';

class InterviewsView extends ConsumerStatefulWidget {
  const InterviewsView({super.key});

  @override
  ConsumerState<InterviewsView> createState() => _InterviewsViewState();
}

class _InterviewsViewState extends ConsumerState<InterviewsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final interviewsAsync = ref.watch(placementInterviewsProvider);

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
                            'Interview Schedules',
                            style: AppTypography.pageTitle.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkText : AppColors.primaryText,
                            ),
                          ),
                          Text(
                            'Track candidate interview rounds & meet links',
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

              // Tab Bar
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
                  tabs: const [
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Completed / Past'),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: interviewsAsync.when(
                  loading: () => const CampusLoadingState(),
                  error: (err, _) => CampusErrorState(
                    message: 'Failed to load interviews',
                    onRetry: () => ref.refresh(placementInterviewsProvider),
                  ),
                  data: (interviews) {
                    final now = DateTime.now();
                    final upcoming = interviews.where((i) => i.scheduledAt.isAfter(now)).toList();
                    final past = interviews.where((i) => !i.scheduledAt.isAfter(now)).toList();

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildInterviewList(upcoming, isDark, isUpcoming: true),
                        _buildInterviewList(past, isDark, isUpcoming: false),
                      ],
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

  Widget _buildInterviewList(List<PlacementInterviewModel> list, bool isDark, {required bool isUpcoming}) {
    if (list.isEmpty) {
      return CampusEmptyState(
        title: isUpcoming ? 'No Upcoming Interviews' : 'No Past Interviews',
        description: isUpcoming
            ? 'There are currently no interviews scheduled.'
            : 'Completed interview records will appear here.',
        icon: Icons.calendar_month_outlined,
      );
    }

    const monthNames = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final interview = list[index];
        final dt = interview.scheduledAt.toLocal();
        final monthStr = monthNames[dt.month - 1];
        final dayStr = dt.day.toString().padLeft(2, '0');
        final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
        final period = dt.hour >= 12 ? 'PM' : 'AM';
        final minute = dt.minute.toString().padLeft(2, '0');
        final timeStr = '$hour:$minute $period';

        final isLink = interview.locationOrLink != null &&
            (interview.locationOrLink!.startsWith('http://') || interview.locationOrLink!.startsWith('https://'));

        return CampusGlassCard(
          intensity: GlassIntensity.medium,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Blueprint Image 12: Calendar Date Block
                  Container(
                    width: 52,
                    height: 56,
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          monthStr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                          ),
                        ),
                        Text(
                          dayStr,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Interview details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          interview.roundName,
                          style: AppTypography.captionMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark ? AppColors.darkText : AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          interview.companyName ?? 'Campus Recruitment Drive',
                          style: AppTypography.micro.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Candidate: ${interview.candidateName ?? 'Applicant'}',
                          style: AppTypography.micro.copyWith(
                            color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status Badge
                  CampusStatusBadge(
                    label: interview.status,
                    type: interview.status == 'PASSED'
                        ? StatusBadgeType.success
                        : (interview.status == 'SCHEDULED' ? StatusBadgeType.info : StatusBadgeType.neutral),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Bottom details row: Time & Venue/Link
              Row(
                children: [
                  Icon(
                    Icons.access_time_outlined,
                    size: 15,
                    color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timeStr,
                    style: AppTypography.micro.copyWith(
                      color: isDark ? AppColors.darkText : AppColors.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (interview.locationOrLink != null && interview.locationOrLink!.isNotEmpty)
                    GestureDetector(
                      onTap: isLink
                          ? () => launchUrlString(interview.locationOrLink!, mode: LaunchMode.externalApplication)
                          : null,
                      child: Row(
                        children: [
                          Icon(
                            isLink ? Icons.videocam_outlined : Icons.room_outlined,
                            size: 15,
                            color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isLink ? 'Join Meet' : interview.locationOrLink!,
                            style: AppTypography.micro.copyWith(
                              color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                              fontWeight: FontWeight.w700,
                              decoration: isLink ? TextDecoration.underline : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

