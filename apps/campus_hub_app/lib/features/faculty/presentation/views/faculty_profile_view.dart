import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: faculty?.avatarUrl != null
                        ? NetworkImage(faculty!.avatarUrl!)
                        : null,
                    child: faculty?.avatarUrl == null
                        ? const Icon(Icons.school, size: 40, color: Colors.blue)
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
                      color: Colors.blue,
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
                  const SizedBox(height: 8),
                  Text(
                    email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Academic Qualifications & Research
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    icon: Icons.science_outlined,
                    title: 'Research Interests',
                    detail: 'Distributed Consensus, Cloud Architecture, Graph Algorithms, and Edge Computing',
                  ),
                  const Divider(height: 20),
                  _buildDetailRow(
                    icon: Icons.article_outlined,
                    title: 'Publications',
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

          // Settings & Preferences
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  leading: const Icon(Icons.security),
                  title: const Text('Account Security'),
                  subtitle: const Text('Password & Session Management'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Institutional SSO Security Active')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(color: Colors.red)),
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
                style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
