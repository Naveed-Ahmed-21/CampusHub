import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/media_storage_service.dart';

enum DownloadState { notDownloaded, downloading, completed, downloaded }

class DownloadMediaButton extends ConsumerStatefulWidget {
  final String messageId;
  final String imageUrl;
  final String? fileName;
  final VoidCallback? onDownloadComplete;

  const DownloadMediaButton({
    super.key,
    required this.messageId,
    required this.imageUrl,
    this.fileName,
    this.onDownloadComplete,
  });

  @override
  ConsumerState<DownloadMediaButton> createState() => _DownloadMediaButtonState();
}

class _DownloadMediaButtonState extends ConsumerState<DownloadMediaButton> {
  DownloadState _state = DownloadState.notDownloaded;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  void _checkInitialState() {
    final storage = ref.read(mediaStorageServiceProvider);
    if (storage.isMessageMediaDownloaded(widget.messageId)) {
      _state = DownloadState.downloaded;
    }
  }

  Future<void> _startDownload() async {
    if (_state == DownloadState.downloading || _state == DownloadState.downloaded) return;

    setState(() {
      _state = DownloadState.downloading;
      _progress = 0.0;
    });

    final storage = ref.read(mediaStorageServiceProvider);
    final savedPath = await storage.downloadAndSaveImage(
      imageUrl: widget.imageUrl,
      messageId: widget.messageId,
      fileName: widget.fileName,
      onProgress: (p) {
        if (mounted) {
          setState(() {
            _progress = p;
          });
        }
      },
    );

    if (savedPath != null && mounted) {
      setState(() {
        _state = DownloadState.completed;
      });

      widget.onDownloadComplete?.call();

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _state = DownloadState.downloaded;
          });
        }
      });
    } else if (mounted) {
      setState(() {
        _state = DownloadState.notDownloaded;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to download image to CampusHub')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state == DownloadState.downloaded) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
      );
    }

    return GestureDetector(
      onTap: _state == DownloadState.notDownloaded ? _startDownload : null,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Container(
          key: ValueKey(_state),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_state == DownloadState.notDownloaded) ...[
                const Icon(Icons.download, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                const Text(
                  'Download',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ] else if (_state == DownloadState.downloading) ...[
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ] else if (_state == DownloadState.completed) ...[
                const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 4),
                const Text(
                  'Saved',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
