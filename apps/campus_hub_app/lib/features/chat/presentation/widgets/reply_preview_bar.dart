import 'package:flutter/material.dart';
import '../../domain/chat_models.dart';

class ReplyPreviewBar extends StatelessWidget {
  final ChatMessageModel message;
  final String currentUserId;
  final VoidCallback onCancel;

  const ReplyPreviewBar({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = message.senderId == currentUserId;
    final senderLabel = isMe ? 'You' : (message.senderName.isNotEmpty ? message.senderName : 'User');

    String previewText;
    IconData? previewIcon;

    if (message.mediaType == 'IMAGE') {
      previewText = 'Photo';
      previewIcon = Icons.photo_camera;
    } else if (message.mediaType == 'VIDEO') {
      previewText = 'Video';
      previewIcon = Icons.videocam;
    } else if (message.mediaType == 'DOCUMENT') {
      previewText = message.fileName ?? 'Document';
      previewIcon = Icons.description;
    } else if (message.mediaType == 'AUDIO') {
      previewText = 'Audio message';
      previewIcon = Icons.mic;
    } else {
      previewText = message.message.isNotEmpty ? message.message : 'Message';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to $senderLabel',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (previewIcon != null) ...[
                      Icon(previewIcon, size: 14, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        previewText,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: theme.colorScheme.onSurfaceVariant,
            visualDensity: VisualDensity.compact,
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}
