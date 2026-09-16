import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/responsive/responsive_layout.dart';
import '../../../../shared/widgets/async_value_widget.dart';
import '../controllers/academics_controller.dart';
import '../../data/academics_remote_datasource.dart';
import '../../domain/models/academic_models.dart';
import '../../../faculty/domain/models/faculty_models.dart';
import '../../../chat/data/chat_repository.dart';

class StudentSubjectDetailView extends ConsumerStatefulWidget {
  final String subjectId;

  const StudentSubjectDetailView({super.key, required this.subjectId});

  @override
  ConsumerState<StudentSubjectDetailView> createState() => _StudentSubjectDetailViewState();
}

class _StudentSubjectDetailViewState extends ConsumerState<StudentSubjectDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedUnitFilter = 'All Units';
  String _resourceQuery = '';
  final TextEditingController _resourceSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _resourceSearchController.dispose();
    super.dispose();
  }

  Future<void> _messageFaculty(BuildContext context, String facultyUserId, String facultyName) async {
    try {
      final chatRepo = ref.read(chatRepositoryProvider);
      final room = await chatRepo.getOrCreateDirectChat(facultyUserId);
      if (context.mounted) {
        context.push('/chat/room/${room.id}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initiate conversation with $facultyName: $e')),
        );
      }
    }
  }

  Future<void> _openResource(BuildContext context, SubjectResource resource) async {
    await ref.read(academicsRemoteDatasourceProvider).recordResourceView(resource.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.teal.shade800,
          content: Text('Opening resource: ${resource.title}\nURL: ${resource.fileUrl}'),
          action: SnackBarAction(
            label: 'DISMISS',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  Future<void> _downloadResource(BuildContext context, SubjectResource resource) async {
    await ref.read(academicsRemoteDatasourceProvider).recordResourceDownload(resource.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.blue.shade800,
          content: Text('Download started for: ${resource.title}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(academicSubjectDetailProvider(widget.subjectId));

    return AsyncValueWidget<AcademicSubjectDetailModel>(
      value: detailAsync,
      data: (subject) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${subject.code} • ${subject.semester} • Section ${subject.section}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Subject',
                onPressed: () {
                  ref.invalidate(academicSubjectDetailProvider(widget.subjectId));
                },
              ),
              const SizedBox(width: 8),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(
                  icon: const Icon(Icons.layers_outlined, size: 18),
                  text: 'Units & Materials (${subject.allResources.length})',
                ),
                const Tab(
                  icon: Icon(Icons.menu_book_outlined, size: 18),
                  text: 'Course Syllabus',
                ),
                const Tab(
                  icon: Icon(Icons.person_outline, size: 18),
                  text: 'Faculty & Office Hours',
                ),
                Tab(
                  icon: const Icon(Icons.campaign_outlined, size: 18),
                  text: 'Announcements (${subject.announcements.length})',
                ),
              ],
            ),
          ),
          body: ResponsiveLayout(
            mobile: _buildTabBarViews(context, subject),
            desktop: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: _buildTabBarViews(context, subject),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBarViews(BuildContext context, AcademicSubjectDetailModel subject) {
    return Column(
      children: [
        // Subject Quick Header Banner
        _buildHeroBanner(context, subject),

        // Tabs Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildUnitsAndMaterialsTab(context, subject),
              _buildSyllabusTab(context, subject),
              _buildFacultyTab(context, subject),
              _buildAnnouncementsTab(context, subject),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner(BuildContext context, AcademicSubjectDetailModel subject) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    subject.code,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${subject.department} • ${subject.credits} Credits',
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Enrollment Action Button
          FilledButton.tonalIcon(
            onPressed: () async {
              final toggled = await ref
                  .read(academicEnrollmentNotifierProvider.notifier)
                  .toggleEnrollment(subject.id, subject.isEnrolled);
              if (toggled && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: subject.isEnrolled ? Colors.orange.shade800 : Colors.green.shade800,
                    content: Text(
                      subject.isEnrolled
                          ? 'Unenrolled from ${subject.code}'
                          : 'Successfully enrolled in ${subject.code}!',
                    ),
                  ),
                );
              }
            },
            icon: Icon(
              subject.isEnrolled ? Icons.check_circle : Icons.add_circle_outline,
              size: 16,
              color: subject.isEnrolled ? Colors.green : Colors.blue,
            ),
            label: Text(
              subject.isEnrolled ? 'Enrolled' : 'Enroll',
              style: TextStyle(
                color: subject.isEnrolled ? Colors.green.shade800 : Colors.blue.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitsAndMaterialsTab(BuildContext context, AcademicSubjectDetailModel subject) {
    final theme = Theme.of(context);

    // Units list: All Units + distinct sorted units
    final List<String> availableUnits = ['All Units', ...subject.resourcesByUnit.keys.toList()..sort()];

    // Filter resources by selected unit and search query
    List<SubjectResource> filteredResources = subject.allResources;
    if (_selectedUnitFilter != 'All Units') {
      filteredResources = subject.resourcesByUnit[_selectedUnitFilter] ?? [];
    }

    if (_resourceQuery.trim().isNotEmpty) {
      final q = _resourceQuery.trim().toLowerCase();
      filteredResources = filteredResources.where((r) =>
        r.title.toLowerCase().contains(q) ||
        (r.topic != null && r.topic!.toLowerCase().contains(q)) ||
        (r.description != null && r.description!.toLowerCase().contains(q)) ||
        r.resourceType.toLowerCase().contains(q)
      ).toList();
    }

    return Column(
      children: [
        // Unit Filter Selector & Search Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            children: [
              // Search in subject
              TextField(
                controller: _resourceSearchController,
                decoration: InputDecoration(
                  hintText: 'Search study material or topic in this subject...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _resourceSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _resourceSearchController.clear();
                            setState(() => _resourceQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  setState(() => _resourceQuery = val);
                },
              ),
              const SizedBox(height: 8),

              // Unit Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: availableUnits.map((unitKey) {
                    final isSelected = _selectedUnitFilter == unitKey;
                    final count = unitKey == 'All Units'
                        ? subject.allResources.length
                        : (subject.resourcesByUnit[unitKey]?.length ?? 0);
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        label: Text('$unitKey ($count)', style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedUnitFilter = unitKey);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Resources List
        Expanded(
          child: filteredResources.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.folder_open, size: 56, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          'No materials found in $_selectedUnitFilter',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Check other units or clear your search term.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredResources.length,
                  itemBuilder: (context, index) {
                    final res = filteredResources[index];
                    return _buildResourceCard(context, res);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildResourceCard(BuildContext context, SubjectResource res) {
    final theme = Theme.of(context);

    // Color and Icon according to resourceType
    IconData iconData = Icons.insert_drive_file;
    Color iconColor = Colors.blue;
    String badgeLabel = res.resourceType;

    switch (res.resourceType.toUpperCase()) {
      case 'NOTES':
        iconData = Icons.description;
        iconColor = Colors.teal;
        badgeLabel = 'NOTES';
        break;
      case 'PDF':
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red.shade700;
        badgeLabel = 'PDF';
        break;
      case 'PRESENTATION':
      case 'PPT':
        iconData = Icons.slideshow;
        iconColor = Colors.orange.shade800;
        badgeLabel = 'SLIDES';
        break;
      case 'VIDEO':
        iconData = Icons.ondemand_video;
        iconColor = Colors.purple;
        badgeLabel = 'VIDEO';
        break;
      case 'YOUTUBE':
        iconData = Icons.play_circle_fill;
        iconColor = Colors.red;
        badgeLabel = 'YOUTUBE';
        break;
      case 'GITHUB':
      case 'CODE':
        iconData = Icons.code;
        iconColor = Colors.grey.shade900;
        badgeLabel = 'GITHUB CODE';
        break;
      case 'ASSIGNMENT':
        iconData = Icons.assignment;
        iconColor = Colors.amber.shade900;
        badgeLabel = 'ASSIGNMENT';
        break;
      case 'QUESTION_BANK':
        iconData = Icons.quiz;
        iconColor = Colors.indigo;
        badgeLabel = 'QUESTION BANK';
        break;
      case 'REFERENCE_BOOK':
        iconData = Icons.auto_stories;
        iconColor = Colors.brown;
        badgeLabel = 'REFERENCE';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      color: theme.colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Unit Tag + Resource Type Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (res.unit != null && res.unit!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          res.unit!,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          color: iconColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                // View & Download Counters
                Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 3),
                    Text('${res.viewCount}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                    const SizedBox(width: 10),
                    Icon(Icons.download_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 3),
                    Text('${res.downloadCount}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title with leading icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(iconData, color: iconColor, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        res.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if (res.topic != null && res.topic!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Topic: ${res.topic}',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            if (res.description != null && res.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                res.description!,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12, height: 1.4),
              ),
            ],

            const SizedBox(height: 12),

            // Bottom Actions Row
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  'By ${res.uploadedByName}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _downloadResource(context, res),
                      icon: const Icon(Icons.download, size: 14),
                      label: const Text('Download', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => _openResource(context, res),
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: const Text('Open / View', style: TextStyle(fontSize: 12)),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyllabusTab(BuildContext context, AcademicSubjectDetailModel subject) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Course Objectives & Syllabus',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subject.description ??
                        'This course provides in-depth exploration of core architectural patterns, theoretical guarantees, practical laboratory benchmarks, and real-world system deployments.',
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                  const Divider(height: 28),
                  Text(
                    'Curriculum Structure (${subject.resourcesByUnit.length} Units)',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...subject.resourcesByUnit.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.teal, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${entry.value.length} learning resources',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacultyTab(BuildContext context, AcademicSubjectDetailModel subject) {
    final theme = Theme.of(context);
    final fac = subject.faculty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Faculty Info Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.blue.withValues(alpha: 0.15),
                        child: Text(
                          fac.name.isNotEmpty ? fac.name[0].toUpperCase() : 'F',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fac.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${fac.designation} • ${fac.department}',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fac.qualification,
                              style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Message Faculty Primary Action Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _messageFaculty(context, fac.id, fac.name),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: Text('Message / Chat with ${fac.name.split(' ').first}'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const Divider(height: 28),

                  // Office Location & Hours
                  Row(
                    children: [
                      const Icon(Icons.meeting_room_outlined, color: Colors.teal, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Office Location', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(fac.officeRoom, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.orange, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Office Hours & Consultations', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(fac.officeHours, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, color: Colors.blue, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Official Email', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(fac.email, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (fac.bio.isNotEmpty) ...[
                    const Divider(height: 28),
                    Text(
                      'Faculty Biography & Research Focus',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      fac.bio,
                      style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.5),
                    ),
                  ],

                  if (fac.expertise.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: fac.expertise.map((e) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(e, style: const TextStyle(fontSize: 11)),
                        );
                      }).toList(),
                    ),
                  ],

                  if (fac.publications.isNotEmpty) ...[
                    const Divider(height: 28),
                    Text(
                      'Selected Research Publications',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...fac.publications.map((p) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.article_outlined, size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['title']?.toString() ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                  Text(
                                    p['venue']?.toString() ?? '',
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsTab(BuildContext context, AcademicSubjectDetailModel subject) {
    if (subject.announcements.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No announcements published yet for this course'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: subject.announcements.length,
      itemBuilder: (context, index) {
        final a = subject.announcements[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        a.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${a.createdAt.day}/${a.createdAt.month}/${a.createdAt.year}',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  a.content,
                  style: const TextStyle(height: 1.4, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Text(
                  'Posted by ${a.authorName}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
