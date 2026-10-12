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
import '../../../../core/widgets/campus_back_button.dart';
import '../../../../core/widgets/campus_empty_state.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../providers/placement_provider.dart';


class StudentProfileView extends ConsumerStatefulWidget {
  final String studentId;

  const StudentProfileView({super.key, required this.studentId});

  @override
  ConsumerState<StudentProfileView> createState() => _StudentProfileViewState();
}

class _StudentProfileViewState extends ConsumerState<StudentProfileView>
    with SingleTickerProviderStateMixin {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(studentPlacementProfileProvider(widget.studentId));

    return Scaffold(
      body: AtmosphericBackground(
        child: SafeArea(
          child: profileAsync.when(
            loading: () => const CampusLoadingState(),
            error: (err, _) => CampusErrorState(
              message: 'Failed to load student placement profile',
              onRetry: () => ref.refresh(studentPlacementProfileProvider(widget.studentId)),
            ),
            data: (data) {
              final student = data['student'] as Map<String, dynamic>? ?? {};
              final dept = student['department'] as Map<String, dynamic>?;
              final portfolio = student['portfolio'] as Map<String, dynamic>?;
              final academic = student['academic_profile'] as Map<String, dynamic>?;
              final applications = (data['applications'] as List?) ?? [];
              final status = data['placementStatus'] ?? 'ELIGIBLE';

              final firstName = student['first_name'] ?? '';
              final lastName = student['last_name'] ?? '';
              final fullName = '$firstName $lastName'.trim();
              final cgpa = (portfolio?['cgpa'] as num?)?.toDouble() ?? 0.0;
              final resumeUrl = portfolio?['resume_url'] as String?;
              final rawAvatar = student['avatar_url'] as String?;
              final resolvedAvatar = (rawAvatar != null && rawAvatar.trim().isNotEmpty)
                  ? ApiEndpoints.resolveUrl(rawAvatar.trim())
                  : null;

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
                          child: Text(
                            'Student Profile',
                            style: AppTypography.pageTitle.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkText : AppColors.primaryText,
                            ),
                          ),
                        ),
                        CampusStatusBadge(
                          label: status,
                          type: status == 'PLACED'
                              ? StatusBadgeType.success
                              : (status == 'OFFERED' ? StatusBadgeType.warning : StatusBadgeType.info),
                        ),
                      ],
                    ),
                  ),

                  // Student Banner & Avatar Header (Image 16)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: CampusGlassCard(
                      intensity: GlassIntensity.medium,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CampusAvatar(
                            imageUrl: resolvedAvatar,
                            name: fullName,
                            radius: 32,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName.isNotEmpty ? fullName : 'Student Candidate',
                                  style: AppTypography.pageTitle.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.darkText : AppColors.primaryText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${student['roll_number'] ?? 'Roll N/A'} • ${dept?['code'] ?? dept?['name'] ?? 'CSE'}',
                                  style: AppTypography.captionMedium.copyWith(
                                    color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  student['email'] ?? '',
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

                  // 4 Tabs: Overview, Academic, Skills, Placement (Image 16)
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
                        Tab(text: 'Overview'),
                        Tab(text: 'Academic'),
                        Tab(text: 'Skills'),
                        Tab(text: 'Placement'),
                      ],
                    ),
                  ),

                  // Tabs Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(student, portfolio, isDark),
                        _buildAcademicTab(academic, cgpa, isDark),
                        _buildSkillsTab(portfolio, isDark),
                        _buildPlacementTab(applications, isDark),
                      ],
                    ),
                  ),

                  // Dual Action Buttons: Message Student & View Resume (Image 16)
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
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.chat_bubble_outline, size: 16),
                            label: const Text('Message'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                              side: BorderSide(color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              context.push('/chat');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                            label: const Text('View Resume'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              if (resumeUrl != null && resumeUrl.isNotEmpty) {
                                UrlLauncherService.openUrl(context, resumeUrl);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No resume link uploaded yet.')),
                                );
                              }
                            },
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

  Widget _buildOverviewTab(Map<String, dynamic> student, Map<String, dynamic>? portfolio, bool isDark) {
    final bio = portfolio?['bio']?.toString().trim();
    final githubUrl = portfolio?['github_url']?.toString().trim();
    final linkedinUrl = portfolio?['linkedin_url']?.toString().trim();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CampusGlassCard(
          intensity: GlassIntensity.medium,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Candidate Summary',
                style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                (bio != null && bio.isNotEmpty) ? bio : 'No candidate summary provided yet.',
                style: AppTypography.body.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.primaryText,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CampusGlassCard(
          intensity: GlassIntensity.medium,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Portfolio & Social Links',
                style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _buildLinkTile(Icons.code, 'GitHub Profile', githubUrl, isDark),
              const Divider(height: 16),
              _buildLinkTile(Icons.work_outline, 'LinkedIn Profile', linkedinUrl, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLinkTile(IconData icon, String title, String? url, bool isDark) {
    final hasUrl = url != null && url.isNotEmpty;
    return InkWell(
      onTap: hasUrl ? () => UrlLauncherService.openUrl(context, url) : null,
      child: Row(
        children: [
          Icon(icon, size: 20, color: hasUrl ? (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue) : Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  hasUrl ? url : 'Not provided',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (hasUrl) const Icon(Icons.launch, size: 14),
        ],
      ),
    );
  }

  Widget _buildAcademicTab(Map<String, dynamic>? academic, double cgpa, bool isDark) {
    final year = academic?['year'] != null ? '${academic!['year']}th Year' : 'N/A';
    final backlogs = academic?['historyOfArrears'] != null
        ? '${academic!['historyOfArrears']} Arrears'
        : (academic?['currentArrears'] != null ? '${academic!['currentArrears']} Arrears' : '0');
    final attendance = academic?['attendancePercentage'] != null
        ? '${academic!['attendancePercentage']}%'
        : 'N/A';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CampusGlassCard(
          intensity: GlassIntensity.medium,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Academic Performance Metrics',
                style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildMetricCell('Cumulative CGPA', '$cgpa', const Color(0xFF10B981), isDark),
                  _buildMetricCell('Current Year', year, isDark ? AppColors.secondaryCyan : AppColors.primaryBlue, isDark),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMetricCell('Standing Backlogs', backlogs, const Color(0xFF10B981), isDark),
                  _buildMetricCell('Attendance Rate', attendance, const Color(0xFF8B5CF6), isDark),
                ],
              ),
            ],
          ),
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
            Text(label, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsTab(Map<String, dynamic>? portfolio, bool isDark) {
    final rawSkills = portfolio?['skills'];
    final List<String> skills = [];
    if (rawSkills is List) {
      for (final s in rawSkills) {
        if (s is String && s.trim().isNotEmpty) {
          skills.add(s.trim());
        } else if (s is Map && s['name'] != null) {
          skills.add(s['name'].toString().trim());
        }
      }
    }

    if (skills.isEmpty) {
      return const Center(
        child: CampusEmptyState(
          title: 'No Skills Recorded',
          description: 'This student has not tagged any technical skills yet.',
          icon: Icons.psychology_outlined,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CampusGlassCard(
          intensity: GlassIntensity.medium,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verified Technical Skills',
                style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills.map((skill) {
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
          ),
        ),
      ],
    );
  }

  Widget _buildPlacementTab(List applications, bool isDark) {
    if (applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 48, color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
            const SizedBox(height: 12),
            Text('No Applications Recorded Yet', style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: applications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final app = applications[index] as Map<String, dynamic>;
        final drive = app['drive'] as Map<String, dynamic>?;
        final appStatus = app['status'] as String? ?? 'APPLIED';

        return CampusGlassCard(
          intensity: GlassIntensity.medium,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drive?['company_name'] ?? 'Company Drive',
                      style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      drive?['role_title'] ?? 'Role',
                      style: AppTypography.micro.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
              CampusStatusBadge(
                label: appStatus,
                type: appStatus == 'OFFERED' ? StatusBadgeType.success : StatusBadgeType.info,
              ),
            ],
          ),
        );
      },
    );
  }
}
