import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'add_subject_dialog.dart';
import 'add_announcement_dialog.dart';
import 'qr_attendance_scanner_dialog.dart';

class FacultyQuickActionsBar extends StatelessWidget {
  const FacultyQuickActionsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.go('/teaching'),
              icon: const Icon(Icons.school, size: 16),
              label: const Text('Teaching Hub'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _ActionChip(
                icon: Icons.add_circle_outline,
                label: 'Add Subject',
                color: Colors.blue,
                onTap: () => showDialog(
                  context: context,
                  builder: (ctx) => const AddSubjectDialog(),
                ),
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.campaign_outlined,
                label: 'Announcement',
                color: Colors.orange,
                onTap: () => showDialog(
                  context: context,
                  builder: (ctx) => const AddAnnouncementDialog(),
                ),
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.qr_code_scanner,
                label: 'Scan Attendance',
                color: Colors.purple,
                onTap: () => showDialog(
                  context: context,
                  builder: (ctx) => const QrAttendanceScannerDialog(),
                ),
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.people_outline,
                label: 'Student Mentoring',
                color: Colors.teal,
                onTap: () => context.go('/teaching'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? color.withValues(alpha: 0.9) : color.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
