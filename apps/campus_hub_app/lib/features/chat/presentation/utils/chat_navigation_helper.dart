import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/chat_repository.dart';
import '../../domain/chat_models.dart';
import '../providers/chat_provider.dart';
import '../views/chat_request_composer_dialog.dart';

class ChatNavigationHelper {
  ChatNavigationHelper._();

  static Future<void> startOrOpenDirectChat(
    BuildContext context,
    WidgetRef ref, {
    required String targetUserId,
    String? targetUserName,
    String? targetUserAvatar,
  }) async {
    try {
      final chatRepo = ref.read(chatRepositoryProvider);

      // 1. Evaluate permission check
      final perm = await chatRepo.checkChatPermission(targetUserId);

      if (!context.mounted) return;

      switch (perm.action) {
        case ChatPermissionAction.allowDirectChat:
          // If room already exists, navigate directly to it
          if (perm.roomId != null && perm.roomId!.isNotEmpty) {
            ref.invalidate(userChatRoomsProvider);
            context.push('/chat/room/${perm.roomId}');
          } else {
            // Otherwise create or get direct room
            final room = await chatRepo.getOrCreateDirectChat(targetUserId);
            ref.invalidate(userChatRoomsProvider);
            if (context.mounted) {
              context.push('/chat/room/${room.id}');
            }
          }
          break;

        case ChatPermissionAction.requireChatRequest:
          final displayName = targetUserName ?? perm.targetUser?.fullName ?? 'Student';
          ChatRequestComposerDialog.show(
            context,
            targetUserId: targetUserId,
            targetUserName: displayName,
            targetUserAvatar: targetUserAvatar ?? perm.targetUser?.avatarUrl,
          );
          break;

        case ChatPermissionAction.requestPending:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.hourglass_empty, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Chat request pending. Awaiting response.'),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.amber,
                onPressed: () {
                  context.push('/chat/requests?tab=1');
                },
              ),
            ),
          );
          break;

        case ChatPermissionAction.blocked:
          final msg = perm.isBlockedByYou
              ? 'You have blocked messages from this user.'
              : 'Messaging is unavailable with this user.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.block, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(msg)),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          break;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not initiate conversation: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
