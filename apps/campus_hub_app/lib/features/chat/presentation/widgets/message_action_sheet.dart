import 'package:flutter/material.dart';
import '../../domain/chat_models.dart';
import 'message_reaction_picker.dart';

class MessageActionSheet extends StatelessWidget {
  final ChatMessageModel message;
  final String currentUserId;
  final ValueChanged<String> onSelectEmoji;
  final VoidCallback onReply;
  final VoidCallback onDeleteForMe;
  final VoidCallback onDeleteForEveryone;

  const MessageActionSheet({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.onSelectEmoji,
    required this.onReply,
    required this.onDeleteForMe,
    required this.onDeleteForEveryone,
  });

  static Future<void> show(
    BuildContext context, {
    required ChatMessageModel message,
    required String currentUserId,
    required ValueChanged<String> onSelectEmoji,
    required VoidCallback onReply,
    required VoidCallback onDeleteForMe,
    required VoidCallback onDeleteForEveryone,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => MessageActionSheet(
        message: message,
        currentUserId: currentUserId,
        onSelectEmoji: onSelectEmoji,
        onReply: onReply,
        onDeleteForMe: onDeleteForMe,
        onDeleteForEveryone: onDeleteForEveryone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = message.senderId == currentUserId;
    final isDeleted = message.isDeletedForEveryone;

    // Check 24-hour window for Delete for Everyone
    final now = DateTime.now();
    final difference = now.difference(message.createdAt);
    final canDeleteForEveryone = isMe && !isDeleted && difference.inHours < 24;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quick reaction bar
              if (!isDeleted) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: MessageReactionPicker(
                    currentSelectedEmojis: message.reactions
                        .where((r) => r.hasReacted)
                        .map((r) => r.emoji)
                        .toList(),
                    onSelectEmoji: (emoji) {
                      Navigator.pop(context);
                      onSelectEmoji(emoji);
                    },
                  ),
                ),
                const Divider(height: 1),
              ],

              // Action Items
              if (!isDeleted)
                ListTile(
                  leading: const Icon(Icons.reply_rounded),
                  title: const Text('Reply'),
                  onTap: () {
                    Navigator.pop(context);
                    onReply();
                  },
                ),

              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Delete for Me'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Message?'),
                      content: const Text('This will delete the message only for you.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    onDeleteForMe();
                  }
                },
              ),

              if (canDeleteForEveryone)
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                  title: const Text('Delete for Everyone', style: TextStyle(color: Colors.red)),
                  subtitle: const Text('Available within 24 hours of sending', style: TextStyle(fontSize: 11)),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete for Everyone?'),
                        content: const Text('This message will be deleted for everyone in this chat.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete for Everyone', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      onDeleteForEveryone();
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
