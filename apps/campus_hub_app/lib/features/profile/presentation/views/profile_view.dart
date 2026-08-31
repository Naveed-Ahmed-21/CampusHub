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
import '../../../../shared/widgets/full_screen_image_viewer.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Profile',
            onPressed: () {
              ref.read(profileControllerProvider.notifier).refreshProfile();
              ref.invalidate(myProposedClubsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to sign out of CampusHub?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
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
    );
  }
}

class _ProfileMobileLayout extends ConsumerStatefulWidget {
  final UserProfile profile;
  const _ProfileMobileLayout({required this.profile});

  @override
  ConsumerState<_ProfileMobileLayout> createState() => _ProfileMobileLayoutState();
}

class _ProfileMobileLayoutState extends ConsumerState<_ProfileMobileLayout>
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
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(icon: Icon(Icons.person_outline, size: 20), text: 'Overview'),
                  Tab(icon: Icon(Icons.groups_outlined, size: 20), text: 'My Clubs'),
                  Tab(icon: Icon(Icons.bookmark_outline, size: 20), text: 'Activity'),
                ],
              ),
              color: theme.scaffoldBackgroundColor,
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Overview (Bio, Skills, Projects, Socials, Resume)
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              _BioSection(profile: profile),
              const SizedBox(height: 16),
              _SkillsSection(profile: profile),
              const SizedBox(height: 16),
              _ProjectsSection(profile: profile),
              const SizedBox(height: 16),
              _SocialLinksSection(profile: profile),
              const SizedBox(height: 16),
              _ResumeSection(profile: profile),
              const SizedBox(height: 32),
            ],
          ),

          // Tab 2: My Clubs
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: const [
              _MyProposedClubsSection(),
              SizedBox(height: 32),
            ],
          ),

          // Tab 3: Activity & Saved
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: const [
              _QuickActivityStatsSection(),
              SizedBox(height: 32),
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
  ConsumerState<_ProfileDesktopLayout> createState() => _ProfileDesktopLayoutState();
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

    Future<void> pickAndUploadAvatar() async {
      final file = await MediaPickerService.showMediaPickerSheet(
        context,
        title: 'Update Profile Picture',
        enableCamera: true,
        enableGallery: true,
        enableVideoCamera: false,
        enableVideoGallery: false,
        enableDocuments: false,
      );

      if (file != null && context.mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploading profile picture...')),
          );

          final uploadService = ref.read(mediaUploadServiceProvider);
          final result = await uploadService.uploadSelectedFile(file);

          await ref.read(profileControllerProvider.notifier).uploadAvatar(result.url);

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
              SnackBar(content: Text('Failed to update avatar: $e'), backgroundColor: Colors.red),
            );
          }
        }
      }
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
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        width: 3,
                      ),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
                          FullScreenImageViewer.openSingle(
                            context,
                            imageUrl: profile.avatarUrl!,
                            heroTag: 'profile_avatar_self_${profile.id}',
                            title: profile.fullName,
                            subtitle: profile.bio ?? profile.role,
                          );
                        }
                      },
                      child: Hero(
                        tag: 'profile_avatar_self_${profile.id}',
                        child: CircleAvatar(
                          radius: 42,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          backgroundImage: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                              ? NetworkImage(ApiEndpoints.resolveUrl(profile.avatarUrl!))
                              : null,
                          child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                              ? Text(
                                  profile.firstName.isNotEmpty ? profile.firstName[0].toUpperCase() : 'U',
                                  style: theme.textTheme.headlineLarge?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Material(
                      color: theme.colorScheme.primary,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: pickAndUploadAvatar,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.camera_alt,
                            size: 15,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // User Info details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.fullName,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
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
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Username chip
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: profile.displayUsername));
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
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.copy, size: 12, color: theme.colorScheme.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Email & Roll Number
                    Text(
                      profile.email,
                      style: TextStyle(fontSize: 12.5, color: theme.colorScheme.outline),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (profile.rollNumber != null && profile.rollNumber!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Roll No: ${profile.rollNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
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
                  onPressed: () => _showEditProfileDialog(context, ref, profile),
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Edit Profile'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => const PortfolioView()),
                    );
                  },
                  icon: const Icon(Icons.work_history_outlined, size: 17),
                  label: const Text('Portfolio'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
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
                MaterialPageRoute(builder: (ctx) => const UserPostsView(initialTabIndex: 0)),
              );
            },
          ),
          Container(width: 1, height: 28, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
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
          Container(width: 1, height: 28, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
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
          Container(width: 1, height: 28, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          _buildStatItem(
            context,
            label: 'Saved',
            value: 'Posts',
            icon: Icons.bookmark_border_rounded,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const UserPostsView(initialTabIndex: 1)),
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
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote_rounded, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'About & Bio',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 19),
                  const SizedBox(width: 8),
                  Text(
                    'Skills & Tech Stack',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
                  label: Text(skill.skillName, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => ref.read(profileControllerProvider.notifier).removeSkill(skill.id),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
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
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.code_rounded, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Featured Projects',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
              final hasDemo = proj.projectUrl != null && proj.projectUrl!.isNotEmpty;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
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
                          child: Icon(Icons.folder_outlined, color: theme.colorScheme.primary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                proj.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                              ),
                              if (proj.description != null && proj.description!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  proj.description!,
                                  style: TextStyle(fontSize: 12.5, color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                          tooltip: 'Remove Project',
                          onPressed: () => ref.read(profileControllerProvider.notifier).removeProject(proj.id),
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
                              label: const Text('Repository', style: TextStyle(fontSize: 11.5)),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: proj.repoUrl!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Repository link copied!'), duration: Duration(seconds: 1)),
                                );
                              },
                            ),
                          if (hasDemo)
                            ActionChip(
                              avatar: const Icon(Icons.open_in_new, size: 14),
                              label: const Text('Live Demo', style: TextStyle(fontSize: 11.5)),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: proj.projectUrl!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Demo link copied!'), duration: Duration(seconds: 1)),
                                );
                              },
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
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link_rounded, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Social & Web Links',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: hasUrl ? theme.colorScheme.primary : theme.colorScheme.outline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(
                  hasUrl ? url : 'Not connected',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasUrl ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.outline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (hasUrl)
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              tooltip: 'Copy Link',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$label link copied!'), duration: const Duration(seconds: 1)),
                );
              },
            ),
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
    final file = await MediaPickerService.showMediaPickerSheet(
      context,
      title: 'Select Resume (PDF / DOCX)',
      enableCamera: false,
      enableGallery: false,
      enableVideoCamera: false,
      enableVideoGallery: false,
      enableDocuments: true,
    );

    if (file != null && mounted) {
      setState(() => _isUploading = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading resume to your portfolio...')),
      );

      try {
        final uploadService = ref.read(mediaUploadServiceProvider);
        final result = await uploadService.uploadSelectedFile(file);

        await ref.read(profileControllerProvider.notifier).uploadResume(result.url);

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
            SnackBar(content: Text('Failed to upload resume: $e'), backgroundColor: Colors.red),
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
            const SnackBar(content: Text('Preparing resume document...'), duration: Duration(seconds: 1)),
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
          SnackBar(content: Text('Could not open resume: $e'), backgroundColor: Colors.red),
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
    final hasResume = profile.resumeUrl != null && profile.resumeUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.description_outlined, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Resume & CV',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
                child: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasResume ? '${profile.firstName}_Resume.pdf' : 'No Resume Uploaded',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    Text(
                      hasResume ? 'Uploaded to your Portfolio' : 'Add your CV for opportunities & recruiters',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
              if (hasResume)
                FilledButton.tonalIcon(
                  onPressed: _isOpening ? null : _viewResume,
                  icon: _isOpening
                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.open_in_new, size: 14),
                  label: const Text('View', style: TextStyle(fontSize: 12)),
                )
              else
                FilledButton.tonalIcon(
                  onPressed: _isUploading ? null : _pickAndUploadResume,
                  icon: _isUploading
                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.upload_file, size: 14),
                  label: const Text('Upload PDF', style: TextStyle(fontSize: 12)),
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
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
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
              child: Icon(Icons.article_outlined, color: theme.colorScheme.primary),
            ),
            title: const Text('My Posts & Saved Items', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Manage your published feed posts and bookmarks'),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
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
              child: Icon(Icons.event_outlined, color: theme.colorScheme.onSecondaryContainer),
            ),
            title: const Text('Registered Events & Tickets', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('View upcoming college and club event registrations'),
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
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.groups, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'My Clubs & Communities',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
                  Text('Proposed by You', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
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
                            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            club.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(Icons.arrow_forward_ios, size: 13, color: theme.colorScheme.primary),
                                        const SizedBox(width: 8),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(statusIcon, size: 12, color: statusColor),
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
                              Text('Category: ${club.category}', style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
                              if (club.description != null && club.description!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(club.description!, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                    ),
                                    icon: const Icon(Icons.open_in_new, size: 15),
                                    label: const Text('View Club Page', style: TextStyle(fontSize: 12)),
                                    onPressed: () => context.push('/clubs/${club.id}'),
                                  ),
                                  if (club.status == 'PENDING' || club.status == 'REJECTED')
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                        side: const BorderSide(color: Colors.redAccent),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      icon: const Icon(Icons.delete_outline, size: 15),
                                      label: const Text('Withdraw Proposal', style: TextStyle(fontSize: 12)),
                                      onPressed: () async {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            title: const Text('Withdraw Club Request'),
                                            content: Text('Are you sure you want to cancel and withdraw your request for "${club.name}"?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, false),
                                                child: const Text('Cancel'),
                                              ),
                                              FilledButton(
                                                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                                onPressed: () => Navigator.pop(ctx, true),
                                                child: const Text('Withdraw'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmed == true) {
                                          try {
                                            final repo = ref.read(clubsRepositoryProvider);
                                            await repo.deleteClub(club.id);
                                            ref.invalidate(myProposedClubsProvider);
                                            ref.invalidate(pendingClubsProvider);

                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Club proposal for "${club.name}" has been withdrawn.'),
                                                  backgroundColor: Colors.orange,
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Failed to withdraw request: $e'),
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
                    style: TextStyle(fontSize: 13, color: theme.colorScheme.outline),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('Active Clubs & Communities', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
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
                            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Text(
                                  club.name.isNotEmpty ? club.name[0].toUpperCase() : 'C',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(club.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text('${club.category} • ${club.memberCount} members', style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, size: 14, color: theme.colorScheme.primary),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
            error: (err, _) => Text('Could not load clubs', style: TextStyle(color: theme.colorScheme.error)),
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: color,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

void _showEditProfileDialog(BuildContext context, WidgetRef ref, UserProfile profile) {
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
            CustomTextField(controller: githubCtrl, label: 'GitHub Profile URL'),
            const SizedBox(height: 12),
            CustomTextField(controller: linkedinCtrl, label: 'LinkedIn Profile URL'),
            const SizedBox(height: 12),
            CustomTextField(controller: websiteCtrl, label: 'Personal Website / Portfolio URL'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
      content: CustomTextField(controller: skillCtrl, label: 'Skill Name (e.g. Flutter, React, Python)'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (skillCtrl.text.trim().isNotEmpty) {
              ref.read(profileControllerProvider.notifier).addSkill(skillCtrl.text.trim(), 'ADVANCED');
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
            CustomTextField(controller: repoUrlCtrl, label: 'GitHub / Repo URL'),
            const SizedBox(height: 12),
            CustomTextField(controller: projectUrlCtrl, label: 'Live Demo / Website URL'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (titleCtrl.text.trim().isNotEmpty) {
              ref.read(profileControllerProvider.notifier).addProject(
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                    projectUrl: projectUrlCtrl.text.trim().isNotEmpty ? projectUrlCtrl.text.trim() : null,
                    repoUrl: repoUrlCtrl.text.trim().isNotEmpty ? repoUrlCtrl.text.trim() : null,
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
