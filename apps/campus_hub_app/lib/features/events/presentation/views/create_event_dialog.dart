import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/events_repository.dart';
import '../providers/events_provider.dart';
import '../../../../core/services/media_picker_service.dart';
import '../../../../core/services/media_upload_service.dart';
import '../../../../shared/widgets/selected_media_preview_widget.dart';

class CreateEventDialog extends ConsumerStatefulWidget {
  const CreateEventDialog({super.key});

  @override
  ConsumerState<CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends ConsumerState<CreateEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _venueController = TextEditingController();
  final _capacityController = TextEditingController();

  String _scope = 'COLLEGE';
  String _category = 'Workshop';
  final DateTime _startTime = DateTime.now().add(const Duration(days: 1));
  final DateTime _endTime = DateTime.now().add(const Duration(days: 1, hours: 3));
  bool _isSubmitting = false;
  SelectedMediaFile? _bannerFile;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _venueController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickBanner() async {
    final file = await MediaPickerService.showMediaPickerSheet(
      context,
      title: 'Select Event Banner / Poster',
      enableCamera: true,
      enableGallery: true,
      enableVideoCamera: false,
      enableVideoGallery: false,
      enableDocuments: false,
    );
    if (file != null && mounted) {
      setState(() => _bannerFile = file);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      String? uploadedBannerUrl;

      if (_bannerFile != null) {
        final uploadService = ref.read(mediaUploadServiceProvider);
        final uploadResult = await uploadService.uploadSelectedFile(_bannerFile!);
        uploadedBannerUrl = uploadResult.url;
      }

      final repo = ref.read(eventsRepositoryProvider);
      await repo.createEvent(
        title: _titleController.text.trim(),
        scope: _scope,
        category: _category,
        startTime: _startTime.toUtc().toIso8601String(),
        endTime: _endTime.toUtc().toIso8601String(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        venue: _venueController.text.trim().isEmpty ? null : _venueController.text.trim(),
        bannerUrl: uploadedBannerUrl,
        maxCapacity: _capacityController.text.trim().isEmpty ? null : int.tryParse(_capacityController.text.trim()),
      );

      ref.invalidate(eventsListProvider);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create event: $e'), backgroundColor: Colors.red),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Create Campus Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 12),

              // Event Banner Picker
              if (_bannerFile != null) ...[
                SelectedMediaPreviewWidget(
                  file: _bannerFile!,
                  onRemove: () => setState(() => _bannerFile = null),
                ),
              ] else ...[
                InkWell(
                  onTap: _pickBanner,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 110,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, color: theme.colorScheme.primary, size: 32),
                        const SizedBox(height: 6),
                        Text(
                          'Add Event Banner / Poster from Device',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _scope,
                decoration: const InputDecoration(labelText: 'Event Scope', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'COLLEGE', child: Text('College-Wide Event')),
                  DropdownMenuItem(value: 'DEPARTMENT', child: Text('Department Event')),
                  DropdownMenuItem(value: 'CLUB', child: Text('Club Event')),
                ],
                onChanged: (val) => setState(() => _scope = val!),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Event Title', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().length < 3) ? 'Enter at least 3 characters' : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'Workshop', child: Text('Workshop')),
                  DropdownMenuItem(value: 'Hackathon', child: Text('Hackathon')),
                  DropdownMenuItem(value: 'Seminar', child: Text('Seminar')),
                  DropdownMenuItem(value: 'Cultural', child: Text('Cultural Fest')),
                  DropdownMenuItem(value: 'Sports', child: Text('Sports')),
                ],
                onChanged: (val) => setState(() => _category = val!),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _venueController,
                decoration: const InputDecoration(labelText: 'Venue / Location', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max Capacity (Optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Event'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
