import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/media_picker_service.dart';
import '../../../../core/services/media_upload_service.dart';
import '../../../../core/services/media_storage_service.dart';
import '../../../../core/services/file_open_service.dart';
import '../../../../shared/widgets/selected_media_preview_widget.dart';
import '../../../../shared/widgets/user_picker_bottom_sheet.dart';
import '../../data/clubs_repository.dart';
import '../../domain/club_models.dart';
import '../providers/club_provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../chat/presentation/views/chat_room_view.dart';
import '../../../feed/presentation/widgets/create_post_sheet.dart';
import '../../../feed/presentation/widgets/feed_post_card_widget.dart';
import '../../../feed/presentation/widgets/comments_sheet.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/widgets/full_screen_image_viewer.dart';

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
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
  void _showCreatePostSheet(Club? club) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreatePostSheet(
        clubId: widget.clubId,
        clubName: club?.name,
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
    SelectedMediaFile? selectedFile;
    bool isUploading = false;
    double? uploadProgress;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Upload Club Resource', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    enabled: !isUploading,
                    decoration: const InputDecoration(
                      labelText: 'Resource Title',
                      hintText: 'e.g. Workshop Guide / Assignment Sheet',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (selectedFile == null) ...[
                    OutlinedButton.icon(
                      onPressed: isUploading
                          ? null
                          : () async {
                              final files = await MediaPickerService.pickDocuments(
                                allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt', 'zip'],
                                allowMultiple: false,
                              );
                              if (files.isNotEmpty) {
                                setModalState(() {
                                  selectedFile = files.first;
                                  if (titleCtrl.text.trim().isEmpty) {
                                    titleCtrl.text = selectedFile!.name.split('.').first;
                                  }
                                });
                              }
                            },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Select File from Device'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ] else ...[
                    SelectedMediaPreviewWidget(
                      file: selectedFile!,
                      isUploading: isUploading,
                      uploadProgress: uploadProgress,
                      onRemove: isUploading
                          ? null
                          : () => setModalState(() => selectedFile = null),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cloud_upload, size: 16),
                label: Text(isUploading ? 'Uploading...' : 'Upload'),
                onPressed: isUploading || selectedFile == null
                    ? null
                    : () async {
                        if (titleCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a title for the resource')),
                          );
                          return;
                        }

                        setModalState(() {
                          isUploading = true;
                          uploadProgress = 0.0;
                        });

                        try {
                          final uploadService = ref.read(mediaUploadServiceProvider);
                          final uploadResult = await uploadService.uploadSelectedFile(
                            selectedFile!,
                            onProgress: (sent, total) {
                              if (total > 0) {
                                setModalState(() => uploadProgress = sent / total);
                              }
                            },
                          );

                          final repo = ref.read(clubsRepositoryProvider);
                          await repo.createClubResource(
                            clubId: widget.clubId,
                            title: titleCtrl.text.trim(),
                            fileUrl: uploadResult.url,
                            fileName: uploadResult.fileName,
                            fileType: selectedFile!.mimeType,
                          );

                          if (ctx.mounted) Navigator.of(ctx).pop();
                          ref.invalidate(clubResourcesProvider(widget.clubId));

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Resource uploaded successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          setModalState(() => isUploading = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error uploading resource: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
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
          final theme = Theme.of(context);
          final currentUser = ref.watch(authControllerProvider).asData?.value;
          final isMember = membersAsync.valueOrNull?.any((m) => m.userId == currentUser?.id) ?? false;

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
                          GestureDetector(
                            onTap: () {
                              if (club.logoUrl != null && club.logoUrl!.isNotEmpty) {
                                FullScreenImageViewer.openSingle(
                                  context,
                                  imageUrl: club.logoUrl!,
                                  heroTag: 'club_logo_${club.id}',
                                  title: club.name,
                                  subtitle: club.category,
                                );
                              }
                            },
                            child: Hero(
                              tag: 'club_logo_${club.id}',
                              child: CircleAvatar(
                                radius: 36,
                                backgroundColor: theme.colorScheme.primaryContainer,
                                backgroundImage: club.logoUrl != null
                                    ? NetworkImage(ApiEndpoints.resolveUrl(club.logoUrl!))
                                    : null,
                                child: club.logoUrl == null
                                    ? Text(
                                        club.name.substring(0, 1).toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onPrimaryContainer,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
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
                                  runSpacing: 4,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        club.category,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    if (club.isCrossDepartment)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.public, size: 12, color: Colors.teal),
                                            SizedBox(width: 3),
                                            Text(
                                              'Cross-Dept',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.teal,
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
                        ],
                      ),
                      if (club.description != null && club.description!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          club.description!,
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.people_outline, size: 20, color: theme.colorScheme.outline),
                              const SizedBox(width: 6),
                              Text(
                                '${club.memberCount} Members',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          isMember
                              ? OutlinedButton.icon(
                                  icon: Icon(Icons.exit_to_app, size: 16, color: theme.colorScheme.error),
                                  label: Text('Leave Club', style: TextStyle(color: theme.colorScheme.error)),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                                  ),
                                  onPressed: _isActionLoading ? null : _leaveClub,
                                )
                              : FilledButton.icon(
                                  icon: const Icon(Icons.person_add, size: 16),
                                  label: const Text('Join Club'),
                                  onPressed: _isActionLoading ? null : _joinClub,
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
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.outline,
                    indicatorColor: theme.colorScheme.primary,
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
                _buildFeedTab(club),

                // 2. Club Members Tab
                _buildMembersTab(club),

                // 3. Club Events Tab
                _buildEventsTab(),

                // 4. Club Resources Tab
                _buildResourcesTab(),

                // 5. Club Real-time Chat Tab
                _buildChatTab(isMember),
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
  Widget _buildFeedTab(Club club) {
    final feedAsync = ref.watch(clubFeedProvider(widget.clubId));
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _showCreatePostSheet(club),
        icon: const Icon(Icons.add_comment),
        label: const Text('Post to Club'),
      ),
      body: feedAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(clubFeedProvider(widget.clubId)),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 48),
                        Icon(Icons.dynamic_feed_outlined, size: 56, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        const Text('No announcements or feed posts yet!'),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => _showCreatePostSheet(club),
                          icon: const Icon(Icons.add),
                          label: const Text('Create First Club Post'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(clubFeedProvider(widget.clubId)),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: posts.length,
              itemBuilder: (ctx, idx) {
                final post = posts[idx];
                return FeedPostCardWidget(
                  post: post,
                  onOpenComments: () => PostCommentsSheet.show(context, post.id),
                  onPostDeleted: () => ref.invalidate(clubFeedProvider(widget.clubId)),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading feed: $err')),
      ),
    );
  }

  void _openAddMemberSheet(Set<String> existingMemberIds) {
    UserPickerBottomSheet.show(
      context: context,
      mode: UserPickerMode.addClubMember,
      clubId: widget.clubId,
      excludedUserIds: existingMemberIds,
    );
  }

  Map<String, dynamic> _getRoleInfo(String role, bool isCreator) {
    if (isCreator || role == 'LEAD' || role == 'ADMIN') {
      return {
        'label': 'Club Lead',
        'icon': Icons.workspace_premium,
        'color': Colors.amber.shade800,
      };
    } else if (role == 'ASSISTANT_ADMIN') {
      return {
        'label': 'Assistant Admin',
        'icon': Icons.shield_outlined,
        'color': Colors.blue.shade700,
      };
    } else if (role == 'FACULTY_ADVISOR') {
      return {
        'label': 'Faculty Advisor',
        'icon': Icons.school_outlined,
        'color': Colors.teal.shade700,
      };
    } else if (role == 'TECHNICAL_LEADER') {
      return {
        'label': 'Technical Lead',
        'icon': Icons.code_rounded,
        'color': Colors.purple.shade700,
      };
    } else if (role == 'EVENT_LEADER') {
      return {
        'label': 'Event Lead',
        'icon': Icons.event_available,
        'color': Colors.deepOrange.shade700,
      };
    } else {
      return {
        'label': 'Member',
        'icon': Icons.person_outline,
        'color': Colors.grey.shade700,
      };
    }
  }

  void _showChangeMemberRoleSheet(Club club, ClubMember member) {
    final theme = Theme.of(context);
    final isTechClub = club.category.toUpperCase().contains('TECH') ||
        club.name.toUpperCase().contains('CODING') ||
        club.name.toUpperCase().contains('DEV') ||
        club.name.toUpperCase().contains('ROBOTIC');

    final roleOptions = [
      {
        'role': 'MEMBER',
        'title': 'Member',
        'subtitle': 'Standard club member with feed & resources access',
        'icon': Icons.person_outline,
        'color': Colors.grey.shade700,
      },
      {
        'role': 'ASSISTANT_ADMIN',
        'title': 'Assistant Admin',
        'subtitle': 'Co-manages club activities, announcements & members',
        'icon': Icons.shield_outlined,
        'color': Colors.blue.shade700,
      },
      {
        'role': 'FACULTY_ADVISOR',
        'title': 'Faculty Advisor',
        'subtitle': 'Faculty / Staff mentor overseeing the club',
        'icon': Icons.school_outlined,
        'color': Colors.teal.shade700,
      },
      if (isTechClub)
        {
          'role': 'TECHNICAL_LEADER',
          'title': 'Technical Leader',
          'subtitle': 'Leads technical workshops, hackathons & code projects',
          'icon': Icons.code_rounded,
          'color': Colors.purple.shade700,
        },
      {
        'role': 'EVENT_LEADER',
        'title': 'Event Leader',
        'subtitle': 'Organizes & manages club events and meetups',
        'icon': Icons.event_available,
        'color': Colors.deepOrange.shade700,
      },
      {
        'role': 'LEAD',
        'title': 'Club Lead / Admin',
        'subtitle': 'Primary club administrator and coordinator',
        'icon': Icons.workspace_premium,
        'color': Colors.amber.shade800,
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
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
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        member.firstName.isNotEmpty ? member.firstName[0].toUpperCase() : 'M',
                        style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(member.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Change club role in ${club.name}', style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...roleOptions.map((opt) {
                final roleCode = opt['role'] as String;
                final isCurrent = member.role == roleCode;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: (opt['color'] as Color).withValues(alpha: 0.12),
                    child: Icon(opt['icon'] as IconData, color: opt['color'] as Color, size: 22),
                  ),
                  title: Row(
                    children: [
                      Text(opt['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'CURRENT',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(opt['subtitle'] as String, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                  trailing: isCurrent ? Icon(Icons.check_circle, color: theme.colorScheme.primary) : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (isCurrent) return;

                    try {
                      final repo = ref.read(clubsRepositoryProvider);
                      await repo.updateMemberRole(club.id, member.userId, roleCode);
                      ref.invalidate(clubMembersProvider(club.id));
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Updated ${member.fullName}\'s role to ${opt['title']}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update role: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Members Tab
  Widget _buildMembersTab(Club club) {
    final theme = Theme.of(context);
    final membersAsync = ref.watch(clubMembersProvider(widget.clubId));
    final currentUser = ref.watch(authControllerProvider).asData?.value;

    return membersAsync.when(
      data: (members) {
        final existingMemberIds = members.map((m) => m.userId).toSet();
        final currentMember = members.where((m) => m.userId == currentUser?.id).firstOrNull;
        final isCreator = club.createdById == currentUser?.id;
        final isLeadOrAdvisor = currentMember?.role == 'LEAD' || currentMember?.role == 'FACULTY_ADVISOR' || currentMember?.role == 'ASSISTANT_ADMIN';
        final isCollegeAdmin = currentUser?.role == 'ADMIN' || currentUser?.role == 'COLLEGE_ADMIN' || currentUser?.role == 'SUPER_ADMIN';
        final canManageMembers = isCreator || isLeadOrAdvisor || isCollegeAdmin;

        return Scaffold(
          floatingActionButton: canManageMembers
              ? FloatingActionButton.extended(
                  heroTag: null,
                  onPressed: () => _openAddMemberSheet(existingMemberIds),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Member'),
                )
              : null,
          body: members.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 56, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        Text(
                          'No members in this club yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (canManageMembers) ...[
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => _openAddMemberSheet(existingMemberIds),
                            icon: const Icon(Icons.person_add),
                            label: const Text('Add First Member'),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final member = members[idx];
                    final isLeadOrCreator = member.role == 'LEAD' ||
                        member.role == 'ADMIN' ||
                        member.userId == club.createdById;

                    final roleInfo = _getRoleInfo(member.role, isLeadOrCreator);

                    return Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => context.push('/profile/${member.userId}'),
                        onLongPress: canManageMembers ? () => _showChangeMemberRoleSheet(club, member) : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: isLeadOrCreator
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.surfaceContainerHighest,
                                child: Text(
                                  member.firstName.isNotEmpty ? member.firstName[0].toUpperCase() : 'M',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isLeadOrCreator
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            member.fullName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      member.departmentName ?? member.email,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (roleInfo['color'] as Color).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: (roleInfo['color'] as Color).withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(roleInfo['icon'] as IconData, size: 13, color: roleInfo['color'] as Color),
                                    const SizedBox(width: 4),
                                    Text(
                                      roleInfo['label'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: roleInfo['color'] as Color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (canManageMembers) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.more_vert, size: 18),
                                  tooltip: 'Change Role',
                                  onPressed: () => _showChangeMemberRoleSheet(club, member),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading members: $err')),
    );
  }

  // 3. Events Tab
  Widget _buildEventsTab() {
    final eventsAsync = ref.watch(clubEventsProvider(widget.clubId));
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _showCreateEventDialog,
        icon: const Icon(Icons.event_available),
        label: const Text('Add Event'),
      ),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy_outlined, size: 56, color: theme.colorScheme.outline),
                    const SizedBox(height: 12),
                    const Text('No club events scheduled yet.'),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (ctx, idx) {
              final ev = events[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ev.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      if (ev.venue != null && ev.venue!.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(ev.venue!, style: TextStyle(fontSize: 12.5, color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(formatDateTime(ev.startTime), style: TextStyle(fontSize: 12.5, color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                      if (ev.description != null && ev.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(ev.description!, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface)),
                      ],
                    ],
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
    final theme = Theme.of(context);
    final currentUserId = ref.watch(authControllerProvider).asData?.value?.id ?? '';

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _showCreateResourceDialog,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
      ),
      body: resourcesAsync.when(
        data: (resources) {
          if (resources.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open_outlined, size: 56, color: theme.colorScheme.outline),
                    const SizedBox(height: 12),
                    const Text('No resources shared yet.'),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: resources.length,
            itemBuilder: (ctx, idx) {
              final res = resources[idx];
              return _ClubResourceTile(
                resource: res,
                currentUserId: currentUserId,
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
  Widget _buildChatTab(bool isMember) {
    final theme = Theme.of(context);
    if (!isMember) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              const Text(
                'Members-Only Group Chat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Join this club to view and participate in official group chat discussions.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isActionLoading ? null : _joinClub,
                icon: const Icon(Icons.person_add),
                label: const Text('Join Club Now'),
              ),
            ],
          ),
        ),
      );
    }

    final roomAsync = ref.watch(clubChatRoomProvider(widget.clubId));

    return roomAsync.when(
      data: (room) => ChatRoomView(
        roomId: room.id,
        isEmbedded: true,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(
                'Error loading club chat: $err',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(clubChatRoomProvider(widget.clubId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
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
      color: Theme.of(context).colorScheme.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

class _ClubResourceTile extends ConsumerStatefulWidget {
  final ClubResource resource;
  final String currentUserId;

  const _ClubResourceTile({
    required this.resource,
    required this.currentUserId,
  });

  @override
  ConsumerState<_ClubResourceTile> createState() => _ClubResourceTileState();
}

class _ClubResourceTileState extends ConsumerState<_ClubResourceTile> {
  bool _isDownloading = false;
  double _progress = 0.0;
  bool _isDownloaded = false;
  String? _localPath;

  bool get _isUploader =>
      widget.resource.uploadedById.isNotEmpty &&
      widget.resource.uploadedById == widget.currentUserId;

  @override
  void initState() {
    super.initState();
    _checkDownloadedState();
  }

  void _checkDownloadedState() {
    final storage = ref.read(mediaStorageServiceProvider);
    final cacheKey = 'club_res_${widget.resource.id}';
    final downloaded = storage.isMessageMediaDownloaded(cacheKey);
    if (downloaded) {
      final path = storage.getDownloadedPathForMessage(cacheKey);
      if (path != null && File(path).existsSync()) {
        _isDownloaded = true;
        _localPath = path;
      }
    }
  }

  Future<void> _handleDownload() async {
    final res = widget.resource;
    if (res.fileUrl.isEmpty) return;

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
    });

    try {
      final storage = ref.read(mediaStorageServiceProvider);
      final cacheKey = 'club_res_${res.id}';
      final path = await storage.downloadAndSaveFile(
        fileUrl: res.fileUrl,
        messageId: cacheKey,
        fileName: res.fileName,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );

      if (mounted) {
        if (path != null) {
          setState(() {
            _isDownloaded = true;
            _localPath = path;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved "${res.fileName}" to CampusHub folder.'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Open',
                textColor: Colors.white,
                onPressed: () => FileOpenService.openLocalFile(path, context: context),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _handleOpen() async {
    final res = widget.resource;
    final storage = ref.read(mediaStorageServiceProvider);
    final cacheKey = 'club_res_${res.id}';

    String? path = _localPath;
    if (path == null || !File(path).existsSync()) {
      if (storage.isMessageMediaDownloaded(cacheKey)) {
        path = storage.getDownloadedPathForMessage(cacheKey);
      }
    }

    if (path == null || !File(path).existsSync()) {
      // If file not on disk yet (e.g. uploader on different device), fetch transparently
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening file...'), duration: Duration(seconds: 1)),
        );
      }
      path = await storage.downloadAndSaveFile(
        fileUrl: res.fileUrl,
        messageId: cacheKey,
        fileName: res.fileName,
      );
      if (mounted && path != null) {
        setState(() {
          _isDownloaded = true;
          _localPath = path;
        });
      }
    }

    if (path != null && mounted) {
      await FileOpenService.openLocalFile(path, context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final res = widget.resource;
    final docInfo = FileOpenService.getDocumentTypeInfo(res.fileName);
    final canOpen = _isUploader || _isDownloaded;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: canOpen ? _handleOpen : _handleDownload,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: docInfo.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(docInfo.icon, color: docInfo.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      res.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: docInfo.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            docInfo.typeLabel,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: docInfo.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'By ${res.uploaderName.isNotEmpty ? res.uploaderName : 'Club Member'} • ${res.fileName}',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (res.description != null && res.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        res.description!,
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Action Button: Open for Sender/Downloaded, Download for Receiver
              if (_isDownloading)
                SizedBox(
                  width: 32,
                  height: 32,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _progress > 0 ? _progress : null,
                        strokeWidth: 3,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                )
              else if (canOpen)
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: _handleOpen,
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('Open', style: TextStyle(fontSize: 12)),
                )
              else
                IconButton.filledTonal(
                  icon: const Icon(Icons.download_rounded, size: 18),
                  tooltip: 'Download Resource',
                  onPressed: _handleDownload,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
