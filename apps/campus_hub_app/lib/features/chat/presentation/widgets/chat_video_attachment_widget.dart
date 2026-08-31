import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/file_open_service.dart';
import '../../../../core/services/media_storage_service.dart';
import '../../domain/chat_models.dart';

enum VideoDownloadState {
  notDownloaded,
  downloading,
  downloaded,
}

class ChatVideoAttachmentWidget extends ConsumerStatefulWidget {
  final ChatMessageModel message;
  final bool isMe;

  const ChatVideoAttachmentWidget({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  ConsumerState<ChatVideoAttachmentWidget> createState() => _ChatVideoAttachmentWidgetState();
}

class _ChatVideoAttachmentWidgetState extends ConsumerState<ChatVideoAttachmentWidget> {
  VideoDownloadState _state = VideoDownloadState.notDownloaded;
  double _downloadProgress = 0.0;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  @override
  void didUpdateWidget(covariant ChatVideoAttachmentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id != widget.message.id) {
      _checkInitialState();
    }
  }

  void _checkInitialState() {
    final storageService = ref.read(mediaStorageServiceProvider);
    if (widget.isMe) {
      // Sender: Check if media is cached or stored locally
      if (storageService.isMessageMediaDownloaded(widget.message.id)) {
        _state = VideoDownloadState.downloaded;
        _localPath = storageService.getDownloadedPathForMessage(widget.message.id);
      } else {
        _state = VideoDownloadState.downloaded;
      }
    } else {
      if (storageService.isMessageMediaDownloaded(widget.message.id)) {
        _state = VideoDownloadState.downloaded;
        _localPath = storageService.getDownloadedPathForMessage(widget.message.id);
      } else {
        _state = VideoDownloadState.notDownloaded;
        _localPath = null;
      }
    }
  }

  Future<void> _startDownload() async {
    if (widget.message.mediaUrl == null || widget.message.mediaUrl!.isEmpty) return;

    setState(() {
      _state = VideoDownloadState.downloading;
      _downloadProgress = 0.0;
    });

    try {
      final storage = ref.read(mediaStorageServiceProvider);
      final savedPath = await storage.downloadAndSaveFile(
        fileUrl: widget.message.mediaUrl!,
        messageId: widget.message.id,
        fileName: widget.message.fileName ?? 'video_${widget.message.id}.mp4',
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
      );

      if (mounted) {
        if (savedPath != null) {
          setState(() {
            _state = VideoDownloadState.downloaded;
            _localPath = savedPath;
          });
        } else {
          setState(() {
            _state = VideoDownloadState.notDownloaded;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = VideoDownloadState.notDownloaded;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download video: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _playVideo() async {
    final storageService = ref.read(mediaStorageServiceProvider);

    // Verify local file exists
    if (_localPath != null && File(_localPath!).existsSync()) {
      await FileOpenService.openLocalFile(_localPath!, context: context);
      return;
    }

    if (storageService.isMessageMediaDownloaded(widget.message.id)) {
      final path = storageService.getDownloadedPathForMessage(widget.message.id);
      if (path != null && File(path).existsSync()) {
        await FileOpenService.openLocalFile(path, context: context);
        return;
      }
    }

    // If remote URL is present, download first or open directly
    if (widget.message.mediaUrl != null && widget.message.mediaUrl!.isNotEmpty) {
      _startDownload();
    }
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileName = widget.message.fileName ?? 'Video';
    final formattedSize = _formatFileSize(widget.message.fileSize);
    final hasRemoteUrl = widget.message.mediaUrl != null && widget.message.mediaUrl!.isNotEmpty;
    final thumbnailUrl = hasRemoteUrl ? MediaStorageService.getBlurredThumbnailUrl(widget.message.mediaUrl!) : '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 240,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background preview image if available
            if (thumbnailUrl.isNotEmpty)
              Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.black87,
                  child: const Center(
                    child: Icon(Icons.movie_creation_outlined, color: Colors.white24, size: 48),
                  ),
                ),
              )
            else
              Container(
                color: Colors.black87,
                child: const Center(
                  child: Icon(Icons.movie_creation_outlined, color: Colors.white24, size: 48),
                ),
              ),

            // Subtle dark overlay gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),

            // Centered Play / Download / Progress Button
            Center(
              child: _buildCenterAction(theme),
            ),

            // Top-left Video Badge
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'VIDEO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Info Bar (File Name + Size)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        fileName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (formattedSize.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        formattedSize,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterAction(ThemeData theme) {
    switch (_state) {
      case VideoDownloadState.downloading:
        return Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: _downloadProgress > 0 ? _downloadProgress : null,
                strokeWidth: 3.5,
                color: theme.colorScheme.primary,
              ),
              if (_downloadProgress > 0)
                Text(
                  '${(_downloadProgress * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        );

      case VideoDownloadState.downloaded:
        return GestureDetector(
          onTap: _playVideo,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: theme.colorScheme.primary,
              size: 36,
            ),
          ),
        );

      case VideoDownloadState.notDownloaded:
        return GestureDetector(
          onTap: _startDownload,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white38, width: 1.5),
            ),
            child: const Icon(
              Icons.download_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        );
    }
  }
}
