import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../feed/presentation/controllers/feed_controller.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  bool _pushNotifications = true;
  bool _messageAlerts = true;
  bool _campusAnnouncements = true;
  bool _showOnlineStatus = true;
  bool _autoDownloadWifi = true;
  bool _autoDownloadDocs = false;

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Log Out?'),
          ],
        ),
        content: const Text('Are you sure you want to log out of CampusHub on this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Account?'),
          ],
        ),
        content: const Text(
          'This action is permanent and cannot be undone. All your posts, submissions, and direct messages will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion request submitted to campus administrator.'),
                ),
              );
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentThemeMode = ref.watch(themeNotifierProvider);
    final currentFeedType = ref.watch(activeFeedTypeProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. APPEARANCE SECTION
          _buildSectionHeader('Appearance & Theme'),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette_outlined, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Theme Mode',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode, size: 16),
                      ),
                    ],
                    selected: {currentThemeMode},
                    onSelectionChanged: (newSelection) {
                      ref.read(themeNotifierProvider.notifier).setThemeMode(newSelection.first);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. FEED PREFERENCES
          _buildSectionHeader('Feed Preferences'),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.feed_outlined, color: theme.colorScheme.primary),
                  title: const Text('Default Feed Tab', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(
                    currentFeedType == 'forYou'
                        ? 'For You (Platform Feed)'
                        : (currentFeedType == 'myDepartment' ? 'My Department (Strict)' : 'Related (Technical Disciplines)'),
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  trailing: DropdownButton<String>(
                    value: ['forYou', 'myDepartment', 'related'].contains(currentFeedType) ? currentFeedType : 'forYou',
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'forYou', child: Text('For You')),
                      DropdownMenuItem(value: 'myDepartment', child: Text('My Department')),
                      DropdownMenuItem(value: 'related', child: Text('Related')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(activeFeedTypeProvider.notifier).setFeedType(val);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. NOTIFICATIONS
          _buildSectionHeader('Notifications'),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: _pushNotifications,
                  activeTrackColor: theme.colorScheme.primary,
                  title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Receive alerts on device lock screen', style: TextStyle(fontSize: 12)),
                  onChanged: (v) => setState(() => _pushNotifications = v),
                ),
                Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                SwitchListTile(
                  value: _messageAlerts,
                  activeTrackColor: theme.colorScheme.primary,
                  title: const Text('Chat Message Alerts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Notifications for direct and club messages', style: TextStyle(fontSize: 12)),
                  onChanged: (v) => setState(() => _messageAlerts = v),
                ),
                Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                SwitchListTile(
                  value: _campusAnnouncements,
                  activeTrackColor: theme.colorScheme.primary,
                  title: const Text('Campus Announcements', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Important college and department notices', style: TextStyle(fontSize: 12)),
                  onChanged: (v) => setState(() => _campusAnnouncements = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. PRIVACY & CHAT
          _buildSectionHeader('Privacy & Chat Media'),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: _showOnlineStatus,
                  activeTrackColor: theme.colorScheme.primary,
                  title: const Text('Show Online Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Let contacts see when you are active in chat', style: TextStyle(fontSize: 12)),
                  onChanged: (v) => setState(() => _showOnlineStatus = v),
                ),
                Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                SwitchListTile(
                  value: _autoDownloadWifi,
                  activeTrackColor: theme.colorScheme.primary,
                  title: const Text('Auto-Download Media on Wi-Fi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Automatically cache photos over Wi-Fi', style: TextStyle(fontSize: 12)),
                  onChanged: (v) => setState(() => _autoDownloadWifi = v),
                ),
                Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                SwitchListTile(
                  value: _autoDownloadDocs,
                  activeTrackColor: theme.colorScheme.primary,
                  title: const Text('Auto-Download Documents', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Save PDF & DOCX files automatically', style: TextStyle(fontSize: 12)),
                  onChanged: (v) => setState(() => _autoDownloadDocs = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. ACCOUNT & LOGOUT
          _buildSectionHeader('Account & Data'),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.person_outline, color: theme.colorScheme.primary),
                  title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Update resume, skills, clubs & bio', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    final role = ref.read(authControllerProvider).asData?.value?.role ?? 'STUDENT';
                    if (role == 'FACULTY') {
                      context.go('/faculty/profile');
                    } else {
                      context.go('/profile');
                    }
                  },
                ),
                Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.orange),
                  title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.orange)),
                  onTap: () => _showLogoutDialog(context),
                ),
                Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.red)),
                  onTap: () => _showDeleteAccountDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 6. SUPPORT & INFORMATION
          _buildSectionHeader('Support & Information'),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.help_outline, color: theme.colorScheme.primary),
                  title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('FAQs, student guidelines & report issues', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => context.push('/help'),
                ),
                Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ListTile(
                  leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  title: const Text('About CampusHub', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Vision, ecosystem pillars & licenses', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => context.push('/about'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About section
          InkWell(
            onTap: () => context.push('/about'),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'CampusHub v1.0.0 (Build 2026.08)',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.outline, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Connected Campus Collaboration Platform • Tap to learn more',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: theme.colorScheme.primary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
