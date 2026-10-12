import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/chat_provider.dart';
import '../../domain/chat_models.dart';
import '../../data/chat_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../shared/widgets/user_picker_bottom_sheet.dart';
import '../utils/chat_date_formatter.dart';
import '../../../../core/widgets/campus_bottom_nav.dart';
import '../../../../core/branding/gcee_logo.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/widgets/atmospheric_background.dart';

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
        child: Builder(
          builder: (ctx) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final avatarBg = isDark ? AppColors.darkElevatedSurface : AppColors.lightSecondarySurface;
            final iconColor = isDark ? Colors.white : AppColors.primaryText;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: avatarBg,
                      child: Icon(Icons.person_add_alt_1, color: iconColor, size: 20),
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
                    leading: CircleAvatar(
                      backgroundColor: avatarBg,
                      child: Icon(Icons.group_add, color: iconColor, size: 20),
                    ),
                    title: const Text('Create New Group', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Create a Public or Private group for projects/clubs'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.push('/chat/create-group');
                    },
                  ),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: avatarBg,
                      child: Icon(Icons.mark_email_unread_outlined, color: iconColor, size: 20),
                    ),
                    title: const Text('Message Requests', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('View and respond to pending chat requests'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.push('/chat/requests');
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final roomsAsync = ref.watch(userChatRoomsProvider);
    final pendingRequestsCount = ref.watch(pendingRequestsCountProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CampusAppBar(
          title: 'Messages',
          subtitle: 'Campus Conversations',
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: FilledButton.tonalIcon(
                onPressed: _openNewMessageAction,
                icon: const Icon(Icons.edit_square, size: 15),
                label: const Text('New', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.domain_outlined, size: 20),
              tooltip: 'Department Chat',
              onPressed: _openDepartmentChat,
            ),
            Badge(
              isLabelVisible: pendingRequestsCount > 0,
              label: Text('$pendingRequestsCount'),
              child: IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.mark_email_unread_outlined, size: 20),
                tooltip: 'Message Requests',
                onPressed: () => context.push('/chat/requests'),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Refresh',
              onPressed: () {
                ref.read(userChatRoomsProvider.notifier).refresh();
                ref.invalidate(publicGroupsProvider(null));
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            // iOS Frosted Search Input Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface.withValues(alpha: 0.6)
                      : AppColors.lightSurface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: TextField(
                  controller: _inboxSearchController,
                  onChanged: (val) => setState(() => _inboxSearchQuery = val.trim()),
                  style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    hintStyle: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                    prefixIcon: Icon(Icons.search, size: 18, color: theme.colorScheme.onSurfaceVariant),
                    suffixIcon: _inboxSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              _inboxSearchController.clear();
                              setState(() => _inboxSearchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),

            // Segmented iOS Frosted Pill TabBar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkElevatedSurface
                    : AppColors.lightSecondarySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : Colors.white,
                  borderRadius: BorderRadius.circular(9),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: isDark ? Colors.white : Colors.black,
                unselectedLabelColor: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Direct'),
                  Tab(text: 'Groups'),
                  Tab(text: 'Explore'),
                ],
              ),
            ),

            Expanded(
              child: roomsAsync.when(
                data: (rooms) {
                  final activeRooms = rooms.where((r) => r.type != 'DIRECT' || r.lastMessage != null || r.lastMessageAt != null).toList();
                  final directRooms = activeRooms.where((r) => r.type == 'DIRECT').toList();
                  final groupRooms = activeRooms.where((r) => r.type == 'GROUP' || r.clubId != null || r.departmentId != null).toList();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRoomsList(activeRooms),
                      _buildRoomsList(directRooms, emptyText: 'No direct conversations yet.\nTap "+ New" above to start a conversation!'),
                      _buildRoomsList(groupRooms, emptyText: 'No joined groups yet.\nVisit Clubs or Explore to join campus communities!'),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomsList(List<ChatRoomModel> rooms, {String? emptyText}) {
    final currentUserId = ref.watch(authControllerProvider.select((s) => s.asData?.value?.id)) ?? '';
    final pendingRequestsCount = ref.watch(pendingRequestsCountProvider);
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
            if (pendingRequestsCount > 0 && _tabController.index <= 1)
              _buildMessageRequestsBanner(theme, pendingRequestsCount),
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 56, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                    const SizedBox(height: 16),
                    Text(
                      _inboxSearchQuery.isNotEmpty
                          ? 'No chats found matching "$_inboxSearchQuery"'
                          : (emptyText ?? 'No conversations yet'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: () => context.push('/chat/contacts'),
                          icon: const Icon(Icons.person_add_outlined, size: 18),
                          label: const Text('Find People'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _tabController.animateTo(3),
                          icon: const Icon(Icons.explore_outlined, size: 18),
                          label: const Text('Explore Campus'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final bool showBanner = pendingRequestsCount > 0 && _tabController.index <= 1;

    return RefreshIndicator(
      onRefresh: () => ref.read(userChatRoomsProvider.notifier).refresh(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        key: PageStorageKey<String>('chat_inbox_list_${_tabController.index}'),
        padding: EdgeInsets.fromLTRB(0, 6, 0, CampusBottomNav.getBottomClearance(context)),
        itemCount: displayedRooms.length + (showBanner ? 1 : 0),
        separatorBuilder: (_, index) {
          if (showBanner && index == 0) {
            return const SizedBox(height: 4);
          }
          return Divider(
            height: 1,
            indent: 74,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
          );
        },
        itemBuilder: (context, index) {
          if (showBanner) {
            if (index == 0) {
              return _buildMessageRequestsBanner(theme, pendingRequestsCount);
            }
            index -= 1;
          }
          final room = displayedRooms[index];
          return _buildRoomTile(room, currentUserId, theme);
        },
      ),
    );
  }

  Widget _buildMessageRequestsBanner(ThemeData theme, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: InkWell(
        onTap: () => context.push('/chat/requests'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message Requests',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      '$count student ${count == 1 ? "request" : "requests"} awaiting approval',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.primary),
            ],
          ),
        ),
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
          room.type == 'DIRECT'
              ? CampusAvatar(
                  imageUrl: otherUser?.avatarUrl,
                  name: otherUser != null ? '${otherUser.firstName} ${otherUser.lastName}'.trim() : 'Chat',
                  radius: 25,
                )
              : (room.avatarUrl != null && room.avatarUrl!.isNotEmpty)
                  ? CampusAvatar(
                      imageUrl: room.avatarUrl,
                      name: room.name ?? 'Group',
                      radius: 25,
                    )
                  : CircleAvatar(
                      radius: 25,
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      child: ((room.name?.toLowerCase().contains('whole college') ?? false)
                          ? const GceeLogo(size: 26)
                          : Icon(
                              room.isPrivate ? Icons.lock : Icons.groups,
                              color: theme.colorScheme.onSecondaryContainer,
                              size: 22,
                            )),
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
            child: Row(
              children: [
                Flexible(
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
                if ((room.name?.toLowerCase().contains('whole college') ?? false)) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'OFFICIAL',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (latestTime != null)
            Text(
              ChatDateFormatter.formatConversationTime(latestTime, context),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                color: hasUnread ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
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
                  ? (lastMsg.mediaType == 'POST' || (lastMsg.message.startsWith('{') && lastMsg.message.contains('"postId"'))
                      ? '📌 Shared Post: ${lastMsg.fileName ?? "View Post"}'
                      : (lastMsg.mediaType != null
                          ? '📎 ${lastMsg.mediaType}: ${lastMsg.fileName ?? lastMsg.message}'
                          : lastMsg.message))
                  : 'Tap to open conversation',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasUnread ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
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
    final groupsAsync = ref.watch(publicGroupsProvider(_exploreSearchQuery.isEmpty ? null : _exploreSearchQuery));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _exploreSearchController,
            decoration: InputDecoration(
              hintText: 'Search public campus groups & study squads...',
              hintStyle: const TextStyle(fontSize: 13.5),
              prefixIcon: const Icon(Icons.search, size: 20),
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
                padding: EdgeInsets.fromLTRB(16, 8, 16, CampusBottomNav.getBottomClearance(context)),
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
                          (group.avatarUrl != null && group.avatarUrl!.isNotEmpty)
                              ? CampusAvatar(
                                  imageUrl: group.avatarUrl,
                                  name: group.name ?? 'Group',
                                  radius: 24,
                                )
                              : CircleAvatar(
                                  radius: 24,
                                  backgroundColor: theme.colorScheme.secondaryContainer,
                                  child: Icon(Icons.groups, color: theme.colorScheme.onSecondaryContainer, size: 24),
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
