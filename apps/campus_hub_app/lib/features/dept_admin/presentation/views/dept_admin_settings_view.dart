import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class DeptAdminSettingsView extends ConsumerWidget {
  const DeptAdminSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: const CampusAppBar(
        title: 'Settings',
        subtitle: 'Department Workspace Configuration',
      ),
      body: AtmosphericBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              CampusGlassCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.palette_outlined),
                        title: const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(
                          themeMode == ThemeMode.dark ? 'Dark Theme Active' : 'Light Theme Active',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Switch(
                          value: themeMode == ThemeMode.dark,
                          onChanged: (val) {
                            ref.read(themeNotifierProvider.notifier).setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.notifications_active_outlined),
                        title: const Text('Department Notifications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text('Alerts on low attendance, circulars', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () => context.push('/notifications'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('Security & Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password modification requires verified college email OTP')),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.help_outline),
                        title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () => context.push('/settings/help'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('About CampusHub', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () => context.push('/settings/about'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.s24),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.15),
                  foregroundColor: Colors.red,
                  elevation: 0,
                  side: const BorderSide(color: Colors.redAccent, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Logout Account', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
