import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/branding/gcee_logo.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_stat_card.dart';
import '../../../../core/widgets/campus_status_badge.dart';
import '../../../../core/widgets/campus_button.dart';
import '../../../../core/widgets/campus_empty_state.dart';
import '../../../../core/widgets/campus_bottom_nav.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../../../../features/dept_admin/presentation/views/dept_placement_view.dart';
import '../providers/placement_provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'placement_drawer.dart';

class PlacementHubView extends ConsumerStatefulWidget {
  const PlacementHubView({super.key});

  @override
  ConsumerState<PlacementHubView> createState() => _PlacementHubViewState();
}

class _PlacementHubViewState extends ConsumerState<PlacementHubView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final isOfficer = user?.isPlacementOfficer == true || user?.isAdmin == true;
    final isDeptAdmin = user?.isDeptAdmin == true || user?.role == 'DEPT_ADMIN';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      drawer: isOfficer ? const PlacementDrawer() : null,
      body: AtmosphericBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header matching blueprint Image 02
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    if (isOfficer) ...[
                      IconButton(
                        icon: const Icon(Icons.menu),
                        tooltip: 'Open Navigation Drawer',
                        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                      const SizedBox(width: 4),
                      Builder(
                        builder: (context) {
                          final avatarUrl = user?.avatarUrl?.trim();
                          final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
                          final resolvedAvatar = hasAvatar ? ApiEndpoints.resolveUrl(avatarUrl) : null;
                          return CampusAvatar(
                            imageUrl: resolvedAvatar,
                            name: user?.fullName.isNotEmpty == true ? user!.fullName : 'P',
                            radius: 20,
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Placement & Career Drives',
                                    style: AppTypography.pageTitle.copyWith(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? AppColors.darkText : AppColors.primaryText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text('👑', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user?.fullName != null ? 'Officer ${user!.fullName}' : 'GCEE Placement Cell',
                                    style: AppTypography.micro.copyWith(
                                      color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Officer Hub',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        icon: const Icon(Icons.notifications_none_outlined),
                        onPressed: () => context.push('/notifications'),
                      ),
                    ] else ...[
                      const GceeLogo(size: 36),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Career & Placements',
                              style: AppTypography.pageTitle.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkText : AppColors.primaryText,
                              ),
                            ),
                            Text(
                              'Explore drives & career roadmap',
                              style: AppTypography.micro.copyWith(
                                color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_none_outlined),
                        onPressed: () => context.push('/notifications'),
                      ),
                    ],
                  ],
                ),
              ),

              // Content based on Role
              Expanded(
                child: isOfficer
                    ? _buildOfficerDashboard(context, isDark)
                    : (isDeptAdmin ? const DeptPlacementView() : _buildStudentDashboard(context, isDark)),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // ==========================================
  // OFFICER DASHBOARD (Image 02)
  // ==========================================
  Widget _buildOfficerDashboard(BuildContext context, bool isDark) {
    final statsAsync = ref.watch(officerDashboardProvider);
    final drivesAsync = ref.watch(placementDrivesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(officerDashboardProvider);
        ref.invalidate(placementDrivesProvider);
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + CampusBottomNav.getBottomClearance(context)),
        children: [
          // KPI Metric Cards (Performant 2-row layout)
          statsAsync.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) {
              final totalDrives = stats['totalDrives'] ?? 0;
              final activeDrives = stats['activeDrives'] ?? 0;
              final acceptedOffers = stats['acceptedOffers'] ?? 0;

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CampusStatCard(
                          title: 'Active Drives',
                          value: '$activeDrives',
                          subtitle: '$totalDrives conducted this season',
                          icon: Icons.work_outline,
                          accentColor: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                          onTap: () => context.push('/placement/opportunities'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CampusStatCard(
                          title: 'Eligible Students',
                          value: '${stats['eligibleStudentsCount'] ?? stats['totalStudents'] ?? 0}',
                          subtitle: 'Across departments',
                          icon: Icons.groups_outlined,
                          accentColor: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                          onTap: () => context.push('/placement/students'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CampusStatCard(
                          title: 'Applications',
                          value: '${stats['totalApplications'] ?? stats['applicationsCount'] ?? 0}',
                          subtitle: 'Pending review',
                          icon: Icons.assignment_outlined,
                          accentColor: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                          onTap: () => context.push('/placement/applications'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CampusStatCard(
                          title: 'Students Placed',
                          value: '$acceptedOffers',
                          subtitle: '${stats['placementRate'] ?? 0}% placement rate',
                          icon: Icons.verified_outlined,
                          accentColor: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                          onTap: () => context.push('/placement/students'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Quick Action Hub Tiles (Performant 3-col rows)
          Text(
            'Quick Operations',
            style: AppTypography.captionMedium.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: isDark ? AppColors.darkText : AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 10),

          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionTile(
                      context,
                      icon: Icons.add_circle_outline,
                      label: 'Post Drive',
                      color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                      onTap: () => context.push('/placement/create-drive'),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickActionTile(
                      context,
                      icon: Icons.business_outlined,
                      label: 'Companies',
                      color: const Color(0xFF38BDF8),
                      onTap: () => context.push('/placement/companies'),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickActionTile(
                      context,
                      icon: Icons.menu_book_outlined,
                      label: 'Preparation',
                      color: const Color(0xFFFBBF24),
                      onTap: () => context.push('/placement/preparation'),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionTile(
                      context,
                      icon: Icons.people_outline,
                      label: 'Students',
                      color: const Color(0xFF4ADE80),
                      onTap: () => context.push('/placement/students'),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickActionTile(
                      context,
                      icon: Icons.checklist_rtl_outlined,
                      label: 'Shortlist',
                      color: const Color(0xFFA78BFA),
                      onTap: () => context.push('/placement/shortlist'),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickActionTile(
                      context,
                      icon: Icons.bar_chart_outlined,
                      label: 'Analytics',
                      color: const Color(0xFFF472B6),
                      onTap: () => context.push('/placement/analytics'),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Upcoming Placement Drives Section
          Row(
            children: [
              Text(
                'Upcoming Drives',
                style: AppTypography.captionMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: isDark ? AppColors.darkText : AppColors.primaryText,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/placement/opportunities'),
                child: const Text('View All'),
              ),
            ],
          ),

          drivesAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
            error: (_, __) => const Text('Could not load drives.'),
            data: (drives) {
              if (drives.isEmpty) {
                return CampusGlassCard(
                  intensity: GlassIntensity.medium,
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.work_off_outlined, size: 36, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text('No upcoming placement drives posted yet.'),
                        const SizedBox(height: 12),
                        CampusButton(
                          label: 'Post First Drive',
                          type: CampusButtonType.secondary,
                          onPressed: () => context.push('/placement/create-drive'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: drives.take(3).map((drive) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CampusGlassCard(
                      intensity: GlassIntensity.medium,
                      onTap: () => context.push('/placement/drives/${drive.id}'),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.border,
                                width: 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: drive.companyLogo != null && drive.companyLogo!.isNotEmpty
                                ? Image.network(
                                    drive.companyLogo!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Text(
                                        drive.companyName.isNotEmpty ? drive.companyName[0].toUpperCase() : 'C',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                          color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      drive.companyName.isNotEmpty ? drive.companyName[0].toUpperCase() : 'C',
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
                                  drive.companyName,
                                  style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${drive.roleTitle} • ${drive.packageCtc ?? 'Competitive CTC'}',
                                  style: AppTypography.micro.copyWith(
                                    color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CampusStatusBadge(
                            label: drive.status,
                            type: drive.status == 'ONGOING' ? StatusBadgeType.success : StatusBadgeType.info,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==========================================
  // STUDENT DASHBOARD
  // ==========================================
  Widget _buildStudentDashboard(BuildContext context, bool isDark) {
    final studentAsync = ref.watch(studentDashboardProvider);
    final drivesAsync = ref.watch(placementDrivesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(studentDashboardProvider);
        ref.invalidate(placementDrivesProvider);
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + CampusBottomNav.getBottomClearance(context)),
        children: [
          // Student Readiness Card
          studentAsync.when(
            loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
            data: (data) {
              final studentProfile = data['studentProfile'] as Map<String, dynamic>? ?? {};
              final myApps = (data['myApplications'] as List?) ?? [];
              final myOffers = (data['myOffers'] as List?) ?? [];
              final eligibleCount = data['eligibleDrivesCount'] ?? 0;

              return Column(
                children: [
                  CampusGlassCard(
                    intensity: GlassIntensity.medium,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.2),
                          child: Icon(Icons.school, color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Placement Readiness',
                                style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'CGPA: ${studentProfile['cgpa'] ?? 'N/A'} • ${studentProfile['department'] ?? 'Department'}',
                                style: AppTypography.micro.copyWith(color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
                              ),
                            ],
                          ),
                        ),
                        CampusButton(
                          label: 'Career Hub',
                          type: CampusButtonType.secondary,
                          onPressed: () => context.push('/career'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: CampusStatCard(
                          title: 'Eligible Drives',
                          value: '$eligibleCount',
                          icon: Icons.verified_outlined,
                          accentColor: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                          onTap: () => context.push('/placement/opportunities'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CampusStatCard(
                          title: 'Applied',
                          value: '${myApps.length}',
                          icon: Icons.send_outlined,
                          accentColor: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CampusStatCard(
                          title: 'Offers',
                          value: '${myOffers.length}',
                          icon: Icons.star_border,
                          accentColor: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Shortcuts: Opportunities & Preparation Hub
          Row(
            children: [
              Expanded(
                child: CampusButton(
                  label: 'View Placement Drives',
                  icon: const Icon(Icons.work_outline),
                  type: CampusButtonType.primary,
                  onPressed: () => context.push('/placement/opportunities'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CampusButton(
                  label: 'Preparation Hub',
                  icon: const Icon(Icons.menu_book_outlined),
                  type: CampusButtonType.secondary,
                  onPressed: () => context.push('/placement/preparation'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Open Drives List
          Text(
            'Open Recruitment Drives',
            style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 10),

          drivesAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
            error: (_, __) => const Text('Could not load drives.'),
            data: (drives) {
              if (drives.isEmpty) {
                return const CampusEmptyState(
                  title: 'No Active Drives',
                  description: 'New campus placement drives will appear here once announced.',
                  icon: Icons.work_off_outlined,
                );
              }

              return Column(
                children: drives.take(5).map((drive) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CampusGlassCard(
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
                                drive.companyName.isNotEmpty ? drive.companyName[0].toUpperCase() : 'C',
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
                                  drive.companyName,
                                  style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${drive.roleTitle} • ${drive.packageCtc ?? 'Competitive CTC'}',
                                  style: AppTypography.micro.copyWith(
                                    color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Apply →',
                            style: AppTypography.captionMedium.copyWith(
                              color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final effectiveColor = isDark ? AppColors.secondaryCyan : AppColors.primaryBlue;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: effectiveColor, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTypography.micro.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.primaryText,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
