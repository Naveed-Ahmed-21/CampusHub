import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/events_repository.dart';
import '../providers/events_provider.dart';

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
  final _bannerController = TextEditingController();
  final _capacityController = TextEditingController();

  String _scope = 'COLLEGE';
  String _category = 'Workshop';
  final DateTime _startTime = DateTime.now().add(const Duration(days: 1));
  final DateTime _endTime = DateTime.now().add(const Duration(days: 1, hours: 3));
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _venueController.dispose();
    _bannerController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(eventsRepositoryProvider);
      await repo.createEvent(
        title: _titleController.text.trim(),
        scope: _scope,
        category: _category,
        startTime: _startTime.toUtc().toIso8601String(),
        endTime: _endTime.toUtc().toIso8601String(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        venue: _venueController.text.trim().isEmpty ? null : _venueController.text.trim(),
        bannerUrl: _bannerController.text.trim().isEmpty ? null : _bannerController.text.trim(),
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
                  const Text('Create Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 12),

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
                    child: _isSubmitting ? const CircularProgressIndicator() : const Text('Create Event'),
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
