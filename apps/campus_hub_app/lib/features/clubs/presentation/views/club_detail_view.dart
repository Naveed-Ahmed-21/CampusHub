import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/clubs_repository.dart';
import '../providers/club_provider.dart';

String formatDateTime(DateTime dt) {
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

String formatTime(DateTime dt) {
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class ClubDetailView extends ConsumerStatefulWidget {
  final String clubId;

  const ClubDetailView({super.key, required this.clubId});

  @override
  ConsumerState<ClubDetailView> createState() => _ClubDetailViewState();
}

class _ClubDetailViewState extends ConsumerState<ClubDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _chatController = TextEditingController();
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _joinClub() async {
    setState(() => _isActionLoading = true);
    try {
      final repo = ref.read(clubsRepositoryProvider);
      await repo.joinClub(widget.clubId);
      ref.invalidate(clubDetailsProvider(widget.clubId));
      ref.invalidate(clubMembersProvider(widget.clubId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined the club!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join club: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _leaveClub() async {
    setState(() => _isActionLoading = true);
    try {
      final repo = ref.read(clubsRepositoryProvider);
      await repo.leaveClub(widget.clubId);
      ref.invalidate(clubDetailsProvider(widget.clubId));
      ref.invalidate(clubMembersProvider(widget.clubId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left the club.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave club: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  // Dialog to create a Feed Post
  void _showCreatePostDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Club Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Content',
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
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                final repo = ref.read(clubsRepositoryProvider);
                await repo.createClubPost(widget.clubId, titleCtrl.text.trim(), contentCtrl.text.trim());
                ref.invalidate(clubFeedProvider(widget.clubId));
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating post: $e')),
                  );
                }
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  // Dialog to create an Event
  void _showCreateEventDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final venueCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Club Event'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: venueCtrl,
                decoration: const InputDecoration(
                  labelText: 'Venue / Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
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
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                final repo = ref.read(clubsRepositoryProvider);
                final now = DateTime.now();
                await repo.createClubEvent(
                  clubId: widget.clubId,
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  venue: venueCtrl.text.trim(),
                  startTime: now.add(const Duration(days: 1)),
                  endTime: now.add(const Duration(days: 1, hours: 2)),
                );
                ref.invalidate(clubEventsProvider(widget.clubId));
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating event: $e')),
                  );
                }
              }
            },
            child: const Text('Create Event'),
          ),
        ],
      ),
    );
  }

  // Dialog to Upload Resource
  void _showCreateResourceDialog() {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload Club Resource'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Resource Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'File URL / Link',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'File Name',
                hintText: 'e.g. Workshop_Guide.pdf',
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
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty || urlCtrl.text.trim().isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                final repo = ref.read(clubsRepositoryProvider);
                await repo.createClubResource(
                  clubId: widget.clubId,
                  title: titleCtrl.text.trim(),
                  fileUrl: urlCtrl.text.trim(),
                  fileName: nameCtrl.text.trim().isEmpty ? 'document.pdf' : nameCtrl.text.trim(),
                  fileType: 'PDF',
                );
                ref.invalidate(clubResourcesProvider(widget.clubId));
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error uploading resource: $e')),
                  );
                }
              }
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendChatMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    _chatController.clear();
    try {
      final repo = ref.read(clubsRepositoryProvider);
      await repo.sendChatMessage(widget.clubId, text);
      ref.invalidate(clubChatMessagesProvider(widget.clubId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clubAsync = ref.watch(clubDetailsProvider(widget.clubId));
    final membersAsync = ref.watch(clubMembersProvider(widget.clubId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Club Details'),
      ),
      body: clubAsync.when(
        data: (club) {
          final isMember = membersAsync.valueOrNull?.any((m) => m.userId.isNotEmpty) ?? false;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.blue.shade100,
                            backgroundImage: club.logoUrl != null ? NetworkImage(club.logoUrl!) : null,
                            child: club.logoUrl == null
                                ? Text(
                                    club.name.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  club.name,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    Chip(
                                      label: Text(club.category, style: const TextStyle(fontSize: 11)),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    if (club.isCrossDepartment)
                                      Chip(
                                        avatar: const Icon(Icons.public, size: 14),
                                        label: const Text('Cross-Dept', style: TextStyle(fontSize: 11)),
                                        backgroundColor: Colors.teal.withValues(alpha: 0.1),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (club.description != null && club.description!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          club.description!,
                          style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.people_outline, size: 20, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('${club.memberCount} Members'),
                            ],
                          ),
                          ElevatedButton.icon(
                            icon: Icon(isMember ? Icons.exit_to_app : Icons.person_add),
                            label: Text(isMember ? 'Leave Club' : 'Join Club'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isMember ? Colors.red.shade400 : Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _isActionLoading
                                ? null
                                : (isMember ? _leaveClub : _joinClub),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(icon: Icon(Icons.dynamic_feed), text: 'Feed'),
                      Tab(icon: Icon(Icons.people), text: 'Members'),
                      Tab(icon: Icon(Icons.event), text: 'Events'),
                      Tab(icon: Icon(Icons.folder_shared), text: 'Resources'),
                      Tab(icon: Icon(Icons.chat), text: 'Chat'),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                // 1. Club Feed Tab
                _buildFeedTab(),

                // 2. Club Members Tab
                _buildMembersTab(),

                // 3. Club Events Tab
                _buildEventsTab(),

                // 4. Club Resources Tab
                _buildResourcesTab(),

                // 5. Club Real-time Chat Tab
                _buildChatTab(),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading club: $err')),
      ),
    );
  }

  // 1. Feed Tab
  Widget _buildFeedTab() {
    final feedAsync = ref.watch(clubFeedProvider(widget.clubId));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePostDialog,
        icon: const Icon(Icons.add_comment),
        label: const Text('Post'),
      ),
      body: feedAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(child: Text('No announcements or feed posts yet!'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (ctx, idx) {
              final post = posts[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            child: Text(post.authorName.isNotEmpty ? post.authorName[0] : 'U'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  formatDateTime(post.createdAt),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(post.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(post.content),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading feed: $err')),
      ),
    );
  }

  // 2. Members Tab
  Widget _buildMembersTab() {
    final membersAsync = ref.watch(clubMembersProvider(widget.clubId));

    return membersAsync.when(
      data: (members) {
        if (members.isEmpty) {
          return const Center(child: Text('No members found.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          separatorBuilder: (ctx, idx) => const Divider(),
          itemBuilder: (ctx, idx) {
            final member = members[idx];
            return ListTile(
              leading: CircleAvatar(
                child: Text(member.firstName.isNotEmpty ? member.firstName[0] : 'M'),
              ),
              title: Text(member.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(member.departmentName ?? member.email),
              trailing: Chip(
                label: Text(member.role),
                backgroundColor: member.role == 'LEAD' ? Colors.amber.shade100 : Colors.grey.shade200,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading members: $err')),
    );
  }

  // 3. Events Tab
  Widget _buildEventsTab() {
    final eventsAsync = ref.watch(clubEventsProvider(widget.clubId));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateEventDialog,
        icon: const Icon(Icons.event_available),
        label: const Text('Add Event'),
      ),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return const Center(child: Text('No club events scheduled yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (ctx, idx) {
              final ev = events[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(ev.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ev.venue != null) Text('Venue: ${ev.venue}'),
                      Text('Starts: ${formatDateTime(ev.startTime)}'),
                      if (ev.description != null) Text(ev.description!),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Register'),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading events: $err')),
      ),
    );
  }

  // 4. Resources Tab
  Widget _buildResourcesTab() {
    final resourcesAsync = ref.watch(clubResourcesProvider(widget.clubId));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateResourceDialog,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
      ),
      body: resourcesAsync.when(
        data: (resources) {
          if (resources.isEmpty) {
            return const Center(child: Text('No resources shared yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: resources.length,
            itemBuilder: (ctx, idx) {
              final res = resources[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file, size: 36, color: Colors.blue),
                  title: Text(res.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('By ${res.uploaderName} • ${res.fileName}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Downloading ${res.fileName}...')),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading resources: $err')),
      ),
    );
  }

  // 5. Chat Tab
  Widget _buildChatTab() {
    final chatAsync = ref.watch(clubChatMessagesProvider(widget.clubId));

    return Column(
      children: [
        Expanded(
          child: chatAsync.when(
            data: (messages) {
              if (messages.isEmpty) {
                return const Center(child: Text('Start the conversation in club chat!'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (ctx, idx) {
                  final msg = messages[idx];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          child: Text(msg.senderName.isNotEmpty ? msg.senderName[0] : 'U'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(msg.senderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(width: 8),
                                  Text(
                                    formatTime(msg.createdAt),
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(msg.message, style: const TextStyle(fontSize: 14)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading chat: $err')),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8.0),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message to club members...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: _sendChatMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
