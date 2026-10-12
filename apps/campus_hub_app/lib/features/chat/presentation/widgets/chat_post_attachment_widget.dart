import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../../../../shared/widgets/campus_network_image.dart';
import '../../domain/chat_models.dart';

class ChatPostAttachmentWidget extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;

  const ChatPostAttachmentWidget({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Parse post metadata from message or JSON
    String title = message.fileName ?? 'Shared Post';
    String content = message.message;
    String authorName = 'Campus Member';
    String? authorAvatar;
    String? mediaUrl = message.mediaUrl;
    String postId = '';

    try {
      final rawMsg = message.message.trim();
      if (rawMsg.startsWith('{') && rawMsg.endsWith('}')) {
        final data = jsonDecode(rawMsg) as Map<String, dynamic>;
        postId = (data['postId'] ?? data['id'] ?? '').toString();
        title = (data['title'] ?? title).toString();
        content = (data['content'] ?? content).toString();
        authorName = (data['authorName'] ?? authorName).toString();
        authorAvatar = data['authorAvatar']?.toString();
        mediaUrl = data['mediaUrl']?.toString() ?? mediaUrl;
      }
    } catch (_) {}

    // Fallback regex extraction if raw JSON parsing didn't match
    if (postId.isEmpty) {
      final postMatch = RegExp(r'"postId"\s*:\s*"([a-zA-Z0-9\-]+)"').firstMatch(message.message);
      if (postMatch != null) {
        postId = postMatch.group(1) ?? '';
      } else {
        final idMatch = RegExp(r'"id"\s*:\s*"([a-zA-Z0-9\-]+)"').firstMatch(message.message);
        if (idMatch != null) {
          postId = idMatch.group(1) ?? '';
        }
      }
    }

    final cardBg = isMe
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        if (postId.isNotEmpty) {
          context.push('/posts/$postId');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening post: $title')),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Post badge & Author
            Row(
              children: [
                CampusAvatar(
                  imageUrl: authorAvatar,
                  name: authorName,
                  radius: 12,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    authorName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isMe ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.feed_outlined, size: 10, color: theme.colorScheme.primary),
                      const SizedBox(width: 3),
                      Text(
                        'POST',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Post Title
            Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: isMe ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (content.isNotEmpty && content != title && !content.startsWith('{')) ...[
              const SizedBox(height: 3),
              Text(
                content,
                style: TextStyle(
                  fontSize: 12,
                  color: isMe
                      ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                      : theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Optional Image Preview
            if (mediaUrl != null && mediaUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CampusNetworkImage(
                  imageUrl: mediaUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],

            const SizedBox(height: 8),
            // Footer Tap CTA
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Tap to view full post',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 12, color: theme.colorScheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
