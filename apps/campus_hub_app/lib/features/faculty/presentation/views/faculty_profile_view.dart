import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../shared/responsive/responsive_layout.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/faculty_controller.dart';

class FacultyProfileView extends ConsumerWidget {
  const FacultyProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).asData?.value;
    final dashboardAsync = ref.watch(facultyDashboardProvider);
    final subjectsAsync = ref.watch(facultySubjectsProvider);
    final isDark = ref.watch(themeNotifierProvider) == ThemeMode.dark;

    final faculty = dashboardAsync.asData?.value.faculty;
    final name = faculty?.name ?? '${user?.firstName ?? "Dr."} ${user?.lastName ?? "Faculty"}';
    final email = faculty?.email ?? user?.email ?? 'faculty@campushub.edu';
    final designation = faculty?.designation ?? 'Associate Professor & Academic Head';
    final department = faculty?.department ?? 'Department of Computer Science & Engineering';

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Faculty Profile Header
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: faculty?.avatarUrl != null && faculty!.avatarUrl!.isNotEmpty
                        ? NetworkImage(ApiEndpoints.resolveUrl(faculty.avatarUrl!))
                        : null,
                    onBackgroundImageError: faculty?.avatarUrl != null && faculty!.avatarUrl!.isNotEmpty
                        ? (_, __) {}
                        : null,
                    child: faculty?.avatarUrl == null || faculty!.avatarUrl!.isEmpty
                        ? Icon(Icons.school, size: 44, color: theme.colorScheme.onPrimaryContainer)
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    designation,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    department,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick Action Buttons (Edit Profile, Settings)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => context.push('/settings'),
                        icon: const Icon(Icons.settings_outlined, size: 16),
                        label: const Text('Settings'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.tonalIcon(
                        onPressed: () => context.go('/teaching'),
                        icon: const Icon(Icons.menu_book, size: 16),
                        label: const Text('Teaching Hub'),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Handled Subjects Section
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subjects & Courses',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        onPressed: () => context.go('/teaching'),
                        tooltip: 'View All Subjects',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  subjectsAsync.when(
                    data: (subjects) {
                      if (subjects.isEmpty) {
                        return const Text(
                          'No subjects registered yet.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        );
                      }
                      return Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: subjects.map((s) {
                          return ActionChip(
                            avatar: const Icon(Icons.book, size: 14),
                            label: Text('${s.code} - ${s.name}', style: const TextStyle(fontSize: 12)),
                            onPressed: () => context.push('/teaching/subjects/${s.id}'),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())),
                    error: (_, __) => const Text('Subjects unavailable', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Academic Qualifications, Bio & Research
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Academic & Research Background',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildDetailRow(
                    icon: Icons.history_edu,
                    title: 'Qualifications',
                    detail: 'Ph.D. in Computer Science (Distributed Systems), M.Tech (CSE)',
                  ),
                  const Divider(height: 20),
                  _buildDetailRow(
                    icon: Icons.biotech_outlined,
                    title: 'Areas of Interest & Research',
                    detail: 'Distributed Consensus, Cloud Architecture, Graph Algorithms, and Edge Computing',
                  ),
                  const Divider(height: 20),
                  _buildDetailRow(
                    icon: Icons.article_outlined,
                    title: 'Publications & Patents',
                    detail: '14 International Journal & IEEE Conference Papers',
                  ),
                  const Divider(height: 20),
                  _buildDetailRow(
                    icon: Icons.access_time,
                    title: 'Office Hours',
                    detail: 'Mon & Wed: 03:00 PM – 05:00 PM (Faculty Cabin B-302)',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Social & Web Links
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Social & Professional Links',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black12,
                      child: Icon(Icons.code, size: 16, color: Colors.black87),
                    ),
                    title: const Text('GitHub Profile', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('github.com/faculty-research', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.open_in_new, size: 16),
                    onTap: () => UrlLauncherService.openUrl(context, 'https://github.com'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFF0077B5),
                      child: Icon(Icons.link, size: 16, color: Colors.white),
                    ),
                    title: const Text('LinkedIn Profile', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('linkedin.com/in/faculty-profile', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.open_in_new, size: 16),
                    onTap: () => UrlLauncherService.openUrl(context, 'https://linkedin.com'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Settings & Preferences
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Theme Mode'),
                  subtitle: Text(isDark ? 'Dark Theme' : 'Light Theme'),
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
                  title: const Text('App Settings'),
                  subtitle: const Text('Preferences, Security & Notifications'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => context.push('/settings'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    await ref.read(authControllerProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Faculty Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ResponsiveLayout(
        mobile: content,
        desktop: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String detail,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 12),
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
                detail,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
