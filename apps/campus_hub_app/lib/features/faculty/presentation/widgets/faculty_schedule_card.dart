import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/faculty_models.dart';
import '../controllers/faculty_controller.dart';
import 'add_edit_schedule_slot_dialog.dart';

class FacultyScheduleCard extends ConsumerWidget {
  final List<ClassScheduleSlot> slots;

  const FacultyScheduleCard({super.key, required this.slots});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (slots.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.event_available, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'No lecture slots scheduled for today 🎉',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => const AddEditScheduleSlotDialog(),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Class Slot'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.schedule,
                          size: 20, color: Colors.blue),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Today's Schedule",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${slots.length} Classes',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          color: Colors.blue, size: 22),
                      tooltip: 'Add Class Slot',
                      onPressed: () => showDialog(
                        context: context,
                        builder: (ctx) => const AddEditScheduleSlotDialog(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...slots.map((slot) => _ScheduleItemTile(slot: slot)),
          ],
        ),
      ),
    );
  }
}

class _ScheduleItemTile extends ConsumerWidget {
  final ClassScheduleSlot slot;

  const _ScheduleItemTile({required this.slot});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Schedule Slot'),
        content: Text(
            'Are you sure you want to remove "${slot.subjectCode} - ${slot.subjectName}" from your schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref
          .read(facultyControllerProvider.notifier)
          .deleteScheduleSlot(slot.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                success ? 'Schedule slot deleted' : 'Failed to delete slot'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _openClassSessionHub(
      BuildContext context, WidgetRef ref, ClassScheduleSlot slot) {
    final subjectsAsync = ref.read(facultySubjectsProvider);
    final subjects = subjectsAsync.value ?? [];
    FacultySubject? matchedSubject;
    if (slot.subjectId != null && slot.subjectId!.isNotEmpty) {
      matchedSubject =
          subjects.where((s) => s.id == slot.subjectId).firstOrNull;
    }
    matchedSubject ??= subjects
        .where((s) => s.code.toUpperCase() == slot.subjectCode.toUpperCase())
        .firstOrNull;

    final theme = Theme.of(context);
    final isLab = slot.sessionType.toUpperCase() == 'LAB';
    final isPlacement = slot.sessionType.toUpperCase() == 'PLACEMENT';
    Color typeColor = Colors.blue;
    if (isLab) typeColor = Colors.purple;
    if (isPlacement) typeColor = Colors.orange.shade800;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      slot.sessionType,
                      style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${slot.startTime} - ${slot.endTime}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${slot.subjectCode} - ${slot.subjectName}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 15, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${slot.roomOrVenue} • ${slot.semester} • Section ${slot.section}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ],
              ),
              if (slot.topic != null && slot.topic!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lecture Topic: ${slot.topic}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Text(
                'Class Session Quick Actions',
                style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (matchedSubject != null) {
                          GoRouter.of(context)
                              .push('/teaching/subjects/${matchedSubject.id}');
                        } else {
                          GoRouter.of(context).go('/teaching');
                        }
                      },
                      icon: const Icon(Icons.how_to_reg,
                          size: 18, color: Colors.teal),
                      label: const Text('Take Attendance'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (matchedSubject != null) {
                          GoRouter.of(context)
                              .push('/teaching/subjects/${matchedSubject.id}');
                        } else {
                          GoRouter.of(context).go('/teaching');
                        }
                      },
                      icon: const Icon(Icons.folder_open,
                          size: 18, color: Colors.blue),
                      label: const Text('Share Notes'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (matchedSubject != null) {
                      GoRouter.of(context)
                          .push('/teaching/subjects/${matchedSubject.id}');
                    } else {
                      GoRouter.of(context).go('/teaching');
                    }
                  },
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Open Subject Workspace'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _openClassSessionHub(context, ref, slot),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                slot.subjectCode,
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.subjectName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${slot.semester} • Section ${slot.section} • ${slot.roomOrVenue}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (slot.topic != null && slot.topic!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3.0),
                      child: Text(
                        '📌 ${slot.topic}',
                        style: TextStyle(
                          color: Colors.teal.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  slot.startTime,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  slot.endTime,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18),
              padding: EdgeInsets.zero,
              onSelected: (val) {
                if (val == 'session') {
                  _openClassSessionHub(context, ref, slot);
                } else if (val == 'edit') {
                  showDialog(
                    context: context,
                    builder: (ctx) => AddEditScheduleSlotDialog(slot: slot),
                  );
                } else if (val == 'delete') {
                  _confirmDelete(context, ref);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'session',
                  child: Row(
                    children: [
                      Icon(Icons.dashboard_outlined,
                          size: 18, color: Colors.teal),
                      SizedBox(width: 8),
                      Text('Session Hub'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit Slot'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
