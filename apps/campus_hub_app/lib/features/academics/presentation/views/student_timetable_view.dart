import '../../../../core/widgets/campus_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_empty_state.dart';
import '../../../../core/widgets/campus_button.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../shared/responsive/responsive_layout.dart';
import '../../../../shared/widgets/async_value_widget.dart';
import '../../../chat/data/chat_repository.dart';
import '../controllers/academics_controller.dart';
import '../../domain/models/academic_models.dart';

class StudentTimetableView extends ConsumerStatefulWidget {
  const StudentTimetableView({super.key});

  @override
  ConsumerState<StudentTimetableView> createState() =>
      _StudentTimetableViewState();
}

class _StudentTimetableViewState extends ConsumerState<StudentTimetableView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedDay = 'ALL';

  final List<String> _days = [
    'ALL',
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _messageFaculty(
      BuildContext context, String facultyId, String facultyName) async {
    try {
      final chatRepo = ref.read(chatRepositoryProvider);
      final room = await chatRepo.getOrCreateDirectChat(facultyId);
      if (context.mounted) {
        context.push('/chat/room/${room.id}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect with $facultyName: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: const CampusAppBar(
        leading: CampusBackButton(),
        title: 'Academic Timetable',
        subtitle: 'Lecture Schedules & Class Venues',
      ),
      body: AtmosphericBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Container(
                height: 46,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.4),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: isDark ? Colors.black : Colors.white,
                  unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.today_outlined, size: 16),
                          SizedBox(width: 8),
                          Text("Today's Classes"),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.date_range_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Weekly Agenda'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            ),
            Expanded(
              child: ResponsiveLayout(
                mobile: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTodayView(context),
                    _buildWeeklyView(context),
                  ],
                ),
                desktop: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTodayView(context),
                        _buildWeeklyView(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayView(BuildContext context) {
    final todayAsync = ref.watch(studentTodayTimetableProvider);

    return AsyncValueWidget<List<StudentTimetableSlot>>(
      value: todayAsync,
      data: (slots) {
        if (slots.isEmpty) {
          return Center(
            child: Padding(
              padding: AppSpacing.p24,
              child: CampusEmptyState(
                icon: Icons.event_available_outlined,
                title: 'No Classes Scheduled for Today',
                description: 'Enjoy your break or explore course resources and assignments in Academics.',
                actionLabel: 'Go to My Subjects',
                onAction: () => context.push('/academics'),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: slots.length,
          itemBuilder: (context, index) =>
              _buildSlotCard(context, slots[index]),
        );
      },
    );
  }

  Widget _buildWeeklyView(BuildContext context) {
    final weekAsync = ref.watch(studentTimetableProvider);

    return Column(
      children: [
        Container(
          height: 50,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final day = _days[idx];
              final isSelected = _selectedDay == day;

              return ChoiceChip(
                label: Text(day == 'ALL' ? 'All Days' : day.substring(0, 3)),
                selected: isSelected,
                selectedColor: Colors.teal.shade700,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) {
                  setState(() => _selectedDay = day);
                },
              );
            },
          ),
        ),
        Expanded(
          child: AsyncValueWidget<List<StudentTimetableSlot>>(
            value: weekAsync,
            data: (slots) {
              final filtered = _selectedDay == 'ALL'
                  ? slots
                  : slots
                      .where((s) => s.dayOfWeek.toUpperCase() == _selectedDay)
                      .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month,
                            size: 50, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No classes scheduled for $_selectedDay',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) =>
                    _buildSlotCard(context, filtered[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openSessionDetails(BuildContext context, StudentTimetableSlot slot) {
    final theme = Theme.of(context);
    final isLab = slot.sessionType.toUpperCase() == 'LAB';
    final isPlacement = slot.sessionType.toUpperCase() == 'PLACEMENT';
    Color typeColor = Colors.teal;
    if (isLab) typeColor = Colors.purple;
    if (isPlacement) typeColor = Colors.orange.shade800;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      slot.sessionType,
                      style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${slot.startTime} - ${slot.endTime}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.teal),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                slot.subjectName,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                '${slot.subjectCode} • ${slot.roomOrVenue.isNotEmpty ? slot.roomOrVenue : 'Lecture Hall'} • ${slot.dayOfWeek}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              if (slot.topic != null && slot.topic!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lecture Topic: ${slot.topic}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CampusAvatar(
                      imageUrl: slot.facultyAvatarUrl,
                      name: slot.facultyName,
                      radius: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slot.facultyName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const Text(
                            'Course Instructor',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (slot.facultyId != null)
                      FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _messageFaculty(
                              context, slot.facultyId!, slot.facultyName);
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: const Text('Chat'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (slot.subjectId != null)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/academics/subjects/${slot.subjectId}');
                    },
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open Subject Workspace & Materials'),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotCard(BuildContext context, StudentTimetableSlot slot) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLab = slot.sessionType.toUpperCase() == 'LAB';
    final isPlacement = slot.sessionType.toUpperCase() == 'PLACEMENT';

    Color typeColor = isDark ? AppColors.secondaryCyan : AppColors.primaryBlue;
    if (isLab) typeColor = Colors.purple;
    if (isPlacement) typeColor = AppColors.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: CampusGlassCard(
        intensity: GlassIntensity.subtle,
        padding: AppSpacing.p16,
        onTap: () => _openSessionDetails(context, slot),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14, color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue),
                      const SizedBox(width: 5),
                      Text(
                        '${slot.startTime} - ${slot.endTime}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    slot.sessionType,
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              slot.subjectName,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 2),
            Text(
              slot.subjectCode,
              style: TextStyle(
                  color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
            if (slot.topic != null && slot.topic!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        size: 14, color: Colors.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Topic: ${slot.topic}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 15, color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    slot.roomOrVenue.isNotEmpty
                        ? slot.roomOrVenue
                        : 'Lecture Hall',
                    style: TextStyle(
                        color: isDark ? AppColors.darkText : AppColors.primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
                const SizedBox(width: 4),
                Text(
                  slot.dayOfWeek,
                  style: TextStyle(color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                CampusAvatar(
                  imageUrl: slot.facultyAvatarUrl,
                  name: slot.facultyName,
                  radius: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    slot.facultyName,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (slot.facultyId != null)
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Message Faculty',
                    onPressed: () => _messageFaculty(
                        context, slot.facultyId!, slot.facultyName),
                  ),
                if (slot.subjectId != null)
                  CampusButton(
                    height: 32,
                    label: 'Open',
                    type: CampusButtonType.secondary,
                    onPressed: () =>
                        context.push('/academics/subjects/${slot.subjectId}'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
