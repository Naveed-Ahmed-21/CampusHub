import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/file_open_service.dart';
import '../../../../core/services/media_storage_service.dart';
import '../../domain/chat_models.dart';

enum DocumentDownloadState {
  notDownloaded,
  downloading,
  downloaded,
}

class ChatDocumentAttachmentWidget extends ConsumerStatefulWidget {
  final ChatMessageModel message;
  final bool isMe;

  const ChatDocumentAttachmentWidget({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  ConsumerState<ChatDocumentAttachmentWidget> createState() => _ChatDocumentAttachmentWidgetState();
}

class _ChatDocumentAttachmentWidgetState extends ConsumerState<ChatDocumentAttachmentWidget> {
  DocumentDownloadState _state = DocumentDownloadState.notDownloaded;
  double _downloadProgress = 0.0;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  @override
  void didUpdateWidget(covariant ChatDocumentAttachmentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id != widget.message.id) {
      _checkInitialState();
    }
  }

  void _checkInitialState() {
    final storageService = ref.read(mediaStorageServiceProvider);
    if (widget.isMe) {
      // Sender: Already has access, never needs download button
      _state = DocumentDownloadState.downloaded;
      _localPath = storageService.getDownloadedPathForMessage(widget.message.id);
    } else {
      // Receiver: Show downloaded only if already in local storage
      if (storageService.isMessageMediaDownloaded(widget.message.id)) {
        _state = DocumentDownloadState.downloaded;
        _localPath = storageService.getDownloadedPathForMessage(widget.message.id);
      } else {
        _state = DocumentDownloadState.notDownloaded;
        _localPath = null;
      }
    }
  }

  Future<void> _startDownload() async {
    if (widget.message.mediaUrl == null || widget.message.mediaUrl!.isEmpty) return;

    setState(() {
      _state = DocumentDownloadState.downloading;
      _downloadProgress = 0.0;
    });

    try {
      final storage = ref.read(mediaStorageServiceProvider);
      final savedPath = await storage.downloadAndSaveFile(
        fileUrl: widget.message.mediaUrl!,
        messageId: widget.message.id,
        fileName: widget.message.fileName,
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
            _state = DocumentDownloadState.downloaded;
            _localPath = savedPath;
          });
        } else {
          setState(() {
            _state = DocumentDownloadState.notDownloaded;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = DocumentDownloadState.notDownloaded;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download document: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openDocument() async {
    final storageService = ref.read(mediaStorageServiceProvider);
    
    // Verify file still exists on disk
    if (!storageService.isMessageMediaDownloaded(widget.message.id)) {
      setState(() {
        _state = DocumentDownloadState.notDownloaded;
        _localPath = null;
      });
      _startDownload();
      return;
    }

    final path = _localPath ?? storageService.getDownloadedPathForMessage(widget.message.id);
    if (path != null) {
      await FileOpenService.openLocalFile(path, context: context);
    } else {
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
    final fileName = widget.message.fileName ?? 'Document';
    final docInfo = FileOpenService.getDocumentTypeInfo(fileName);
    final formattedSize = _formatFileSize(widget.message.fileSize);

    return InkWell(
      onTap: () {
        if (_state == DocumentDownloadState.downloaded) {
          _openDocument();
        } else if (_state == DocumentDownloadState.notDownloaded) {
          _startDownload();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            // Colored Document Type Icon Badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: docInfo.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  docInfo.icon,
                  color: docInfo.color,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // File Name, Type, and Size
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: docInfo.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          docInfo.typeLabel,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: docInfo.color,
                          ),
                        ),
                      ),
                      if (formattedSize.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          formattedSize,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Download / Open Action Button
            _buildActionIndicator(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIndicator(ThemeData theme) {
    switch (_state) {
      case DocumentDownloadState.downloading:
        return SizedBox(
          width: 32,
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: _downloadProgress > 0 ? _downloadProgress : null,
                strokeWidth: 3,
                color: theme.colorScheme.primary,
              ),
              if (_downloadProgress > 0)
                Text(
                  '${(_downloadProgress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        );

      case DocumentDownloadState.downloaded:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.open_in_new_rounded, size: 14, color: theme.colorScheme.onPrimaryContainer),
              const SizedBox(width: 4),
              Text(
                'Open',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        );

      case DocumentDownloadState.notDownloaded:
        return CircleAvatar(
          radius: 16,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          child: Icon(
            Icons.download_rounded,
            color: theme.colorScheme.primary,
            size: 18,
          ),
        );
    }
  }
}
