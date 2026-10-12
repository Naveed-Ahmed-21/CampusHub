import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_loading_state.dart';
import '../../../../core/widgets/campus_error_state.dart';
import '../../../../core/widgets/campus_empty_state.dart';
import '../providers/dept_admin_provider.dart';
import '../../domain/models/dept_admin_models.dart';
import '../../data/repositories/dept_admin_repository.dart';

class DeptTimetableView extends ConsumerStatefulWidget {
  const DeptTimetableView({super.key});

  @override
  ConsumerState<DeptTimetableView> createState() => _DeptTimetableViewState();
}

class _DeptTimetableViewState extends ConsumerState<DeptTimetableView> {
  final List<String> _days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY'];

  @override
  Widget build(BuildContext context) {
    final activeDay = ref.watch(deptTimetableDayProvider);
    final timetableAsync = ref.watch(deptTimetableProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const CampusAppBar(
        title: 'Timetable Management',
        subtitle: 'Class Schedules & Conflict Detection',
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: isDark ? AppColors.electricBlue : AppColors.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Slot', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAddSlotDialog(context),
      ),
      body: AtmosphericBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Day Selector Pills
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                  itemCount: _days.length,
                  itemBuilder: (context, index) {
                    final day = _days[index];
                    final isSelected = activeDay == day;
                    final shortDay = day.substring(0, 3);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          ref.read(deptTimetableDayProvider.notifier).state = day;
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? AppColors.electricBlue : AppColors.primaryBlue)
                                : (isDark ? AppColors.darkSurface : Colors.white),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : (isDark ? AppColors.darkBorder : AppColors.border),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              shortDay,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? AppColors.darkText : AppColors.primaryText),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Slots Timeline
              Expanded(
                child: timetableAsync.when(
                  loading: () => const CampusLoadingState(),
                  error: (err, _) => CampusErrorState(
                    title: 'Error loading timetable',
                    message: err.toString(),
                    onRetry: () => ref.refresh(deptTimetableProvider),
                  ),
                  data: (slots) {
                    if (slots.isEmpty) {
                      return CampusEmptyState(
                        title: 'No Classes Scheduled',
                        description: 'No academic lecture or lab scheduled for $activeDay.',
                        icon: Icons.calendar_today_outlined,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => ref.refresh(deptTimetableProvider.future),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.s16),
                        itemCount: slots.length,
                        itemBuilder: (context, index) {
                          final slot = slots[index];
                          return _buildSlotTile(context, slot, isDark);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotTile(BuildContext context, DeptTimetableSlot slot, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CampusGlassCard(
        intensity: GlassIntensity.medium,
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Pillar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    slot.startTime,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                    ),
                  ),
                  const Text('to', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text(
                    slot.endTime,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s16),
            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          slot.subjectName,
                          style: AppTypography.cardTitle.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          slot.subjectCode,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Faculty: ${slot.facultyName}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.meeting_room_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(slot.room, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      const Icon(Icons.groups_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(slot.className, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSlotDialog(BuildContext context) {
    final academicsAsync = ref.read(deptAcademicsProvider);
    final facultyAsync = ref.read(deptFacultyProvider);

    final subjects = academicsAsync.value?.subjects ?? [];
    final classes = academicsAsync.value?.classes ?? [];
    final facultyList = facultyAsync.value ?? [];

    String? selectedSubjectId = subjects.isNotEmpty ? subjects.first.id : null;
    String? selectedFacultyId = facultyList.isNotEmpty ? facultyList.first.id : null;
    String? selectedClassId = classes.isNotEmpty ? classes.first.id : null;
    String startTime = '09:00';
    String endTime = '10:00';
    String activeDay = ref.read(deptTimetableDayProvider);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Timetable Slot'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedSubjectId,
                      decoration: const InputDecoration(labelText: 'Subject'),
                      items: subjects
                          .map((s) => DropdownMenuItem(value: s.id, child: Text('${s.code} - ${s.name}')))
                          .toList(),
                      onChanged: (val) => setDialogState(() => selectedSubjectId = val),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedFacultyId,
                      decoration: const InputDecoration(labelText: 'Faculty'),
                      items: facultyList
                          .map((f) => DropdownMenuItem(value: f.id, child: Text(f.name)))
                          .toList(),
                      onChanged: (val) => setDialogState(() => selectedFacultyId = val),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedClassId,
                      decoration: const InputDecoration(labelText: 'Class / Section'),
                      items: classes
                          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (val) => setDialogState(() => selectedClassId = val),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: startTime,
                            decoration: const InputDecoration(labelText: 'Start Time (HH:MM)'),
                            onChanged: (val) => startTime = val,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: endTime,
                            decoration: const InputDecoration(labelText: 'End Time (HH:MM)'),
                            onChanged: (val) => endTime = val,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedSubjectId == null || selectedFacultyId == null || selectedClassId == null) {
                      return;
                    }
                    try {
                      await ref.read(deptAdminRepositoryProvider).createTimetableSlot(
                            facultyId: selectedFacultyId!,
                            subjectId: selectedSubjectId!,
                            classId: selectedClassId!,
                            dayOfWeek: activeDay,
                            startTime: startTime,
                            endTime: endTime,
                          );
                      if (context.mounted) {
                        Navigator.of(dialogCtx).pop();
                        ref.invalidate(deptTimetableProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Timetable slot added successfully')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: const Text('Save Slot'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
