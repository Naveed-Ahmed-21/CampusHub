import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/chat_repository.dart';
import '../providers/chat_provider.dart';

class StartDirectChatDialog extends ConsumerStatefulWidget {
  const StartDirectChatDialog({super.key});

  @override
  ConsumerState<StartDirectChatDialog> createState() => _StartDirectChatDialogState();
}

class _StartDirectChatDialogState extends ConsumerState<StartDirectChatDialog> {
  final _userIdController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _startChat() async {
    final targetId = _userIdController.text.trim();
    if (targetId.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(chatRepositoryProvider);
      final room = await repo.getOrCreateDirectChat(targetId);
      ref.invalidate(userChatRoomsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        context.push('/chat/room/${room.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'New Personal Chat',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _userIdController,
              decoration: const InputDecoration(
                labelText: 'Target User ID (UUID)',
                hintText: 'Enter student or faculty UUID...',
                prefixIcon: Icon(Icons.person_search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _startChat,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Start Chat'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
