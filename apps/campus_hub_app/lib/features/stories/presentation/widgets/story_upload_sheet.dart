import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/media_picker_service.dart';
import '../../../../core/services/media_upload_service.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/selected_media_preview_widget.dart';
import '../providers/stories_provider.dart';

class StoryUploadSheet extends ConsumerStatefulWidget {
  const StoryUploadSheet({super.key});

  @override
  ConsumerState<StoryUploadSheet> createState() => _StoryUploadSheetState();
}

class _StoryUploadSheetState extends ConsumerState<StoryUploadSheet> {
  final TextEditingController _captionController = TextEditingController();
  SelectedMediaFile? _selectedFile;
  int _storyDurationSeconds = 5;
  bool _isUploading = false;
  double? _uploadProgress;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromCamera() async {
    final file = await MediaPickerService.pickImageFromCamera();
    if (file != null && mounted) {
      setState(() => _selectedFile = file);
    }
  }

  Future<void> _pickImageFromGallery() async {
    final file = await MediaPickerService.pickImageFromGallery();
    if (file != null && mounted) {
      setState(() => _selectedFile = file);
    }
  }

  Future<void> _recordVideo() async {
    final file = await MediaPickerService.recordVideo();
    if (file != null && mounted) {
      setState(() {
        _selectedFile = file;
        _storyDurationSeconds = 15;
      });
    }
  }

  Future<void> _pickVideoFromGallery() async {
    final file = await MediaPickerService.pickVideoFromGallery();
    if (file != null && mounted) {
      setState(() {
        _selectedFile = file;
        _storyDurationSeconds = 15;
      });
    }
  }

  Future<void> _handleUpload() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a photo or select a video from your device.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final uploadService = ref.read(mediaUploadServiceProvider);
      final uploadResult = await uploadService.uploadSelectedFile(
        _selectedFile!,
        onProgress: (sent, total) {
          if (total > 0 && mounted) {
            setState(() => _uploadProgress = sent / total);
          }
        },
      );

      await ref.read(storiesControllerProvider.notifier).createStory(
            mediaUrl: uploadResult.url,
            mediaType: _selectedFile!.isVideo ? 'VIDEO' : 'IMAGE',
            caption: _captionController.text.trim().isNotEmpty
                ? _captionController.text.trim()
                : null,
            duration: _storyDurationSeconds,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Your 24-Hour Story is now live!'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post story: $e'),
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
              // Drag Handle
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

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_stories, color: theme.colorScheme.primary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Add 24h Story',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable Body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_selectedFile == null) ...[
                      Text(
                        'Select Media from Your Device',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Share memorable campus moments with your batch and college. Stories automatically expire after 24 hours.',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 20),

                      // Device Selection Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildPickerCard(
                              icon: Icons.camera_alt,
                              color: Colors.blue,
                              title: 'Take Photo',
                              subtitle: 'Capture with Camera',
                              onTap: _pickImageFromCamera,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPickerCard(
                              icon: Icons.photo_library,
                              color: Colors.purple,
                              title: 'Photo Gallery',
                              subtitle: 'Pick from Album',
                              onTap: _pickImageFromGallery,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPickerCard(
                              icon: Icons.videocam,
                              color: Colors.red,
                              title: 'Record Video',
                              subtitle: 'Live Camera Clip',
                              onTap: _recordVideo,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPickerCard(
                              icon: Icons.video_library,
                              color: Colors.orange,
                              title: 'Video Gallery',
                              subtitle: 'Select from Videos',
                              onTap: _pickVideoFromGallery,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Media Selected Preview
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Story Preview',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _isUploading
                                ? null
                                : () => setState(() => _selectedFile = null),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Change Media', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      SelectedMediaPreviewWidget(
                        file: _selectedFile!,
                        isUploading: _isUploading,
                        uploadProgress: _uploadProgress,
                        onRemove: _isUploading ? null : () => setState(() => _selectedFile = null),
                      ),
                      const SizedBox(height: 16),

                      // Caption
                      CustomTextField(
                        controller: _captionController,
                        label: 'Story Caption (Optional)',
                        hintText: 'Add a message, tag, or context...',
                      ),
                      const SizedBox(height: 16),

                      // Duration Selector (for images)
                      if (!_selectedFile!.isVideo) ...[
                        Row(
                          children: [
                            const Text(
                              'Display Duration:',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 12),
                            ...[5, 10, 15].map((sec) {
                              final isSelected = _storyDurationSeconds == sec;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text('${sec}s'),
                                  selected: isSelected,
                                  onSelected: _isUploading
                                      ? null
                                      : (_) => setState(() => _storyDurationSeconds = sec),
                                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                                  labelStyle: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Publish Button
                      CustomButton(
                        label: _isUploading ? 'Publishing Story...' : 'Publish Story',
                        isLoading: _isUploading,
                        icon: Icons.send,
                        onPressed: _isUploading ? null : _handleUpload,
                      ),
                    ],
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

  Widget _buildPickerCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
