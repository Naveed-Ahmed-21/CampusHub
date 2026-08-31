import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/responsive/responsive_layout.dart';
import '../../../../shared/widgets/async_value_widget.dart';
import '../controllers/faculty_controller.dart';
import '../../domain/models/faculty_models.dart';
import '../widgets/add_subject_dialog.dart';

class FacultyTeachingView extends ConsumerStatefulWidget {
  const FacultyTeachingView({super.key});

  @override
  ConsumerState<FacultyTeachingView> createState() => _FacultyTeachingViewState();
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
            Tab(icon: Icon(Icons.people_alt_outlined, size: 20), text: 'Mentoring'),
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

  Widget _buildSubjectsTab(BuildContext context, WidgetRef ref, {required bool isDesktop}) {
    final subjectsAsync = ref.watch(facultySubjectsProvider);

    return AsyncValueWidget(
      value: subjectsAsync,
      data: (subjects) {
        if (subjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No assigned subjects yet'),
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

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 3 : 1,
            childAspectRatio: isDesktop ? 1.4 : 2.0,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final subject = subjects[index];
            return _SubjectCard(subject: subject);
          },
        );
      },
    );
  }

  Widget _buildScheduleTab(BuildContext context, WidgetRef ref, {required bool isDesktop}) {
    final scheduleAsync = ref.watch(facultyScheduleProvider);

    return AsyncValueWidget(
      value: scheduleAsync,
      data: (slots) {
        if (slots.isEmpty) {
          return const Center(child: Text('No timetable slots available'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: slots.length,
          itemBuilder: (context, index) {
            final slot = slots[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    slot.subjectCode,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
                title: Text(slot.subjectName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${slot.semester} • Section ${slot.section}\n📍 ${slot.roomOrVenue}'),
                isThreeLine: true,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      slot.startTime,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    Text(slot.endTime, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMentoringTab(BuildContext context, WidgetRef ref, {required bool isDesktop}) {
    final menteesAsync = ref.watch(facultyMenteesProvider);

    return AsyncValueWidget(
      value: menteesAsync,
      data: (mentees) {
        if (mentees.isEmpty) {
          return const Center(child: Text('No student mentees assigned yet'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: mentees.length,
          itemBuilder: (context, index) {
            final student = mentees[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: student.avatarUrl != null
                          ? NetworkImage(student.avatarUrl!)
                          : null,
                      child: student.avatarUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                student.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'CGPA: ${student.cgpa}',
                                  style: const TextStyle(
                                    color: Colors.teal,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${student.rollNumber} • ${student.department} • ${student.semester}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
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

class _SubjectCard extends StatelessWidget {
  final FacultySubject subject;

  const _SubjectCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${subject.credits} Credits',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
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
                      const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${subject.studentsCount} Students', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.folder_copy_outlined, size: 16, color: Colors.teal),
                      const SizedBox(width: 4),
                      Text('${subject.resourcesCount} Notes', style: const TextStyle(fontSize: 12, color: Colors.teal)),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
