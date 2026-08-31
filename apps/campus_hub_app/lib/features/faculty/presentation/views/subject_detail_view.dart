import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/responsive/responsive_layout.dart';
import '../../../../shared/widgets/async_value_widget.dart';
import '../controllers/faculty_controller.dart';
import '../../domain/models/faculty_models.dart';
import '../widgets/upload_resource_dialog.dart';
import '../widgets/add_announcement_dialog.dart';

class SubjectDetailView extends ConsumerStatefulWidget {
  final String subjectId;

  const SubjectDetailView({super.key, required this.subjectId});

  @override
  ConsumerState<SubjectDetailView> createState() => _SubjectDetailViewState();
}

class _SubjectDetailViewState extends ConsumerState<SubjectDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjectAsync = ref.watch(facultySubjectDetailProvider(widget.subjectId));

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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(icon: Icon(Icons.info_outline, size: 18), text: 'Overview'),
                Tab(icon: Icon(Icons.folder_open, size: 18), text: 'Study Materials'),
                Tab(icon: Icon(Icons.campaign, size: 18), text: 'Announcements'),
                Tab(icon: Icon(Icons.group_outlined, size: 18), text: 'Enrolled Students'),
              ],
            ),
          ),
          body: ResponsiveLayout(
            mobile: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(context, subject),
                _buildResourcesTab(context, subject),
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
                    _buildResourcesTab(context, subject),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    subject.name,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${subject.department} • ${subject.semester} • Section ${subject.section}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                  ),
                  const Divider(height: 28),
                  Text(
                    'Syllabus & Course Objectives',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            title: Text(resource.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              resource.description ?? 'Uploaded by ${resource.uploadedByName}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.open_in_new, color: Colors.blue),
              tooltip: 'Open in ImageKit viewer',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Opening resource: ${resource.fileUrl}')),
                );
              },
            ),
          ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Class Notice',
                        style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  announcement.content,
                  style: const TextStyle(height: 1.4),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person_pin, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Posted by ${announcement.authorName}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
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

  Widget _buildStudentsTab(BuildContext context, FacultySubject subject) {
    if (subject.studentsCount == 0) {
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
      itemCount: subject.studentsCount,
      itemBuilder: (context, index) {
        final rollNumber = '21CS0${10 + index}';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                'S${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
            title: Text('Student ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Roll No: $rollNumber • ${subject.semester} • Section ${subject.section}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Enrolled',
                style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }
}
