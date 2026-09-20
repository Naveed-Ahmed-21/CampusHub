import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/responsive/responsive_layout.dart';
import '../../../../shared/widgets/async_value_widget.dart';
import '../../../chat/data/chat_repository.dart';
import '../controllers/faculty_controller.dart';
import '../../domain/models/faculty_models.dart';
import '../widgets/upload_resource_dialog.dart';
import '../widgets/add_announcement_dialog.dart';
import '../widgets/add_subject_dialog.dart';
import '../widgets/session_attendance_sheet.dart';

class SubjectDetailView extends ConsumerStatefulWidget {
  final String subjectId;
  final int? initialTab;

  const SubjectDetailView({
    super.key,
    required this.subjectId,
    this.initialTab,
  });

  @override
  ConsumerState<SubjectDetailView> createState() => _SubjectDetailViewState();
}

class _SubjectDetailViewState extends ConsumerState<SubjectDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialIndex = (widget.initialTab != null &&
            widget.initialTab! >= 0 &&
            widget.initialTab! < 8)
        ? widget.initialTab!
        : 0;
    _tabController =
        TabController(length: 8, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _confirmDeleteSubject(BuildContext context, FacultySubject subject) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject?'),
        content: Text(
          'Are you sure you want to delete ${subject.code} - ${subject.name}? This will delete all course units, uploaded study materials, and subject announcements.',
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
                if (ok) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.teal,
                      content: Text('Subject deleted successfully'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.red,
                      content: Text('Failed to delete subject'),
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteResource(
      BuildContext context, String subjectId, SubjectResource resource) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Study Material?'),
        content: Text('Are you sure you want to delete "${resource.title}"?'),
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
                  .deleteSubjectResource(
                    subjectId: subjectId,
                    resourceId: resource.id,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: ok ? Colors.teal.shade700 : Colors.red,
                    content: Text(ok
                        ? 'Material deleted successfully'
                        : 'Failed to delete material'),
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
    final subjectAsync =
        ref.watch(facultySubjectDetailProvider(widget.subjectId));

    return AsyncValueWidget(
      value: subjectAsync,
      data: (subject) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${subject.code} • ${subject.semester} (Section ${subject.section})',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.upload_file),
                tooltip: 'Upload Study Material',
                onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => UploadResourceDialog(
                    subjectId: subject.id,
                    subjectName: subject.name,
                    defaultResourceType: '',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.campaign_outlined),
                tooltip: 'Post Announcement',
                onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => AddAnnouncementDialog(
                    subjectId: subject.id,
                    subjectName: subject.name,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (val) {
                  if (val == 'edit') {
                    showDialog(
                      context: context,
                      builder: (ctx) =>
                          AddSubjectDialog(subjectToEdit: subject),
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
                        Icon(Icons.edit_outlined, size: 18, color: Colors.teal),
                        SizedBox(width: 8),
                        Text('Edit Subject Details'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Subject',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(icon: Icon(Icons.info_outline, size: 18), text: 'Overview'),
                Tab(
                    icon: Icon(Icons.menu_book_outlined, size: 18),
                    text: 'Syllabus'),
                Tab(
                    icon: Icon(Icons.folder_open, size: 18),
                    text: 'Study Materials'),
                Tab(
                    icon: Icon(Icons.assignment_outlined, size: 18),
                    text: 'Assignments'),
                Tab(
                    icon: Icon(Icons.quiz_outlined, size: 18),
                    text: 'Assessments'),
                Tab(
                    icon: Icon(Icons.how_to_reg_outlined, size: 18),
                    text: 'Attendance'),
                Tab(
                    icon: Icon(Icons.campaign, size: 18),
                    text: 'Announcements'),
                Tab(
                    icon: Icon(Icons.group_outlined, size: 18),
                    text: 'Enrolled Students'),
              ],
            ),
          ),
          body: ResponsiveLayout(
            mobile: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(context, subject),
                _buildSyllabusTab(context, subject),
                _buildResourcesTab(context, subject),
                _buildAssignmentsTab(context, subject),
                _buildAssessmentsTab(context, subject),
                _buildAttendanceTab(context, subject),
                _buildAnnouncementsTab(context, subject),
                _buildStudentsTab(context, subject),
              ],
            ),
            desktop: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(context, subject),
                    _buildSyllabusTab(context, subject),
                    _buildResourcesTab(context, subject),
                    _buildAssignmentsTab(context, subject),
                    _buildAssessmentsTab(context, subject),
                    _buildAttendanceTab(context, subject),
                    _buildAnnouncementsTab(context, subject),
                    _buildStudentsTab(context, subject),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(BuildContext context, FacultySubject subject) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.15),
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
                      Text(
                        '${subject.credits} Academic Credits',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    subject.name,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${subject.department} • ${subject.semester} • Section ${subject.section}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                  const Divider(height: 28),
                  Text(
                    'Syllabus & Course Objectives',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subject.description ??
                        'This course covers foundational and advanced topics in ${subject.name}, including theoretical models, practical laboratory experiments, algorithmic complexity, and real-world system applications.',
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (ctx) => UploadResourceDialog(
                      subjectId: subject.id,
                      subjectName: subject.name,
                      defaultResourceType: '',
                    ),
                  ),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Notes'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (ctx) => AddAnnouncementDialog(
                      subjectId: subject.id,
                      subjectName: subject.name,
                    ),
                  ),
                  icon: const Icon(Icons.campaign),
                  label: const Text('Announcement'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Career Hub & Industry Bridge Card
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            color: Colors.teal.withValues(alpha: 0.07),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.psychology,
                            color: Colors.teal, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Career Hub & Industry Skill Alignment',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Topics taught in ${subject.code} (${subject.name}) directly build competency for campus placements, technical OA rounds, and AI career tracks.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.verified,
                            size: 14, color: Colors.teal),
                        label: const Text('Core Curriculum Skill',
                            style: TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.white,
                      ),
                      Chip(
                        avatar: const Icon(Icons.work_outline,
                            size: 14, color: Colors.blue),
                        label: const Text('Placement OA Tested',
                            style: TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.white,
                      ),
                      Chip(
                        avatar: const Icon(Icons.school,
                            size: 14, color: Colors.purple),
                        label: const Text('Mentorship Path',
                            style: TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => context.push('/career'),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('View Career Roadmaps'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesTab(BuildContext context, FacultySubject subject) {
    if (subject.resources.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No study materials uploaded for this subject yet'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (ctx) => UploadResourceDialog(
                  subjectId: subject.id,
                  subjectName: subject.name,
                  defaultResourceType: '',
                ),
              ),
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Upload First Handout / Slide Deck'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: subject.resources.length,
      itemBuilder: (context, index) {
        final resource = subject.resources[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                resource.fileType == 'PDF'
                    ? Icons.picture_as_pdf
                    : resource.fileType == 'PPT'
                        ? Icons.slideshow
                        : Icons.insert_drive_file,
                color: Colors.teal,
              ),
            ),
            title: Text(resource.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (resource.unit != null && resource.unit!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          resource.unit!,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue),
                        ),
                      ),
                    if (resource.topic != null && resource.topic!.isNotEmpty)
                      Text(
                        resource.topic!,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.teal),
                      ),
                  ],
                ),
                if (resource.description != null &&
                    resource.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    resource.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.open_in_new, color: Colors.blue),
                  tooltip: 'Open resource',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Resource Link: ${resource.fileUrl}')),
                    );
                  },
                ),
                PopupMenuButton<String>(
                  icon:
                      const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  onSelected: (val) {
                    if (val == 'delete') {
                      _confirmDeleteResource(context, subject.id, resource);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Material',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAnnouncementDetail(
    BuildContext context,
    SubjectAnnouncement announcement,
    FacultySubject subject,
  ) {
    final theme = Theme.of(context);
    final dateStr =
        '${announcement.createdAt.day.toString().padLeft(2, '0')}/${announcement.createdAt.month.toString().padLeft(2, '0')}/${announcement.createdAt.year}';
    final timeStr =
        '${announcement.createdAt.hour.toString().padLeft(2, '0')}:${announcement.createdAt.minute.toString().padLeft(2, '0')}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (sheetContext, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.campaign_rounded,
                                size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Subject Notice',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
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
                    '${subject.code} • ${subject.name}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    announcement.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.blue.withValues(alpha: 0.15),
                          child: Text(
                            announcement.authorName.isNotEmpty
                                ? announcement.authorName[0].toUpperCase()
                                : 'F',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
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
                                announcement.authorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                              Text(
                                'Posted on $dateStr at $timeStr',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 32),
                  SelectableText(
                    announcement.content,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnnouncementsTab(BuildContext context, FacultySubject subject) {
    if (subject.announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.campaign_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No announcements published for this subject'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (ctx) => AddAnnouncementDialog(
                  subjectId: subject.id,
                  subjectName: subject.name,
                ),
              ),
              icon: const Icon(Icons.campaign),
              label: const Text('Post First Announcement'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: subject.announcements.length,
      itemBuilder: (context, index) {
        final announcement = subject.announcements[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () =>
                _showAnnouncementDetail(context, announcement, subject),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          announcement.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Class Notice',
                          style: TextStyle(
                              color: Colors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    announcement.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_pin,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            'Posted by ${announcement.authorName}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'Read more',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 11,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditSyllabusDialog(BuildContext context, FacultySubject subject) {
    final controller = TextEditingController(text: subject.description ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.menu_book, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Edit Course Syllabus',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update the syllabus, course description, and learning objectives for ${subject.code}:',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText:
                        'Enter course objectives, unit breakdown, prerequisites, and syllabus...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      final success = await ref
                          .read(facultyControllerProvider.notifier)
                          .updateSubject(
                            code: subject.id,
                            description: controller.text.trim(),
                            subjectId: '',
                          );
                      if (dialogCtx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Syllabus updated successfully!'
                                : 'Failed to update syllabus'),
                            backgroundColor:
                                success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Syllabus'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyllabusTab(BuildContext context, FacultySubject subject) {
    final theme = Theme.of(context);
    final syllabusResources =
        subject.resources.where((r) => r.resourceType == 'SYLLABUS').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.menu_book,
                              color: theme.colorScheme.primary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Course Syllabus & Objectives',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            _showEditSyllabusDialog(context, subject),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit Syllabus'),
                        style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    subject.description != null &&
                            subject.description!.isNotEmpty
                        ? subject.description!
                        : 'No detailed syllabus text added yet. Click "Edit Syllabus" above to add course objectives, curriculum breakdown, and learning outcomes.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: subject.description != null &&
                              subject.description!.isNotEmpty
                          ? null
                          : Colors.grey.shade600,
                    ),
                  ),
                  const Divider(height: 32),
                  Text(
                    'Subject Information',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoBadge(
                          context, Icons.tag, 'Code: ${subject.code}'),
                      const SizedBox(width: 8),
                      _buildInfoBadge(context, Icons.stars_outlined,
                          '${subject.credits} Credits'),
                      const SizedBox(width: 8),
                      _buildInfoBadge(context, Icons.calendar_today_outlined,
                          subject.academicYear),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Upload syllabus PDF / document button
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (ctx) => UploadResourceDialog(
                      subjectId: subject.id,
                      subjectName: subject.name,
                      defaultResourceType: 'SYLLABUS',
                    ),
                  ),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Syllabus Document / PDF'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),

          if (syllabusResources.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Attached Syllabus Documents (${syllabusResources.length})',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...syllabusResources.map((res) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.4)),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.picture_as_pdf,
                          color: Colors.red, size: 20),
                    ),
                    title: Text(res.title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(res.description ?? res.academicYear),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 18),
                      onPressed: () =>
                          _confirmDeleteResource(context, subject.id, res),
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoBadge(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showStudentDetailSheet(
      BuildContext context, SubjectStudent student, FacultySubject subject) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/profile/${student.id}');
                  },
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.blue.withValues(alpha: 0.15),
                    backgroundImage: student.avatarUrl != null &&
                            student.avatarUrl!.isNotEmpty
                        ? NetworkImage(
                            ApiEndpoints.resolveUrl(student.avatarUrl!))
                        : null,
                    child:
                        student.avatarUrl == null || student.avatarUrl!.isEmpty
                            ? Text(
                                student.name.isNotEmpty
                                    ? student.name[0].toUpperCase()
                                    : 'S',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    color: Colors.blue),
                              )
                            : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          context.push('/profile/${student.id}');
                        },
                        child: Text(
                          student.name,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Roll No: ${student.rollNumber} • ${student.department}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.outline),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${subject.semester} • Section ${subject.section}',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/profile/${student.id}');
                    },
                    icon: const Icon(Icons.person_outline, size: 18),
                    label: const Text('View Profile'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        final chatRepo = ref.read(chatRepositoryProvider);
                        final room =
                            await chatRepo.getOrCreateDirectChat(student.id);
                        if (context.mounted) {
                          context.push('/chat/room/${room.id}');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to open chat: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Message'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            if (student.email.isNotEmpty) ...[
              const Divider(height: 32),
              Row(
                children: [
                  const Icon(Icons.email_outlined,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    student.email,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsTab(BuildContext context, FacultySubject subject) {
    final theme = Theme.of(context);
    final students = subject.students;

    if (students.isEmpty && subject.studentsCount == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'No Students Enrolled Yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Students assigned to ${subject.code} (${subject.semester} - Section ${subject.section}) will appear here.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.isNotEmpty ? students.length : subject.studentsCount,
      itemBuilder: (context, index) {
        if (students.isNotEmpty) {
          final student = students[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _showStudentDetailSheet(context, student, subject),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.push('/profile/${student.id}'),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blue.withValues(alpha: 0.15),
                        backgroundImage: student.avatarUrl != null &&
                                student.avatarUrl!.isNotEmpty
                            ? NetworkImage(
                                ApiEndpoints.resolveUrl(student.avatarUrl!))
                            : null,
                        child: student.avatarUrl == null ||
                                student.avatarUrl!.isEmpty
                            ? Text(
                                student.name.isNotEmpty
                                    ? student.name[0].toUpperCase()
                                    : 'S',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    fontSize: 16),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => context.push('/profile/${student.id}'),
                            child: Text(
                              student.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Roll No: ${student.rollNumber} • ${student.department}',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Enrolled',
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final rollNumber = '21CS0${10 + index}';
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                'S${index + 1}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
            title: Text('Student ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
                'Roll No: $rollNumber • ${subject.semester} • Section ${subject.section}'),
          ),
        );
      },
    );
  }

  Widget _buildAssignmentsTab(BuildContext context, FacultySubject subject) {
    final assignmentsAsync =
        ref.watch(facultySubjectAssignmentsProvider(subject.id));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
                bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Course Assignments',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Assignment'),
                onPressed: () => _showCreateAssignmentDialog(context, subject),
              ),
            ],
          ),
        ),
        Expanded(
          child: AsyncValueWidget<List<SubjectAssignment>>(
            value: assignmentsAsync,
            data: (assignments) {
              if (assignments.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_late_outlined,
                            size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No Assignments Created Yet',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Publish assignments, define deadlines, and track submissions for ${subject.code}.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () =>
                              _showCreateAssignmentDialog(context, subject),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create First Assignment'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: assignments.length,
                itemBuilder: (context, index) {
                  final assignment = assignments[index];
                  final isPastDue = DateTime.now().isAfter(assignment.dueAt);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side:
                          BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.assignment_outlined,
                                    color: Colors.teal, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      assignment.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    if (assignment.unit != null &&
                                        assignment.unit!.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        '${assignment.unit}${assignment.topic != null && assignment.topic!.isNotEmpty ? ' • ${assignment.topic}' : ''}',
                                        style: TextStyle(
                                            color: Colors.teal.shade700,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPastDue
                                      ? Colors.red.withValues(alpha: 0.1)
                                      : Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isPastDue ? 'Closed' : 'Active',
                                  style: TextStyle(
                                    color: isPastDue ? Colors.red : Colors.blue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (assignment.description != null &&
                              assignment.description!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              assignment.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.grey.shade700, fontSize: 13),
                            ),
                          ],
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined,
                                      size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Due: ${assignment.dueAt.day}/${assignment.dueAt.month}/${assignment.dueAt.year}',
                                    style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 12),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.star_outline,
                                      size: 14, color: Colors.amber.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${assignment.maxMarks} Marks',
                                    style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor: Colors.teal.shade800,
                                ),
                                icon:
                                    const Icon(Icons.people_outline, size: 15),
                                label: Text(
                                    '${assignment.submissionsCount} Submissions'),
                                onPressed: () => _showSubmissionsBottomSheet(
                                    context, subject, assignment),
                              ),
                            ],
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
      ],
    );
  }

  void _showCreateAssignmentDialog(
      BuildContext context, FacultySubject subject) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final topicCtrl = TextEditingController();
    final marksCtrl = TextEditingController(text: '100');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    String submissionType = 'FILE';
    bool allowLate = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('New Assignment for ${subject.code}'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Assignment Title *',
                      hintText: 'e.g. MapReduce Analysis Report',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: unitCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            hintText: 'Unit 2',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: topicCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Topic',
                            hintText: 'Distributed Systems',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Instructions & Description',
                      hintText:
                          'Describe required deliverables, rubric, and format...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: marksCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Max Marks',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: submissionType,
                          decoration: const InputDecoration(
                            labelText: 'Submission Mode',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'FILE', child: Text('File Upload')),
                            DropdownMenuItem(
                                value: 'LINK', child: Text('External Link')),
                            DropdownMenuItem(
                                value: 'TEXT', child: Text('Text Response')),
                            DropdownMenuItem(
                                value: 'GITHUB', child: Text('GitHub Repo')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => submissionType = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side:
                          BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                    title: const Text('Submission Deadline',
                        style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                    trailing:
                        const Icon(Icons.calendar_month, color: Colors.teal),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    title: const Text('Allow Late Submissions',
                        style: TextStyle(fontSize: 14)),
                    value: allowLate,
                    onChanged: (v) => setState(() => allowLate = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(backgroundColor: Colors.teal.shade700),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.of(ctx).pop();
                final ok = await ref
                    .read(facultyControllerProvider.notifier)
                    .createAssignment(
                  subject.id,
                  {
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'unit': unitCtrl.text.trim(),
                    'topic': topicCtrl.text.trim(),
                    'maxMarks': int.tryParse(marksCtrl.text.trim()) ?? 100,
                    'dueAt': selectedDate.toIso8601String(),
                    'submissionType': submissionType,
                    'allowLate': allowLate,
                  },
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: ok ? Colors.teal.shade700 : Colors.red,
                      content: Text(ok
                          ? 'Assignment published successfully'
                          : 'Failed to publish assignment'),
                    ),
                  );
                }
              },
              child: const Text('Publish Assignment'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubmissionsBottomSheet(
    BuildContext context,
    FacultySubject subject,
    SubjectAssignment assignment,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final submissionsAsync =
              ref.watch(assignmentSubmissionsProvider(assignment.id));

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            maxChildSize: 0.95,
            minChildSize: 0.4,
            builder: (ctx, scrollCtrl) => Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              assignment.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                            Text(
                              'Submissions • ${subject.code} (${subject.semester})',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: AsyncValueWidget<List<AssignmentSubmission>>(
                    value: submissionsAsync,
                    data: (submissions) {
                      if (submissions.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined,
                                    size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 10),
                                const Text(
                                  'No Submissions Yet',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Enrolled students have not submitted solutions for this assignment yet.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: submissions.length,
                        itemBuilder: (ctx, idx) {
                          final sub = submissions[idx];
                          final isGraded = sub.status == 'GRADED';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.2)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Colors.teal.shade100,
                                        child: Text(
                                          sub.studentName.isNotEmpty
                                              ? sub.studentName[0].toUpperCase()
                                              : 'S',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal.shade900),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sub.studentName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14),
                                            ),
                                            if (sub.studentRollNumber != null)
                                              Text(
                                                'Roll: ${sub.studentRollNumber}',
                                                style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 11),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isGraded
                                              ? Colors.green
                                                  .withValues(alpha: 0.12)
                                              : Colors.orange
                                                  .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isGraded
                                              ? '${sub.marks}/${assignment.maxMarks}'
                                              : 'Pending Review',
                                          style: TextStyle(
                                            color: isGraded
                                                ? Colors.green.shade800
                                                : Colors.orange.shade800,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (sub.textContent != null &&
                                      sub.textContent!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.grey.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        sub.textContent!,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                  if (sub.fileUrl != null &&
                                      sub.fileUrl!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                          visualDensity: VisualDensity.compact),
                                      icon: const Icon(Icons.attach_file,
                                          size: 14),
                                      label:
                                          const Text('View Attached Solution'),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Submission file: ${sub.fileUrl}')),
                                        );
                                      },
                                    ),
                                  ],
                                  if (sub.feedback != null &&
                                      sub.feedback!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Feedback: ${sub.feedback}',
                                      style: TextStyle(
                                          color: Colors.teal.shade800,
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      FilledButton.tonalIcon(
                                        style: FilledButton.styleFrom(
                                            visualDensity:
                                                VisualDensity.compact),
                                        icon: const Icon(Icons.grade_outlined,
                                            size: 15),
                                        label: Text(isGraded
                                            ? 'Update Grade'
                                            : 'Grade Solution'),
                                        onPressed: () => _showGradeDialog(
                                            context, subject, assignment, sub),
                                      ),
                                    ],
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
              ],
            ),
          );
        },
      ),
    );
  }

  void _showGradeDialog(
    BuildContext context,
    FacultySubject subject,
    SubjectAssignment assignment,
    AssignmentSubmission submission,
  ) {
    final marksCtrl =
        TextEditingController(text: submission.marks?.toString() ?? '');
    final feedbackCtrl = TextEditingController(text: submission.feedback ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Grade ${submission.studentName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Max Marks: ${assignment.maxMarks}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: marksCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Marks Awarded (out of ${assignment.maxMarks}) *',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Faculty Feedback',
                hintText: 'Add constructive feedback for the student...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: Colors.teal.shade700),
            onPressed: () async {
              final marks = double.tryParse(marksCtrl.text.trim());
              if (marks == null) return;
              Navigator.of(ctx).pop();
              final ok = await ref
                  .read(facultyControllerProvider.notifier)
                  .gradeSubmission(
                    assignment.id,
                    submission.id,
                    {
                      'marks': marks,
                      'feedback': feedbackCtrl.text.trim(),
                    },
                    subject.id,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: ok ? Colors.teal.shade700 : Colors.red,
                    content: Text(ok
                        ? 'Grade recorded successfully'
                        : 'Failed to record grade'),
                  ),
                );
              }
            },
            child: const Text('Save Grade'),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentsTab(BuildContext context, FacultySubject subject) {
    final assessmentsAsync =
        ref.watch(facultySubjectAssessmentsProvider(subject.id));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
                bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Internal Assessments & Tests',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _showCreateAssessmentDialog(context, subject),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Assessment'),
              ),
            ],
          ),
        ),
        Expanded(
          child: assessmentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) =>
                Center(child: Text('Error loading assessments: $err')),
            data: (assessments) {
              if (assessments.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.quiz_outlined,
                            size: 64, color: Colors.purple.shade300),
                        const SizedBox(height: 14),
                        const Text(
                          'No Assessments Created Yet',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Schedule continuous evaluation exams, unit quizzes, or lab practicals.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.purple.shade700),
                          onPressed: () =>
                              _showCreateAssessmentDialog(context, subject),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create First Assessment'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: assessments.length,
                itemBuilder: (context, index) {
                  final a = assessments[index];
                  final isExam =
                      a.assessmentType.toUpperCase().contains('EXAM');
                  final isQuiz =
                      a.assessmentType.toUpperCase().contains('QUIZ');
                  Color badgeColor = Colors.blue;
                  if (isExam) badgeColor = Colors.indigo;
                  if (isQuiz) badgeColor = Colors.purple;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side:
                          BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  a.assessmentType.replaceAll('_', ' '),
                                  style: TextStyle(
                                      color: badgeColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: a.status == 'COMPLETED'
                                      ? Colors.green.withValues(alpha: 0.12)
                                      : Colors.orange.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  a.status,
                                  style: TextStyle(
                                    color: a.status == 'COMPLETED'
                                        ? Colors.green.shade800
                                        : Colors.orange.shade800,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (a.scheduledAt != null)
                                Row(
                                  children: [
                                    const Icon(Icons.event,
                                        size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${a.scheduledAt!.day}/${a.scheduledAt!.month}/${a.scheduledAt!.year}',
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            a.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (a.unit != null || a.topic != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (a.unit != null) a.unit,
                                if (a.topic != null) a.topic
                              ].join(' • '),
                              style: TextStyle(
                                  color: Colors.teal.shade800,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                          if (a.description != null &&
                              a.description!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              a.description!,
                              style: TextStyle(
                                  color: Colors.grey.shade700, fontSize: 13),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text('Total Marks',
                                        style: TextStyle(
                                            fontSize: 11, color: Colors.grey)),
                                    Text('${a.totalMarks}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text('Pass Marks',
                                        style: TextStyle(
                                            fontSize: 11, color: Colors.grey)),
                                    Text('${a.passingMarks}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.green)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text('Duration',
                                        style: TextStyle(
                                            fontSize: 11, color: Colors.grey)),
                                    Text('${a.durationMinutes ?? 60}m',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text('Evaluated',
                                        style: TextStyle(
                                            fontSize: 11, color: Colors.grey)),
                                    Text(
                                      '${a.evaluatedCount}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.purple.shade700),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                a.averageMarks != null
                                    ? 'Class Avg: ${a.averageMarks} / ${a.totalMarks}'
                                    : 'Awaiting Grading',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: a.averageMarks != null
                                      ? Colors.teal.shade800
                                      : Colors.grey,
                                ),
                              ),
                              FilledButton.tonalIcon(
                                style: FilledButton.styleFrom(
                                    visualDensity: VisualDensity.compact),
                                onPressed: () => _showGradeAssessmentDialog(
                                    context, subject, a),
                                icon: const Icon(Icons.edit_note, size: 16),
                                label: const Text('Enter Marks'),
                              ),
                            ],
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
      ],
    );
  }

  void _showCreateAssessmentDialog(
      BuildContext context, FacultySubject subject) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final topicCtrl = TextEditingController();
    final totalMarksCtrl = TextEditingController(text: '50');
    final passingMarksCtrl = TextEditingController(text: '20');
    final durationCtrl = TextEditingController(text: '60');
    String selectedType = 'INTERNAL_EXAM';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 3));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Assessment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Assessment Title *',
                    hintText: 'e.g. CIA 1 - Units 1 & 2',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration:
                      const InputDecoration(labelText: 'Assessment Type'),
                  items: const [
                    DropdownMenuItem(
                        value: 'INTERNAL_EXAM',
                        child: Text('Internal Exam (CIA)')),
                    DropdownMenuItem(
                        value: 'QUIZ', child: Text('Unit Quiz / MCQ')),
                    DropdownMenuItem(
                        value: 'LAB_EXAM', child: Text('Lab Viva / Practical')),
                    DropdownMenuItem(
                        value: 'SEMESTER_EXAM',
                        child: Text('End-Sem Model Exam')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: unitCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Unit', hintText: 'Unit 1 & 2'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: topicCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Topic', hintText: 'Linear Regression'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: totalMarksCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Max Marks'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: passingMarksCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Pass Marks'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: durationCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Duration (m)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Instructions / Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.purple.shade700),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final ok = await ref
                    .read(facultyControllerProvider.notifier)
                    .createAssessment(
                  subject.id,
                  {
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'assessmentType': selectedType,
                    'unit': unitCtrl.text.trim(),
                    'topic': topicCtrl.text.trim(),
                    'totalMarks':
                        int.tryParse(totalMarksCtrl.text.trim()) ?? 50,
                    'passingMarks':
                        int.tryParse(passingMarksCtrl.text.trim()) ?? 20,
                    'durationMinutes':
                        int.tryParse(durationCtrl.text.trim()) ?? 60,
                    'scheduledAt': selectedDate.toIso8601String(),
                  },
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: ok ? Colors.purple.shade700 : Colors.red,
                      content: Text(ok
                          ? 'Assessment created successfully!'
                          : 'Failed to create assessment'),
                    ),
                  );
                }
              },
              child: const Text('Create Assessment'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGradeAssessmentDialog(
    BuildContext context,
    FacultySubject subject,
    SubjectAssessment assessment,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _GradeAssessmentSheet(subject: subject, assessment: assessment);
      },
    );
  }

  Widget _buildAttendanceTab(BuildContext context, FacultySubject subject) {
    final sessionsAsync =
        ref.watch(facultyAttendanceSessionsProvider(subject.id));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
                bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Class Attendance Records',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.how_to_reg, size: 16),
                label: const Text('Take Attendance'),
                onPressed: () => _showTakeAttendanceDialog(context, subject),
              ),
            ],
          ),
        ),
        Expanded(
          child: AsyncValueWidget<List<AttendanceSession>>(
            value: sessionsAsync,
            data: (sessions) {
              if (sessions.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month_outlined,
                            size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No Attendance Sessions Recorded',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Mark attendance for lectures, tutorials, or lab sessions of ${subject.code}.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () =>
                              _showTakeAttendanceDialog(context, subject),
                          icon:
                              const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Take Today\'s Attendance'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  final pct = session.totalStudents > 0
                      ? ((session.presentCount / session.totalStudents) * 100)
                          .round()
                      : 100;
                  final isLocked = session.status.toUpperCase() == 'LOCKED';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side:
                          BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => SessionAttendanceSheet.show(
                        context,
                        sessionId: session.id,
                        subjectId: subject.id,
                        subjectCode: subject.code,
                        subjectName: subject.name,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.event_note,
                                      color: Colors.teal, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Session Date: ${session.sessionDate}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isLocked
                                                  ? Colors.red
                                                      .withValues(alpha: 0.12)
                                                  : Colors.green
                                                      .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isLocked
                                                      ? Icons.lock
                                                      : Icons.lock_open,
                                                  size: 10,
                                                  color: isLocked
                                                      ? Colors.red
                                                      : Colors.green,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  isLocked ? 'LOCKED' : 'OPEN',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isLocked
                                                        ? Colors.red.shade800
                                                        : Colors.green.shade800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (session.topic != null &&
                                          session.topic!.isNotEmpty)
                                        Text(
                                          'Topic: ${session.topic}',
                                          style: TextStyle(
                                              color: Colors.teal.shade800,
                                              fontSize: 12),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: pct >= 75
                                        ? Colors.green.withValues(alpha: 0.12)
                                        : Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$pct% Present',
                                    style: TextStyle(
                                      color: pct >= 75
                                          ? Colors.green.shade800
                                          : Colors.amber.shade900,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.people_alt_outlined,
                                        size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${session.presentCount} of ${session.totalStudents} students attended',
                                      style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                                const Row(
                                  children: [
                                    Text(
                                      'Mark / View Roster',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.teal,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Icon(Icons.chevron_right,
                                        size: 16, color: Colors.teal),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showTakeAttendanceDialog(BuildContext context, FacultySubject subject) {
    final topicCtrl = TextEditingController();
    final students = subject.enrolledStudents;
    final Map<String, String> statusMap = {};
    for (final s in students) {
      statusMap[s.id] = 'PRESENT';
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.how_to_reg, color: Colors.teal),
              const SizedBox(width: 8),
              Text('Attendance • ${subject.code}'),
            ],
          ),
          content: SizedBox(
            width: 500,
            height: 480,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: topicCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Lecture / Session Topic',
                    hintText: 'e.g. Distributed Consensus & Raft Protocol',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Roster (${students.length} Students)',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Row(
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact),
                          onPressed: () {
                            setState(() {
                              for (final s in students) {
                                statusMap[s.id] = 'PRESENT';
                              }
                            });
                          },
                          child: const Text('All Present'),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact),
                          onPressed: () {
                            setState(() {
                              for (final s in students) {
                                statusMap[s.id] = 'ABSENT';
                              }
                            });
                          },
                          child: const Text('All Absent',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: students.isEmpty
                      ? Center(
                          child: Text(
                            'No enrolled students found in ${subject.code}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.builder(
                          itemCount: students.length,
                          itemBuilder: (ctx, idx) {
                            final s = students[idx];
                            final currentStatus = statusMap[s.id] ?? 'PRESENT';
                            final isPresent = currentStatus == 'PRESENT';

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: isPresent
                                    ? Colors.teal.shade100
                                    : Colors.red.shade100,
                                child: Text(
                                  s.name.isNotEmpty ? s.name[0] : 'S',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isPresent
                                        ? Colors.teal.shade900
                                        : Colors.red.shade900,
                                  ),
                                ),
                              ),
                              title: Text(s.name,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text('Roll: ${s.rollNumber}',
                                  style: const TextStyle(fontSize: 11)),
                              trailing: SegmentedButton<String>(
                                showSelectedIcon: false,
                                segments: const [
                                  ButtonSegment(
                                      value: 'PRESENT', label: Text('P')),
                                  ButtonSegment(
                                      value: 'ABSENT', label: Text('A')),
                                ],
                                selected: {currentStatus},
                                onSelectionChanged: (val) {
                                  setState(() => statusMap[s.id] = val.first);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(backgroundColor: Colors.teal.shade700),
              onPressed: () async {
                Navigator.of(ctx).pop();
                final records = statusMap.entries
                    .map((e) => {
                          'studentId': e.key,
                          'status': e.value,
                        })
                    .toList();

                final ok = await ref
                    .read(facultyControllerProvider.notifier)
                    .recordAttendance(
                  subject.id,
                  {
                    'sessionDate':
                        DateTime.now().toIso8601String().split('T')[0],
                    'topic': topicCtrl.text.trim(),
                    'records': records,
                  },
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: ok ? Colors.teal.shade700 : Colors.red,
                      content: Text(ok
                          ? 'Attendance saved successfully'
                          : 'Failed to save attendance'),
                    ),
                  );
                }
              },
              child: const Text('Save Attendance'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeAssessmentSheet extends ConsumerStatefulWidget {
  final FacultySubject subject;
  final SubjectAssessment assessment;

  const _GradeAssessmentSheet({
    required this.subject,
    required this.assessment,
  });

  @override
  ConsumerState<_GradeAssessmentSheet> createState() =>
      _GradeAssessmentSheetState();
}

class _GradeAssessmentSheetState extends ConsumerState<_GradeAssessmentSheet> {
  final Map<String, TextEditingController> _marksControllers = {};
  final Map<String, TextEditingController> _gradeControllers = {};
  final Map<String, TextEditingController> _remarksControllers = {};
  bool _isInitialized = false;

  @override
  void dispose() {
    for (final c in _marksControllers.values) {
      c.dispose();
    }
    for (final c in _gradeControllers.values) {
      c.dispose();
    }
    for (final c in _remarksControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initControllers(List<StudentAssessmentResult> existingResults) {
    if (_isInitialized) return;
    final resultMap = {for (final r in existingResults) r.studentId: r};

    for (final student in widget.subject.enrolledStudents) {
      final res = resultMap[student.id];
      _marksControllers[student.id] = TextEditingController(
        text: res?.marksObtained != null ? res!.marksObtained.toString() : '',
      );
      _gradeControllers[student.id] = TextEditingController(
        text: res?.grade ?? '',
      );
      _remarksControllers[student.id] = TextEditingController(
        text: res?.remarks ?? '',
      );
    }
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resultsAsync =
        ref.watch(facultyAssessmentResultsProvider(widget.assessment.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return resultsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading scores: $e')),
          data: (existingResults) {
            _initControllers(existingResults);

            return Padding(
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Grade Assessment: ${widget.assessment.title}',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Max Marks: ${widget.assessment.totalMarks} • Pass: ${widget.assessment.passingMarks}',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  if (widget.subject.enrolledStudents.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                            'No students currently enrolled in this subject'),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: widget.subject.enrolledStudents.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final student =
                              widget.subject.enrolledStudents[index];
                          final marksCtrl = _marksControllers[student.id];
                          final gradeCtrl = _gradeControllers[student.id];
                          final remarksCtrl = _remarksControllers[student.id];

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.purple.shade100,
                                      backgroundImage:
                                          student.avatarUrl != null &&
                                                  student.avatarUrl!.isNotEmpty
                                              ? NetworkImage(
                                                  ApiEndpoints.resolveUrl(
                                                      student.avatarUrl!))
                                              : null,
                                      child: student.avatarUrl == null ||
                                              student.avatarUrl!.isEmpty
                                          ? Text(
                                              student.name.isNotEmpty
                                                  ? student.name[0]
                                                      .toUpperCase()
                                                  : 'S',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      Colors.purple.shade900),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14),
                                          ),
                                          Text(
                                            student.rollNumber,
                                            style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 80,
                                      child: TextField(
                                        controller: marksCtrl,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        decoration: InputDecoration(
                                          labelText: 'Score',
                                          suffixText:
                                              '/${widget.assessment.totalMarks}',
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 8),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 65,
                                      child: TextField(
                                        controller: gradeCtrl,
                                        decoration: InputDecoration(
                                          labelText: 'Grade',
                                          hintText: 'A+',
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 8),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: remarksCtrl,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Feedback / Remarks for student...',
                                    hintStyle: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade300),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final List<Map<String, dynamic>> resultsList = [];
                        for (final student in widget.subject.enrolledStudents) {
                          final marksText =
                              _marksControllers[student.id]?.text.trim() ?? '';
                          final gradeText =
                              _gradeControllers[student.id]?.text.trim() ?? '';
                          final remarksText =
                              _remarksControllers[student.id]?.text.trim() ??
                                  '';
                          final marks = double.tryParse(marksText);

                          if (marks != null ||
                              gradeText.isNotEmpty ||
                              remarksText.isNotEmpty) {
                            resultsList.add({
                              'studentId': student.id,
                              if (marks != null) 'marksObtained': marks,
                              if (gradeText.isNotEmpty) 'grade': gradeText,
                              if (remarksText.isNotEmpty)
                                'remarks': remarksText,
                              'status': 'EVALUATED',
                            });
                          }
                        }

                        Navigator.pop(context);
                        final ok = await ref
                            .read(facultyControllerProvider.notifier)
                            .recordAssessmentMarks(
                              widget.assessment.id,
                              {'results': resultsList},
                              widget.subject.id,
                            );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor:
                                  ok ? Colors.purple.shade700 : Colors.red,
                              content: Text(ok
                                  ? 'Assessment scores saved successfully!'
                                  : 'Failed to save scores'),
                            ),
                          );
                        }
                      },
                      child: const Text('Save Assessment Grades'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
