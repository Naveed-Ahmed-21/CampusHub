import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/media_picker_service.dart';
import '../../../../core/services/media_upload_service.dart';
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
    required String defaultResourceType,
  });

  @override
  ConsumerState<UploadResourceDialog> createState() =>
      _UploadResourceDialogState();
}

class _UploadResourceDialogState extends ConsumerState<UploadResourceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _topicController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();

  late String _selectedUnit;
  String _selectedResourceType = 'NOTES';
  String _selectedVisibility = 'PUBLIC';
  bool _isUploading = false;
  String? _uploadStatusText;
  double _uploadProgress = 0.0;

  // Mode: 0 = Direct File Upload, 1 = Google Drive / Cloud URL
  int _uploadMode = 0;
  SelectedMediaFile? _selectedFile;

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
    'PRESENTATION': 'Slide Deck (PPT / Slides)',
    'VIDEO': 'Video Lecture',
    'YOUTUBE': 'YouTube Video / Playlist',
    'GITHUB': 'GitHub Code / Repository',
    'ASSIGNMENT': 'Lab / Homework Assignment',
    'QUESTION_BANK': 'Question Bank & Solutions',
    'REFERENCE_BOOK': 'Reference Book / Syllabus',
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

  Future<void> _pickDocument() async {
    try {
      final pickedFiles = await MediaPickerService.pickDocuments(
        allowMultiple: false,
        allowedExtensions: [
          'pdf',
          'ppt',
          'pptx',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'txt',
          'zip',
          'mp4'
        ],
      );

      if (pickedFiles.isNotEmpty) {
        final file = pickedFiles.first;
        setState(() {
          _selectedFile = file;

          // Auto-fill title if empty
          if (_titleController.text.trim().isEmpty) {
            // Strip extension and format nicely
            final rawName = file.name;
            final dotIndex = rawName.lastIndexOf('.');
            final cleanName =
                dotIndex != -1 ? rawName.substring(0, dotIndex) : rawName;
            _titleController.text =
                cleanName.replaceAll('_', ' ').replaceAll('-', ' ');
          }

          // Auto-detect resource category based on extension
          final lowerName = file.name.toLowerCase();
          if (lowerName.endsWith('.ppt') || lowerName.endsWith('.pptx')) {
            _selectedResourceType = 'PRESENTATION';
          } else if (lowerName.endsWith('.pdf')) {
            _selectedResourceType = 'PDF';
          } else if (lowerName.endsWith('.mp4') || lowerName.endsWith('.mov')) {
            _selectedResourceType = 'VIDEO';
          } else {
            _selectedResourceType = 'NOTES';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select file: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_uploadMode == 0 &&
        _selectedFile == null &&
        _urlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content:
              Text('Please select a file to upload or switch to Link mode.'),
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatusText = _uploadMode == 0
          ? 'Uploading file to CampusHub...'
          : 'Publishing resource...';
    });

    String fileUrlToSave = _urlController.text.trim();
    String calculatedFileType = 'PDF';

    if (_uploadMode == 0 && _selectedFile != null) {
      try {
        final uploadResult =
            await ref.read(mediaUploadServiceProvider).uploadSelectedFile(
          _selectedFile!,
          onProgress: (sent, total) {
            if (total > 0 && mounted) {
              setState(() {
                _uploadProgress = sent / total;
                _uploadStatusText =
                    'Uploading: ${(_uploadProgress * 100).toStringAsFixed(0)}%';
              });
            }
          },
        );

        fileUrlToSave = uploadResult.fullUrl.isNotEmpty
            ? uploadResult.fullUrl
            : uploadResult.url;
        calculatedFileType = _selectedFile!.name.split('.').last.toUpperCase();
      } catch (e) {
        if (mounted) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text('Upload failed: $e'),
            ),
          );
        }
        return;
      }
    } else {
      calculatedFileType = _selectedResourceType == 'PRESENTATION'
          ? 'PPT'
          : _selectedResourceType == 'VIDEO' ||
                  _selectedResourceType == 'YOUTUBE'
              ? 'VIDEO'
              : _selectedResourceType == 'GITHUB'
                  ? 'CODE'
                  : 'PDF';
    }

    if (mounted) {
      setState(() => _uploadStatusText = 'Saving resource metadata...');
    }

    final success = await ref
        .read(facultyControllerProvider.notifier)
        .uploadSubjectResource(
          subjectId: widget.subjectId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          fileUrl: fileUrlToSave,
          fileType: calculatedFileType,
          unit: _selectedUnit,
          topic: _topicController.text.trim().isNotEmpty
              ? _topicController.text.trim()
              : null,
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
            content: Text(
                'Study material published to $_selectedUnit successfully!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to publish resource. Please try again.'),
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
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child:
                            const Icon(Icons.upload_file, color: Colors.teal),
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
                        onPressed: _isUploading
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Mode Selector: Upload File vs Google Drive / Cloud Link
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _isUploading
                                ? null
                                : () => setState(() => _uploadMode = 0),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _uploadMode == 0
                                    ? theme.colorScheme.surface
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _uploadMode == 0
                                    ? [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.06),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.file_upload_outlined,
                                    size: 18,
                                    color: _uploadMode == 0
                                        ? Colors.teal
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Upload File',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontWeight: _uploadMode == 0
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: _uploadMode == 0
                                            ? Colors.teal
                                            : Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: _isUploading
                                ? null
                                : () => setState(() => _uploadMode = 1),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _uploadMode == 1
                                    ? theme.colorScheme.surface
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _uploadMode == 1
                                    ? [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.06),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.link,
                                    size: 18,
                                    color: _uploadMode == 1
                                        ? Colors.teal
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Drive / Web Link',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontWeight: _uploadMode == 1
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: _uploadMode == 1
                                            ? Colors.teal
                                            : Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // File Picker area or URL Field
                  if (_uploadMode == 0) ...[
                    InkWell(
                      onTap: _isUploading ? null : _pickDocument,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedFile != null
                                ? Colors.teal
                                : theme.colorScheme.outlineVariant,
                            width: _selectedFile != null ? 1.5 : 1.0,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          color: _selectedFile != null
                              ? Colors.teal.withValues(alpha: 0.05)
                              : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.2),
                        ),
                        child: _selectedFile != null
                            ? Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.teal.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.description,
                                        color: Colors.teal, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedFile!.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _selectedFile!.formattedSize,
                                          style: TextStyle(
                                              color: theme.colorScheme.outline,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed:
                                        _isUploading ? null : _pickDocument,
                                    child: const Text('Change',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: _isUploading
                                        ? null
                                        : () => setState(() {
                                              _selectedFile = null;
                                            }),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  const Icon(Icons.cloud_upload_outlined,
                                      size: 36, color: Colors.teal),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Choose Study Material File',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'PDF, PPT, DOCX, TXT, ZIP, or Video (Max 50MB)',
                                    style: TextStyle(
                                        color: theme.colorScheme.outline,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ] else ...[
                    TextFormField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: 'Google Drive / OneDrive / Media Link *',
                        hintText:
                            'https://drive.google.com/... or https://youtube.com/...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.link, size: 20),
                      ),
                      validator: (val) {
                        if (_uploadMode == 1 &&
                            (val == null || val.trim().isEmpty)) {
                          return 'Please provide a valid document or link URL';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Curriculum Unit Dropdown (isExpanded: true to prevent RenderFlex overflow)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedUnit,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Curriculum Unit *',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.layers_outlined, size: 20),
                    ),
                    items: _units
                        .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(u, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedUnit = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Resource Category Dropdown (isExpanded: true to prevent RenderFlex overflow)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedResourceType,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Resource Category *',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                      if (val != null) {
                        setState(() => _selectedResourceType = val);
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // Resource Title
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Resource Title *',
                      hintText:
                          'e.g. Unit 3 Docker Containerization & Microservices',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.title, size: 20),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Please enter resource title'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // Topic name
                  TextFormField(
                    controller: _topicController,
                    decoration: InputDecoration(
                      labelText: 'Syllabus Topic / Sub-topic (Optional)',
                      hintText:
                          'e.g. Virtualization & Hypervisors (Type 1 & 2)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.tag, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Visibility Selector (isExpanded: true)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedVisibility,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Student Visibility',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon:
                          const Icon(Icons.visibility_outlined, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'PUBLIC',
                        child: Text(
                          'Public to All Students & Departments',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'ENROLLED_ONLY',
                        child: Text(
                          'Restricted to Enrolled Students Only',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedVisibility = val);
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Description / Instructions (Optional)',
                      hintText:
                          'Key learning outcomes, lab prerequisites, or practice exercises',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Upload Progress indicator if active
                  if (_isUploading) ...[
                    if (_uploadProgress > 0)
                      LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: Colors.teal.withValues(alpha: 0.2),
                        color: Colors.teal,
                      ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _uploadStatusText ?? 'Processing...',
                        style: TextStyle(
                            fontSize: 12, color: theme.colorScheme.outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Action Buttons with Wrap to prevent overflow
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      TextButton(
                        onPressed: _isUploading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      FilledButton.icon(
                        onPressed: _isUploading ? null : _submit,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.cloud_upload, size: 18),
                        label: Text(_uploadMode == 0
                            ? 'Upload & Publish'
                            : 'Publish Material'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
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
