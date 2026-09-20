import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/responsive/responsive_layout.dart';
import '../../../../shared/widgets/async_value_widget.dart';
import '../controllers/faculty_controller.dart';
import '../../domain/models/faculty_models.dart';
import '../widgets/add_subject_dialog.dart';
import '../widgets/faculty_drawer_widget.dart';

class FacultyTeachingView extends ConsumerStatefulWidget {
  const FacultyTeachingView({super.key});

  @override
  ConsumerState<FacultyTeachingView> createState() =>
      _FacultyTeachingViewState();
}

class _FacultyTeachingViewState extends ConsumerState<FacultyTeachingView>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      drawer: const FacultyDrawerWidget(),
      appBar: AppBar(
        title: const Text(
          'Teaching Hub',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Add Subject',
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => const AddSubjectDialog(),
            ),
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
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book, size: 20), text: 'My Subjects'),
            Tab(icon: Icon(Icons.schedule, size: 20), text: 'Schedule'),
            Tab(
                icon: Icon(Icons.people_alt_outlined, size: 20),
                text: 'Mentoring'),
          ],
        ),
      ),
      body: ResponsiveLayout(
        mobile: TabBarView(
          controller: _tabController,
          children: [
            _buildSubjectsTab(context, ref, isDesktop: false),
            _buildScheduleTab(context, ref, isDesktop: false),
            _buildMentoringTab(context, ref, isDesktop: false),
          ],
        ),
        desktop: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSubjectsTab(context, ref, isDesktop: true),
                _buildScheduleTab(context, ref, isDesktop: true),
                _buildMentoringTab(context, ref, isDesktop: true),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => showDialog(
          context: context,
          builder: (ctx) => const AddSubjectDialog(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Subject'),
      ),
    );
  }

  Widget _buildTermAcademicHeader(
      BuildContext context, FacultyAcademicContext contextData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.shade800,
            Colors.teal.shade900,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.2),
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
                      '${contextData.academicYear} • ${contextData.termName}',
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
                  '${contextData.termType} SEMESTER',
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
            contextData.academicHeader,
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

  Widget _buildSubjectsTab(BuildContext context, WidgetRef ref,
      {required bool isDesktop}) {
    final academicContextAsync = ref.watch(facultyAcademicContextProvider);
    final subjectsAsync = ref.watch(facultySubjectsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(facultySubjectsProvider);
        ref.invalidate(facultyAcademicContextProvider);
      },
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.school_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                          'No assigned subjects for the current academic term'),
                      const SizedBox(height: 12),
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
                );
              }

              if (isDesktop) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.4,
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
    );
  }

  Widget _buildScheduleTab(BuildContext context, WidgetRef ref,
      {required bool isDesktop}) {
    final scheduleAsync = ref.watch(facultyScheduleProvider);
    final academicContextAsync = ref.watch(facultyAcademicContextProvider);

    final contextSlots = academicContextAsync.value?.todaySchedule ?? [];

    return AsyncValueWidget(
      value: scheduleAsync,
      data: (slots) {
        final displaySlots = slots.isNotEmpty ? slots : contextSlots;

        if (displaySlots.isEmpty) {
          return const Center(
              child: Text('No timetable slots scheduled for today'));
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
    );
  }

  Widget _buildMentoringTab(BuildContext context, WidgetRef ref,
      {required bool isDesktop}) {
    final menteesAsync = ref.watch(facultyMenteesProvider);
    final theme = Theme.of(context);

    return AsyncValueWidget(
      value: menteesAsync,
      data: (mentees) {
        if (mentees.isEmpty) {
          return Center(
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
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: student.avatarUrl != null &&
                              student.avatarUrl!.isNotEmpty
                          ? NetworkImage(
                              ApiEndpoints.resolveUrl(student.avatarUrl!))
                          : null,
                      onBackgroundImageError: student.avatarUrl != null &&
                              student.avatarUrl!.isNotEmpty
                          ? (_, __) {}
                          : null,
                      child: student.avatarUrl == null ||
                              student.avatarUrl!.isEmpty
                          ? Text(
                              student.name.isNotEmpty
                                  ? student.name[0].toUpperCase()
                                  : 'S',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            )
                          : null,
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
                          const Icon(Icons.person_outline, color: Colors.teal),
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
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
                    ),
                  ),
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
                                    size: 18, color: Colors.teal),
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
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_outline,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${subject.studentsCount} Students',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.folder_copy_outlined,
                          size: 16, color: Colors.teal),
                      const SizedBox(width: 4),
                      Text('${subject.resourcesCount} Notes',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.teal)),
                    ],
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
