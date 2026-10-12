import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/branding/gcee_brand.dart';
import '../../../../core/branding/gcee_logo.dart';
import '../../../../core/services/media_picker_service.dart';
import '../../../../core/services/media_upload_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../core/widgets/atmospheric_background.dart';

import '../../../profile/presentation/widgets/profile_story_avatar.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../providers/placement_provider.dart';

class PlacementProfileView extends ConsumerStatefulWidget {
  const PlacementProfileView({super.key});

  @override
  ConsumerState<PlacementProfileView> createState() => _PlacementProfileViewState();
}

class _PlacementProfileViewState extends ConsumerState<PlacementProfileView> {
  bool _isUploadingAvatar = false;

  Future<void> _pickAndUploadAvatar() async {
    if (_isUploadingAvatar) return;

    try {
      final file = await MediaPickerService.showMediaPickerSheet(
        context,
        enableVideoGallery: false,
        enableDocuments: false,
      );

      if (file == null || !mounted) return;

      setState(() => _isUploadingAvatar = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Uploading profile picture...'),
            ],
          ),
          duration: Duration(seconds: 4),
        ),
      );

      final uploadService = ref.read(mediaUploadServiceProvider);
      final result = await uploadService.uploadSelectedFile(file);

      await ref.read(profileControllerProvider.notifier).uploadAvatar(result.url);
      ref.invalidate(authControllerProvider);
      ref.invalidate(profileControllerProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile picture updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload picture: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final statsAsync = ref.watch(officerDashboardProvider);
    final themeMode = ref.watch(themeNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final fullName = user?.fullName.isNotEmpty == true ? user!.fullName : 'Placement Officer';
    final email = user?.email.isNotEmpty == true ? user!.email : 'placement@gcee.ac.in';

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Sleek iOS Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    if (context.canPop()) ...[
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        'Officer Profile',
                        style: AppTypography.pageTitle.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          color: isDark ? AppColors.darkText : AppColors.primaryText,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      tooltip: 'Refresh Stats',
                      style: IconButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        ref.invalidate(officerDashboardProvider);
                        ref.invalidate(placementDrivesProvider);
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // 1. Officer Identity Glass Hero Card with Interactive Avatar Upload
                    CampusGlassCard(
                      intensity: GlassIntensity.medium,
                      borderRadius: BorderRadius.circular(22),
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          // Avatar with Upload Trigger Badge
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              ProfileStoryAvatar(
                                userId: user?.id ?? '',
                                avatarUrl: user?.avatarUrl,
                                name: fullName,
                                radius: 38,
                                showCameraBadge: true,
                                onCameraTap: _pickAndUploadAvatar,
                                fallbackOnTap: _pickAndUploadAvatar,
                              ),
                              if (_isUploadingAvatar)
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: const BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(width: 16),
                          // Officer Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName,
                                  style: AppTypography.pageTitle.copyWith(
                                    fontSize: 18.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                    color: isDark ? AppColors.darkText : AppColors.primaryText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Placement Officer 👑',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'GCEE T&P Cell',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  email,
                                  style: TextStyle(
                                    color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 2. Recruitment Season Performance
                    _buildSectionHeader('Recruitment Season Performance', isDark),
                    const SizedBox(height: 10),

                    statsAsync.when(
                      loading: () => CampusGlassCard(
                        intensity: GlassIntensity.subtle,
                        borderRadius: BorderRadius.circular(18),
                        child: const SizedBox(
                          height: 120,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                      error: (_, __) => CampusGlassCard(
                        intensity: GlassIntensity.subtle,
                        borderRadius: BorderRadius.circular(18),
                        padding: const EdgeInsets.all(16),
                        child: const Text('Live season statistics currently syncing.'),
                      ),
                      data: (stats) {
                        final totalDrives = stats['totalDrives'] ?? 0;
                        final activeDrives = stats['activeDrives'] ?? 0;
                        final placedStudents = stats['acceptedOffers'] ?? stats['offeredCount'] ?? 0;
                        final placementRate = stats['placementRate'] ?? 0;
                        final highestCtc = stats['highestCtc']?.toString() ?? 'N/A';
                        final averageCtc = stats['averageCtc']?.toString() ?? 'N/A';

                        return CampusGlassCard(
                          intensity: GlassIntensity.subtle,
                          borderRadius: BorderRadius.circular(20),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  _buildStatBox(
                                    label: 'Total Drives',
                                    value: '$totalDrives',
                                    subtitle: '$activeDrives Active',
                                    color: const Color(0xFF2563EB),
                                    icon: Icons.business_center_rounded,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 10),
                                  _buildStatBox(
                                    label: 'Offers Placed',
                                    value: '$placedStudents',
                                    subtitle: '$placementRate% Success',
                                    color: const Color(0xFF10B981),
                                    icon: Icons.check_circle_rounded,
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _buildStatBox(
                                    label: 'Highest CTC',
                                    value: highestCtc,
                                    subtitle: 'Campus Record',
                                    color: const Color(0xFF8B5CF6),
                                    icon: Icons.military_tech_rounded,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 10),
                                  _buildStatBox(
                                    label: 'Average CTC',
                                    value: averageCtc,
                                    subtitle: 'Cohort Average',
                                    color: const Color(0xFFF59E0B),
                                    icon: Icons.trending_up_rounded,
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 22),

                    // 3. Operational Shortcuts Hub (iOS Inset Grouped)
                    _buildSectionHeader('Placement Operations Hub', isDark),
                    const SizedBox(height: 10),

                    CampusGlassCard(
                      intensity: GlassIntensity.subtle,
                      borderRadius: BorderRadius.circular(20),
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildOperationTile(
                            context,
                            icon: Icons.add_business_rounded,
                            iconColor: const Color(0xFF2563EB),
                            title: 'Post New Placement Drive',
                            subtitle: 'Publish requirements, CTC & rounds',
                            onTap: () => context.push('/placement/create-drive'),
                            isDark: isDark,
                          ),
                          _buildDivider(isDark),
                          _buildOperationTile(
                            context,
                            icon: Icons.apartment_rounded,
                            iconColor: const Color(0xFF0D9488),
                            title: 'Corporate Recruiter Directory',
                            subtitle: 'View partnering companies and contacts',
                            onTap: () => context.push('/placement/companies'),
                            isDark: isDark,
                          ),
                          _buildDivider(isDark),
                          _buildOperationTile(
                            context,
                            icon: Icons.fact_check_rounded,
                            iconColor: const Color(0xFF10B981),
                            title: 'Candidate Shortlists & Interviews',
                            subtitle: 'Manage rounds and publish selected students',
                            onTap: () => context.push('/placement/shortlist'),
                            isDark: isDark,
                          ),
                          _buildDivider(isDark),
                          _buildOperationTile(
                            context,
                            icon: Icons.pie_chart_outline_rounded,
                            iconColor: const Color(0xFF8B5CF6),
                            title: 'Department Analytics & Trends',
                            subtitle: 'Branch-wise placement stats and salary curves',
                            onTap: () => context.push('/placement/analytics'),
                            isDark: isDark,
                          ),
                          _buildDivider(isDark),
                          _buildOperationTile(
                            context,
                            icon: Icons.file_present_rounded,
                            iconColor: const Color(0xFFF59E0B),
                            title: 'Accreditation Reports & Dossiers',
                            subtitle: 'Download NAAC / NIRF data records',
                            onTap: () => context.push('/placement/reports'),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // 4. Institutional Office & Official Contact
                    _buildSectionHeader('Placement Cell Office', isDark),
                    const SizedBox(height: 10),

                    CampusGlassCard(
                      intensity: GlassIntensity.subtle,
                      borderRadius: BorderRadius.circular(20),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              GceeLogo(size: 38),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      GceeBrand.institutionName,
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Centre for Career Guidance and Placement (CCGP)',
                                      style: TextStyle(fontSize: 11.5, color: AppColors.secondaryText),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildDivider(isDark),
                          const SizedBox(height: 12),
                          _buildOfficeInfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'Office Location',
                            value: 'Training & Placement Block, Ground Floor, Admin Wing',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),
                          _buildOfficeInfoRow(
                            icon: Icons.mail_outline_rounded,
                            label: 'Official Cell Email',
                            value: 'placement@gcee.ac.in',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),
                          _buildOfficeInfoRow(
                            icon: Icons.phone_in_talk_outlined,
                            label: 'Campus Helpline',
                            value: '0424-2533374 / +91 94433 00000',
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // 5. System Preferences
                    _buildSectionHeader('System Preferences', isDark),
                    const SizedBox(height: 10),

                    CampusGlassCard(
                      intensity: GlassIntensity.subtle,
                      borderRadius: BorderRadius.circular(20),
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                themeMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                                size: 20,
                              ),
                            ),
                            title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text(
                              themeMode == ThemeMode.dark ? 'Enabled' : 'Disabled',
                              style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
                            ),
                            trailing: Switch.adaptive(
                              value: themeMode == ThemeMode.dark,
                              activeTrackColor: AppColors.primaryBlue,
                              onChanged: (val) {
                                ref
                                    .read(themeNotifierProvider.notifier)
                                    .setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                              },
                            ),
                          ),
                          _buildDivider(isDark),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                color: Colors.amber,
                                size: 20,
                              ),
                            ),
                            title: const Text('Placement Notifications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text(
                              'Drive updates and student alerts',
                              style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                            onTap: () => context.push('/notifications'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // 6. Sign Out Button (Sleek iOS Stadium)
                    Center(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.logout_rounded, size: 16, color: theme.colorScheme.error),
                        label: Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.error,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.35)),
                          backgroundColor: theme.colorScheme.error.withValues(alpha: 0.06),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text('Confirm Sign Out'),
                              content: const Text(
                                'Are you sure you want to sign out of the Placement Officer portal?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red.shade700,
                                  ),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Sign Out'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await ref.read(authControllerProvider.notifier).logout();
                          }
                        },
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

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: AppTypography.captionMedium.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 15,
        letterSpacing: -0.2,
        color: isDark ? AppColors.darkText : AppColors.primaryText,
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.22), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.secondaryText,
                  ),
                ),
                Icon(icon, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
          color: isDark ? AppColors.darkText : AppColors.primaryText,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11.5,
          color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildOfficeInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkText : AppColors.primaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
