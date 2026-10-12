import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/chat_repository.dart';
import '../providers/chat_provider.dart';

class ChatRequestComposerDialog extends ConsumerStatefulWidget {
  final String targetUserId;
  final String targetUserName;
  final String? targetUserAvatar;

  const ChatRequestComposerDialog({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    this.targetUserAvatar,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String targetUserId,
    required String targetUserName,
    String? targetUserAvatar,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChatRequestComposerDialog(
        targetUserId: targetUserId,
        targetUserName: targetUserName,
        targetUserAvatar: targetUserAvatar,
      ),
    );
  }

  @override
  ConsumerState<ChatRequestComposerDialog> createState() =>
      _ChatRequestComposerDialogState();
}

class _ChatRequestComposerDialogState
    extends ConsumerState<ChatRequestComposerDialog> {
  final _messageController = TextEditingController();
  bool _isSending = false;
  String? _errorMessage;

  static const int _maxChars = 300;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || text.length > _maxChars) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(chatRepositoryProvider);
      await repo.sendChatRequest(
        recipientId: widget.targetUserId,
        introductoryMessage: text,
      );

      ref.invalidate(sentChatRequestsProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Chat request sent to ${widget.targetUserName}'),
                ),
              ],
            ),
            backgroundColor: Colors.teal.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      String msg = 'Failed to send chat request. Please try again.';
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          msg = data['message'].toString();
        }
      }
      if (mounted) {
        setState(() {
          _isSending = false;
          _errorMessage = msg;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final currentLength = _messageController.text.length;
    final isValid = currentLength > 0 && currentLength <= _maxChars;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      widget.targetUserName.isNotEmpty
                          ? widget.targetUserName[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Send Chat Request to ${widget.targetUserName}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.targetUserName} requires chat requests for new student conversations. Faculty and staff can message directly.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: theme.colorScheme.outline,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Introductory Message Text Field
              TextField(
                controller: _messageController,
                maxLength: _maxChars,
                maxLines: 4,
                minLines: 3,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Add an introductory message...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.outline.withValues(alpha: 0.8),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  counterText: '$currentLength/$_maxChars',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),

              // Error display
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSending ? null : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: (_isSending || !isValid) ? null : _sendRequest,
                      icon: _isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, size: 18),
                      label: Text(_isSending ? 'Sending...' : 'Send Request'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
