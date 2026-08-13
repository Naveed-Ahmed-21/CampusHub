import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(profileControllerProvider.notifier).refreshProfile();
              ref.invalidate(myProposedClubsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
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

class _ProfileMobileLayout extends ConsumerWidget {
  final UserProfile profile;
  const _ProfileMobileLayout({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ProfileHeader(profile: profile),
        const SizedBox(height: 16),
        const _QuickActivityStatsSection(),
        const SizedBox(height: 16),
        const _MyProposedClubsSection(),
        const SizedBox(height: 16),
        _BioSection(profile: profile),
        const SizedBox(height: 16),
        _SocialLinksSection(profile: profile),
        const SizedBox(height: 16),
        _SkillsSection(profile: profile),
        const SizedBox(height: 16),
        _ProjectsSection(profile: profile),
        const SizedBox(height: 16),
        _ResumeSection(profile: profile),
      ],
    );
  }
}

class _ProfileDesktopLayout extends ConsumerWidget {
  final UserProfile profile;
  const _ProfileDesktopLayout({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 960),
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _ProfileHeader(profile: profile),
              const SizedBox(height: 24),
              const _QuickActivityStatsSection(),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        const _MyProposedClubsSection(),
                        const SizedBox(height: 16),
                        _BioSection(profile: profile),
                        const SizedBox(height: 16),
                        _SocialLinksSection(profile: profile),
                        const SizedBox(height: 16),
                        _ResumeSection(profile: profile),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _SkillsSection(profile: profile),
                        const SizedBox(height: 16),
                        _ProjectsSection(profile: profile),
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

class _QuickActivityStatsSection extends StatelessWidget {
  const _QuickActivityStatsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 2,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const UserPostsView()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(Icons.article_outlined, color: theme.colorScheme.onPrimaryContainer),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Posts', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text('View all created posts', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            elevation: 2,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const UserEventsView()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      child: Icon(Icons.event_outlined, color: theme.colorScheme.onSecondaryContainer),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Events', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text('Tickets & registrations', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.groups, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Your Proposed Clubs',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () => ref.invalidate(myProposedClubsProvider),
                ),
              ],
            ),
            const SizedBox(height: 12),
            myClubsAsync.when(
              data: (clubs) {
                if (clubs.isEmpty) {
                  return Text(
                    'You haven\'t proposed any clubs yet. Go to Clubs tab to propose a new club!',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                  );
                }

                return Column(
                  children: clubs.map((club) {
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

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: theme.colorScheme.surfaceContainerLow,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    club.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(statusIcon, size: 14, color: statusColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        statusLabel,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Category: ${club.category}', style: theme.textTheme.bodySmall),
                            if (club.description != null) ...[
                              const SizedBox(height: 6),
                              Text(club.description!, style: theme.textTheme.bodyMedium),
                            ],
                            if (club.status == 'PENDING' || club.status == 'REJECTED') ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: const Icon(Icons.delete_outline, size: 16),
                                  label: const Text('Withdraw Request'),
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
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
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
              error: (err, _) => Text('Could not load proposed clubs', style: TextStyle(color: theme.colorScheme.error)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  final UserProfile profile;
  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
                  child: profile.avatarUrl == null
                      ? Text(
                          profile.firstName[0],
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile image uploaded successfully.')),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${profile.firstName} ${profile.lastName}',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    profile.email,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                  ),
                  if (profile.rollNumber != null) ...[
                    const SizedBox(height: 4),
                    Chip(
                      label: Text('Roll No: ${profile.rollNumber}'),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => const PortfolioView()),
                      );
                    },
                    icon: const Icon(Icons.work_history),
                    label: const Text('Digital Portfolio'),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showEditProfileDialog(context, ref, profile),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About & Bio', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              profile.bio ?? 'No bio provided yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: profile.bio == null ? theme.colorScheme.outline : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialLinksSection extends StatelessWidget {
  final UserProfile profile;
  const _SocialLinksSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Social & Web Links', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('GitHub'),
              subtitle: Text(profile.githubUrl ?? 'Not linked'),
              dense: true,
            ),
            ListTile(
              leading: const Icon(Icons.work_outline),
              title: const Text('LinkedIn'),
              subtitle: Text(profile.linkedinUrl ?? 'Not linked'),
              dense: true,
            ),
          ],
        ),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Skills & Expertise', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _showAddSkillDialog(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (profile.skills.isEmpty)
              Text('No skills added yet.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.skills.map((skill) {
                  return InputChip(
                    label: Text(skill.skillName),
                    onDeleted: () => ref.read(profileControllerProvider.notifier).removeSkill(skill.id),
                  );
                }).toList(),
              ),
          ],
        ),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Portfolio Projects', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _showAddProjectDialog(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (profile.projects.isEmpty)
              Text('No portfolio projects added.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline))
            else
              ...profile.projects.map((proj) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: theme.colorScheme.surfaceContainerLow,
                  child: ListTile(
                    title: Text(proj.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(proj.description ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => ref.read(profileControllerProvider.notifier).removeProject(proj.id),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ResumeSection extends StatelessWidget {
  final UserProfile profile;
  const _ResumeSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resume & CV', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.red, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alex_Vance_CV.pdf', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        profile.resumeUrl != null ? 'Uploaded' : 'No resume uploaded',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Resume uploaded successfully.')),
                    );
                  },
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Upload'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _showEditProfileDialog(BuildContext context, WidgetRef ref, UserProfile profile) {
  final bioCtrl = TextEditingController(text: profile.bio);
  final githubCtrl = TextEditingController(text: profile.githubUrl);
  final linkedinCtrl = TextEditingController(text: profile.linkedinUrl);

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Edit Profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(controller: bioCtrl, label: 'Bio'),
            const SizedBox(height: 12),
            CustomTextField(controller: githubCtrl, label: 'GitHub URL'),
            const SizedBox(height: 12),
            CustomTextField(controller: linkedinCtrl, label: 'LinkedIn URL'),
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
                );
            Navigator.pop(ctx);
          },
          child: const Text('Save'),
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
      title: const Text('Add Skill'),
      content: CustomTextField(controller: skillCtrl, label: 'Skill Name (e.g. Flutter, Node.js)'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (skillCtrl.text.trim().isNotEmpty) {
              ref.read(profileControllerProvider.notifier).addSkill(skillCtrl.text.trim(), 'ADVANCED');
              Navigator.pop(ctx);
            }
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}

void _showAddProjectDialog(BuildContext context, WidgetRef ref) {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Add Portfolio Project'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(controller: titleCtrl, label: 'Project Title'),
            const SizedBox(height: 12),
            CustomTextField(controller: descCtrl, label: 'Description'),
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
                    description: descCtrl.text.trim(),
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
