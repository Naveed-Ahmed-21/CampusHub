import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/campus_button.dart';
import '../../../../core/widgets/campus_text_field.dart';
import '../../data/repositories/dept_admin_repository.dart';
import '../../../feed/presentation/controllers/feed_controller.dart';

class DeptCreateAnnouncementView extends ConsumerStatefulWidget {
  const DeptCreateAnnouncementView({super.key});

  @override
  ConsumerState<DeptCreateAnnouncementView> createState() => _DeptCreateAnnouncementViewState();
}

class _DeptCreateAnnouncementViewState extends ConsumerState<DeptCreateAnnouncementView> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  int? _selectedYear;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _publishAnnouncement() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both title and content for the announcement')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(deptAdminRepositoryProvider).createAnnouncement(
            title: title,
            content: content,
            targetYear: _selectedYear,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ref.read(feedControllerProvider.notifier).refreshFeed();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement broadcasted to department students successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Publish Department Notice',
              style: AppTypography.cardTitle.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              'Broadcast official circular to IT department students',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 16),
            CampusTextField(
              controller: _titleController,
              label: 'Notice Title',
              hint: 'e.g. Internal Assessment 2 Timetable',
            ),
            const SizedBox(height: 12),
            CampusTextField(
              controller: _contentController,
              label: 'Notice Content',
              hint: 'Enter circular details and instructions...',
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _selectedYear,
              decoration: const InputDecoration(labelText: 'Target Audience'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All IT Students (1st - 4th Year)')),
                DropdownMenuItem(value: 4, child: Text('4th Year (Batch 2027)')),
                DropdownMenuItem(value: 3, child: Text('3rd Year (Batch 2028)')),
                DropdownMenuItem(value: 2, child: Text('2nd Year (Batch 2029)')),
                DropdownMenuItem(value: 1, child: Text('1st Year (Batch 2030)')),
              ],
              onChanged: (val) => setState(() => _selectedYear = val),
            ),
            const SizedBox(height: 20),
            CampusButton(
              label: _isLoading ? 'Publishing...' : 'Broadcast Notice',
              isLoading: _isLoading,
              onPressed: _publishAnnouncement,
            ),
          ],
        ),
      ),
    );
  }
}
