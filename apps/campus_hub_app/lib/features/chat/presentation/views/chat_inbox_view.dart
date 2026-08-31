import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../providers/chat_provider.dart';
import '../../domain/chat_models.dart';
import '../../data/chat_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../shared/widgets/user_picker_bottom_sheet.dart';
import '../utils/chat_date_formatter.dart';

class ChatInboxView extends ConsumerStatefulWidget {
  const ChatInboxView({super.key});

  @override
  ConsumerState<ChatInboxView> createState() => _ChatInboxViewState();
}

class _ChatInboxViewState extends ConsumerState<ChatInboxView>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final _inboxSearchController = TextEditingController();
  final _exploreSearchController = TextEditingController();
  String _inboxSearchQuery = '';
  String _exploreSearchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inboxSearchController.dispose();
    _exploreSearchController.dispose();
    super.dispose();
  }

  Future<void> _openDepartmentChat() async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      final room = await repo.getDepartmentChat();
      ref.invalidate(userChatRoomsProvider);
      if (mounted) {
        context.push('/chat/room/${room.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Department chat error: $e')),
        );
      }
    }
  }

  void _openNewMessageAction() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.person_add_alt_1, color: Colors.white, size: 20),
                ),
                title: const Text('New Direct Message', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Search campus members and start chatting'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  UserPickerBottomSheet.show(
                    context: context,
                    mode: UserPickerMode.newChat,
                  );
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: Icon(Icons.group_add, color: Colors.white, size: 20),
                ),
                title: const Text('Create New Group', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Create a Public or Private group for projects/clubs'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push('/chat/create-group');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final roomsAsync = ref.watch(userChatRoomsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          // Prominent New Message Button at the Top
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilledButton.tonalIcon(
              onPressed: _openNewMessageAction,
              icon: const Icon(Icons.edit_square, size: 16),
              label: const Text('New Message', style: TextStyle(fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.domain_outlined),
            tooltip: 'Open Department Chat',
            onPressed: _openDepartmentChat,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(userChatRoomsProvider.notifier).refresh();
              ref.invalidate(publicGroupsProvider(null));
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              // Search conversations input bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: TextField(
                    controller: _inboxSearchController,
                    onChanged: (val) => setState(() => _inboxSearchQuery = val.trim()),
                    style: TextStyle(fontSize: 14.5, color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Search conversations...',
                      hintStyle: TextStyle(fontSize: 13.5, color: theme.colorScheme.outline),
                      prefixIcon: Icon(Icons.search, size: 20, color: theme.colorScheme.outline),
                      suffixIcon: _inboxSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _inboxSearchController.clear();
                                setState(() => _inboxSearchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),

              // Navigation Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: theme.colorScheme.primary,
                indicatorWeight: 3,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.outline,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Direct'),
                  Tab(text: 'Groups'),
                  Tab(text: 'Explore'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: roomsAsync.when(
        data: (rooms) {
          final activeRooms = rooms.where((r) => r.type != 'DIRECT' || r.lastMessage != null || r.lastMessageAt != null).toList();
          final directRooms = activeRooms.where((r) => r.type == 'DIRECT').toList();
          final groupRooms = activeRooms.where((r) => r.type == 'GROUP' || r.clubId != null || r.departmentId != null).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildRoomsList(activeRooms),
              _buildRoomsList(directRooms, emptyText: 'No direct messages yet.\nTap "+ New Message" above to start a conversation!'),
              _buildRoomsList(groupRooms, emptyText: 'No joined groups yet.\nExplore campus groups to join discussions!'),
              _buildExploreGroupsTab(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading chats: $err'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.read(userChatRoomsProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomsList(List<ChatRoomModel> rooms, {String? emptyText}) {
    final currentUserId = ref.watch(authControllerProvider.select((s) => s.asData?.value?.id)) ?? '';
    final theme = Theme.of(context);

    // Apply search filter ONLY on actual existing conversations
    List<ChatRoomModel> displayedRooms = rooms;
    if (_inboxSearchQuery.isNotEmpty) {
      final q = _inboxSearchQuery.toLowerCase();
      displayedRooms = rooms.where((r) {
        final name = r.getDisplayName(currentUserId).toLowerCase();
        final lastMsg = r.lastMessage?.message.toLowerCase() ?? '';
        final otherUser = r.getOtherParticipant(currentUserId);
        final username = otherUser?.username?.toLowerCase() ?? '';
        final email = otherUser?.email.toLowerCase() ?? '';
        return name.contains(q) || lastMsg.contains(q) || username.contains(q) || email.contains(q);
      }).toList();
    }

    if (displayedRooms.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(userChatRoomsProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 56, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      _inboxSearchQuery.isNotEmpty
                          ? 'No conversations found matching "$_inboxSearchQuery"'
                          : (emptyText ?? 'No conversations yet.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.outline, fontSize: 14.5),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.tonalIcon(
                      onPressed: _openNewMessageAction,
                      icon: const Icon(Icons.edit_square, size: 16),
                      label: const Text('Start a Conversation'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(userChatRoomsProvider.notifier).refresh(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        key: PageStorageKey<String>('chat_inbox_list_${_tabController.index}'),
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: displayedRooms.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 74,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
        itemBuilder: (context, index) {
          final room = displayedRooms[index];
          return _buildRoomTile(room, currentUserId, theme);
        },
      ),
    );
  }

  Widget _buildRoomTile(ChatRoomModel room, String currentUserId, ThemeData theme) {
    final otherUser = room.getOtherParticipant(currentUserId);
    final isOnline = otherUser?.isOnline ?? false;
    final roomName = room.getDisplayName(currentUserId);
    final lastMsg = room.lastMessage;
    final isLastMsgMine = lastMsg != null && lastMsg.senderId == currentUserId;
    final isIncomingUnread = (lastMsg != null &&
        lastMsg.senderId != currentUserId &&
        !lastMsg.readByUserIdList.contains(currentUserId));
    final roomUnreadCount = isLastMsgMine ? 0 : (room.unreadCount > 0 ? room.unreadCount : (isIncomingUnread ? 1 : 0));
    final hasUnread = roomUnreadCount > 0;

    final latestTime = room.lastMessageAt ?? lastMsg?.createdAt;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: () => context.push('/chat/room/${room.id}'),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: room.type == 'DIRECT'
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.secondaryContainer,
            backgroundImage: room.type == 'DIRECT'
                ? (otherUser?.avatarUrl != null && otherUser!.avatarUrl!.isNotEmpty
                    ? NetworkImage(ApiEndpoints.resolveUrl(otherUser.avatarUrl!))
                    : null)
                : (room.avatarUrl != null && room.avatarUrl!.isNotEmpty
                    ? NetworkImage(ApiEndpoints.resolveUrl(room.avatarUrl!))
                    : null),
            child: (room.type == 'DIRECT' && (otherUser?.avatarUrl == null || otherUser!.avatarUrl!.isEmpty))
                ? Text(
                    otherUser != null && otherUser.firstName.isNotEmpty
                        ? otherUser.firstName[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  )
                : (room.type != 'DIRECT' && (room.avatarUrl == null || room.avatarUrl!.isEmpty)
                    ? Icon(
                        room.isPrivate ? Icons.lock : Icons.groups,
                        color: theme.colorScheme.onSecondaryContainer,
                        size: 22,
                      )
                    : null),
          ),
          if (room.type == 'DIRECT' && isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              roomName,
              style: TextStyle(
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                fontSize: 15.5,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (latestTime != null)
            Text(
              ChatDateFormatter.formatConversationTime(latestTime, context),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                color: hasUnread ? theme.colorScheme.primary : theme.colorScheme.outline,
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          if (room.type != 'DIRECT') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                room.departmentId != null ? 'Dept' : (room.clubId != null ? 'Club' : 'Group'),
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              lastMsg != null
                  ? (lastMsg.mediaType != null
                      ? '📎 ${lastMsg.mediaType}: ${lastMsg.fileName ?? lastMsg.message}'
                      : lastMsg.message)
                  : 'Tap to open conversation',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasUnread ? theme.colorScheme.onSurface : theme.colorScheme.outline,
                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
          if (hasUnread) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$roomUnreadCount',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExploreGroupsTab() {
    final theme = Theme.of(context);
    final groupsAsync = ref.watch(publicGroupsProvider(_exploreSearchQuery));

    return Column(
      children: [
        // Search Input Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _exploreSearchController,
            decoration: InputDecoration(
              hintText: 'Search public groups by name or topic...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _exploreSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _exploreSearchController.clear();
                        setState(() => _exploreSearchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) {
              setState(() => _exploreSearchQuery = val.trim());
            },
          ),
        ),

        Expanded(
          child: groupsAsync.when(
            data: (groups) {
              if (groups.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.groups_outlined, size: 56, color: theme.colorScheme.outline),
                      const SizedBox(height: 12),
                      Text(
                        _exploreSearchQuery.isNotEmpty
                            ? 'No public groups matching "$_exploreSearchQuery"'
                            : 'No public groups available at this time.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.outline),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(
                        onPressed: () => context.push('/chat/create-group'),
                        icon: const Icon(Icons.add),
                        label: const Text('Create a Group'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: groups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final group = groups[index];

                  return Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: theme.colorScheme.secondaryContainer,
                            backgroundImage: group.avatarUrl != null && group.avatarUrl!.isNotEmpty
                                ? NetworkImage(ApiEndpoints.resolveUrl(group.avatarUrl!))
                                : null,
                            child: group.avatarUrl == null || group.avatarUrl!.isEmpty
                                ? Icon(Icons.groups, color: theme.colorScheme.onSecondaryContainer, size: 24)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.name ?? 'Campus Group',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (group.description != null && group.description!.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    group.description!,
                                    style: TextStyle(fontSize: 12.5, color: theme.colorScheme.onSurfaceVariant),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.people_outline, size: 14, color: theme.colorScheme.outline),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${group.memberCount} members',
                                      style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          group.isMember
                              ? OutlinedButton(
                                  onPressed: () => context.push('/chat/room/${group.id}'),
                                  child: const Text('Open', style: TextStyle(fontSize: 12)),
                                )
                              : FilledButton(
                                  onPressed: () async {
                                    try {
                                      final repo = ref.read(chatRepositoryProvider);
                                      await repo.joinGroup(group.id);
                                      ref.read(userChatRoomsProvider.notifier).refresh();
                                      ref.invalidate(publicGroupsProvider(null));

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Joined "${group.name}"!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                        context.push('/chat/room/${group.id}');
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to join: $e')),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text('Join', style: TextStyle(fontSize: 12)),
                                ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading public groups: $err')),
          ),
        ),
      ],
    );
  }
}
