import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../chat/data/chat_repository.dart';
import '../../../chat/domain/chat_models.dart';
import '../../../clubs/domain/club_models.dart';
import '../../../clubs/presentation/providers/club_provider.dart';
import '../../domain/models/post_item.dart';

class SharePostSheet extends ConsumerStatefulWidget {
  final PostItem post;

  const SharePostSheet({
    super.key,
    required this.post,
  });

  static Future<void> show(BuildContext context, PostItem post) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SharePostSheet(post: post),
    );
  }

  @override
  ConsumerState<SharePostSheet> createState() => _SharePostSheetState();
}

class _ShareDestination {
  final String id;
  final String name;
  final String? subtitle;
  final String? avatarUrl;
  final bool isGroup;
  final String? roomId;
  final String? targetUserId;
  final String? clubId;

  _ShareDestination({
    required this.id,
    required this.name,
    this.subtitle,
    this.avatarUrl,
    required this.isGroup,
    this.roomId,
    this.targetUserId,
    this.clubId,
  });
}

class _SharePostSheetState extends ConsumerState<SharePostSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<String> _selectedIds = {};
  bool _isSharing = false;
  List<ChatRoomModel> _rooms = [];
  bool _isLoadingRooms = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableRooms();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableRooms() async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      final rooms = await repo.getUserRooms();
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _isLoadingRooms = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingRooms = false);
      }
    }
  }

  Future<void> _handleShare(List<_ShareDestination> allDestinations) async {
    final selectedDests = allDestinations.where((d) => _selectedIds.contains(d.id)).toList();
    if (selectedDests.isEmpty) return;

    setState(() => _isSharing = true);

    final chatRepo = ref.read(chatRepositoryProvider);

    final payload = jsonEncode({
      'postId': widget.post.id,
      'title': widget.post.title,
      'content': widget.post.content,
      'authorName': widget.post.authorName,
      'authorAvatar': widget.post.authorAvatarUrl,
      'mediaUrl': widget.post.attachments.isNotEmpty ? widget.post.attachments.first.fileUrl : null,
      'type': widget.post.type,
    });

    int successCount = 0;

    for (final dest in selectedDests) {
      try {
        String? targetRoomId = dest.roomId;

        // If direct chat without established room ID, create/get one
        if (targetRoomId == null && dest.targetUserId != null) {
          final directRoom = await chatRepo.getOrCreateDirectChat(dest.targetUserId!);
          targetRoomId = directRoom.id;
        } else if (targetRoomId == null && dest.clubId != null) {
          final clubRoom = await chatRepo.getOrCreateClubChat(dest.clubId!);
          targetRoomId = clubRoom.id;
        }

        if (targetRoomId != null && targetRoomId.isNotEmpty) {
          await chatRepo.sendMessage(
            roomId: targetRoomId,
            message: payload,
            mediaType: 'POST',
            fileName: widget.post.title,
            mediaUrl: widget.post.attachments.isNotEmpty ? widget.post.attachments.first.fileUrl : null,
          );
          successCount++;
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isSharing = false);
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post shared successfully with $successCount ${successCount == 1 ? 'chat' : 'chats'}!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = ref.watch(authControllerProvider).asData?.value?.id ?? '';
    final myClubsAsync = ref.watch(myClubsProvider);

    final destinations = <_ShareDestination>[];

    // 1. Direct chats from existing chat rooms
    for (final r in _rooms) {
      if (r.type == 'DIRECT') {
        final otherUser = r.participants.firstWhere(
          (p) => p.id != currentUserId,
          orElse: () => r.participants.isNotEmpty ? r.participants.first : ChatParticipantUser(id: '', firstName: 'User', lastName: '', email: ''),
        );
        if (otherUser.id.isNotEmpty) {
          destinations.add(
            _ShareDestination(
              id: 'dm_${otherUser.id}',
              name: otherUser.fullName.isNotEmpty ? otherUser.fullName : otherUser.displayUsername,
              subtitle: otherUser.departmentName != null ? '${otherUser.departmentName} • Direct' : 'Direct Message',
              avatarUrl: otherUser.avatarUrl,
              isGroup: false,
              roomId: r.id,
              targetUserId: otherUser.id,
            ),
          );
        }
      } else {
        // Group or Club chat room
        destinations.add(
          _ShareDestination(
            id: 'room_${r.id}',
            name: r.name ?? 'Campus Group',
            subtitle: 'Group Chat • ${r.memberCount} members',
            avatarUrl: r.avatarUrl,
            isGroup: true,
            roomId: r.id,
          ),
        );
      }
    }

    // 2. Clubs the user has joined (from myClubsProvider)
    final myClubs = myClubsAsync.asData?.value ?? <Club>[];
    for (final club in myClubs) {
      final existsInRooms = destinations.any((d) => d.name == club.name || d.id == 'club_${club.id}');
      if (!existsInRooms) {
        destinations.add(
          _ShareDestination(
            id: 'club_${club.id}',
            name: club.name,
            subtitle: '${club.category} • Club',
            avatarUrl: club.logoUrl,
            isGroup: true,
            clubId: club.id,
          ),
        );
      }
    }

    // Filter by search query
    final query = _searchCtrl.text.trim().toLowerCase();
    final filteredDestinations = query.isEmpty
        ? destinations
        : destinations.where((d) => d.name.toLowerCase().contains(query) || (d.subtitle?.toLowerCase().contains(query) ?? false)).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4.5,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share Post',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Send as interactive card in chat',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: '${ApiEndpoints.baseUrl}/api/v1/posts/${widget.post.id}'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post link copied to clipboard!')),
                    );
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.link, size: 16),
                  label: const Text('Copy Link', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search people or groups...',
                  hintStyle: TextStyle(fontSize: 13, color: theme.colorScheme.outline),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.cancel, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          const Divider(height: 12),

          // Destinations List
          Expanded(
            child: _isLoadingRooms
                ? const Center(child: CircularProgressIndicator())
                : filteredDestinations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 48, color: theme.colorScheme.outline),
                            const SizedBox(height: 8),
                            Text(
                              query.isEmpty ? 'No recent chats or joined groups' : 'No matches found',
                              style: TextStyle(color: theme.colorScheme.outline),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        itemCount: filteredDestinations.length,
                        itemBuilder: (ctx, idx) {
                          final dest = filteredDestinations[idx];
                          final isSelected = _selectedIds.contains(dest.id);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: CheckboxListTile(
                              value: isSelected,
                              activeColor: theme.colorScheme.primary,
                              checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedIds.add(dest.id);
                                  } else {
                                    _selectedIds.remove(dest.id);
                                  }
                                });
                              },
                              secondary: CircleAvatar(
                                radius: 20,
                                backgroundColor: dest.isGroup
                                    ? theme.colorScheme.secondaryContainer
                                    : theme.colorScheme.primaryContainer,
                                backgroundImage: dest.avatarUrl != null && dest.avatarUrl!.isNotEmpty
                                    ? NetworkImage(ApiEndpoints.resolveUrl(dest.avatarUrl!))
                                    : null,
                                child: dest.avatarUrl == null || dest.avatarUrl!.isEmpty
                                    ? Icon(
                                        dest.isGroup ? Icons.groups : Icons.person,
                                        size: 20,
                                        color: dest.isGroup
                                            ? theme.colorScheme.onSecondaryContainer
                                            : theme.colorScheme.onPrimaryContainer,
                                      )
                                    : null,
                              ),
                              title: Text(
                                dest.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: dest.subtitle != null
                                  ? Text(dest.subtitle!, style: TextStyle(fontSize: 12, color: theme.colorScheme.outline))
                                  : null,
                            ),
                          );
                        },
                      ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedIds.isEmpty
                          ? 'Select recipients to share'
                          : '${_selectedIds.length} ${_selectedIds.length == 1 ? 'recipient' : 'recipients'} selected',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _selectedIds.isEmpty ? FontWeight.normal : FontWeight.bold,
                        color: _selectedIds.isEmpty ? theme.colorScheme.outline : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _selectedIds.isEmpty || _isSharing
                        ? null
                        : () => _handleShare(destinations),
                    icon: _isSharing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 16),
                    label: Text(
                      _selectedIds.length > 1 ? 'Share to (${_selectedIds.length})' : 'Share',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
}
