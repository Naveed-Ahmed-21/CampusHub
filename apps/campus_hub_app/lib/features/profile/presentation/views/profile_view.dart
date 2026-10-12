import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/media_picker_service.dart';
import '../../../../core/services/media_upload_service.dart';
import '../../../../core/services/media_storage_service.dart';
import '../../../../core/services/file_open_service.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../../../shared/responsive/responsive_layout.dart';
import '../../../../shared/widgets/async_value_widget.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../../domain/models/user_profile.dart';
import '../../../portfolio/presentation/views/portfolio_view.dart';
import '../../../clubs/presentation/providers/club_provider.dart';
import '../../../clubs/data/clubs_repository.dart';
import 'user_posts_view.dart';
import 'user_events_view.dart';
import 'user_follows_view.dart';
import '../../../clubs/presentation/views/club_detail_view.dart';
import '../../../../shared/widgets/full_screen_image_viewer.dart';
import '../widgets/request_change_dialog.dart';
import '../providers/student_profile_provider.dart';
import '../../../../core/widgets/campus_bottom_nav.dart';
import '../../../admin/presentation/views/admin_profile_view.dart';
import '../../../dept_admin/presentation/views/dept_admin_profile_view.dart';
import '../../../faculty/presentation/views/faculty_profile_view.dart';
import '../../../placement/presentation/views/placement_profile_view.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_app_bar.dart';

import '../widgets/profile_story_avatar.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final profileAsync = ref.watch(profileControllerProvider);
    final theme = Theme.of(context);

    // Prioritize authenticated user role so switching accounts updates immediately
    final effectiveRole = user?.role ?? profileAsync.value?.role;
    final isDeptAdmin = user?.isDeptAdmin == true || effectiveRole == 'DEPT_ADMIN';
    final isPlacement = user?.isPlacementOfficer == true ||
        effectiveRole == 'PLACEMENT' ||
        effectiveRole == 'PLACEMENT_OFFICER';
    final isFaculty = user?.isFaculty == true || effectiveRole == 'FACULTY';
    final isAdmin = user?.isAdmin == true ||
        effectiveRole == 'ADMIN' ||
        effectiveRole == 'SUPER_ADMIN';

    if (isDeptAdmin) {
      return const DeptAdminProfileView();
    }
    if (isPlacement) {
      return const PlacementProfileView();
    }
    if (isAdmin) {
      return const AdminProfileView();
    }
    if (isFaculty) {
      return const FacultyProfileView();
    }

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CampusAppBar(
          title: 'My Profile',
          automaticallyImplyLeading: false,
          actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Profile',
            onPressed: () {
              ref.read(profileControllerProvider.notifier).refreshProfile();
              ref.invalidate(myProposedClubsProvider);
              ref.invalidate(studentDetailedProfileProvider);
              ref.invalidate(studentChangeRequestsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: const Text('Log Out'),
                  content: const Text(
                      'Are you sure you want to sign out of CampusHub?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Log Out'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                ref.read(authControllerProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
      body: AsyncValueWidget<UserProfile>(
        value: profileAsync,
        data: (profile) => ResponsiveLayout(
          mobile: _ProfileMobileLayout(profile: profile),
          desktop: _ProfileDesktopLayout(profile: profile),
        ),
      ),
    ),
  );
  }
}


class _ProfileMobileLayout extends ConsumerStatefulWidget {
  final UserProfile profile;
  const _ProfileMobileLayout({required this.profile});

  @override
  ConsumerState<_ProfileMobileLayout> createState() =>
      _ProfileMobileLayoutState();
}

class _ProfileMobileLayoutState extends ConsumerState<_ProfileMobileLayout>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool get _isAdmin => widget.profile.role == 'ADMIN';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _isAdmin ? 3 : 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = widget.profile;

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _ProfileHeroCard(profile: profile),
                  const SizedBox(height: 14),
                  _ProfileStatsBar(profile: profile),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: theme.colorScheme.primary,
                indicatorWeight: 3,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.outline,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  if (!_isAdmin)
                    const Tab(
                        icon: Icon(Icons.verified_user_outlined, size: 20),
                        text: 'Official Record'),
                  const Tab(
                      icon: Icon(Icons.person_outline, size: 20),
                      text: 'Overview'),
                  const Tab(
                      icon: Icon(Icons.groups_outlined, size: 20),
                      text: 'My Clubs'),
                  const Tab(
                      icon: Icon(Icons.bookmark_outline, size: 20),
                      text: 'Activity'),
                ],
              ),
              color: theme.brightness == Brightness.dark
                  ? AppColors.darkBase
                  : AppColors.lightBackground,
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Official Record (Students only, locked & approval required)
          if (!_isAdmin)
            ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                _OfficialRecordSection(profile: profile),
                const CampusBottomNavSpacer(),
              ],
            ),

          // Tab 2: Overview (Bio, Resume, Clubs, Projects, Skills, Socials)
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              _BioSection(profile: profile),
              const SizedBox(height: 16),
              _ResumeSection(profile: profile),
              const SizedBox(height: 16),
              _ProfileClubsSection(profile: profile),
              const SizedBox(height: 16),
              _ProjectsSection(profile: profile),
              const SizedBox(height: 16),
              _SkillsSection(profile: profile),
              const SizedBox(height: 16),
              _SocialLinksSection(profile: profile),
              const CampusBottomNavSpacer(),
            ],
          ),

          // Tab 3: My Clubs
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: const [
              _MyProposedClubsSection(),
              CampusBottomNavSpacer(),
            ],
          ),

          // Tab 4: Activity & Saved
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: const [
              _QuickActivityStatsSection(),
              CampusBottomNavSpacer(),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileDesktopLayout extends ConsumerStatefulWidget {
  final UserProfile profile;
  const _ProfileDesktopLayout({required this.profile});

  @override
  ConsumerState<_ProfileDesktopLayout> createState() =>
      _ProfileDesktopLayoutState();
}

class _ProfileDesktopLayoutState extends ConsumerState<_ProfileDesktopLayout> {
  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1080),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _ProfileHeroCard(profile: profile),
              const SizedBox(height: 20),
              _ProfileStatsBar(profile: profile),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        if (profile.role != 'ADMIN') ...[
                          _OfficialRecordSection(profile: profile),
                          const SizedBox(height: 16),
                        ],
                        _BioSection(profile: profile),
                        const SizedBox(height: 16),
                        _SkillsSection(profile: profile),
                        const SizedBox(height: 16),
                        _SocialLinksSection(profile: profile),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 6,
                    child: Column(
                      children: [
                        _ProjectsSection(profile: profile),
                        const SizedBox(height: 16),
                        _ResumeSection(profile: profile),
                        const SizedBox(height: 16),
                        const _MyProposedClubsSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeroCard extends ConsumerWidget {
  final UserProfile profile;
  const _ProfileHeroCard({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Future<void> uploadFile(SelectedMediaFile file) async {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading profile picture...')),
        );

        final uploadService = ref.read(mediaUploadServiceProvider);
        final result = await uploadService.uploadSelectedFile(file);

        await ref
            .read(profileControllerProvider.notifier)
            .uploadAvatar(result.url);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to update avatar: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }

    Future<void> pickAndUploadAvatar() async {
      final hasAvatar = profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty;
      final resolvedAvatarUrl = hasAvatar ? ApiEndpoints.resolveUrl(profile.avatarUrl!.trim()) : null;
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetCtx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  'Profile Photo',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (hasAvatar && resolvedAvatarUrl != null)
                ListTile(
                  leading: const Icon(Icons.fullscreen_rounded),
                  title: const Text('View Profile Photo'),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    FullScreenImageViewer.openSingle(
                      context,
                      imageUrl: resolvedAvatarUrl,
                      heroTag: 'profile_avatar_self_${profile.id}',
                      title: profile.fullName,
                      subtitle: profile.bio ?? profile.role,
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take Photo with Camera'),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final file = await MediaPickerService.pickImageFromCamera();
                  if (file != null && context.mounted) {
                    await uploadFile(file);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final file = await MediaPickerService.pickImageFromGallery();
                  if (file != null && context.mounted) {
                    await uploadFile(file);
                  }
                },
              ),
              if (hasAvatar)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove Current Photo', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Remove Profile Photo?'),
                        content: const Text(
                          'Are you sure you want to remove your profile photo? Your initials will be displayed instead.',
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      try {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Removing profile photo...')),
                        );
                        await ref.read(profileControllerProvider.notifier).removeAvatar();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile photo removed successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to remove photo: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    }
                  },
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with camera action
              Builder(
                builder: (context) {
                  final resolvedAvatarUrl = (profile.avatarUrl != null && profile.avatarUrl!.trim().isNotEmpty)
                      ? ApiEndpoints.resolveUrl(profile.avatarUrl!.trim())
                      : null;

                  return ProfileStoryAvatar(
                    userId: profile.id,
                    avatarUrl: profile.avatarUrl,
                    name: profile.fullName,
                    radius: 42,
                    heroTag: 'profile_avatar_self_${profile.id}',
                    showCameraBadge: true,
                    onCameraTap: pickAndUploadAvatar,
                    fallbackOnTap: () {
                      if (resolvedAvatarUrl != null) {
                        FullScreenImageViewer.openSingle(
                          context,
                          imageUrl: resolvedAvatarUrl,
                          heroTag: 'profile_avatar_self_${profile.id}',
                          title: profile.fullName,
                          subtitle: profile.bio ?? profile.role,
                        );
                      } else {
                        pickAndUploadAvatar();
                      }
                    },
                  );

            },
          ),
          const SizedBox(width: 16),

              // User Info details
              Expanded(
                child: Builder(
                  builder: (context) {
                    final detailed = ref.watch(studentDetailedProfileProvider).value;
                    final authUser = ref.watch(authControllerProvider).value;

                    final resolvedName = detailed?.overview.fullName.isNotEmpty == true
                        ? detailed!.overview.fullName
                        : (profile.fullName.isNotEmpty
                            ? profile.fullName
                            : (authUser != null ? '${authUser.firstName} ${authUser.lastName}'.trim() : ''));
                    final displayName = resolvedName.isNotEmpty ? resolvedName : 'Student';

                    final dept = detailed?.officialIdentity.departmentName ??
                        (profile.department != null && profile.department!.isNotEmpty
                            ? profile.department!
                            : (authUser?.departmentId != null ? 'Information Technology' : ''));

                    final rawBatch = detailed?.officialIdentity.batchName ??
                        (detailed?.officialIdentity.admissionYear != null
                            ? '${detailed!.officialIdentity.admissionYear}'
                            : '');
                    final batchText = rawBatch.isNotEmpty
                        ? (rawBatch.toLowerCase().contains('batch') ? rawBatch : '$rawBatch batch')
                        : '';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Full Student Name without truncation
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                            height: 1.2,
                          ),
                        ),
                        if (dept.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          // 2. Full Department Name on its own line
                          Text(
                            dept,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                              height: 1.25,
                            ),
                          ),
                        ],
                        if (batchText.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          // 3. Batch on its own line (e.g. "2024 batch")
                          Text(
                            batchText,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),

                        // 4. Roll Number (if available)
                        if (profile.rollNumber != null &&
                            profile.rollNumber!.isNotEmpty) ...[
                          Text(
                            'Roll No: ${profile.rollNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 3),
                        ],

                        // 5. Username Chip
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: profile.displayUsername));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Username copied to clipboard!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  profile.displayUsername,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.copy,
                                    size: 12, color: theme.colorScheme.primary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),

                        // 6. Email
                        Text(
                          profile.email,
                          style: TextStyle(
                              fontSize: 12, color: theme.colorScheme.outline),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),

                        // 7. Role & Status Badges at bottom at last
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                profile.role,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.green.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      size: 12, color: Colors.green),
                                  SizedBox(width: 4),
                                  Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons: Edit Profile & Digital Portfolio
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () =>
                      _showEditProfileDialog(context, ref, profile),
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Edit Profile'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (ctx) => const PortfolioView()),
                    );
                  },
                  icon: const Icon(Icons.work_history_outlined, size: 17),
                  label: const Text('Portfolio'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileStatsBar extends StatelessWidget {
  final UserProfile profile;
  const _ProfileStatsBar({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            label: 'Posts',
            value: '${profile.postsCount}',
            icon: Icons.grid_on_rounded,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (ctx) => const UserPostsView(initialTabIndex: 0)),
              );
            },
          ),
          Container(
              width: 1,
              height: 28,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          _buildStatItem(
            context,
            label: 'Followers',
            value: '${profile.followersCount}',
            icon: Icons.people_outline,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => UserFollowsView(
                    userId: profile.id,
                    userName: profile.fullName,
                    initialIndex: 0,
                  ),
                ),
              );
            },
          ),
          Container(
              width: 1,
              height: 28,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          _buildStatItem(
            context,
            label: 'Following',
            value: '${profile.followingCount}',
            icon: Icons.person_add_alt_1_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => UserFollowsView(
                    userId: profile.id,
                    userName: profile.fullName,
                    initialIndex: 1,
                  ),
                ),
              );
            },
          ),
          Container(
              width: 1,
              height: 28,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          _buildStatItem(
            context,
            label: 'Saved',
            value: 'Posts',
            icon: Icons.bookmark_border_rounded,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (ctx) => const UserPostsView(initialTabIndex: 1)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfficialRecordSection extends ConsumerWidget {
  final UserProfile profile;
  const _OfficialRecordSection({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (profile.role == 'ADMIN') {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final detailedAsync = ref.watch(studentDetailedProfileProvider);

    return detailedAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(28.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Unable to load institutional official record: $e'),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(studentDetailedProfileProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (detailed) {
        final id = detailed.officialIdentity;
        final p = detailed.personal;
        final f = detailed.family;
        final addr = detailed.address;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // B. Official Information (Locked 🔒)
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Official Information (Locked)',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'LOCKED',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Official institutional data. To update, submit a request.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const Divider(height: 20),
                    _buildLockedFieldItem(
                      theme,
                      context,
                      ref,
                      label: 'Full Name',
                      value: detailed.overview.fullName,
                      fieldName: 'full_name',
                      category: 'ACADEMIC_IDENTITY_CHANGE',
                    ),
                    const SizedBox(height: 8),
                    _buildLockedFieldItem(
                      theme,
                      context,
                      ref,
                      label: 'Registration Number',
                      value: id.registrationNumber ?? 'Pending Registration',
                      fieldName: 'registration_number',
                      category: 'ACADEMIC_IDENTITY_CHANGE',
                    ),
                    const SizedBox(height: 8),
                    _buildLockedFieldItem(
                      theme,
                      context,
                      ref,
                      label: 'Roll Number',
                      value: id.rollNumber ?? profile.rollNumber ?? 'Not Assigned',
                      fieldName: 'roll_number',
                      category: 'ACADEMIC_IDENTITY_CHANGE',
                    ),
                    const SizedBox(height: 8),
                    _buildLockedFieldItem(
                      theme,
                      context,
                      ref,
                      label: 'Department',
                      value: id.departmentName ?? (profile.department != null && profile.department!.isNotEmpty ? profile.department! : 'Assigned by Department'),
                      fieldName: 'department',
                      category: 'ACADEMIC_IDENTITY_CHANGE',
                    ),
                    const SizedBox(height: 8),
                    _buildLockedFieldItem(
                      theme,
                      context,
                      ref,
                      label: 'Batch',
                      value: id.batchName ?? (id.admissionYear != null ? '${id.admissionYear} Cohort' : 'Official Record'),
                      fieldName: 'batch_name',
                      category: 'ACADEMIC_IDENTITY_CHANGE',
                    ),
                    const SizedBox(height: 8),
                    _buildLockedFieldItem(
                      theme,
                      context,
                      ref,
                      label: 'Section',
                      value: id.section != null && id.section!.isNotEmpty ? 'Section ${id.section}' : 'Not Assigned',
                      fieldName: 'section',
                      category: 'ACADEMIC_IDENTITY_CHANGE',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // C. Personal Information (Approval Required ⚠️)
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Personal Information (Approval Required)',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'REQUIRES APPROVAL',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Editing creates a profile change request submitted to college administration.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const Divider(height: 20),
                    _buildApprovalFieldItem(
                      theme,
                      context,
                      ref,
                      label: 'Date of Birth',
                      value: p.dob ?? 'Not set',
                      subtitle: p.age != null ? 'Age: ${p.age} years' : null,
                      fieldName: 'dob',
                      category: 'PERSONAL_CHANGE',
                    ),
                    const SizedBox(height: 8),
                    _buildApprovalFieldItem(
                      theme,
                      context,
                      ref,
                      label: 'Personal Email',
                      value: detailed.overview.email.isNotEmpty ? detailed.overview.email : profile.email,
                      fieldName: 'email',
                      category: 'PERSONAL_CHANGE',
                    ),
                    const SizedBox(height: 8),
                    _buildApprovalFieldItem(
                      theme,
                      context,
                      ref,
                      label: 'Mobile Number',
                      value: p.phone ?? profile.phone ?? 'Not set',
                      fieldName: 'phone',
                      category: 'PERSONAL_CHANGE',
                    ),
                    const SizedBox(height: 8),
                    _buildApprovalFieldItem(
                      theme,
                      context,
                      ref,
                      label: 'Father Name',
                      value: f.fatherName ?? 'Not set',
                      fieldName: 'father_name',
                      category: 'PERSONAL_CHANGE',
                    ),
                    const SizedBox(height: 8),
                    _buildApprovalFieldItem(
                      theme,
                      context,
                      ref,
                      label: 'Father Phone',
                      value: f.fatherPhone ?? 'Not set',
                      fieldName: 'father_phone',
                      category: 'PERSONAL_CHANGE',
                    ),
                    const SizedBox(height: 8),
                    _buildApprovalFieldItem(
                      theme,
                      context,
                      ref,
                      label: 'Mother Name',
                      value: f.motherName ?? 'Not set',
                      fieldName: 'mother_name',
                      category: 'PERSONAL_CHANGE',
                    ),
                    const SizedBox(height: 8),
                    _buildApprovalFieldItem(
                      theme,
                      context,
                      ref,
                      label: 'Mother Phone',
                      value: f.motherPhone ?? 'Not set',
                      fieldName: 'mother_phone',
                      category: 'PERSONAL_CHANGE',
                    ),
                    const SizedBox(height: 8),
                    _buildApprovalFieldItem(
                      theme,
                      context,
                      ref,
                      label: 'Permanent Address',
                      value: addr.fullPermanentAddress.isEmpty ? 'Not set' : addr.fullPermanentAddress,
                      fieldName: 'permanent_address',
                      category: 'PERSONAL_CHANGE',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Section 10: Change Requests Tracking
            _buildChangeRequestsTracker(theme, ref),
          ],
        );
      },
    );
  }

  Widget _buildLockedFieldItem(
    ThemeData theme,
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required String value,
    required String fieldName,
    required String category,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, size: 16, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              minimumSize: const Size(0, 30),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => RequestChangeDialog.show(
              context,
              fieldName: fieldName,
              fieldDisplayName: label,
              category: category,
              currentValue: value,
              onSuccess: () {
                ref.invalidate(studentChangeRequestsProvider);
                ref.invalidate(studentDetailedProfileProvider);
              },
            ),
            child: const Text('Request Change', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalFieldItem(
    ThemeData theme,
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required String value,
    required String fieldName,
    required String category,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_note, size: 18, color: Colors.orange.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              minimumSize: const Size(0, 30),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => RequestChangeDialog.show(
              context,
              fieldName: fieldName,
              fieldDisplayName: label,
              category: category,
              currentValue: value,
              onSuccess: () {
                ref.invalidate(studentChangeRequestsProvider);
                ref.invalidate(studentDetailedProfileProvider);
              },
            ),
            child: const Text('Request Change', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeRequestsTracker(ThemeData theme, WidgetRef ref) {
    final requestsAsync = ref.watch(studentChangeRequestsProvider);

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history_outlined, size: 20, color: Colors.indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Change Request Tracking',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Refresh Requests',
                  onPressed: () => ref.invalidate(studentChangeRequestsProvider),
                ),
              ],
            ),
            const Divider(height: 16),
            requestsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Text(
                'Could not load change requests: $err',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              data: (requests) {
                if (requests.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No profile change requests submitted yet.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
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

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(statusIcon, color: statusColor, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                req.field.replaceAll('_', ' ').toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  req.status,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Requested: "${req.requestedValue}" (Current: "${req.currentValue.isEmpty ? 'Not set' : req.currentValue}")',
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Reason: ${req.reason}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          if (req.reviewComment != null && req.reviewComment!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Admin note: ${req.reviewComment}',
                              style: TextStyle(fontSize: 11, color: statusColor, fontStyle: FontStyle.italic),
                            ),
                          ],
                          if (req.isPending) ...[
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
                                      const SnackBar(content: Text('Request cancelled.')),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BioSection extends StatelessWidget {
  final UserProfile profile;
  const _BioSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote_rounded,
                  color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'About & Bio',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            profile.bio != null && profile.bio!.isNotEmpty
                ? profile.bio!
                : 'No bio provided yet. Tap "Edit Profile" above to introduce yourself to your campus!',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: profile.bio != null && profile.bio!.isNotEmpty
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillsSection extends ConsumerWidget {
  final UserProfile profile;
  const _SkillsSection({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome,
                      color: theme.colorScheme.primary, size: 19),
                  const SizedBox(width: 8),
                  Text(
                    'Skills & Tech Stack',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                color: theme.colorScheme.primary,
                tooltip: 'Add Skill',
                onPressed: () => _showAddSkillDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (profile.skills.isEmpty)
            Text(
              'No skills added yet. Add your programming languages and expertise!',
              style: TextStyle(fontSize: 13, color: theme.colorScheme.outline),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.skills.map((skill) {
                return Chip(
                  label: Text(skill.skillName,
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600)),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.7),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => ref
                      .read(profileControllerProvider.notifier)
                      .removeSkill(skill.id),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.4)),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _ProjectsSection extends ConsumerWidget {
  final UserProfile profile;
  const _ProjectsSection({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.code_rounded,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Featured Projects',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                color: theme.colorScheme.primary,
                tooltip: 'Add Project',
                onPressed: () => _showAddProjectDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (profile.projects.isEmpty)
            Text(
              'No projects added to your showcase yet.',
              style: TextStyle(fontSize: 13, color: theme.colorScheme.outline),
            )
          else
            ...profile.projects.map((proj) {
              final hasRepo = proj.repoUrl != null && proj.repoUrl!.isNotEmpty;
              final hasDemo =
                  proj.projectUrl != null && proj.projectUrl!.isNotEmpty;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(Icons.folder_outlined,
                              color: theme.colorScheme.primary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                proj.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5),
                              ),
                              if (proj.description != null &&
                                  proj.description!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  proj.description!,
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      color:
                                          theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent, size: 18),
                          tooltip: 'Remove Project',
                          onPressed: () => ref
                              .read(profileControllerProvider.notifier)
                              .removeProject(proj.id),
                        ),
                      ],
                    ),
                    if (hasRepo || hasDemo) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (hasRepo)
                            ActionChip(
                              avatar: const Icon(Icons.code, size: 14),
                              label: const Text('Repository',
                                  style: TextStyle(fontSize: 11.5)),
                              onPressed: () =>
                                  UrlLauncherService.openUrl(context, proj.repoUrl!),
                            ),
                          if (hasDemo)
                            ActionChip(
                              avatar: const Icon(Icons.open_in_new, size: 14),
                              label: const Text('Live Demo',
                                  style: TextStyle(fontSize: 11.5)),
                              onPressed: () =>
                                  UrlLauncherService.openUrl(context, proj.projectUrl!),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SocialLinksSection extends StatelessWidget {
  final UserProfile profile;
  const _SocialLinksSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link_rounded,
                  color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Social & Web Links',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLinkTile(
            context,
            icon: Icons.code,
            label: 'GitHub',
            url: profile.githubUrl,
          ),
          const SizedBox(height: 8),
          _buildLinkTile(
            context,
            icon: Icons.work_outline,
            label: 'LinkedIn',
            url: profile.linkedinUrl,
          ),
          const SizedBox(height: 8),
          _buildLinkTile(
            context,
            icon: Icons.language,
            label: 'Portfolio / Website',
            url: profile.websiteUrl,
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String? url,
  }) {
    final theme = Theme.of(context);
    final hasUrl = url != null && url.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasUrl ? () => UrlLauncherService.openUrl(context, url) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: hasUrl
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      hasUrl ? url : 'Not connected',
                      style: TextStyle(
                        fontSize: 12,
                        color: hasUrl
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (hasUrl) ...[
                IconButton(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  tooltip: 'Open $label',
                  onPressed: () => UrlLauncherService.openUrl(context, url),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  tooltip: 'Copy Link',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('$label link copied!'),
                          duration: const Duration(seconds: 1)),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileClubsSection extends StatelessWidget {
  final UserProfile profile;
  const _ProfileClubsSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (profile.clubs.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_outlined,
                  color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'My Clubs & Organizations',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...profile.clubs.map((club) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.3)),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (ctx) => ClubDetailView(clubId: club.clubId)),
                  );
                },
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage:
                      club.logoUrl != null && club.logoUrl!.isNotEmpty
                          ? NetworkImage(ApiEndpoints.resolveUrl(club.logoUrl!))
                          : null,
                  child: club.logoUrl == null || club.logoUrl!.isEmpty
                      ? Icon(Icons.groups,
                          size: 18, color: theme.colorScheme.primary)
                      : null,
                ),
                title: Text(club.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: Text('${club.role} • ${club.category}',
                    style: TextStyle(
                        fontSize: 11.5, color: theme.colorScheme.outline)),
                trailing: const Icon(Icons.chevron_right, size: 18),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ResumeSection extends ConsumerStatefulWidget {
  final UserProfile profile;
  const _ResumeSection({required this.profile});

  @override
  ConsumerState<_ResumeSection> createState() => _ResumeSectionState();
}

class _ResumeSectionState extends ConsumerState<_ResumeSection> {
  bool _isUploading = false;
  bool _isOpening = false;

  Future<void> _pickAndUploadResume() async {
    final files = await MediaPickerService.pickDocuments(
      allowedExtensions: ['pdf', 'doc', 'docx'],
      allowMultiple: false,
    );

    if (files.isNotEmpty && mounted) {
      final file = files.first;
      setState(() => _isUploading = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading resume to your portfolio...')),
      );

      try {
        final uploadService = ref.read(mediaUploadServiceProvider);
        final result = await uploadService.uploadSelectedFile(file);

        await ref
            .read(profileControllerProvider.notifier)
            .uploadResume(result.url);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Resume uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to upload resume: $e'),
                backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _viewResume() async {
    final resumeUrl = widget.profile.resumeUrl;
    if (resumeUrl == null || resumeUrl.isEmpty) {
      _pickAndUploadResume();
      return;
    }

    setState(() => _isOpening = true);
    try {
      final storage = ref.read(mediaStorageServiceProvider);
      final cacheKey = 'user_resume_${widget.profile.id}';

      String? localPath;
      if (storage.isMessageMediaDownloaded(cacheKey)) {
        localPath = storage.getDownloadedPathForMessage(cacheKey);
      }

      if (localPath == null || !File(localPath).existsSync()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Preparing resume document...'),
                duration: Duration(seconds: 1)),
          );
        }
        localPath = await storage.downloadAndSaveFile(
          fileUrl: resumeUrl,
          messageId: cacheKey,
          fileName: '${widget.profile.firstName}_Resume.pdf',
        );
      }

      if (localPath != null && mounted) {
        await FileOpenService.openLocalFile(localPath, context: context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Could not open resume: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = widget.profile;
    final hasResume =
        profile.resumeUrl != null && profile.resumeUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.description_outlined,
                      color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Resume & CV',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (hasResume)
                IconButton(
                  icon: const Icon(Icons.upload_file, size: 18),
                  tooltip: 'Update / Replace Resume',
                  onPressed: _isUploading ? null : _pickAndUploadResume,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf,
                    color: Colors.redAccent, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasResume
                          ? '${profile.firstName}_Resume.pdf'
                          : 'No Resume Uploaded',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    Text(
                      hasResume
                          ? 'Uploaded to your Portfolio'
                          : 'Add your CV for opportunities & recruiters',
                      style: TextStyle(
                          fontSize: 12, color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
              if (hasResume)
                FilledButton.tonalIcon(
                  onPressed: _isOpening ? null : _viewResume,
                  icon: _isOpening
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.open_in_new, size: 14),
                  label: const Text('View', style: TextStyle(fontSize: 12)),
                )
              else
                FilledButton.tonalIcon(
                  onPressed: _isUploading ? null : _pickAndUploadResume,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.upload_file, size: 14),
                  label:
                      const Text('Upload PDF', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActivityStatsSection extends StatelessWidget {
  const _QuickActivityStatsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const UserPostsView()),
              );
            },
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              radius: 22,
              child: Icon(Icons.article_outlined,
                  color: theme.colorScheme.primary),
            ),
            title: const Text('My Posts & Saved Items',
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle:
                const Text('Manage your published feed posts and bookmarks'),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const UserEventsView()),
              );
            },
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              radius: 22,
              child: Icon(Icons.event_outlined,
                  color: theme.colorScheme.onSecondaryContainer),
            ),
            title: const Text('Registered Events & Tickets',
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text(
                'View upcoming college and club event registrations'),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      ],
    );
  }
}

class _MyProposedClubsSection extends ConsumerWidget {
  const _MyProposedClubsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final myClubsAsync = ref.watch(myProposedClubsProvider);
    final approvedClubsAsync = ref.watch(approvedClubsProvider);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.groups,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'My Clubs & Communities',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 19),
                tooltip: 'Refresh Clubs',
                onPressed: () {
                  ref.invalidate(myProposedClubsProvider);
                  ref.invalidate(approvedClubsProvider);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. Proposed Clubs by User
          myClubsAsync.when(
            data: (clubs) {
              if (clubs.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Proposed by You',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary)),
                  const SizedBox(height: 8),
                  ...clubs.map((club) {
                    Color statusColor = Colors.orange;
                    IconData statusIcon = Icons.access_time;
                    String statusLabel = 'PENDING APPROVAL';

                    if (club.status == 'APPROVED') {
                      statusColor = Colors.green;
                      statusIcon = Icons.check_circle_outline;
                      statusLabel = 'APPROVED & ACTIVE';
                    } else if (club.status == 'REJECTED') {
                      statusColor = Colors.red;
                      statusIcon = Icons.cancel_outlined;
                      statusLabel = 'REJECTED';
                    }

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => context.push('/clubs/${club.id}'),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            club.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(Icons.arrow_forward_ios,
                                            size: 13,
                                            color: theme.colorScheme.primary),
                                        const SizedBox(width: 8),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color:
                                          statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: statusColor.withValues(
                                              alpha: 0.4)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(statusIcon,
                                            size: 12, color: statusColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          statusLabel,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('Category: ${club.category}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.outline)),
                              if (club.description != null &&
                                  club.description!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(club.description!,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: theme
                                            .colorScheme.onSurfaceVariant)),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                    ),
                                    icon:
                                        const Icon(Icons.open_in_new, size: 15),
                                    label: Text(
                                        club.status == 'APPROVED'
                                            ? 'View Club Page'
                                            : 'Preview Proposal',
                                        style: const TextStyle(fontSize: 12)),
                                    onPressed: () =>
                                        context.push('/clubs/${club.id}'),
                                  ),
                                  if (club.status == 'PENDING' ||
                                      club.status == 'REJECTED')
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                        side: const BorderSide(
                                            color: Colors.redAccent),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      icon: const Icon(Icons.delete_outline,
                                          size: 15),
                                      label: const Text('Withdraw Proposal',
                                          style: TextStyle(fontSize: 12)),
                                      onPressed: () async {
                                        final confirmed =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16)),
                                            title: const Text(
                                                'Withdraw Club Request'),
                                            content: Text(
                                                'Are you sure you want to cancel and withdraw your request for "${club.name}"?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child: const Text('Cancel'),
                                              ),
                                              FilledButton(
                                                style: FilledButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.red),
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child: const Text('Withdraw'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmed == true) {
                                          try {
                                            final repo = ref
                                                .read(clubsRepositoryProvider);
                                            await repo.deleteClub(club.id);
                                            ref.invalidate(
                                                myProposedClubsProvider);
                                            ref.invalidate(
                                                pendingClubsProvider);

                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Club proposal for "${club.name}" has been withdrawn.'),
                                                  backgroundColor:
                                                      Colors.orange,
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Failed to withdraw request: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // 2. Active Campus Clubs
          approvedClubsAsync.when(
            data: (allClubs) {
              if (allClubs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Explore student communities in the Clubs tab!',
                    style: TextStyle(
                        fontSize: 13, color: theme.colorScheme.outline),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('Active Clubs & Communities',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary)),
                  const SizedBox(height: 8),
                  ...allClubs.take(4).map((club) {
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => context.push('/clubs/${club.id}'),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                child: Text(
                                  club.name.isNotEmpty
                                      ? club.name[0].toUpperCase()
                                      : 'C',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(club.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                    Text(
                                        '${club.category} • ${club.memberCount} members',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: theme.colorScheme.outline)),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios,
                                  size: 14, color: theme.colorScheme.primary),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
            loading: () => const Center(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator())),
            error: (err, _) => Text('Could not load clubs',
                style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color color;

  _SliverTabBarDelegate(this._tabBar, {required this.color});

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: color,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return true;
  }
}

void _showEditProfileDialog(
    BuildContext context, WidgetRef ref, UserProfile profile) {
  final bioCtrl = TextEditingController(text: profile.bio);
  final githubCtrl = TextEditingController(text: profile.githubUrl);
  final linkedinCtrl = TextEditingController(text: profile.linkedinUrl);
  final websiteCtrl = TextEditingController(text: profile.websiteUrl);

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Edit Profile Details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(controller: bioCtrl, label: 'Bio / About You'),
            const SizedBox(height: 12),
            CustomTextField(
                controller: githubCtrl, label: 'GitHub Profile URL'),
            const SizedBox(height: 12),
            CustomTextField(
                controller: linkedinCtrl, label: 'LinkedIn Profile URL'),
            const SizedBox(height: 12),
            CustomTextField(
                controller: websiteCtrl,
                label: 'Personal Website / Portfolio URL'),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            ref.read(profileControllerProvider.notifier).updateProfile(
                  bio: bioCtrl.text.trim(),
                  githubUrl: githubCtrl.text.trim(),
                  linkedinUrl: linkedinCtrl.text.trim(),
                  websiteUrl: websiteCtrl.text.trim(),
                );
            Navigator.pop(ctx);
          },
          child: const Text('Save Changes'),
        ),
      ],
    ),
  );
}

void _showAddSkillDialog(BuildContext context, WidgetRef ref) {
  final skillCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Add New Skill'),
      content: CustomTextField(
          controller: skillCtrl,
          label: 'Skill Name (e.g. Flutter, React, Python)'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (skillCtrl.text.trim().isNotEmpty) {
              ref
                  .read(profileControllerProvider.notifier)
                  .addSkill(skillCtrl.text.trim(), 'ADVANCED');
              Navigator.pop(ctx);
            }
          },
          child: const Text('Add Skill'),
        ),
      ],
    ),
  );
}

void _showAddProjectDialog(BuildContext context, WidgetRef ref) {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final projectUrlCtrl = TextEditingController();
  final repoUrlCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Add Portfolio Project'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(controller: titleCtrl, label: 'Project Title *'),
            const SizedBox(height: 12),
            CustomTextField(controller: descCtrl, label: 'Project Description'),
            const SizedBox(height: 12),
            CustomTextField(
                controller: repoUrlCtrl, label: 'GitHub / Repo URL'),
            const SizedBox(height: 12),
            CustomTextField(
                controller: projectUrlCtrl, label: 'Live Demo / Website URL'),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (titleCtrl.text.trim().isNotEmpty) {
              ref.read(profileControllerProvider.notifier).addProject(
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim().isNotEmpty
                        ? descCtrl.text.trim()
                        : null,
                    projectUrl: projectUrlCtrl.text.trim().isNotEmpty
                        ? projectUrlCtrl.text.trim()
                        : null,
                    repoUrl: repoUrlCtrl.text.trim().isNotEmpty
                        ? repoUrlCtrl.text.trim()
                        : null,
                  );
              Navigator.pop(ctx);
            }
          },
          child: const Text('Add Project'),
        ),
      ],
    ),
  );
}
