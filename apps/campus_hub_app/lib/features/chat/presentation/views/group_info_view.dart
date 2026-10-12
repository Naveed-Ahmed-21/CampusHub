import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/media_picker_service.dart';
import '../../../../core/services/media_upload_service.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../providers/chat_provider.dart';
import '../../domain/chat_models.dart';
import '../../data/chat_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../shared/widgets/full_screen_image_viewer.dart';
import '../../../../shared/widgets/user_picker_bottom_sheet.dart';

class GroupInfoView extends ConsumerStatefulWidget {
  final String roomId;

  const GroupInfoView({super.key, required this.roomId});

  @override
  ConsumerState<GroupInfoView> createState() => _GroupInfoViewState();
}

class _GroupInfoViewState extends ConsumerState<GroupInfoView> {
  final _addMemberController = TextEditingController();
  bool _isUpdatingImage = false;

  @override
  void dispose() {
    _addMemberController.dispose();
    super.dispose();
  }

  void _changeGroupImage(ChatRoomModel room) {
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
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Take Photo (Camera)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await MediaPickerService.pickImageFromCamera();
                  if (file != null && mounted) {
                    _uploadAndSaveGroupImage(room, file);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.purple),
                title: const Text('Choose Image (Gallery)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await MediaPickerService.pickImageFromGallery();
                  if (file != null && mounted) {
                    _uploadAndSaveGroupImage(room, file);
                  }
                },
              ),
              if (room.avatarUrl != null && room.avatarUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove Group Image', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    _removeGroupImage(room);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadAndSaveGroupImage(ChatRoomModel room, SelectedMediaFile file) async {
    setState(() => _isUpdatingImage = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(const SnackBar(content: Text('Uploading group image...')));
      final uploadService = ref.read(mediaUploadServiceProvider);
      final uploadResult = await uploadService.uploadSelectedFile(file);

      final repo = ref.read(chatRepositoryProvider);
      await repo.updateGroupAvatar(room.id, uploadResult.url);

      try {
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
      } catch (_) {}

      ref.invalidate(chatRoomDetailsProvider(room.id));
      ref.invalidate(userChatRoomsProvider);
      ref.invalidate(publicGroupsProvider(null));

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Group image updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to update group image: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingImage = false);
    }
  }

  Future<void> _removeGroupImage(ChatRoomModel room) async {
    setState(() => _isUpdatingImage = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(chatRepositoryProvider);
      await repo.updateGroupAvatar(room.id, null);

      try {
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
      } catch (_) {}

      ref.invalidate(chatRoomDetailsProvider(room.id));
      ref.invalidate(userChatRoomsProvider);
      ref.invalidate(publicGroupsProvider(null));

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Group image removed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to remove group image: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingImage = false);
    }
  }

  void _showAddMemberDialog(ChatRoomModel room) {
    UserPickerBottomSheet.show(
      context: context,
      mode: UserPickerMode.addGroupMember,
      title: 'Add Member to ${room.name ?? "Group"}',
      roomId: room.id,
      excludedUserIds: room.participants.map((p) => p.id).toSet(),
    );
  }

  Future<void> _leaveGroup(ChatRoomModel room, String currentUserId) async {
    final isInstitutional = (room.name?.trim() == 'Whole College') ||
        (room.name?.startsWith('Batch ') ?? false) ||
        (room.name?.contains('Department') ?? false) ||
        (room.departmentId != null) ||
        (room.name != null && room.name!.contains('(') && room.name!.contains(')'));

    if (isInstitutional) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leaving official institutional groups is not permitted.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Group?'),
        content: const Text('Are you sure you want to leave this group conversation?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final repo = ref.read(chatRepositoryProvider);
        await repo.removeRoomMember(room.id, currentUserId);
        ref.invalidate(userChatRoomsProvider);
        if (mounted) {
          context.go('/chat');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Left group conversation')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(chatRoomDetailsProvider(widget.roomId));
    final currentUser = ref.watch(authControllerProvider).asData?.value;
    final currentUserId = currentUser?.id ?? '';
    final theme = Theme.of(context);

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CampusAppBar(
          leading: const CampusBackButton(),
          title: 'Group Info',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(chatRoomDetailsProvider(widget.roomId)),
            ),
          ],
        ),
        body: roomAsync.when(
          data: (room) {
            final memberCount = room.memberCount > 0 ? room.memberCount : room.participants.length;
            final onlineCount = room.onlineMemberCount > 0
                ? room.onlineMemberCount
                : room.participants.where((p) => p.isOnline).length;

            final isCreator = room.createdById == currentUserId;
            final userParticipant = room.participants.where((p) => p.id == currentUserId).firstOrNull;
            final isAdmin = (userParticipant != null && userParticipant.role == 'ADMIN') || isCreator;
            final isMember = userParticipant != null || isCreator;
            final canEditGroupImage = room.isPrivate ? isAdmin : isMember;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Group Header Tile
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (room.avatarUrl != null && room.avatarUrl!.isNotEmpty) {
                                    FullScreenImageViewer.openSingle(
                                      context,
                                      imageUrl: room.avatarUrl!,
                                      heroTag: 'group_avatar_${room.id}',
                                      title: room.getDisplayName(currentUserId),
                                      subtitle: room.description ?? 'Group Conversation',
                                    );
                                  }
                                },
                                child: CampusAvatar(
                                  imageUrl: room.avatarUrl,
                                  name: room.name ?? 'Group',
                                  radius: 50,
                                  heroTag: 'group_avatar_${room.id}',
                                ),
                              ),
                            if (canEditGroupImage)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: theme.colorScheme.primary,
                                  child: IconButton(
                                    icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                    onPressed: _isUpdatingImage ? null : () => _changeGroupImage(room),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (canEditGroupImage) ...[
                          const SizedBox(height: 6),
                          TextButton.icon(
                            onPressed: _isUpdatingImage ? null : () => _changeGroupImage(room),
                            icon: const Icon(Icons.edit, size: 14),
                            label: Text(
                              room.avatarUrl != null && room.avatarUrl!.isNotEmpty
                                  ? 'Change Group Image'
                                  : 'Add Group Image',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          room.name ?? 'Group Chat',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (room.isPrivate ? Colors.orange : Colors.blue).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    room.isPrivate ? Icons.lock : Icons.public,
                                    size: 14,
                                    color: room.isPrivate ? Colors.orange.shade800 : Colors.blue.shade800,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    room.isPrivate ? 'Private Group' : 'Public Group',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: room.isPrivate ? Colors.orange.shade800 : Colors.blue.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          onlineCount > 0
                              ? '$memberCount members • $onlineCount online'
                              : '$memberCount members',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        if (room.description != null && room.description!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            room.description!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _showAddMemberDialog(room),
                              icon: const Icon(Icons.person_add),
                              label: const Text('Add Member'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Members Header
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Group Members (${room.participants.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Members List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: room.participants.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
                  itemBuilder: (context, index) {
                    final member = room.participants[index];
                    final isMe = member.id == currentUserId;

                    return ListTile(
                      onTap: () {
                        if (isMe) {
                          context.push('/profile');
                        } else {
                          context.push('/profile/user/${member.id}');
                        }
                      },
                      leading: CampusAvatar(
                        imageUrl: member.avatarUrl,
                        name: member.fullName,
                        radius: 20,
                      ),
                      title: Text(
                        isMe ? '${member.fullName} (You)' : member.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(member.displayUsername),
                      trailing: isMe
                          ? const Chip(label: Text('You'), backgroundColor: Colors.amberAccent)
                          : const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Exit Group or Institutional Badge
                if ((room.name?.trim() == 'Whole College') ||
                    (room.name?.startsWith('Batch ') ?? false) ||
                    (room.name?.contains('Department') ?? false) ||
                    (room.departmentId != null) ||
                    (room.name != null && room.name!.contains('(') && room.name!.contains(')')))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, color: Colors.blue, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Official Institutional Group',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.blue),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Membership is managed automatically by CampusHub based on your department and batch enrollment.',
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListTile(
                    onTap: () => _leaveGroup(room, currentUserId),
                    leading: const Icon(Icons.exit_to_app, color: Colors.red),
                    title: const Text('Leave Group Conversation', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading room: $err')),
      ),
    ),
  );
}
}
