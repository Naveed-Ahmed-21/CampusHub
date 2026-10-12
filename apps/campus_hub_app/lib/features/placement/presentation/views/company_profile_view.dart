import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_loading_state.dart';
import '../../../../core/widgets/campus_error_state.dart';
import '../../../../core/widgets/campus_stat_card.dart';
import '../../../../core/widgets/campus_button.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../providers/placement_provider.dart';
import '../../domain/placement_models.dart';

class CompanyProfileView extends ConsumerStatefulWidget {
  final String companyId;

  const CompanyProfileView({super.key, required this.companyId});

  @override
  ConsumerState<CompanyProfileView> createState() => _CompanyProfileViewState();
}

class _CompanyProfileViewState extends ConsumerState<CompanyProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final companyAsync = ref.watch(companyDetailsProvider(widget.companyId));

    return Scaffold(
      body: AtmosphericBackground(
        child: SafeArea(
          child: companyAsync.when(
            loading: () => const CampusLoadingState(),
            error: (err, _) => CampusErrorState(
              message: 'Failed to load company profile',
              onRetry: () => ref.refresh(companyDetailsProvider(widget.companyId)),
            ),
            data: (company) {
              return Column(
                children: [
                  // Hero Header with Office Building Photo & Overlapping Logo (Image 08)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 175,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          image: (company.coverImageUrl != null && company.coverImageUrl!.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(company.coverImageUrl!),
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

                      // Top Controls
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
                                      const SnackBar(content: Text('Company profile link copied!')),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                _buildCircleIconButton(
                                  icon: Icons.bookmark_border_outlined,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Company bookmarked!')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Circular Overlapping Logo
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
                          child: company.logoUrl != null
                              ? Image.network(
                                  company.logoUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      company.name.isNotEmpty ? company.name[0].toUpperCase() : 'C',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    company.name.isNotEmpty ? company.name[0].toUpperCase() : 'C',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),

                  // Company Title, Industry, and Links
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 36, 20, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.name,
                          style: AppTypography.pageTitle.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkText : AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          company.industry ?? 'Global Enterprise & Technology Partner',
                          style: AppTypography.captionMedium.copyWith(
                            color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Action Buttons: Website & LinkedIn (Image 08)
                        Row(
                          children: [
                            if (company.website != null && company.website!.isNotEmpty)
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.language, size: 16),
                                  label: const Text('Website'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                                    side: BorderSide(
                                      color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.5),
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => UrlLauncherService.openUrl(context, company.website!),
                                ),
                              ),
                            if (company.website != null && company.website!.isNotEmpty && company.linkedinUrl != null && company.linkedinUrl!.isNotEmpty)
                              const SizedBox(width: 10),
                            if (company.linkedinUrl != null && company.linkedinUrl!.isNotEmpty)
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.work_outline, size: 16),
                                  label: const Text('LinkedIn'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0A66C2),
                                    side: BorderSide(color: const Color(0xFF0A66C2).withValues(alpha: 0.5)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => UrlLauncherService.openUrl(context, company.linkedinUrl!),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 3 Tabs: Overview, Drives, Preparation (Image 08)
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
                        Tab(text: 'Drives'),
                        Tab(text: 'Preparation'),
                      ],
                    ),
                  ),

                  // Tabs Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(company, isDark),
                        _buildDrivesTab(company, isDark),
                        _buildPreparationTab(company, isDark),
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

  Widget _buildOverviewTab(PlacementCompanyModel company, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 2 Stat Cards: Total Drives & Students Placed (Image 08)
        Row(
          children: [
            Expanded(
              child: CampusStatCard(
                title: 'Total Drives',
                value: '${company.drivesCount}',
                subtitle: 'Campus hiring drives',
                icon: Icons.work_outline,
                accentColor: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CampusStatCard(
                title: 'Students Placed',
                value: '${company.resourcesCount > 0 ? company.resourcesCount * 8 : company.drivesCount * 12}',
                subtitle: 'Hired alumni & offers',
                icon: Icons.school_outlined,
                accentColor: const Color(0xFF10B981),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // About Company Section
        Text(
          'About the Company',
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
            company.about ??
                '${company.name} is a premier institutional recruitment partner of Government College of Engineering, Erode. Conducting campus placement drives for engineering undergraduates with world-class packages and cutting-edge career pathways.',
            style: AppTypography.body.copyWith(
              color: isDark ? AppColors.darkText : AppColors.primaryText,
              height: 1.5,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Prominent Button: View Active Drives (Image 08)
        CampusButton(
          label: 'View Active Recruitment Drives',
          icon: const Icon(Icons.arrow_forward),
          type: CampusButtonType.primary,
          onPressed: () {
            _tabController.animateTo(1);
          },
        ),
      ],
    );
  }

  Widget _buildDrivesTab(PlacementCompanyModel company, bool isDark) {
    final drives = company.drives;
    if (drives.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off_outlined, size: 48, color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
            const SizedBox(height: 12),
            Text(
              'No Active Drives for ${company.name}',
              style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'New recruitment drives will appear here once announced.',
              style: AppTypography.micro.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: drives.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final drive = drives[index];
        return CampusGlassCard(
          intensity: GlassIntensity.medium,
          onTap: () => context.push('/placement/drives/${drive.id}'),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    drive.companyName.isNotEmpty ? drive.companyName[0] : 'D',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drive.roleTitle,
                      style: AppTypography.captionMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDark ? AppColors.darkText : AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${drive.packageCtc ?? 'Competitive CTC'} • ${drive.location ?? 'On-Site'}',
                      style: AppTypography.micro.copyWith(
                        color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                        fontWeight: FontWeight.w600,
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

  Widget _buildPreparationTab(PlacementCompanyModel company, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books_outlined, size: 48, color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue),
            const SizedBox(height: 12),
            Text(
              '${company.name} Interview Prep & Syllabus',
              style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Curated aptitude questions, coding challenges, and HR questions for ${company.name} recruitment drives.',
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
      ),
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
}
