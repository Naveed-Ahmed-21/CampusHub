import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/faculty_controller.dart';
import '../../domain/models/faculty_models.dart';

class AddSubjectDialog extends ConsumerStatefulWidget {
  final FacultySubject? subjectToEdit;

  const AddSubjectDialog({super.key, this.subjectToEdit});

  @override
  ConsumerState<AddSubjectDialog> createState() => _AddSubjectDialogState();
}

class _AddSubjectDialogState extends ConsumerState<AddSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _departmentController =
      TextEditingController(text: 'Computer Science & Engineering');
  final _descriptionController = TextEditingController();
  String _selectedSemester = 'Semester 5';
  String _selectedSection = 'A';
  int _credits = 4;
  bool _isSubmitting = false;

  final List<String> _semesters = [
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
    'Semester 5',
    'Semester 6',
    'Semester 7',
    'Semester 8',
  ];

  final List<String> _sections = ['A', 'B', 'C', 'D'];

  bool get isEditing => widget.subjectToEdit != null;

  @override
  void initState() {
    super.initState();
    if (widget.subjectToEdit != null) {
      final s = widget.subjectToEdit!;
      _codeController.text = s.code;
      _nameController.text = s.name;
      _departmentController.text = s.department;
      _descriptionController.text = s.description ?? '';
      _credits = s.credits;

      if (_semesters.contains(s.semester)) {
        _selectedSemester = s.semester;
      } else {
        _semesters.add(s.semester);
        _selectedSemester = s.semester;
      }

      if (_sections.contains(s.section)) {
        _selectedSection = s.section;
      } else {
        _sections.add(s.section);
        _selectedSection = s.section;
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _departmentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    bool success;
    if (isEditing) {
      success =
          await ref.read(facultyControllerProvider.notifier).updateSubject(
                subjectId: widget.subjectToEdit!.id,
                code: _codeController.text.trim(),
                name: _nameController.text.trim(),
                semester: _selectedSemester,
                section: _selectedSection,
                credits: _credits,
                departmentName: _departmentController.text.trim(),
                description: _descriptionController.text.trim().isNotEmpty
                    ? _descriptionController.text.trim()
                    : null,
              );
    } else {
      success =
          await ref.read(facultyControllerProvider.notifier).createSubject(
                code: _codeController.text.trim(),
                name: _nameController.text.trim(),
                semester: _selectedSemester,
                section: _selectedSection,
                credits: _credits,
                departmentName: _departmentController.text.trim(),
                description: _descriptionController.text.trim().isNotEmpty
                    ? _descriptionController.text.trim()
                    : null,
              );
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.teal.shade700,
            content: Text(isEditing
                ? 'Subject updated successfully'
                : 'Subject created successfully'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(isEditing
                ? 'Failed to update subject. Please try again.'
                : 'Failed to create subject. Please check input.'),
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isEditing ? Colors.teal : Colors.blue)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit_note : Icons.school,
                          color: isEditing ? Colors.teal : Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEditing
                              ? 'Edit Subject / Course'
                              : 'Add New Subject',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Subject Code *',
                      hintText: 'e.g. CS301, IT402',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.code),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Please enter subject code'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Subject Name *',
                      hintText: 'e.g. Data Structures & Algorithms',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.book_outlined),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Please enter subject title'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedSemester,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Semester',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          items: _semesters
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s,
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedSemester = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedSection,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Section',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          items: _sections
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s,
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedSection = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _departmentController,
                          decoration: InputDecoration(
                            labelText: 'Department',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.apartment),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 110,
                        child: DropdownButtonFormField<int>(
                          initialValue: _credits,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Credits',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          items: [1, 2, 3, 4, 5]
                              .map((c) =>
                                  DropdownMenuItem(value: c, child: Text('$c')))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _credits = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Syllabus / Course Description (Optional)',
                      hintText:
                          'Brief course summary, prerequisites, and learning objectives',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      FilledButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(isEditing ? Icons.check : Icons.add,
                                size: 18),
                        label: Text(
                            isEditing ? 'Update Subject' : 'Create Subject'),
                        style: FilledButton.styleFrom(
                          backgroundColor: isEditing
                              ? Colors.teal.shade700
                              : Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
