import 'package:campus_hub_app/features/faculty/domain/models/faculty_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/media_picker_service.dart';
import '../../../../core/services/media_upload_service.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../shared/responsive/responsive_layout.dart';
import '../../../../shared/widgets/async_value_widget.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/full_screen_image_viewer.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../controllers/faculty_controller.dart';
// import '../domain/models/faculty_models.dart';
import '../widgets/add_subject_dialog.dart';
import '../widgets/faculty_drawer_widget.dart';

class FacultyProfileView extends ConsumerWidget {
  const FacultyProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(facultyProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const FacultyDrawerWidget(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('Faculty Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Profile',
            onPressed: () {
              ref.invalidate(facultyProfileProvider);
              ref.invalidate(facultyDashboardProvider);
              ref.invalidate(facultySubjectsProvider);
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
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      body: AsyncValueWidget<FacultyProfileModel>(
        value: profileAsync,
        data: (profile) => ResponsiveLayout(
          mobile: _FacultyProfileMobileLayout(profile: profile),
          desktop: _FacultyProfileDesktopLayout(profile: profile),
        ),
      ),
    );
  }

  static Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to sign out of CampusHub Faculty Portal?'),
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
    if (confirm == true && context.mounted) {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }
}

class _FacultyProfileMobileLayout extends StatefulWidget {
  final FacultyProfileModel profile;
  const _FacultyProfileMobileLayout({required this.profile});

  @override
  State<_FacultyProfileMobileLayout> createState() => _FacultyProfileMobileLayoutState();
}

class _FacultyProfileMobileLayoutState extends State<_FacultyProfileMobileLayout>
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
                  _FacultyHeroCard(profile: profile),
                  const SizedBox(height: 14),
                  _FacultyStatsBar(profile: profile),
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
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                tabs: const [
                  Tab(icon: Icon(Icons.person_outline, size: 20), text: 'Overview'),
                  Tab(icon: Icon(Icons.menu_book_outlined, size: 20), text: 'Courses & Notes'),
                  Tab(icon: Icon(Icons.article_outlined, size: 20), text: 'Research & Activity'),
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
          // Tab 1: Overview (Bio, Specialization, Office Hours, Socials)
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              _BioSection(profile: profile),
              const SizedBox(height: 16),
              _SpecializationSection(profile: profile),
              const SizedBox(height: 16),
              _OfficeHoursSection(profile: profile),
              const SizedBox(height: 16),
              _SocialLinksSection(profile: profile),
              const SizedBox(height: 32),
            ],
          ),

          // Tab 2: Courses & Notes
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              _CoursesSection(profile: profile),
              const SizedBox(height: 32),
            ],
          ),

          // Tab 3: Research & Settings
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              _PublicationsSection(profile: profile),
              const SizedBox(height: 16),
              const _QuickSettingsSection(),
              const SizedBox(height: 32),
            ],
          ),
        ],
      ),
    );
  }
}

class _FacultyProfileDesktopLayout extends StatelessWidget {
  final FacultyProfileModel profile;
  const _FacultyProfileDesktopLayout({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1080),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _FacultyHeroCard(profile: profile),
              const SizedBox(height: 20),
              _FacultyStatsBar(profile: profile),
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
                        _SpecializationSection(profile: profile),
                        const SizedBox(height: 16),
                        _OfficeHoursSection(profile: profile),
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
                        _CoursesSection(profile: profile),
                        const SizedBox(height: 16),
                        _PublicationsSection(profile: profile),
                        const SizedBox(height: 16),
                        const _QuickSettingsSection(),
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

class _FacultyHeroCard extends ConsumerWidget {
  final FacultyProfileModel profile;
  const _FacultyHeroCard({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Future<void> pickAndUploadAvatar() async {
      final file = await MediaPickerService.showMediaPickerSheet(
        context,
        title: 'Update Faculty Avatar',
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
          await ref.read(facultyControllerProvider.notifier).updateProfile({'avatarUrl': result.url});

          ref.invalidate(facultyProfileProvider);
          ref.invalidate(facultyDashboardProvider);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Faculty profile picture updated successfully!'),
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
                            heroTag: 'faculty_avatar_${profile.id}',
                            title: profile.name,
                            subtitle: '${profile.designation} • ${profile.department}',
                          );
                        }
                      },
                      child: Hero(
                        tag: 'faculty_avatar_${profile.id}',
                        child: CircleAvatar(
                          radius: 42,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          backgroundImage: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                              ? NetworkImage(ApiEndpoints.resolveUrl(profile.avatarUrl!))
                              : null,
                          child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                              ? Text(
                                  profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'F',
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

              // Faculty Info details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.name,
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
                            'FACULTY',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Designation & Department
                    Text(
                      profile.designation,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.department,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Copyable Email
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: profile.email));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email copied to clipboard!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                profile.email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.outline,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.copy, size: 11, color: theme.colorScheme.outline),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons: Edit Profile & Teaching Hub
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _showEditFacultyProfileDialog(context, ref, profile),
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
                  onPressed: () => context.go('/teaching'),
                  icon: const Icon(Icons.school_outlined, size: 17),
                  label: const Text('Teaching Hub'),
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

class _FacultyStatsBar extends StatelessWidget {
  final FacultyProfileModel profile;
  const _FacultyStatsBar({required this.profile});

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
            label: 'Subjects',
            value: '${profile.subjectsCount}',
            icon: Icons.book_outlined,
            onTap: () => context.go('/teaching'),
          ),
          Container(width: 1, height: 28, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          _buildStatItem(
            context,
            label: 'Mentees',
            value: '${profile.menteesCount}',
            icon: Icons.people_outline,
            onTap: () => context.go('/faculty'),
          ),
          Container(width: 1, height: 28, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          _buildStatItem(
            context,
            label: 'Classes Today',
            value: '${profile.subjectsCount > 0 ? (profile.subjectsCount > 3 ? 3 : profile.subjectsCount) : 0}',
            icon: Icons.schedule_outlined,
            onTap: () => context.go('/teaching'),
          ),
          Container(width: 1, height: 28, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          _buildStatItem(
            context,
            label: 'Publications',
            value: '${profile.publications.length}',
            icon: Icons.article_outlined,
            onTap: () {},
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                fontSize: 11,
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
  final FacultyProfileModel profile;
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
                'About & Academic Bio',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            profile.bio.isNotEmpty
                ? profile.bio
                : 'No bio provided yet. Tap "Edit Profile" above to add your academic background, experience, and research vision.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: profile.bio.isNotEmpty ? theme.colorScheme.onSurface : theme.colorScheme.outline,
            ),
          ),
          if (profile.qualification.isNotEmpty) ...[
            const Divider(height: 20),
            Row(
              children: [
                Icon(Icons.school_outlined, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Qualifications: ',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
                Expanded(
                  child: Text(
                    profile.qualification,
                    style: TextStyle(fontSize: 12.5, color: theme.colorScheme.outline),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SpecializationSection extends StatelessWidget {
  final FacultyProfileModel profile;
  const _SpecializationSection({required this.profile});

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
              Icon(Icons.psychology_outlined, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Areas of Interest & Specialization',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (profile.specialization.isNotEmpty)
            Text(
              profile.specialization,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
            ),
          const SizedBox(height: 10),
          if (profile.expertise.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.expertise.map((exp) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    exp,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                );
              }).toList(),
            )
          else
            Text(
              'No expertise tags added yet. Tap "Edit Profile" to list your specializations.',
              style: TextStyle(fontSize: 12.5, color: theme.colorScheme.outline),
            ),
        ],
      ),
    );
  }
}

class _OfficeHoursSection extends StatelessWidget {
  final FacultyProfileModel profile;
  const _OfficeHoursSection({required this.profile});

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
              Icon(Icons.access_time_filled_outlined, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Office & Consultation Hours',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.meeting_room_outlined,
            title: 'Cabin / Office',
            value: profile.officeRoom.isNotEmpty ? profile.officeRoom : 'Faculty Block B, Cabin 304',
            theme: theme,
          ),
          const Divider(height: 18),
          _buildInfoRow(
            icon: Icons.schedule_outlined,
            title: 'Available Hours',
            value: profile.officeHours.isNotEmpty ? profile.officeHours : 'Mon - Thu: 2:00 PM - 4:00 PM',
            theme: theme,
          ),
          const Divider(height: 18),
          _buildInfoRow(
            icon: Icons.alternate_email_outlined,
            title: 'Direct Academic Email',
            value: profile.email,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 11.5, color: theme.colorScheme.outline)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CoursesSection extends ConsumerWidget {
  final FacultyProfileModel profile;
  const _CoursesSection({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subjectsAsync = ref.watch(facultySubjectsProvider);

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
                  Icon(Icons.menu_book_outlined, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Active Courses & Subjects',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                tooltip: 'Add Subject',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const AddSubjectDialog(),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          subjectsAsync.when(
            data: (subjects) {
              if (subjects.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      children: [
                        Icon(Icons.library_books_outlined, size: 36, color: theme.colorScheme.outline),
                        const SizedBox(height: 8),
                        const Text(
                          'No courses registered yet.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => const AddSubjectDialog(),
                            );
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Subject'),
                          style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: subjects.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final s = subjects[index];
                  return Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      onTap: () => context.push('/teaching/subjects/${s.id}'),
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              s.code,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '${s.semester} • Section ${s.section} • ${s.credits} Credits • ${s.resourcesCount} Notes',
                          style: TextStyle(fontSize: 11.5, color: theme.colorScheme.outline),
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => const Text(
              'Unable to load subjects at this time.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicationsSection extends StatelessWidget {
  final FacultyProfileModel profile;
  const _PublicationsSection({required this.profile});

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
              Icon(Icons.article_outlined, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Publications & Research Works',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (profile.publications.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'No publications recorded yet. Use "Edit Profile" to add research papers or patents.',
                style: TextStyle(fontSize: 12.5, color: theme.colorScheme.outline),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: profile.publications.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final pub = profile.publications[index];
                final title = pub['title'] as String? ?? 'Research Publication';
                final venue = pub['venue'] as String? ?? 'Conference / Journal';
                final link = pub['link'] as String?;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.menu_book, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            venue,
                            style: TextStyle(color: theme.colorScheme.outline, fontSize: 11.5),
                          ),
                          if (link != null && link.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () => UrlLauncherService.openUrl(context, link),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View Publication',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.open_in_new, size: 11, color: theme.colorScheme.primary),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SocialLinksSection extends StatelessWidget {
  final FacultyProfileModel profile;
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
                'Professional & Social Profiles',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF0077B5),
              child: Icon(Icons.link, size: 16, color: Colors.white),
            ),
            title: const Text('LinkedIn Profile', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
            subtitle: Text(
              profile.linkedinUrl != null && profile.linkedinUrl!.isNotEmpty
                  ? profile.linkedinUrl!
                  : 'linkedin.com/in/faculty-profile',
              style: const TextStyle(fontSize: 11.5),
            ),
            trailing: const Icon(Icons.open_in_new, size: 15),
            onTap: () => UrlLauncherService.openUrl(
              context,
              profile.linkedinUrl != null && profile.linkedinUrl!.isNotEmpty
                  ? profile.linkedinUrl!
                  : 'https://linkedin.com',
            ),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blueGrey,
              child: Icon(Icons.school, size: 16, color: Colors.white),
            ),
            title: const Text('Google Scholar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
            subtitle: Text(
              profile.googleScholar != null && profile.googleScholar!.isNotEmpty
                  ? profile.googleScholar!
                  : 'scholar.google.com/citations',
              style: const TextStyle(fontSize: 11.5),
            ),
            trailing: const Icon(Icons.open_in_new, size: 15),
            onTap: () => UrlLauncherService.openUrl(
              context,
              profile.googleScholar != null && profile.googleScholar!.isNotEmpty
                  ? profile.googleScholar!
                  : 'https://scholar.google.com',
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickSettingsSection extends ConsumerWidget {
  const _QuickSettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = ref.watch(themeNotifierProvider) == ThemeMode.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
            subtitle: Text(isDark ? 'Dark Theme' : 'Light Theme', style: const TextStyle(fontSize: 11.5)),
            trailing: Switch(
              value: isDark,
              onChanged: (val) {
                ref.read(themeNotifierProvider.notifier).toggleTheme(val);
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('App Settings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
            subtitle: const Text('Account, notifications & security', style: TextStyle(fontSize: 11.5)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => context.push('/settings'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13.5)),
            onTap: () => FacultyProfileView._confirmLogout(context, ref),
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

void _showEditFacultyProfileDialog(
  BuildContext context,
  WidgetRef ref,
  FacultyProfileModel profile,
) {
  final designationCtrl = TextEditingController(text: profile.designation);
  final departmentCtrl = TextEditingController(text: profile.department);
  final qualificationCtrl = TextEditingController(text: profile.qualification);
  final specializationCtrl = TextEditingController(text: profile.specialization);
  final officeRoomCtrl = TextEditingController(text: profile.officeRoom);
  final officeHoursCtrl = TextEditingController(text: profile.officeHours);
  final bioCtrl = TextEditingController(text: profile.bio);
  final linkedinCtrl = TextEditingController(text: profile.linkedinUrl ?? '');
  final googleScholarCtrl = TextEditingController(text: profile.googleScholar ?? '');

  bool isSaving = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        final theme = Theme.of(ctx);

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.88,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 16,
            left: 20,
            right: 20,
          ),
          child: Column(
            children: [
              // Header Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Faculty Profile',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: designationCtrl,
                        label: 'Academic Designation',
                        hintText: 'e.g. Associate Professor & Coordinator',
                        prefixIcon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: departmentCtrl,
                        label: 'Department',
                        hintText: 'e.g. Computer Science & Engineering',
                        prefixIcon: Icons.apartment_outlined,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: qualificationCtrl,
                        label: 'Qualifications',
                        hintText: 'e.g. Ph.D. in Computer Science, M.Tech',
                        prefixIcon: Icons.school_outlined,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: specializationCtrl,
                        label: 'Specialization & Research Focus',
                        hintText: 'e.g. Distributed Systems & Cloud Computing',
                        prefixIcon: Icons.psychology_outlined,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: officeRoomCtrl,
                        label: 'Office / Cabin Location',
                        hintText: 'e.g. Room 304, Tech Block B',
                        prefixIcon: Icons.meeting_room_outlined,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: officeHoursCtrl,
                        label: 'Office Consultation Hours',
                        hintText: 'e.g. Mon - Thu: 2:00 PM - 4:00 PM',
                        prefixIcon: Icons.schedule_outlined,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: bioCtrl,
                        label: 'Faculty Bio',
                        hintText: 'Write a brief summary of your teaching journey and academic interests...',
                        maxLines: 4,
                        prefixIcon: Icons.description_outlined,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: linkedinCtrl,
                        label: 'LinkedIn Profile URL',
                        hintText: 'https://linkedin.com/in/...',
                        prefixIcon: Icons.link,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: googleScholarCtrl,
                        label: 'Google Scholar Profile URL',
                        hintText: 'https://scholar.google.com/citations?...',
                        prefixIcon: Icons.menu_book,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setModalState(() => isSaving = true);
                          final payload = {
                            'designation': designationCtrl.text.trim(),
                            'departmentName': departmentCtrl.text.trim(),
                            'qualification': qualificationCtrl.text.trim(),
                            'specialization': specializationCtrl.text.trim(),
                            'officeRoom': officeRoomCtrl.text.trim(),
                            'officeHours': officeHoursCtrl.text.trim(),
                            'bio': bioCtrl.text.trim(),
                            if (linkedinCtrl.text.trim().isNotEmpty) 'linkedinUrl': linkedinCtrl.text.trim(),
                            if (googleScholarCtrl.text.trim().isNotEmpty) 'googleScholar': googleScholarCtrl.text.trim(),
                          };

                          final success = await ref
                              .read(facultyControllerProvider.notifier)
                              .updateProfile(payload);

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success ? 'Profile updated successfully!' : 'Failed to update profile',
                                ),
                                backgroundColor: success ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Profile Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
