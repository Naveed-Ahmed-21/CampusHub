import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/media_storage_service.dart';
import '../../../../shared/widgets/campus_network_image.dart';
import '../../../../shared/widgets/full_screen_image_viewer.dart';
import '../../domain/chat_models.dart';
import 'download_media_button.dart';

class ChatImageAttachmentWidget extends ConsumerStatefulWidget {
  final ChatMessageModel message;
  final bool isMe;
  final List<ChatMessageModel> allMessages;

  const ChatImageAttachmentWidget({
    super.key,
    required this.message,
    required this.isMe,
    required this.allMessages,
  });

  @override
  ConsumerState<ChatImageAttachmentWidget> createState() => _ChatImageAttachmentWidgetState();
}

class _ChatImageAttachmentWidgetState extends ConsumerState<ChatImageAttachmentWidget> {
  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final mediaUrl = msg.mediaUrl ?? '';
    if (mediaUrl.isEmpty) return const SizedBox.shrink();

    final storage = ref.watch(mediaStorageServiceProvider);
    final isDownloaded = storage.isMessageMediaDownloaded(msg.id);
    final localPath = isDownloaded ? storage.getDownloadedPathForMessage(msg.id) : null;

    // Sender or Receiver with downloaded local file
    if (widget.isMe || (isDownloaded && localPath != null)) {
      return GestureDetector(
        onTap: () => _openFullScreenGallery(localPath: localPath, isDownloaded: true),
        child: Hero(
          tag: 'chat_msg_img_${msg.id}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: localPath != null && !kIsWeb
                ? Image.file(
                    File(localPath),
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : CampusNetworkImage(
                    imageUrl: mediaUrl,
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
      );
    }

    // Receiver with un-downloaded image: ONLY load blurred low-resolution thumbnail
    final blurredThumbnailUrl = MediaStorageService.getBlurredThumbnailUrl(mediaUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 190,
        width: double.infinity,
        color: Colors.black26,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Intentionally low-res blurred thumbnail (original image URL is NEVER requested here)
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: CampusNetworkImage(
                imageUrl: blurredThumbnailUrl,
                height: 190,
                width: double.infinity,
                fit: BoxFit.cover,
                cacheWidth: 80,
                cacheHeight: 80,
                placeholder: Container(
                  color: Colors.grey.shade900,
                  child: const Center(
                    child: Icon(Icons.image, size: 36, color: Colors.white24),
                  ),
                ),
              ),
            ),

            // Semi-transparent dark overlay for high contrast
            Container(color: Colors.black38),

            // Prominent Centered Download Button
            Center(
              child: DownloadMediaButton(
                messageId: msg.id,
                imageUrl: mediaUrl,
                fileName: msg.fileName,
                onDownloadComplete: () {
                  if (mounted) {
                    setState(() {});
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullScreenGallery({String? localPath, required bool isDownloaded}) {
    final imageMessages = widget.allMessages
        .where((m) =>
            m.mediaType == 'IMAGE' &&
            m.mediaUrl != null &&
            m.mediaUrl!.isNotEmpty &&
            !m.isDeletedForEveryone)
        .toList();

    final storage = ref.read(mediaStorageServiceProvider);

    final galleryImages = imageMessages.map((m) {
      final mDownloaded = widget.isMe || storage.isMessageMediaDownloaded(m.id);
      final mLocalPath = mDownloaded ? storage.getDownloadedPathForMessage(m.id) : null;
      final blurredThumb = MediaStorageService.getBlurredThumbnailUrl(m.mediaUrl!);

      return FullScreenImageData(
        imageUrl: m.mediaUrl!,
        filePath: mLocalPath,
        blurredThumbnailUrl: blurredThumb,
        isDownloaded: mDownloaded,
        messageId: m.id,
        heroTag: 'chat_msg_img_${m.id}',
        title: m.fileName ?? 'Photo',
        subtitle: 'Shared by ${m.senderName}',
      );
    }).toList();

    final initialIdx = imageMessages.indexWhere((m) => m.id == widget.message.id);

    FullScreenImageViewer.open(
      context,
      images: galleryImages.isNotEmpty
          ? galleryImages
          : [
              FullScreenImageData(
                imageUrl: widget.message.mediaUrl!,
                filePath: localPath,
                blurredThumbnailUrl: MediaStorageService.getBlurredThumbnailUrl(widget.message.mediaUrl!),
                isDownloaded: isDownloaded,
                messageId: widget.message.id,
                heroTag: 'chat_msg_img_${widget.message.id}',
                title: widget.message.fileName ?? 'Photo',
                subtitle: 'Shared by ${widget.message.senderName}',
              ),
            ],
      initialIndex: initialIdx >= 0 ? initialIdx : 0,
    );
  }
}
