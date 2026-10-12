import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/faculty_models.dart';
import '../controllers/faculty_controller.dart';

class AddEditScheduleSlotDialog extends ConsumerStatefulWidget {
  final ClassScheduleSlot? slot;

  const AddEditScheduleSlotDialog({super.key, this.slot});

  @override
  ConsumerState<AddEditScheduleSlotDialog> createState() =>
      _AddEditScheduleSlotDialogState();
}

class _AddEditScheduleSlotDialogState
    extends ConsumerState<AddEditScheduleSlotDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _venueController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;
  late final TextEditingController _semesterController;
  late final TextEditingController _sectionController;

  bool _isSaving = false;

  bool get isEditing => widget.slot != null;

  @override
  void initState() {
    super.initState();
    final s = widget.slot;
    _codeController = TextEditingController(text: s?.subjectCode ?? '');
    _nameController = TextEditingController(text: s?.subjectName ?? '');
    _venueController =
        TextEditingController(text: s?.roomOrVenue ?? 'Lecture Hall 101');
    _startTimeController =
        TextEditingController(text: s?.startTime ?? '09:00 AM');
    _endTimeController = TextEditingController(text: s?.endTime ?? '10:00 AM');
    _semesterController =
        TextEditingController(text: s?.semester ?? 'Semester 5');
    final rawSec = s?.section ?? 'Year 1';
    final mappedSec = rawSec == 'A'
        ? 'Year 1'
        : rawSec == 'B'
            ? 'Year 2'
            : rawSec == 'C'
                ? 'Year 3'
                : rawSec == 'D'
                    ? 'Year 4'
                    : rawSec;
    _sectionController = TextEditingController(text: mappedSec);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _venueController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _semesterController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final payload = {
      'subjectCode': _codeController.text.trim().toUpperCase(),
      'subjectName': _nameController.text.trim(),
      'roomOrVenue': _venueController.text.trim(),
      'startTime': _startTimeController.text.trim(),
      'endTime': _endTimeController.text.trim(),
      'semester': _semesterController.text.trim(),
      'section': _sectionController.text.trim().toUpperCase(),
      'dayOfWeek': widget.slot?.dayOfWeek ?? 'TODAY',
    };

    bool success;
    if (isEditing) {
      success = await ref
          .read(facultyControllerProvider.notifier)
          .updateScheduleSlot(widget.slot!.id, payload);
    } else {
      success = await ref
          .read(facultyControllerProvider.notifier)
          .createScheduleSlot(payload);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing
                ? 'Schedule slot updated successfully!'
                : 'Class slot added to schedule!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing
                ? 'Failed to update schedule slot'
                : 'Failed to add schedule slot'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isEditing
                                  ? Icons.edit_calendar_outlined
                                  : Icons.add_alarm_rounded,
                              color: Colors.blue,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isEditing
                                  ? 'Edit Class Slot'
                                  : 'Add Class to Schedule',
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Synchronized Subject Code & Name Dropdowns
                Builder(
                  builder: (context) {
                    final subjects = ref.watch(facultySubjectsProvider).value ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                initialValue: subjects.any((s) => s.code == _codeController.text)
                                    ? _codeController.text
                                    : null,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Subject Code',
                                  hintText: 'Select Code',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.3),
                                ),
                                items: [
                                  ...subjects.map(
                                    (s) => DropdownMenuItem(
                                      value: s.code,
                                      child: Text(s.code, overflow: TextOverflow.ellipsis),
                                    ),
                                  ),
                                  const DropdownMenuItem(
                                    value: '__ADD_SUBJECT__',
                                    child: Row(
                                      children: [
                                        Icon(Icons.add_circle_outline, size: 16, color: Colors.blue),
                                        SizedBox(width: 4),
                                        Text(
                                          '+ Add',
                                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val == '__ADD_SUBJECT__') {
                                    Navigator.pop(context);
                                    context.push('/faculty/teaching');
                                    return;
                                  }
                                  if (val != null) {
                                    final match = subjects.firstWhere((s) => s.code == val);
                                    setState(() {
                                      _codeController.text = match.code;
                                      _nameController.text = match.name;
                                      if (match.semester.isNotEmpty) _semesterController.text = match.semester;
                                      if (match.section.isNotEmpty) _sectionController.text = match.section;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                initialValue: subjects.any((s) => s.name == _nameController.text)
                                    ? _nameController.text
                                    : null,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Subject',
                                  hintText: 'Select Subject',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.3),
                                ),
                                items: [
                                  ...subjects.map(
                                    (s) => DropdownMenuItem(
                                      value: s.name,
                                      child: Text(s.name, overflow: TextOverflow.ellipsis),
                                    ),
                                  ),
                                  const DropdownMenuItem(
                                    value: '__ADD_SUBJECT__',
                                    child: Row(
                                      children: [
                                        Icon(Icons.add_circle_outline, size: 16, color: Colors.blue),
                                        SizedBox(width: 4),
                                        Text(
                                          '+ Add Subject',
                                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val == '__ADD_SUBJECT__') {
                                    Navigator.pop(context);
                                    context.push('/faculty/teaching');
                                    return;
                                  }
                                  if (val != null) {
                                    final match = subjects.firstWhere((s) => s.name == val);
                                    setState(() {
                                      _codeController.text = match.code;
                                      _nameController.text = match.name;
                                      if (match.semester.isNotEmpty) _semesterController.text = match.semester;
                                      if (match.section.isNotEmpty) _sectionController.text = match.section;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        if (subjects.isEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _codeController,
                                  decoration: InputDecoration(
                                    labelText: 'Custom Code',
                                    hintText: 'e.g. CS3381',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    filled: true,
                                    fillColor: theme.colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.3),
                                  ),
                                  textCapitalization: TextCapitalization.characters,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Custom Subject',
                                    hintText: 'e.g. Data Science',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    filled: true,
                                    fillColor: theme.colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.3),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),

                // Venue
                TextFormField(
                  controller: _venueController,
                  decoration: InputDecoration(
                    labelText: 'Room / Venue',
                    hintText: 'e.g. Lecture Hall 101, Lab 3',
                    prefixIcon: const Icon(Icons.meeting_room_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                // Start Time & End Time
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startTimeController,
                        decoration: InputDecoration(
                          labelText: 'Start Time',
                          hintText: '09:00 AM',
                          prefixIcon: const Icon(Icons.access_time),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _endTimeController,
                        decoration: InputDecoration(
                          labelText: 'End Time',
                          hintText: '10:00 AM',
                          prefixIcon: const Icon(Icons.access_time_filled),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Semester & Section
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _semesterController,
                        decoration: InputDecoration(
                          labelText: 'Semester',
                          hintText: 'Semester 5',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: ['Year 1', 'Year 2', 'Year 3', 'Year 4']
                                .contains(_sectionController.text)
                            ? _sectionController.text
                            : 'Year 1',
                        decoration: InputDecoration(
                          labelText: 'Year',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                        ),
                        items: ['Year 1', 'Year 2', 'Year 3', 'Year 4']
                            .map((y) => DropdownMenuItem(
                                  value: y,
                                  child: Text(y),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) _sectionController.text = v;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(isEditing ? Icons.save_outlined : Icons.add),
                      label: Text(isEditing ? 'Save Changes' : 'Add Slot'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
