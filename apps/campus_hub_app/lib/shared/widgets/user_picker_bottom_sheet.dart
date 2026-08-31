import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_endpoints.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/chat/data/chat_repository.dart';
import '../../features/chat/domain/chat_models.dart';
import '../../features/chat/presentation/providers/chat_provider.dart';
import '../../features/clubs/data/clubs_repository.dart';
import '../../features/clubs/presentation/providers/club_provider.dart';

enum UserPickerMode {
  newChat,
  addClubMember,
  addGroupMember,
  select,
}

class UserPickerBottomSheet extends ConsumerStatefulWidget {
  final UserPickerMode mode;
  final String title;
  final String? clubId;
  final String? roomId;
  final Set<String> excludedUserIds;
  final ValueChanged<ChatParticipantUser>? onUserSelected;

  const UserPickerBottomSheet({
    super.key,
    required this.mode,
    this.title = 'Select User',
    this.clubId,
    this.roomId,
    this.excludedUserIds = const {},
    this.onUserSelected,
  });

  static Future<ChatParticipantUser?> show({
    required BuildContext context,
    required UserPickerMode mode,
    String? title,
    String? clubId,
    String? roomId,
    Set<String> excludedUserIds = const {},
    ValueChanged<ChatParticipantUser>? onUserSelected,
  }) {
    return showModalBottomSheet<ChatParticipantUser>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UserPickerBottomSheet(
        mode: mode,
        title: title ??
            (mode == UserPickerMode.newChat
                ? 'New Conversation'
                : (mode == UserPickerMode.addClubMember
                    ? 'Add Club Member'
                    : (mode == UserPickerMode.addGroupMember
                        ? 'Add Group Member'
                        : 'Select User'))),
        clubId: clubId,
        roomId: roomId,
        excludedUserIds: excludedUserIds,
        onUserSelected: onUserSelected,
      ),
    );
  }

  @override
  ConsumerState<UserPickerBottomSheet> createState() => _UserPickerBottomSheetState();
}

class _UserPickerBottomSheetState extends ConsumerState<UserPickerBottomSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  final Set<String> _processedUserIds = {};
  String _selectedRole = 'MEMBER';
  String? _actionInProgressUserId;

  @override
  void initState() {
    super.initState();
    _processedUserIds.addAll(widget.excludedUserIds);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _searchQuery = val.trim());
      }
    });
  }

  Future<void> _handleUserAction(ChatParticipantUser user) async {
    if (_actionInProgressUserId != null) return;
    setState(() => _actionInProgressUserId = user.id);

    try {
      if (widget.mode == UserPickerMode.newChat) {
        final repo = ref.read(chatRepositoryProvider);
        final room = await repo.getOrCreateDirectChat(user.id);
        ref.invalidate(userChatRoomsProvider);

        if (mounted) {
          Navigator.of(context).pop(user);
          context.push('/chat/room/${room.id}');
        }
      } else if (widget.mode == UserPickerMode.addClubMember && widget.clubId != null) {
        final repo = ref.read(clubsRepositoryProvider);
        await repo.addMember(widget.clubId!, user.id, role: _selectedRole);

        ref.invalidate(clubMembersProvider(widget.clubId!));
        ref.invalidate(clubDetailsProvider(widget.clubId!));

        if (mounted) {
          setState(() {
            _processedUserIds.add(user.id);
            _actionInProgressUserId = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.fullName} added to the club!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      } else if (widget.mode == UserPickerMode.addGroupMember && widget.roomId != null) {
        final repo = ref.read(chatRepositoryProvider);
        await repo.addRoomMember(widget.roomId!, user.id);

        ref.invalidate(chatRoomDetailsProvider(widget.roomId!));
        ref.invalidate(userChatRoomsProvider);

        if (mounted) {
          setState(() {
            _processedUserIds.add(user.id);
            _actionInProgressUserId = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.fullName} added to the group!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      } else if (widget.mode == UserPickerMode.select) {
        widget.onUserSelected?.call(user);
        if (mounted) Navigator.of(context).pop(user);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actionInProgressUserId = null);
    }
  }

  Color _getRoleColor(String role, ColorScheme colorScheme) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
      case 'COLLEGE_ADMIN':
        return Colors.red;
      case 'FACULTY':
      case 'FACULTY_ADVISOR':
        return Colors.orange;
      case 'PLACEMENT_OFFICER':
        return Colors.purple;
      case 'LEAD':
        return Colors.amber.shade800;
      default:
        return colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentAuthUser = ref.watch(authControllerProvider).asData?.value;
    final usersAsync = ref.watch(campusUsersProvider(_searchQuery));

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.mode == UserPickerMode.newChat
                            ? 'Select someone to start a conversation'
                            : (widget.mode == UserPickerMode.addClubMember
                                ? 'Find campus members to add to the club'
                                : 'Search campus users'),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Role selection if adding club member
          if (widget.mode == UserPickerMode.addClubMember)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Assign Role: ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedRole,
                    isDense: true,
                    borderRadius: BorderRadius.circular(12),
                    items: const [
                      DropdownMenuItem(value: 'MEMBER', child: Text('Regular Member')),
                      DropdownMenuItem(value: 'LEAD', child: Text('Club Lead / Admin')),
                      DropdownMenuItem(value: 'FACULTY_ADVISOR', child: Text('Faculty Advisor')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRole = val);
                    },
                  ),
                ],
              ),
            ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name, username, department, or role...',
                hintStyle: TextStyle(fontSize: 13.5, color: theme.colorScheme.outline),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          const Divider(height: 1),

          // User Results List
          Expanded(
            child: usersAsync.when(
              data: (users) {
                // Filter out current user and already-added members
                final filtered = users.where((u) {
                  if (currentAuthUser != null && u.id == currentAuthUser.id) return false;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search_outlined,
                            size: 56,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No users matching "$_searchQuery"'
                                : 'No campus users found',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try searching by first name, last name, or public handle.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) {
                    final user = filtered[idx];
                    final isAlreadyAdded = _processedUserIds.contains(user.id);
                    final isBusy = _actionInProgressUserId == user.id;
                    final roleColor = _getRoleColor(user.role, theme.colorScheme);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      color: theme.colorScheme.surfaceContainerLow,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: isAlreadyAdded ? null : () => _handleUserAction(user),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              // Avatar (tappable to view profile)
                              GestureDetector(
                                onTap: () => context.push('/profile/${user.id}'),
                                child: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: roleColor.withValues(alpha: 0.15),
                                  backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                      ? NetworkImage(ApiEndpoints.resolveUrl(user.avatarUrl!))
                                      : null,
                                  child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                                      ? Text(
                                          user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
                                          style: TextStyle(
                                            color: roleColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Name + Handle + Department
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: GestureDetector(
                                            onTap: () => context.push('/profile/${user.id}'),
                                            child: Text(
                                              user.fullName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: roleColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            user.role,
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              color: roleColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      user.displayUsername,
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (user.departmentName != null && user.departmentName!.isNotEmpty) ...[
                                      const SizedBox(height: 1),
                                      Text(
                                        user.departmentName!,
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontSize: 11.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Action Button
                              if (isAlreadyAdded)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check, size: 14, color: theme.colorScheme.outline),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Added',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                FilledButton.tonal(
                                  onPressed: isBusy ? null : () => _handleUserAction(user),
                                  style: FilledButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                  child: isBusy
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Text(
                                          widget.mode == UserPickerMode.newChat ? 'Chat' : '+ Add',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error, size: 36),
                      const SizedBox(height: 8),
                      Text('Error loading users: $err'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(campusUsersProvider(_searchQuery)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
