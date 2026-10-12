import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/socket_chat_service.dart';
import '../../data/chat_repository.dart';
import '../../domain/chat_models.dart';
import '../providers/chat_provider.dart';
import '../utils/presence_formatter.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../../../../core/theme/app_colors.dart';

class ChatAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final String roomId;
  final ChatRoomModel? initialRoom;
  final List<Widget>? actions;

  const ChatAppBar({
    super.key,
    required this.roomId,
    this.initialRoom,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  ConsumerState<ChatAppBar> createState() => _ChatAppBarState();
}

class _ChatAppBarState extends ConsumerState<ChatAppBar> {
  StreamSubscription? _presenceSubscription;
  final Map<String, bool> _liveOnlineOverrides = {};
  final Map<String, DateTime?> _liveLastSeenOverrides = {};

  @override
  void initState() {
    super.initState();
    _subscribePresence();
  }

  void _subscribePresence() {
    final socket = ref.read(socketChatServiceProvider);
    _presenceSubscription = socket.onPresenceChange.listen((event) {
      final userId = event['userId'] as String?;
      final isOnline = event['isOnline'] as bool?;
      final lastSeenRaw = event['lastSeen'];
      final lastSeen = lastSeenRaw != null ? DateTime.tryParse(lastSeenRaw.toString()) : DateTime.now();

      if (userId != null && isOnline != null && mounted) {
        setState(() {
          _liveOnlineOverrides[userId] = isOnline;
          if (!isOnline) {
            _liveLastSeenOverrides[userId] = lastSeen;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _presenceSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(chatRoomDetailsProvider(widget.roomId));
    final typingUser = ref.watch(roomTypingUserProvider(widget.roomId)).valueOrNull;
    final currentUser = ref.watch(authControllerProvider).asData?.value;
    final currentUserId = currentUser?.id ?? '';

    return roomAsync.when(
      data: (room) => _buildLoadedAppBar(context, room, currentUserId, typingUser),
      loading: () {
        if (widget.initialRoom != null) {
          return _buildLoadedAppBar(context, widget.initialRoom!, currentUserId, typingUser);
        }
        return _buildLoadingAppBar(context);
      },
      error: (err, _) {
        if (widget.initialRoom != null) {
          return _buildLoadedAppBar(context, widget.initialRoom!, currentUserId, typingUser);
        }
        return _buildErrorAppBar(context, err);
      },
    );
  }

  Widget _buildLoadedAppBar(
    BuildContext context,
    ChatRoomModel room,
    String currentUserId,
    String? typingUser,
  ) {
    final isDirect = room.type.toUpperCase() == 'DIRECT';

    if (isDirect) {
      return _buildDirectChatAppBar(context, room, currentUserId, typingUser);
    } else {
      return _buildGroupChatAppBar(context, room, typingUser);
    }
  }

  Widget _buildDirectChatAppBar(
    BuildContext context,
    ChatRoomModel room,
    String currentUserId,
    String? typingUser,
  ) {
    final theme = Theme.of(context);
    final otherParticipant = room.getOtherParticipant(currentUserId) ??
        (room.participants.isNotEmpty
            ? room.participants.first
            : ChatParticipantUser(
                id: '',
                firstName: 'User',
                lastName: '',
                email: '',
              ));

    final isOnline = _liveOnlineOverrides[otherParticipant.id] ?? otherParticipant.isOnline;
    final lastSeen = _liveLastSeenOverrides[otherParticipant.id] ?? otherParticipant.lastSeen;
    final isTyping = typingUser != null && typingUser.isNotEmpty;

    final statusText = PresenceFormatter.formatUserStatus(
      isOnline: isOnline,
      lastSeen: lastSeen,
      isTyping: isTyping,
    );

    final statusColor = isTyping
        ? Colors.green.shade700
        : (isOnline ? Colors.green.shade600 : theme.colorScheme.onSurfaceVariant);

    final isDark = theme.brightness == Brightness.dark;
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? AppColors.darkAppBarSurface : AppColors.lightAppBarSurface,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Container(color: Colors.transparent),
        ),
      ),
      titleSpacing: 0,
      leading: const CampusBackButton(),
      title: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          if (otherParticipant.id.isNotEmpty) {
            context.push('/profile/${otherParticipant.id}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
          child: Row(
            children: [
              Stack(
                children: [
                  CampusAvatar(
                    imageUrl: otherParticipant.avatarUrl,
                    name: otherParticipant.firstName,
                    radius: 20,
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      otherParticipant.fullName.isNotEmpty
                          ? otherParticipant.fullName
                          : (room.name ?? 'Chat User'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: isOnline || isTyping ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: widget.actions ??
          [
            IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: 'View Profile',
              onPressed: () {
                if (otherParticipant.id.isNotEmpty) {
                  context.push('/profile/${otherParticipant.id}');
                }
              },
            ),
            if (otherParticipant.id.isNotEmpty)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (val) {
                  if (val == 'profile') {
                    context.push('/profile/${otherParticipant.id}');
                  } else if (val == 'block') {
                    _showBlockDialog(context, otherParticipant);
                  } else if (val == 'unblock') {
                    _showUnblockDialog(context, otherParticipant);
                  }
                },
                itemBuilder: (ctx) {
                  final perm = ref.read(chatPermissionProvider(otherParticipant.id)).valueOrNull;
                  final isBlockedByYou = perm?.isBlockedByYou ?? false;
                  return [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, size: 20),
                          SizedBox(width: 8),
                          Text('View Profile'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: isBlockedByYou ? 'unblock' : 'block',
                      child: Row(
                        children: [
                          Icon(
                            isBlockedByYou ? Icons.lock_open : Icons.block,
                            size: 20,
                            color: isBlockedByYou ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isBlockedByYou ? 'Unblock Messages' : 'Block Messages',
                            style: TextStyle(
                              color: isBlockedByYou ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              ),
          ],
    );
  }

  void _showBlockDialog(BuildContext context, ChatParticipantUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Block ${user.fullName}?'),
        content: const Text(
          'They will not be able to message you in chat. Academic enrollments, attendance, and campus club memberships are not affected.',
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
              try {
                final repo = ref.read(chatRepositoryProvider);
                await repo.blockUser(user.id);
                ref.invalidate(chatPermissionProvider(user.id));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Blocked messages from ${user.fullName}')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to block user: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Block Messages'),
          ),
        ],
      ),
    );
  }

  void _showUnblockDialog(BuildContext context, ChatParticipantUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Unblock ${user.fullName}?'),
        content: const Text('They will be able to send you messages in chat again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final repo = ref.read(chatRepositoryProvider);
                await repo.unblockUser(user.id);
                ref.invalidate(chatPermissionProvider(user.id));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Unblocked messages from ${user.fullName}')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to unblock user: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Unblock Messages'),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupChatAppBar(
    BuildContext context,
    ChatRoomModel room,
    String? typingUser,
  ) {
    final theme = Theme.of(context);
    final memberCount = room.memberCount > 0 ? room.memberCount : room.participants.length;

    int liveOnlineCount = room.onlineMemberCount;
    for (final participant in room.participants) {
      if (_liveOnlineOverrides.containsKey(participant.id)) {
        final override = _liveOnlineOverrides[participant.id]!;
        if (override && !participant.isOnline) {
          liveOnlineCount++;
        } else if (!override && participant.isOnline && liveOnlineCount > 0) {
          liveOnlineCount--;
        }
      }
    }

    final isTyping = typingUser != null && typingUser.isNotEmpty;
    final statusText = PresenceFormatter.formatGroupStatus(
      memberCount: memberCount,
      onlineMemberCount: liveOnlineCount,
      typingUserName: isTyping ? typingUser : null,
    );

    final isDark = theme.brightness == Brightness.dark;
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? AppColors.darkAppBarSurface : AppColors.lightAppBarSurface,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Container(color: Colors.transparent),
        ),
      ),
      titleSpacing: 0,
      leading: const CampusBackButton(),
      title: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          context.push('/chat/group-info/${room.id}');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
          child: Row(
            children: [
              (room.avatarUrl != null && room.avatarUrl!.isNotEmpty)
                  ? CampusAvatar(
                      imageUrl: room.avatarUrl,
                      name: room.name ?? 'Group',
                      radius: 20,
                    )
                  : CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      child: Icon(
                        room.isPrivate ? Icons.lock : Icons.groups,
                        color: theme.colorScheme.onSecondaryContainer,
                        size: 22,
                      ),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      room.name ?? 'Group Conversation',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: isTyping ? Colors.green.shade700 : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isTyping ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: widget.actions ??
          [
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Group Details',
              onPressed: () => context.push('/chat/group-info/${room.id}'),
            ),
          ],
    );
  }

  Widget _buildLoadingAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? AppColors.darkAppBarSurface : AppColors.lightAppBarSurface,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Container(color: Colors.transparent),
        ),
      ),
      titleSpacing: 0,
      leading: const CampusBackButton(),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 14,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 70,
                height: 10,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorAppBar(BuildContext context, Object error) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? AppColors.darkAppBarSurface : AppColors.lightAppBarSurface,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Container(color: Colors.transparent),
        ),
      ),
      leading: const CampusBackButton(),
      title: const Text('Conversation'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Retry',
          onPressed: () => ref.invalidate(chatRoomDetailsProvider(widget.roomId)),
        ),
      ],
    );
  }
}
