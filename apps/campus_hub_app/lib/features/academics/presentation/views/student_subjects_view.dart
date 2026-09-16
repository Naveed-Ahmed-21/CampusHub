import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/responsive/responsive_layout.dart';
import '../../../../shared/widgets/async_value_widget.dart';
import '../controllers/academics_controller.dart';
import '../../domain/models/academic_models.dart';
import '../../../feed/presentation/widgets/student_drawer_widget.dart';
import '../../../faculty/presentation/widgets/faculty_drawer_widget.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class StudentSubjectsView extends ConsumerStatefulWidget {
  const StudentSubjectsView({super.key});

  @override
  ConsumerState<StudentSubjectsView> createState() => _StudentSubjectsViewState();
}

class _StudentSubjectsViewState extends ConsumerState<StudentSubjectsView> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _semesters = [
    'All Semesters',
    'Semester 3',
    'Semester 4',
    'Semester 5',
    'Semester 6',
    'Semester 7',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    final subjectsAsync = ref.watch(academicSubjectsProvider);
    final filter = ref.watch(academicFilterProvider);

    final user = ref.watch(authControllerProvider).asData?.value;
    final isFaculty = user?.isFaculty == true;

    return Scaffold(
      drawer: isFaculty ? const FacultyDrawerWidget() : const StudentDrawerWidget(),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.school, color: Colors.blue, size: 22),
            SizedBox(width: 8),
            Text(
              'Academic Subjects',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.badge_outlined),
            tooltip: 'Faculty Directory',
            onPressed: () => context.push('/academics/faculty'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(academicSubjectsProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ResponsiveLayout(
        mobile: _buildBody(context, ref, subjectsAsync, filter, isDesktop: false),
        desktop: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: _buildBody(context, ref, subjectsAsync, filter, isDesktop: true),
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
                  hintText: 'Search by Subject Code (e.g. CS335), Name, or Topic...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(academicFilterProvider.notifier).setQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
                        filter.onlyEnrolled ? Icons.check_circle : Icons.bookmark_border,
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
                        ref.read(academicFilterProvider.notifier).toggleOnlyEnrolled();
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
                          label: Text(sem, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              ref.read(academicFilterProvider.notifier).setSemester(
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
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No subjects match your search',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                },
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 16,
                    vertical: 16,
                  ),
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    return _buildSubjectCard(context, subject);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectCard(BuildContext context, AcademicSubjectModel subject) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: subject.isEnrolled ? Colors.blue.withValues(alpha: 0.3) : Colors.grey.shade200,
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
              // Top Row: Code Badge + Enrolled Badge + Credits
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 12),
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
                  Text(
                    '${subject.credits} Credits',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
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

              if (subject.description != null && subject.description!.isNotEmpty) ...[
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
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        subject.faculty.name,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),

                  // Resources Count Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.menu_book, color: Colors.teal, size: 14),
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
}
