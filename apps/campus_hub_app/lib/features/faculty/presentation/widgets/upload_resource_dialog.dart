import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/faculty_controller.dart';

class UploadResourceDialog extends ConsumerStatefulWidget {
  final String subjectId;
  final String subjectName;
  final String? initialUnit;

  const UploadResourceDialog({
    super.key,
    required this.subjectId,
    required this.subjectName,
    this.initialUnit,
  });

  @override
  ConsumerState<UploadResourceDialog> createState() => _UploadResourceDialogState();
}

class _UploadResourceDialogState extends ConsumerState<UploadResourceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _topicController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController(text: 'https://ik.imagekit.io/campushub/academic/lecture_notes.pdf');

  late String _selectedUnit;
  String _selectedResourceType = 'NOTES';
  String _selectedVisibility = 'PUBLIC';
  bool _isUploading = false;

  final List<String> _units = [
    'Unit 1',
    'Unit 2',
    'Unit 3',
    'Unit 4',
    'Unit 5',
    'Lab & Practical',
    'General',
  ];

  final Map<String, String> _resourceTypeLabels = {
    'NOTES': 'Lecture Notes / Handout',
    'PDF': 'Document (PDF)',
    'PRESENTATION': 'Slide Deck (PPT / Keynote)',
    'VIDEO': 'Video Lecture',
    'YOUTUBE': 'YouTube Video / Playlist',
    'GITHUB': 'GitHub Code / Repository',
    'ASSIGNMENT': 'Lab / Homework Assignment',
    'QUESTION_BANK': 'Question Bank & Solutions',
    'REFERENCE_BOOK': 'Reference Book / Syllabus Guide',
  };

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.initialUnit ?? _units[0];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _topicController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isUploading = true);

    final success = await ref.read(facultyControllerProvider.notifier).uploadSubjectResource(
          subjectId: widget.subjectId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          fileUrl: _urlController.text.trim(),
          fileType: _selectedResourceType == 'PRESENTATION'
              ? 'PPT'
              : _selectedResourceType == 'VIDEO' || _selectedResourceType == 'YOUTUBE'
                  ? 'VIDEO'
                  : _selectedResourceType == 'GITHUB'
                      ? 'CODE'
                      : 'PDF',
          unit: _selectedUnit,
          topic: _topicController.text.trim().isNotEmpty ? _topicController.text.trim() : null,
          resourceType: _selectedResourceType,
          visibility: _selectedVisibility,
        );

    if (mounted) {
      setState(() => _isUploading = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.teal.shade700,
            content: Text('Study material published to $_selectedUnit successfully!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to upload material. Please try again.'),
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
                          color: Colors.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.upload_file, color: Colors.teal),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Publish Academic Material',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.subjectName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Unit Selector & Resource Type Selector in a Row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedUnit,
                          decoration: InputDecoration(
                            labelText: 'Curriculum Unit *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.layers_outlined, size: 20),
                          ),
                          items: _units
                              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedUnit = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedResourceType,
                          decoration: InputDecoration(
                            labelText: 'Resource Category *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.category_outlined, size: 20),
                          ),
                          items: _resourceTypeLabels.entries
                              .map((e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(
                                      e.value,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedResourceType = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Resource Title
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Resource Title *',
                      hintText: 'e.g. Unit 3 Docker Containerization & Microservices.pdf',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.title, size: 20),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please enter resource title' : null,
                  ),
                  const SizedBox(height: 14),

                  // Topic name
                  TextFormField(
                    controller: _topicController,
                    decoration: InputDecoration(
                      labelText: 'Syllabus Topic / Sub-topic (Optional)',
                      hintText: 'e.g. Virtualization & Hypervisors (Type 1 & 2)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.tag, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // File / Media URL
                  TextFormField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: 'Resource File / Web Link URL *',
                      hintText: 'https://ik.imagekit.io/... or https://youtube.com/...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.link, size: 20),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please provide URL' : null,
                  ),
                  const SizedBox(height: 14),

                  // Visibility Selector
                  DropdownButtonFormField<String>(
                    initialValue: _selectedVisibility,
                    decoration: InputDecoration(
                      labelText: 'Student Visibility',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.visibility_outlined, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'PUBLIC',
                        child: Text('Public to All Students & Departments'),
                      ),
                      DropdownMenuItem(
                        value: 'ENROLLED_ONLY',
                        child: Text('Restricted to Enrolled Students Only'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedVisibility = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Description / Instructions (Optional)',
                      hintText: 'Key learning outcomes, lab prerequisites, or practice exercises',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _isUploading ? null : _submit,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.cloud_upload, size: 18),
                        label: const Text('Publish Material'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
