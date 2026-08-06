import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/responsive/responsive_layout.dart';
import '../../../../shared/widgets/async_value_widget.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../../domain/models/user_profile.dart';
import '../../../portfolio/presentation/views/portfolio_view.dart';

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
            onPressed: () => ref.read(profileControllerProvider.notifier).refreshProfile(),
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
        const SizedBox(height: 24),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
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
                    flex: 2,
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
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Social & Web Links', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
