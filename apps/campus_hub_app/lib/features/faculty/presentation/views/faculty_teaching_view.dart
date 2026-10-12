import '../../../../core/widgets/campus_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/async_value_widget.dart';
import '../controllers/faculty_controller.dart';
import '../../domain/models/faculty_models.dart';
import '../widgets/add_subject_dialog.dart';
import '../widgets/add_edit_schedule_slot_dialog.dart';
import '../widgets/faculty_drawer_widget.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/widgets/campus_segmented_control.dart';
import '../../../../core/theme/app_colors.dart';

class FacultyTeachingView extends ConsumerStatefulWidget {
  const FacultyTeachingView({super.key});

  @override
  ConsumerState<FacultyTeachingView> createState() =>
      _FacultyTeachingViewState();
}

class _FacultyTeachingViewState extends ConsumerState<FacultyTeachingView>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging &&
          _selectedTabIndex != _tabController.index) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onPrimaryAction() {
    if (_selectedTabIndex == 0) {
      showDialog(
        context: context,
        builder: (ctx) => const AddSubjectDialog(),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => const AddEditScheduleSlotDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      drawer: const FacultyDrawerWidget(),
      appBar: CampusAppBar(
        title: 'Teaching Hub',
        subtitle: _selectedTabIndex == 0
            ? 'My Subjects'
            : _selectedTabIndex == 1
                ? 'Weekly Schedule'
                : 'Student Mentoring',
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Open Drawer',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _selectedTabIndex == 0
                  ? Icons.add_box_outlined
                  : Icons.more_time_rounded,
            ),
            tooltip:
                _selectedTabIndex == 0 ? 'Add Subject' : 'Add Schedule',
            onPressed: _onPrimaryAction,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(facultySubjectsProvider);
              ref.invalidate(facultyAcademicContextProvider);
              ref.invalidate(facultyScheduleProvider);
              ref.invalidate(facultyMenteesProvider);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: CampusSegmentedControl(
              height: 38,
              selectedIndex: _selectedTabIndex,
              items: const [
                CampusSegmentItem(label: 'Subjects'),
                CampusSegmentItem(label: 'Schedule'),
                CampusSegmentItem(label: 'Mentoring'),
              ],
              onValueChanged: (index) {
                setState(() {
                  _selectedTabIndex = index;
                });
                _tabController.animateTo(index);
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSubjectsTab(context, ref),
                _buildScheduleTab(context, ref),
                _buildMentoringTab(context, ref),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _onPrimaryAction,
        icon: Icon(
          _selectedTabIndex == 0 ? Icons.add : Icons.add_alarm_outlined,
        ),
        label: Text(
          _selectedTabIndex == 0 ? 'Add Subject' : 'Add Schedule',
        ),
      ),
    );
  }

  Widget _buildTermAcademicHeader(
      BuildContext context, FacultyAcademicContext contextData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryNavy,
            Color(0xFF1E3A5F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      contextData.academicYear,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${contextData.termType.toUpperCase()} SEMESTER',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${contextData.academicYear} • ${contextData.termType.toUpperCase()} Semester | My Teaching',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.2,
            ),
          ),
          if (contextData.classes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: contextData.classes.map((cls) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${cls.semester} (Sec ${cls.section}): ${cls.studentCount} student${cls.studentCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubjectsTab(BuildContext context, WidgetRef ref) {
    final academicContextAsync = ref.watch(facultyAcademicContextProvider);
    final subjectsAsync = ref.watch(facultySubjectsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(facultySubjectsProvider);
        ref.invalidate(facultyAcademicContextProvider);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 768;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Dynamic Term-Driven Header
                  academicContextAsync.when(
                    data: (ctxData) => _buildTermAcademicHeader(context, ctxData),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  // Subjects Section
                  subjectsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text('Error loading subjects: $err'),
                      ),
                    ),
                    data: (subjects) {
                      final displaySubjects = subjects.isNotEmpty
                          ? subjects
                          : (academicContextAsync.value?.assignedSubjects ?? []);

                      if (displaySubjects.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.school_outlined,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  'No assigned subjects for the current academic term',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: () => showDialog(
                                    context: context,
                                    builder: (ctx) => const AddSubjectDialog(),
                                  ),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Your First Subject'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (isDesktop) {
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 420,
                            mainAxisExtent: 210,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: displaySubjects.length,
                          itemBuilder: (context, index) {
                            final subject = displaySubjects[index];
                            return _SubjectCard(subject: subject);
                          },
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displaySubjects.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final subject = displaySubjects[index];
                          return _SubjectCard(subject: subject);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleTab(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(facultyScheduleProvider);
    final academicContextAsync = ref.watch(facultyAcademicContextProvider);

    final contextSlots = academicContextAsync.value?.todaySchedule ?? [];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: AsyncValueWidget(
          value: scheduleAsync,
          data: (slots) {
            final displaySlots = slots.isNotEmpty ? slots : contextSlots;

            if (displaySlots.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No timetable slots scheduled for today',
                          style: TextStyle(color: Colors.grey, fontSize: 15)),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: displaySlots.length,
              itemBuilder: (context, index) {
                final slot = displaySlots[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        slot.subjectCode,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                    title: Text(slot.subjectName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${slot.semester} • Section ${slot.section}\n📍 ${slot.roomOrVenue}'),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          slot.startTime,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        Text(slot.endTime,
                            style:
                                const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMentoringTab(BuildContext context, WidgetRef ref) {
    final menteesAsync = ref.watch(facultyMenteesProvider);
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: AsyncValueWidget(
          value: menteesAsync,
          data: (mentees) {
            if (mentees.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No student mentees assigned yet.',
                        style:
                            theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: mentees.length,
          itemBuilder: (context, index) {
            final student = mentees[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    CampusAvatar(
                      imageUrl: student.avatarUrl,
                      name: student.name,
                      radius: 24,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${student.rollNumber} • ${student.department} • ${student.semester}',
                            style: TextStyle(
                                color: theme.colorScheme.outline, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.person_outline, color: AppColors.primaryBlue),
                      tooltip: 'View Profile',
                      onPressed: () => context.push('/profile/${student.id}'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline,
                          color: Colors.blue),
                      tooltip: 'Message Mentee',
                      onPressed: () => context.go('/chat'),
                    ),
                  ],
                ),
              ),
              );
            },
          );
        },
      ),
    ),
  );
}
}

class _SubjectCard extends ConsumerWidget {
  final FacultySubject subject;

  const _SubjectCard({required this.subject});

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject?'),
        content: Text(
          'Are you sure you want to delete ${subject.code} - ${subject.name}? This will remove all materials, units, and announcements linked to this subject.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final ok = await ref
                  .read(facultyControllerProvider.notifier)
                  .deleteSubject(subject.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: ok ? Colors.teal.shade700 : Colors.red,
                    content: Text(ok
                        ? 'Subject deleted successfully'
                        : 'Failed to delete subject'),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        onTap: () => context.push('/teaching/subjects/${subject.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        subject.code,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${subject.credits} Credits',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert,
                            size: 18, color: Colors.grey),
                        padding: EdgeInsets.zero,
                        onSelected: (val) {
                          if (val == 'edit') {
                            showDialog(
                              context: context,
                              builder: (ctx) =>
                                  AddSubjectDialog(subjectToEdit: subject),
                            );
                          } else if (val == 'delete') {
                            _confirmDelete(context, ref);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined,
                                    size: 18, color: AppColors.primaryBlue),
                                SizedBox(width: 8),
                                Text('Edit Subject'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete Subject',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subject.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${subject.semester} • Section ${subject.section}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.people_outline,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${subject.studentsCount} Students',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.folder_copy_outlined,
                            size: 16, color: AppColors.primaryBlue),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${subject.resourcesCount} Notes',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.primaryBlue),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
