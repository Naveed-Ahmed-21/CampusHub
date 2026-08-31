import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/socket_chat_service.dart';
import '../providers/chat_provider.dart';
import '../../domain/chat_models.dart';
import '../widgets/chat_app_bar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/message_status_icon.dart';
import '../widgets/date_separator_widget.dart';
import '../widgets/reply_preview_bar.dart';
import '../widgets/message_action_sheet.dart';
import '../widgets/chat_image_attachment_widget.dart';
import '../widgets/chat_document_attachment_widget.dart';
import '../widgets/chat_video_attachment_widget.dart';
import '../widgets/swipe_to_reply_wrapper.dart';
import '../../../../core/services/media_picker_service.dart';
import '../../../../core/services/media_upload_service.dart';
import '../../../../core/services/media_storage_service.dart';
import '../../../../shared/widgets/selected_media_preview_widget.dart';
import '../utils/chat_date_formatter.dart';

class ChatRoomView extends ConsumerStatefulWidget {
  final String roomId;
  final bool isEmbedded;

  const ChatRoomView({
    super.key,
    required this.roomId,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends ConsumerState<ChatRoomView> with WidgetsBindingObserver {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;
  ChatMessageModel? _replyingTo;
  String? _highlightedMessageId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageController.addListener(_onTextChanged);
    ref.read(socketChatServiceProvider).sendPresencePing();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userChatRoomsProvider.notifier).markRoomAsRead(widget.roomId);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      ref.read(socketChatServiceProvider).sendPresenceSet(true);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      ref.read(socketChatServiceProvider).sendPresenceSet(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

    final replyId = _replyingTo?.id;

    _messageController.clear();
    setState(() {
      _replyingTo = null;
    });

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
            replyToMessageId: replyId,
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

  void _scrollToMessage(String messageId, List<ChatMessageModel> messages) {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index != -1 && _scrollController.hasClients) {
      final total = messages.length;
      final targetScroll = (index / total) * _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        targetScroll.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );

      setState(() {
        _highlightedMessageId = messageId;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _highlightedMessageId == messageId) {
          setState(() {
            _highlightedMessageId = null;
          });
        }
      });
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Share Attachment',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.camera_alt,
                    color: Colors.blue,
                    label: 'Camera',
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      final file = await MediaPickerService.pickImageFromCamera();
                      if (file != null && mounted) {
                        // PART 3: Auto-save camera-captured image locally to CampusHub album for sender
                        if (file.path != null) {
                          ref.read(mediaStorageServiceProvider).saveCameraImageToCampusHub(
                                originalPath: file.path!,
                                preferredName: file.name,
                              );
                        }
                        _confirmAndSendAttachment(file);
                      }
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.photo_library,
                    color: Colors.purple,
                    label: 'Gallery',
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      final file = await MediaPickerService.pickImageFromGallery();
                      // PART 5: Gallery images are NOT duplicated/auto-saved for sender
                      if (file != null && mounted) _confirmAndSendAttachment(file);
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.videocam,
                    color: Colors.red,
                    label: 'Record Video',
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      final file = await MediaPickerService.recordVideo();
                      if (file != null && mounted) _confirmAndSendAttachment(file);
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.video_library,
                    color: Colors.orange,
                    label: 'Choose Video',
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      final file = await MediaPickerService.pickVideoFromGallery();
                      if (file != null && mounted) _confirmAndSendAttachment(file);
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.insert_drive_file,
                    color: Colors.teal,
                    label: 'Document',
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      final files = await MediaPickerService.pickDocuments(allowMultiple: false);
                      if (files.isNotEmpty && mounted) _confirmAndSendAttachment(files.first);
                    },
                  ),
                ],
              ),
            ],
          ),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 88,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAndSendAttachment(SelectedMediaFile file) {
    final captionCtrl = TextEditingController();
    bool isUploading = false;
    double? uploadProgress;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final theme = Theme.of(ctx);
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: theme.colorScheme.surface,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          file.isImage
                              ? 'Send Photo'
                              : (file.isVideo ? 'Send Video' : 'Send Document'),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (!isUploading)
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.of(ctx).pop(),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SelectedMediaPreviewWidget(
                      file: file,
                      isUploading: isUploading,
                      uploadProgress: uploadProgress,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: captionCtrl,
                      enabled: !isUploading,
                      decoration: InputDecoration(
                        hintText: 'Add an optional caption...',
                        hintStyle: TextStyle(fontSize: 13.5, color: theme.colorScheme.outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isUploading ? null : () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          icon: isUploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send, size: 16),
                          label: Text(isUploading ? 'Uploading...' : 'Send'),
                          onPressed: isUploading
                              ? null
                              : () async {
                                  setModalState(() {
                                    isUploading = true;
                                    uploadProgress = 0.0;
                                  });

                                  try {
                                    final uploadService = ref.read(mediaUploadServiceProvider);
                                    final uploadResult = await uploadService.uploadSelectedFile(
                                      file,
                                      onProgress: (sent, total) {
                                        if (total > 0) {
                                          setModalState(() => uploadProgress = sent / total);
                                        }
                                      },
                                    );

                                    if (ctx.mounted) Navigator.of(ctx).pop();

                                    final caption = captionCtrl.text.trim();
                                    if (caption.isNotEmpty) {
                                      _messageController.text = caption;
                                    }

                                    await _sendMessage(
                                      mediaUrl: uploadResult.url,
                                      mediaType: file.mediaType,
                                      fileName: uploadResult.fileName,
                                      fileSize: uploadResult.fileSize,
                                    );
                                  } catch (e) {
                                    setModalState(() => isUploading = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error uploading attachment: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showMessageActionSheet(ChatMessageModel msg, String currentUserId) {
    MessageActionSheet.show(
      context,
      message: msg,
      currentUserId: currentUserId,
      onSelectEmoji: (emoji) {
        ref.read(chatRoomMessagesProvider(widget.roomId).notifier).toggleReaction(msg.id, emoji);
      },
      onReply: () {
        setState(() {
          _replyingTo = msg;
        });
      },
      onDeleteForMe: () {
        ref.read(chatRoomMessagesProvider(widget.roomId).notifier).deleteForMe(msg.id);
      },
      onDeleteForEveryone: () {
        ref.read(chatRoomMessagesProvider(widget.roomId).notifier).deleteForEveryone(msg.id);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatRoomMessagesProvider(widget.roomId));
    final typingUser = ref.watch(roomTypingUserProvider(widget.roomId)).valueOrNull;
    final currentUser = ref.watch(authControllerProvider).asData?.value;
    final currentUserId = currentUser?.id ?? '';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final chatBody = Container(
      color: isDark
          ? theme.scaffoldBackgroundColor
          : theme.colorScheme.surfaceContainerLowest,
      child: Column(
        children: [
          // Messages List
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mark_chat_read_outlined, size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet. Send a message to start chatting!',
                          style: TextStyle(color: theme.colorScheme.outline, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (ctx, idx) {
                    final msg = messages[idx];
                    final isMe = (currentUserId.isNotEmpty && msg.senderId == currentUserId) ||
                        (currentUser != null && msg.senderName.contains(currentUser.firstName));

                    final bool showDateSeparator = idx == 0 ||
                        msg.createdAt.day != messages[idx - 1].createdAt.day ||
                        msg.createdAt.month != messages[idx - 1].createdAt.month ||
                        msg.createdAt.year != messages[idx - 1].createdAt.year;

                    final dateStr = ChatDateFormatter.formatDateSeparator(msg.createdAt);
                    final isHighlighted = _highlightedMessageId == msg.id;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDateSeparator) DateSeparatorWidget(text: dateStr),
                        // Swipe to Reply gesture on each message
                        SwipeToReplyWrapper(
                          isMe: isMe,
                          onReply: () {
                            setState(() {
                              _replyingTo = msg;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: isHighlighted
                                  ? theme.colorScheme.primary.withValues(alpha: 0.18)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: _buildWhatsAppMessageBubble(
                                msg,
                                isMe,
                                currentUserId,
                                theme,
                                isDark,
                                messages,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Error loading messages: $err', style: TextStyle(color: theme.colorScheme.error)),
                ),
              ),
            ),
          ),

          // Typing Indicator Bar
          if (typingUser != null)
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$typingUser is typing...',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Reply Preview Bar
          if (_replyingTo != null)
            ReplyPreviewBar(
              message: _replyingTo!,
              currentUserId: currentUserId,
              onCancel: () {
                setState(() {
                  _replyingTo = null;
                });
              },
            ),

          // Bottom Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.attach_file, color: theme.colorScheme.onSurfaceVariant),
                    onPressed: _showAttachmentOptions,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14.5),
                      decoration: InputDecoration(
                        hintText: _replyingTo != null ? 'Type your reply...' : 'Message...',
                        hintStyle: TextStyle(color: theme.colorScheme.outline, fontSize: 14),
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
                    backgroundColor: theme.colorScheme.primary,
                    radius: 22,
                    child: IconButton(
                      icon: Icon(Icons.send, color: theme.colorScheme.onPrimary, size: 19),
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.isEmbedded) {
      return chatBody;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ChatAppBar(roomId: widget.roomId),
      body: chatBody,
    );
  }

  Widget _buildWhatsAppMessageBubble(
    ChatMessageModel msg,
    bool isMe,
    String currentUserId,
    ThemeData theme,
    bool isDark,
    List<ChatMessageModel> allMessages,
  ) {
    final isDeleted = msg.isDeletedForEveryone;

    final bubbleColor = isMe
        ? (isDark ? theme.colorScheme.primaryContainer : const Color(0xFFDCF8C6))
        : (isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white);
    final textColor = isMe
        ? (isDark ? theme.colorScheme.onPrimaryContainer : const Color(0xFF111B21))
        : theme.colorScheme.onSurface;
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Container(
      margin: EdgeInsets.only(bottom: msg.reactions.isNotEmpty ? 10 : 4),
      child: Column(
        crossAxisAlignment: align,
        children: [
          GestureDetector(
            onLongPress: () => _showMessageActionSheet(msg, currentUserId),
            child: Container(
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
                  // Sender Name for Incoming Group Messages
                  if (!isMe && msg.senderName.isNotEmpty && !isDeleted) ...[
                    Text(
                      msg.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],

                  // PART 7: Quoted Replied Message Box
                  if (msg.replyToMessage != null && !isDeleted) ...[
                    GestureDetector(
                      onTap: () => _scrollToMessage(msg.replyToMessage!.id, allMessages),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 3.5,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.replyToMessage!.senderName,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              msg.replyToMessage!.isDeletedForEveryone
                                  ? 'This message was deleted'
                                  : (msg.replyToMessage!.mediaType == 'IMAGE'
                                      ? '📷 Photo'
                                      : (msg.replyToMessage!.mediaType == 'VIDEO'
                                          ? '🎬 Video'
                                          : (msg.replyToMessage!.mediaType == 'DOCUMENT'
                                              ? '📄 ${msg.replyToMessage!.fileName ?? "Document"}'
                                              : msg.replyToMessage!.message))),
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor.withValues(alpha: 0.75),
                                fontStyle: msg.replyToMessage!.isDeletedForEveryone
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // PART 10: Deleted for Everyone Message Placeholder
                  if (isDeleted) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.do_not_disturb_alt,
                          size: 15,
                          color: textColor.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'This message was deleted',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontStyle: FontStyle.italic,
                            color: textColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Image Attachment Card with Receiver Privacy & Download Flow
                    if (msg.mediaType == 'IMAGE' && msg.mediaUrl != null) ...[
                      ChatImageAttachmentWidget(
                        message: msg,
                        isMe: isMe,
                        allMessages: allMessages,
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Video Attachment Card with Poster & Play/Download Flow
                    if (msg.mediaType == 'VIDEO' && msg.mediaUrl != null) ...[
                      ChatVideoAttachmentWidget(
                        message: msg,
                        isMe: isMe,
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Document / File Attachment Card with Native Open Support
                    if (msg.mediaType == 'DOCUMENT' || msg.fileName != null && msg.mediaType != 'IMAGE' && msg.mediaType != 'VIDEO') ...[
                      ChatDocumentAttachmentWidget(
                        message: msg,
                        isMe: isMe,
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Text Content
                    if (msg.message.isNotEmpty)
                      Text(
                        msg.message,
                        style: TextStyle(fontSize: 14.5, color: textColor, height: 1.3),
                      ),
                  ],

                  const SizedBox(height: 4),

                  // Time & Read Receipt Ticks
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        ChatDateFormatter.formatMessageTime(msg.createdAt, context),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isMe
                              ? (isDark
                                  ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                                  : Colors.black54)
                              : theme.colorScheme.outline,
                        ),
                      ),
                      if (isMe && !isDeleted) ...[
                        const SizedBox(width: 4),
                        MessageStatusIcon(
                          status: msg.readByUserIdList.isNotEmpty
                              ? MessageDeliveryStatus.read
                              : MessageDeliveryStatus.delivered,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // PART 1: Reactions Row positioned directly below the bubble without overlapping
          if (msg.reactions.isNotEmpty && !isDeleted) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
              children: msg.reactions.map((reaction) {
                return GestureDetector(
                  onTap: () {
                    ref
                        .read(chatRoomMessagesProvider(widget.roomId).notifier)
                        .toggleReaction(msg.id, reaction.emoji);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: reaction.hasReacted
                            ? theme.colorScheme.primary
                            : (isDark ? Colors.white12 : Colors.black12),
                        width: reaction.hasReacted ? 1.2 : 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(reaction.emoji, style: const TextStyle(fontSize: 13)),
                        if (reaction.count > 1) ...[
                          const SizedBox(width: 3),
                          Text(
                            '${reaction.count}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: reaction.hasReacted
                                  ? theme.colorScheme.primary
                                  : textColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
