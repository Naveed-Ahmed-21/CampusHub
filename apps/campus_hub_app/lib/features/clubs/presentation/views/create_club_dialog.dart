import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/clubs_repository.dart';
import '../providers/club_provider.dart';
import '../../../../core/services/media_picker_service.dart';
import '../../../../core/services/media_upload_service.dart';
import '../../../../shared/widgets/selected_media_preview_widget.dart';

class CreateClubDialog extends ConsumerStatefulWidget {
  const CreateClubDialog({super.key});

  @override
  ConsumerState<CreateClubDialog> createState() => _CreateClubDialogState();
}

class _CreateClubDialogState extends ConsumerState<CreateClubDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Technical';
  bool _isCrossDepartment = true;
  bool _isSubmitting = false;
  SelectedMediaFile? _logoFile;

  final List<String> _categories = [
    'Technical',
    'Cultural',
    'Sports',
    'Academic',
    'Social Service',
    'Literature & Arts',
    'Innovation & E-Cell',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final file = await MediaPickerService.showMediaPickerSheet(
      context,
      title: 'Select Club Logo',
      enableCamera: true,
      enableGallery: true,
      enableVideoCamera: false,
      enableVideoGallery: false,
      enableDocuments: false,
    );
    if (file != null && mounted) {
      setState(() => _logoFile = file);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      String? uploadedLogoUrl;

      if (_logoFile != null) {
        final uploadService = ref.read(mediaUploadServiceProvider);
        final result = await uploadService.uploadSelectedFile(_logoFile!);
        uploadedLogoUrl = result.url;
      }

      final repository = ref.read(clubsRepositoryProvider);
      await repository.createClub(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        logoUrl: uploadedLogoUrl,
        isCrossDepartment: _isCrossDepartment,
      );

      if (mounted) {
        ref.invalidate(approvedClubsProvider);
        ref.invalidate(pendingClubsProvider);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Club proposed successfully! Submitted for admin verification.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Failed to create club. Please try again.';
        if (e is DioException && e.response?.data is Map) {
          msg = e.response?.data['message'] ?? msg;
        } else {
          msg = e.toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Propose New Club',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Club Logo Picker
                  Center(
                    child: Column(
                      children: [
                        if (_logoFile != null) ...[
                          SelectedMediaPreviewWidget(
                            file: _logoFile!,
                            onRemove: () => setState(() => _logoFile = null),
                          ),
                        ] else ...[
                          InkWell(
                            onTap: _pickLogo,
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                              ),
                              child: Icon(Icons.add_a_photo, color: theme.colorScheme.primary, size: 30),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add Club Logo (Optional)',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Club Name',
                      hintText: 'e.g. AI & Robotics Club',
                      prefixIcon: Icon(Icons.groups_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter a club name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: _categories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Club Description',
                      hintText: 'Describe the mission, activities, and goals of this club...',
                      prefixIcon: Icon(Icons.description_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text(
                      'Cross-Department Club',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Allow students from any department in the college to join.',
                    ),
                    value: _isCrossDepartment,
                    activeThumbColor: theme.colorScheme.primary,
                    onChanged: (val) => setState(() => _isCrossDepartment = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Submit Request'),
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
