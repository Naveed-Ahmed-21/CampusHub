import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/faculty_controller.dart';
import '../../domain/models/faculty_models.dart';
import 'add_subject_dialog.dart';
import 'add_announcement_dialog.dart';
import 'qr_attendance_scanner_dialog.dart';
import 'add_edit_schedule_slot_dialog.dart';

class FacultyQuickActionsBar extends ConsumerWidget {
  const FacultyQuickActionsBar({super.key});

  void _selectSubjectAndNavigate(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required int targetTab,
    required String actionLabel,
  }) async {
    List<FacultySubject> subjects = [];
    final currentAsync = ref.read(facultySubjectsProvider);
    if (currentAsync.hasValue &&
        currentAsync.value != null &&
        currentAsync.value!.isNotEmpty) {
      subjects = currentAsync.value!;
    } else {
      try {
        subjects = await ref.read(facultySubjectsProvider.future);
      } catch (_) {
        subjects = [];
      }
    }

    if (!context.mounted) return;

    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'No subjects assigned yet. Create a subject to $actionLabel.'),
          action: SnackBarAction(
            label: 'Add Subject',
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => const AddSubjectDialog(),
            ),
          ),
        ),
      );
      return;
    }

    if (subjects.length == 1) {
      context.push('/teaching/subjects/${subjects.first.id}?tab=$targetTab');
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: subjects.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, index) {
                    final sub = subjects[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          sub.code,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        sub.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        '${sub.semester} • Section ${sub.section} • ${sub.studentsCount} Students',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          size: 14, color: Colors.grey),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push(
                            '/teaching/subjects/${sub.id}?tab=$targetTab');
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Quick Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => context.go('/teaching'),
              icon: const Icon(Icons.school, size: 16),
              label: const Text('Teaching Hub'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _ActionChip(
                icon: Icons.how_to_reg_outlined,
                label: 'Take Attendance',
                color: Colors.indigo,
                onTap: () => _selectSubjectAndNavigate(
                  context,
                  ref,
                  title: 'Select Subject for Attendance',
                  targetTab: 5,
                  actionLabel: 'record attendance',
                ),
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.quiz_outlined,
                label: 'Add Assessment',
                color: Colors.teal,
                onTap: () => _selectSubjectAndNavigate(
                  context,
                  ref,
                  title: 'Select Subject for Assessment',
                  targetTab: 4,
                  actionLabel: 'create continuous assessment',
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
                icon: Icons.schedule_outlined,
                label: 'Schedule Slot',
                color: Colors.blue,
                onTap: () => showDialog(
                  context: context,
                  builder: (ctx) => const AddEditScheduleSlotDialog(),
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
                icon: Icons.add_circle_outline,
                label: 'Add Subject',
                color: Colors.green,
                onTap: () => showDialog(
                  context: context,
                  builder: (ctx) => const AddSubjectDialog(),
                ),
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
                  color: isDark
                      ? color.withValues(alpha: 0.9)
                      : color.withValues(alpha: 0.9),
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
