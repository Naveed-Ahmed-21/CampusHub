import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/media_picker_service.dart';
import '../../../../core/services/media_upload_service.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/selected_media_preview_widget.dart';
import '../controllers/feed_controller.dart';

class CreatePostSheet extends ConsumerStatefulWidget {
  final String? clubId;
  final String? clubName;

  const CreatePostSheet({
    super.key,
    this.clubId,
    this.clubName,
  });

  @override
  ConsumerState<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<CreatePostSheet> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _contentCtrl = TextEditingController();

  String _selectedType = 'GENERAL';
  bool _isSubmitting = false;
  double? _uploadProgress;
  String _uploadStatusText = '';

  final List<SelectedMediaFile> _selectedFiles = [];

  final List<Map<String, String>> _postCategories = [
    {'value': 'GENERAL', 'label': 'General'},
    {'value': 'ANNOUNCEMENT', 'label': 'Announcement'},
    {'value': 'ACADEMIC', 'label': 'Academic'},
    {'value': 'EVENT_PROMO', 'label': 'Event Promo'},
    {'value': 'PLACEMENT', 'label': 'Placement'},
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromCamera() async {
    final file = await MediaPickerService.pickImageFromCamera();
    if (file != null && mounted) {
      setState(() => _selectedFiles.add(file));
    }
  }

  Future<void> _pickFromGallery() async {
    final files = await MediaPickerService.pickMultipleImages();
    if (files.isNotEmpty && mounted) {
      setState(() => _selectedFiles.addAll(files));
    }
  }

  Future<void> _recordVideo() async {
    final file = await MediaPickerService.recordVideo();
    if (file != null && mounted) {
      setState(() => _selectedFiles.add(file));
    }
  }

  Future<void> _pickVideoFromGallery() async {
    final file = await MediaPickerService.pickVideoFromGallery();
    if (file != null && mounted) {
      setState(() => _selectedFiles.add(file));
    }
  }

  Future<void> _pickDocuments() async {
    final files = await MediaPickerService.pickDocuments(
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt', 'zip'],
      allowMultiple: true,
    );
    if (files.isNotEmpty && mounted) {
      setState(() => _selectedFiles.addAll(files));
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    if (title.isEmpty && content.isEmpty && _selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some text, photo, video, or document to your post.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0.0;
      _uploadStatusText = _selectedFiles.isNotEmpty ? 'Uploading media...' : 'Publishing post...';
    });

    try {
      final List<Map<String, String>> uploadedAttachments = [];

      if (_selectedFiles.isNotEmpty) {
        final uploadService = ref.read(mediaUploadServiceProvider);

        for (int i = 0; i < _selectedFiles.length; i++) {
          final file = _selectedFiles[i];
          setState(() {
            _uploadStatusText = 'Uploading ${file.name} (${i + 1}/${_selectedFiles.length})...';
            _uploadProgress = (i + 1) / _selectedFiles.length;
          });

          final uploadedResult = await uploadService.uploadSelectedFile(file);
          uploadedAttachments.add({
            'fileName': uploadedResult.fileName,
            'fileUrl': uploadedResult.url,
            'fileType': uploadedResult.fileType,
          });
        }
      }

      setState(() {
        _uploadStatusText = 'Publishing post to feed...';
      });

      String effectiveTitle = title.isNotEmpty
          ? title
          : (content.isNotEmpty
              ? (content.length > 35 ? '${content.substring(0, 35)}...' : content)
              : (_selectedFiles.isNotEmpty ? _selectedFiles.first.name : 'New Post'));
      if (effectiveTitle.trim().length < 2) effectiveTitle = 'New Post';

      String effectiveContent = content.isNotEmpty ? content : effectiveTitle;
      if (effectiveContent.trim().length < 5) effectiveContent = '$effectiveTitle - Shared via CampusHub';

      final validTypes = ['ANNOUNCEMENT', 'GENERAL', 'ACADEMIC', 'EVENT_PROMO', 'PLACEMENT'];
      final effectiveType = validTypes.contains(_selectedType) ? _selectedType : 'GENERAL';

      await ref.read(feedControllerProvider.notifier).createPost(
            title: effectiveTitle.trim(),
            content: effectiveContent.trim(),
            type: effectiveType,
            clubId: widget.clubId,
            attachments: uploadedAttachments.isNotEmpty ? uploadedAttachments : null,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(widget.clubId != null
                    ? 'Post published to ${widget.clubName ?? 'Club'} feed!'
                    : 'Post published successfully to feed!'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish post: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Sheet Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),

              // Sheet Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.clubName != null ? 'Create Club Post' : 'Create Post',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (widget.clubName != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Posting to: ${widget.clubName}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Body Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Post Category / Type Selector
                    Text(
                      'Post Category',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _postCategories.map((type) {
                          final isSelected = _selectedType == type['value'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(type['label']!),
                              selected: isSelected,
                              onSelected: _isSubmitting
                                  ? null
                                  : (_) {
                                      setState(() => _selectedType = type['value']!);
                                    },
                              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                              checkmarkColor: theme.colorScheme.primary,
                              labelStyle: TextStyle(
                                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    CustomTextField(
                      controller: _titleCtrl,
                      label: 'Post Title',
                      hintText: 'What would you like to share or announce?',
                    ),
                    const SizedBox(height: 16),

                    // Content
                    CustomTextField(
                      controller: _contentCtrl,
                      label: 'Post Description / Details',
                      hintText: 'Write your thoughts, questions, or details here...',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 20),

                    // Media Selection Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add to Your Post',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        if (_selectedFiles.isNotEmpty)
                          Text(
                            '${_selectedFiles.length} item(s) selected',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Action buttons grid
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildMediaOptionButton(
                          icon: Icons.camera_alt,
                          color: Colors.blue,
                          label: 'Camera',
                          onTap: _isSubmitting ? null : _pickFromCamera,
                        ),
                        _buildMediaOptionButton(
                          icon: Icons.photo_library,
                          color: Colors.purple,
                          label: 'Gallery',
                          onTap: _isSubmitting ? null : _pickFromGallery,
                        ),
                        _buildMediaOptionButton(
                          icon: Icons.videocam,
                          color: Colors.red,
                          label: 'Record Video',
                          onTap: _isSubmitting ? null : _recordVideo,
                        ),
                        _buildMediaOptionButton(
                          icon: Icons.video_library,
                          color: Colors.orange,
                          label: 'Video',
                          onTap: _isSubmitting ? null : _pickVideoFromGallery,
                        ),
                        _buildMediaOptionButton(
                          icon: Icons.insert_drive_file,
                          color: Colors.teal,
                          label: 'Document',
                          onTap: _isSubmitting ? null : _pickDocuments,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Selected Media Previews
                    if (_selectedFiles.isNotEmpty) ...[
                      const Text(
                        'Attached Media & Files Preview:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ..._selectedFiles.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final file = entry.value;
                        return SelectedMediaPreviewWidget(
                          file: file,
                          isUploading: _isSubmitting,
                          uploadProgress: _uploadProgress,
                          onRemove: _isSubmitting ? null : () => _removeFile(idx),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],

                    if (_isSubmitting) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _uploadStatusText,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Publish Button
                    CustomButton(
                      label: _isSubmitting ? 'Publishing Post...' : 'Publish Post',
                      isLoading: _isSubmitting,
                      icon: Icons.send,
                      onPressed: _isSubmitting ? null : _handleSubmit,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaOptionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.onSurface
                    : (color is MaterialColor ? color.shade900 : color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
