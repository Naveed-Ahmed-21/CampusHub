import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/responsive/responsive_layout.dart';
import '../../../../shared/widgets/async_value_widget.dart';
import '../controllers/academics_controller.dart';
import '../../domain/models/academic_models.dart';
import '../../../feed/presentation/widgets/student_drawer_widget.dart';
import '../../../faculty/presentation/widgets/faculty_drawer_widget.dart';
import '../../../faculty/presentation/widgets/add_subject_dialog.dart';
import '../../../faculty/domain/models/faculty_models.dart';
import '../../../faculty/presentation/controllers/faculty_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class StudentSubjectsView extends ConsumerStatefulWidget {
  const StudentSubjectsView({super.key});

  @override
  ConsumerState<StudentSubjectsView> createState() =>
      _StudentSubjectsViewState();
}

class _StudentSubjectsViewState extends ConsumerState<StudentSubjectsView> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _semesters = [
    'All Semesters',
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
    'Semester 5',
    'Semester 6',
    'Semester 7',
    'Semester 8',
  ];

  final List<String> _sections = [
    'All Sections',
    'Section A',
    'Section B',
    'Section C',
    'Section D',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDeleteSubject(
      BuildContext context, AcademicSubjectModel subject) {
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
                ref.invalidate(academicSubjectsProvider);
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
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    final subjectsAsync = ref.watch(academicSubjectsProvider);
    final filter = ref.watch(academicFilterProvider);

    final user = ref.watch(authControllerProvider).asData?.value;
    final isFaculty = user?.isFaculty == true;

    return Scaffold(
      drawer:
          isFaculty ? const FacultyDrawerWidget() : const StudentDrawerWidget(),
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school, color: Colors.blue, size: 20),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Academic Subjects',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: 'Class Timetable',
            onPressed: () => context.push('/academics/timetable'),
          ),
          IconButton(
            icon: const Icon(Icons.badge_outlined),
            tooltip: 'Faculty Directory',
            onPressed: () => context.push('/academics/faculty'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(academicSubjectsProvider);
              ref.invalidate(academicContextProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ResponsiveLayout(
        mobile: _buildBody(context, ref, subjectsAsync, filter,
            isFaculty: isFaculty, isDesktop: false),
        desktop: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: _buildBody(context, ref, subjectsAsync, filter,
                isFaculty: isFaculty, isDesktop: true),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<AcademicSubjectModel>> subjectsAsync,
    AcademicFilterState filter, {
    required bool isFaculty,
    required bool isDesktop,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search & Discovery Header
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText:
                      'Search by Subject Code (e.g. CS335), Name, or Topic...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(academicFilterProvider.notifier)
                                .setQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  ref.read(academicFilterProvider.notifier).setQuery(val);
                },
              ),
              const SizedBox(height: 10),

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Only Enrolled Toggle Chip
                    FilterChip(
                      selected: filter.onlyEnrolled,
                      avatar: Icon(
                        filter.onlyEnrolled
                            ? Icons.check_circle
                            : Icons.bookmark_border,
                        size: 16,
                        color: filter.onlyEnrolled ? Colors.white : Colors.blue,
                      ),
                      label: const Text('My Enrolled Subjects'),
                      selectedColor: Colors.blue,
                      labelStyle: TextStyle(
                        color: filter.onlyEnrolled ? Colors.white : null,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (_) {
                        ref
                            .read(academicFilterProvider.notifier)
                            .toggleOnlyEnrolled();
                      },
                    ),
                    const SizedBox(width: 8),

                    // Semester Dropdown / Chips
                    ..._semesters.map((sem) {
                      final isSelected = sem == 'All Semesters'
                          ? filter.semester == null
                          : filter.semester == sem;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          label:
                              Text(sem, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              ref
                                  .read(academicFilterProvider.notifier)
                                  .setSemester(
                                    sem == 'All Semesters' ? null : sem,
                                  );
                            }
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Section Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Text(
                        'Section:',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                    ),
                    ..._sections.map((sec) {
                      final cleanSec = sec == 'All Sections'
                          ? null
                          : sec.replaceAll('Section ', '').trim();
                      final isSelected = sec == 'All Sections'
                          ? filter.section == null
                          : (filter.section == sec ||
                              filter.section == cleanSec);
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          label:
                              Text(sec, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              ref
                                  .read(academicFilterProvider.notifier)
                                  .setSection(cleanSec);
                            }
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Subjects List
        Expanded(
          child: AsyncValueWidget<List<AcademicSubjectModel>>(
            value: subjectsAsync,
            data: (subjects) {
              if (subjects.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No subjects match your search',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Try searching with course code "CS335", "Cloud Computing", or clear filters.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            _searchController.clear();
                            ref.read(academicFilterProvider.notifier).reset();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset All Filters'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(academicSubjectsProvider);
                  ref.invalidate(academicContextProvider);
                  if (!isFaculty) {
                    ref.invalidate(studentPendingAssignmentsProvider);
                    ref.invalidate(studentAssessmentsSummaryProvider);
                    ref.invalidate(studentTodayTimetableProvider);
                  }
                },
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 16,
                    vertical: 16,
                  ),
                  itemCount: subjects.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildAcademicsSummaryHeader(context, ref,
                          isFaculty: isFaculty, isDesktop: isDesktop);
                    }
                    final subject = subjects[index - 1];
                    return _buildSubjectCard(context, subject,
                        isFaculty: isFaculty);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectCard(BuildContext context, AcademicSubjectModel subject,
      {required bool isFaculty}) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: subject.isEnrolled
              ? Colors.blue.withValues(alpha: 0.3)
              : Colors.grey.shade200,
          width: subject.isEnrolled ? 1.5 : 1.0,
        ),
      ),
      elevation: subject.isEnrolled ? 2 : 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.push('/academics/subjects/${subject.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Code Badge + Enrolled Badge + Credits + Faculty Menu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          subject.code,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (subject.isEnrolled) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Enrolled',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${subject.credits} Credits',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      if (isFaculty) ...[
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert,
                              size: 18, color: Colors.grey),
                          padding: EdgeInsets.zero,
                          onSelected: (val) {
                            if (val == 'edit') {
                              showDialog(
                                context: context,
                                builder: (ctx) => AddSubjectDialog(
                                  subjectToEdit: FacultySubject(
                                    id: subject.id,
                                    code: subject.code,
                                    name: subject.name,
                                    department: subject.department,
                                    semester: subject.semester,
                                    section: 'A',
                                    credits: subject.credits,
                                    description: subject.description,
                                    resourcesCount: subject.resourcesCount,
                                    announcementsCount: 0,
                                    studentsCount: 0,
                                  ),
                                ),
                              );
                            } else if (val == 'delete') {
                              _confirmDeleteSubject(context, subject);
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
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Subject Title
              Text(
                subject.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),

              // Department & Semester subtitle
              Text(
                '${subject.department} • ${subject.semester}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),

              if (subject.description != null &&
                  subject.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subject.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],

              const Divider(height: 20),

              // Bottom Row: Faculty info + Resource count pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Faculty Avatar & Name
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.blue.withValues(alpha: 0.2),
                        child: Text(
                          subject.faculty.name.isNotEmpty
                              ? subject.faculty.name[0].toUpperCase()
                              : 'F',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        subject.faculty.name,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),

                  // Resources Count Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.menu_book,
                            color: Colors.teal, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${subject.resourcesCount} Materials • ${subject.unitsCount} Units',
                          style: const TextStyle(
                            color: Colors.teal,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAcademicsSummaryHeader(
    BuildContext context,
    WidgetRef ref, {
    required bool isFaculty,
    required bool isDesktop,
  }) {
    if (isFaculty) {
      return _buildFacultyOverviewBanner(context);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStudentAcademicProgressionBanner(context, ref),
        _buildStudentDashboardBanner(context, ref, isDesktop: isDesktop),
      ],
    );
  }

  Widget _buildStudentAcademicProgressionBanner(
      BuildContext context, WidgetRef ref) {
    final contextAsync = ref.watch(academicContextProvider);

    return contextAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (acad) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade800,
                Colors.indigo.shade900,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top badge row
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
                          '${acad.yearRoman} Year • ${acad.semesterRoman} Semester',
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      acad.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Main Academic Header String
              Text(
                acad.academicHeader,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              // Subtitle details
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${acad.program} • Section ${acad.section} • Batch ${acad.batchName}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  if (acad.hasOverride)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Override: ${acad.overrideReason ?? "Custom"}',
                        style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFacultyOverviewBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school, color: Colors.blue, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Faculty Curriculum View',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  'Manage lecture units, question banks, attendance records, and continuous assessments.',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
            onPressed: () => context.go('/teaching'),
            child: const Text('Teaching Hub'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentDashboardBanner(
    BuildContext context,
    WidgetRef ref, {
    required bool isDesktop,
  }) {
    final pendingAsync = ref.watch(studentPendingAssignmentsProvider);
    final assessmentsSummaryAsync =
        ref.watch(studentAssessmentsSummaryProvider);
    final todayScheduleAsync = ref.watch(studentTodayTimetableProvider);

    final pendingList = pendingAsync.value ?? [];
    final List<StudentSubjectAssessmentModel> allAssessments = [];
    for (final s in (assessmentsSummaryAsync.value ?? [])) {
      allAssessments.addAll(s.assessments);
    }
    final scheduledAssessments = allAssessments
        .where((a) => a.status == 'SCHEDULED' || a.result == null)
        .toList();
    scheduledAssessments.sort((a, b) {
      if (a.scheduledAt == null) return 1;
      if (b.scheduledAt == null) return -1;
      return a.scheduledAt!.compareTo(b.scheduledAt!);
    });

    final todaySlots = todayScheduleAsync.value ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Academic Status & Tasks',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => context.push('/academics/timetable'),
                    icon: const Icon(Icons.calendar_month, size: 14),
                    label:
                        const Text('Timetable', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cards Row / Grid
          LayoutBuilder(
            builder: (ctx, constraints) {
              final isWide = constraints.maxWidth > 580;

              final pendingCard = _buildDashboardMetricTile(
                context,
                title:
                    '${pendingList.length} Assignment${pendingList.length == 1 ? '' : 's'} Due',
                subtitle: pendingList.isNotEmpty
                    ? '${pendingList.first.title} (${_getDueCountdown(pendingList.first.dueAt)})'
                    : 'All coursework submitted',
                icon: Icons.assignment_outlined,
                accentColor: pendingList.isNotEmpty
                    ? Colors.amber.shade900
                    : Colors.teal,
                bgColor: pendingList.isNotEmpty
                    ? Colors.amber.withValues(alpha: 0.1)
                    : Colors.teal.withValues(alpha: 0.08),
                borderColor: pendingList.isNotEmpty
                    ? Colors.amber.withValues(alpha: 0.3)
                    : Colors.teal.withValues(alpha: 0.2),
                onTap: () => _showPendingAssignmentsSheet(context, pendingList),
              );

              final assessmentCard = _buildDashboardMetricTile(
                context,
                title:
                    '${scheduledAssessments.length} Test${scheduledAssessments.length == 1 ? '' : 's'} Ahead',
                subtitle: scheduledAssessments.isNotEmpty
                    ? '${scheduledAssessments.first.title} (${_getScheduleCountdown(scheduledAssessments.first.scheduledAt)})'
                    : 'No internal exams scheduled',
                icon: Icons.quiz_outlined,
                accentColor: Colors.purple.shade700,
                bgColor: Colors.purple.withValues(alpha: 0.08),
                borderColor: Colors.purple.withValues(alpha: 0.25),
                onTap: () => _showUpcomingAssessmentsSheet(
                    context, scheduledAssessments),
              );

              final scheduleCard = _buildDashboardMetricTile(
                context,
                title:
                    '${todaySlots.length} Class${todaySlots.length == 1 ? '' : 'es'} Today',
                subtitle: todaySlots.isNotEmpty
                    ? '${todaySlots.first.subjectCode} @ ${todaySlots.first.startTime} (${todaySlots.first.roomOrVenue})'
                    : 'No lectures scheduled today',
                icon: Icons.schedule_outlined,
                accentColor: Colors.blue.shade700,
                bgColor: Colors.blue.withValues(alpha: 0.08),
                borderColor: Colors.blue.withValues(alpha: 0.25),
                onTap: () => context.push('/academics/timetable'),
              );

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: pendingCard),
                    const SizedBox(width: 10),
                    Expanded(child: assessmentCard),
                    const SizedBox(width: 10),
                    Expanded(child: scheduleCard),
                  ],
                );
              }

              return Column(
                children: [
                  pendingCard,
                  const SizedBox(height: 8),
                  assessmentCard,
                  const SizedBox(height: 8),
                  scheduleCard,
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // Shortcut Links Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildShortcutChip(
                  context,
                  icon: Icons.badge_outlined,
                  label: 'Faculty Mentors',
                  onTap: () => context.push('/academics/faculty'),
                ),
                const SizedBox(width: 8),
                _buildShortcutChip(
                  context,
                  icon: Icons.work_outline,
                  label: 'Career & Placement Hub',
                  color: Colors.deepPurple,
                  onTap: () => context.push('/career'),
                ),
                const SizedBox(width: 8),
                _buildShortcutChip(
                  context,
                  icon: Icons.history_edu,
                  label: 'Attendance Records',
                  color: Colors.teal,
                  onTap: () {
                    // Filter to enrolled
                    if (!ref.read(academicFilterProvider).onlyEnrolled) {
                      ref
                          .read(academicFilterProvider.notifier)
                          .toggleOnlyEnrolled();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardMetricTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: accentColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 12, color: accentColor.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color color = Colors.blue,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDueCountdown(DateTime dueAt) {
    final now = DateTime.now();
    final diff = dueAt.difference(now).inDays;
    if (diff < 0) return '${-diff}d overdue';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due in ${diff}d';
  }

  String _getScheduleCountdown(DateTime? scheduledAt) {
    if (scheduledAt == null) return 'Upcoming';
    final now = DateTime.now();
    final diff = scheduledAt.difference(now).inDays;
    if (diff < 0) return 'Past';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return 'In ${diff}d';
  }

  void _showPendingAssignmentsSheet(
      BuildContext context, List<StudentAssignmentModel> assignments) {
    if (assignments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Great job! You have no pending assignments.')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pending Coursework (${assignments.length})',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    controller: scrollCtrl,
                    itemCount: assignments.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, index) {
                      final a = assignments[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.assignment_outlined,
                              color: Colors.amber.shade900, size: 20),
                        ),
                        title: Text(a.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          '${a.subjectCode} • ${a.subjectName}\nDue: ${_getDueCountdown(a.dueAt)} • Max: ${a.maxMarks} marks',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
                        ),
                        isThreeLine: true,
                        trailing: FilledButton.tonal(
                          style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact),
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.push(
                                '/academics/subjects/${a.subjectId}?tab=2');
                          },
                          child: const Text('Submit'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUpcomingAssessmentsSheet(
      BuildContext context, List<StudentSubjectAssessmentModel> assessments) {
    if (assessments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'No upcoming continuous internal assessments at this time.')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upcoming Assessments (${assessments.length})',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    controller: scrollCtrl,
                    itemCount: assessments.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, index) {
                      final a = assessments[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.quiz_outlined,
                              color: Colors.purple, size: 20),
                        ),
                        title: Text(a.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          '${a.subjectCode} • ${a.subjectName}\n${a.unit ?? "All Units"} • ${_getScheduleCountdown(a.scheduledAt)} • Pass: ${a.passingMarks}/${a.totalMarks}',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
                        ),
                        isThreeLine: true,
                        trailing: FilledButton.tonal(
                          style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact),
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.push(
                                '/academics/subjects/${a.subjectId}?tab=3');
                          },
                          child: const Text('Details'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
