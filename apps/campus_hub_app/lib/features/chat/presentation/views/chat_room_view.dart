import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/socket_chat_service.dart';
import '../providers/chat_provider.dart';
import '../../domain/chat_models.dart';

class ChatRoomView extends ConsumerStatefulWidget {
  final String roomId;

  const ChatRoomView({super.key, required this.roomId});

  @override
  ConsumerState<ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends ConsumerState<ChatRoomView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    final socket = ref.read(socketChatServiceProvider);
    if (_messageController.text.trim().isNotEmpty && !_isTyping) {
      _isTyping = true;
      socket.sendTypingStart(widget.roomId, 'User');
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        socket.sendTypingStop(widget.roomId);
      }
    });
  }

  Future<void> _sendMessage({String? mediaUrl, String? mediaType, String? fileName, int? fileSize}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && mediaUrl == null) return;

    _messageController.clear();
    _typingTimer?.cancel();
    if (_isTyping) {
      _isTyping = false;
      ref.read(socketChatServiceProvider).sendTypingStop(widget.roomId);
    }

    try {
      await ref.read(chatRoomMessagesProvider(widget.roomId).notifier).sendMessage(
            message: text,
            mediaUrl: mediaUrl,
            mediaType: mediaType,
            fileName: fileName,
            fileSize: fileSize,
          );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share Content',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttachmentOption(
                  icon: Icons.image,
                  color: Colors.purple,
                  label: 'Share Image',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showSendMediaDialog('IMAGE');
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.insert_drive_file,
                  color: Colors.blue,
                  label: 'Share Document',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showSendMediaDialog('DOCUMENT');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  void _showSendMediaDialog(String mediaType) {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(mediaType == 'IMAGE' ? 'Share Image' : 'Share Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlCtrl,
              decoration: InputDecoration(
                labelText: mediaType == 'IMAGE' ? 'Image URL' : 'Document URL',
                hintText: 'https://...',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'File Name',
                hintText: mediaType == 'IMAGE' ? 'photo.jpg' : 'guide.pdf',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Optional Caption',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (urlCtrl.text.trim().isEmpty) return;
              Navigator.of(ctx).pop();
              _sendMessage(
                mediaUrl: urlCtrl.text.trim(),
                mediaType: mediaType,
                fileName: nameCtrl.text.trim().isEmpty
                    ? (mediaType == 'IMAGE' ? 'image.png' : 'document.pdf')
                    : nameCtrl.text.trim(),
                fileSize: 1024 * 500, // sample size
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatRoomMessagesProvider(widget.roomId));
    final typingUser = ref.watch(roomTypingUserProvider(widget.roomId)).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.teal,
              child: Icon(Icons.chat, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chat Room', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    typingUser != null ? '$typingUser is typing...' : 'Online',
                    style: TextStyle(
                      fontSize: 12,
                      color: typingUser != null ? Colors.green.shade700 : Colors.green,
                      fontStyle: typingUser != null ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
        ),
        child: Column(
          children: [
            // Messages List
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mark_chat_read_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No messages yet. Send a message to start chatting!', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (ctx, idx) {
                      final msg = messages[idx];
                      // Sample test check for sender vs self
                      final isMe = idx % 2 == 1; // Visual demonstration of incoming/outgoing layout

                      return _buildWhatsAppMessageBubble(msg, isMe);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error loading messages: $err')),
              ),
            ),

            // Typing Indicator Bar
            if (typingUser != null)
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$typingUser is typing...',
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ],
                ),
              ),

            // Bottom Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: Colors.white,
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file, color: Colors.grey),
                      onPressed: _showAttachmentOptions,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          fillColor: Colors.grey.shade100,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Colors.teal.shade600,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 20),
                        onPressed: () => _sendMessage(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppMessageBubble(ChatMessageModel msg, bool isMe) {
    final bubbleColor = isMe ? const Color(0xFFDCF8C6) : Colors.white;
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isMe ? 14 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 14),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe && msg.senderName.isNotEmpty) ...[
                  Text(
                    msg.senderName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                // Image Attachment Card
                if (msg.mediaType == 'IMAGE' && msg.mediaUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      msg.mediaUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        height: 120,
                        color: Colors.grey.shade300,
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('Image Attachment'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],

                // Document Attachment Card
                if (msg.mediaType == 'DOCUMENT') ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.teal.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.fileName ?? 'Document.pdf',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${((msg.fileSize ?? 512000) / 1024).toStringAsFixed(1)} KB',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.download_for_offline, color: Colors.teal),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],

                // Text Content
                if (msg.message.isNotEmpty)
                  Text(
                    msg.message,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),

                const SizedBox(height: 4),

                // Time & Read Receipt Ticks
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      // Read receipts: Double blue ticks if read, double gray if delivered
                      Icon(
                        Icons.done_all,
                        size: 16,
                        color: msg.readByUserIdList.isNotEmpty ? Colors.blue : Colors.grey,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
