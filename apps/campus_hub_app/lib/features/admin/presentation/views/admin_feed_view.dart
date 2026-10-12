import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_page_header.dart';
import '../../../feed/presentation/views/feed_view.dart';

class AdminFeedView extends ConsumerStatefulWidget {
  const AdminFeedView({super.key});

  @override
  ConsumerState<AdminFeedView> createState() => _AdminFeedViewState();
}

class _AdminFeedViewState extends ConsumerState<AdminFeedView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showCreatePostDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String selectedType = 'ANNOUNCEMENT';
    String selectedAudience = 'ALL';
    String? selectedDeptId;
    final user = ref.read(authControllerProvider).value;
    final isDeptAdmin = user?.isDeptAdmin == true;
    if (isDeptAdmin && user?.departmentId != null) {
      selectedAudience = 'DEPARTMENT';
      selectedDeptId = user?.departmentId;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final depts = ref.watch(adminDepartmentsProvider).value ?? [];

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.campaign, color: Colors.blue),
                SizedBox(width: 8),
                Text('Create Official Campus Post'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'Post Type *', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'ANNOUNCEMENT', child: Text('Official Announcement', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'ACADEMIC', child: Text('Academic Notice', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'PLACEMENT', child: Text('Career & Placement', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'EVENT', child: Text('Campus Event', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'EMERGENCY', child: Text('Emergency / Urgent Alert', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'GENERAL', child: Text('General Campus Notice', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedType = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Post Title *',
                      hintText: 'e.g. Mid-Term Examination Schedule Released',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Content Details *',
                      hintText: 'Enter complete information for students and staff...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedAudience,
                    decoration: const InputDecoration(labelText: 'Target Audience *', border: OutlineInputBorder()),
                    items: [
                      if (!isDeptAdmin) const DropdownMenuItem(value: 'ALL', child: Text('All Campus Users', overflow: TextOverflow.ellipsis)),
                      const DropdownMenuItem(value: 'STUDENT', child: Text('Students Only', overflow: TextOverflow.ellipsis)),
                      const DropdownMenuItem(value: 'FACULTY', child: Text('Faculty Only', overflow: TextOverflow.ellipsis)),
                      const DropdownMenuItem(value: 'DEPARTMENT', child: Text('Specific Department', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedAudience = val);
                    },
                  ),
                  if (selectedAudience == 'DEPARTMENT' && !isDeptAdmin) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedDeptId,
                      decoration: const InputDecoration(labelText: 'Select Department *', border: OutlineInputBorder()),
                      items: depts.map((d) => DropdownMenuItem(
                        value: d['id'].toString(),
                        child: Text('${d['name']} (${d['code']})', overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (val) => setDialogState(() => selectedDeptId = val),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final content = contentCtrl.text.trim();
                  final messenger = ScaffoldMessenger.of(context);

                  if (title.isEmpty || content.isEmpty) {
                    messenger.showSnackBar(const SnackBar(content: Text('Title and content are required')));
                    return;
                  }

                  Navigator.pop(ctx);
                  try {
                    await ref.read(adminRemoteDataSourceProvider).sendBroadcastNotification({
                      'title': '[$selectedType] $title',
                      'body': content,
                      'targetAudience': selectedAudience,
                      if (selectedDeptId != null) 'departmentId': selectedDeptId,
                    });
                    ref.invalidate(adminModerationPostsProvider);
                    ref.invalidate(adminAuditReportsProvider);
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Official campus post published successfully!'), backgroundColor: Colors.green),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to publish: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
                child: const Text('Publish Post'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(adminModerationPostsProvider(null));
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title: 'Campus Feed & Announcements',
            subtitle: 'Direct administrative feed access, campus-wide broadcast posting, and content moderation.',
            badge: 'INSTITUTIONAL BROADCAST',
            primaryAction: ElevatedButton.icon(
              onPressed: _showCreatePostDialog,
              icon: const Icon(Icons.add_comment, size: 18),
              label: const Text('Create Campus Post'),
            ),
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(icon: Icon(Icons.dynamic_feed), text: 'All-College Feed'),
              Tab(icon: Icon(Icons.shield_outlined), text: 'Content Moderation Queue'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: All-College Feed (Live Campus Hub Community Stream)
                const FeedView(showAppBar: false),

                // Tab 2: Content Moderation Queue
                postsAsync.when(
                  data: (posts) {
                    if (posts.isEmpty) {
                      return const Center(child: Text('Moderation queue clear. No reported posts.', style: TextStyle(color: Colors.grey)));
                    }

                    return ListView.separated(
                      itemCount: posts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final p = posts[i] as Map<String, dynamic>;
                        final id = p['id']?.toString() ?? '';
                        final title = p['title'] ?? 'Untitled';
                        final author = p['author'] as Map<String, dynamic>?;
                        final authorName = author != null ? '${author['first_name']} ${author['last_name']}' : 'User';

                        return Card(
                          elevation: 0.5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: const Icon(Icons.shield_outlined, color: Colors.orange),
                            title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface)),
                            subtitle: Text('Author: $authorName • ID: ${id.length >= 8 ? id.substring(0, 8) : id}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              tooltip: 'Remove Post (Moderation)',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Confirm Moderation Removal'),
                                    content: Text("Remove post '$title' from campus feed?"),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Remove Post'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    await ref.read(adminRemoteDataSourceProvider).deleteModerationPost(id);
                                    ref.invalidate(adminModerationPostsProvider);
                                    ref.invalidate(adminAuditReportsProvider);
                                  } catch (_) {}
                                }
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
