import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/services/media_picker_service.dart';
import 'campus_video_player.dart';

class SelectedMediaPreviewWidget extends StatelessWidget {
  final SelectedMediaFile file;
  final VoidCallback? onRemove;
  final double? uploadProgress; // 0.0 to 1.0, or null if not uploading
  final bool isUploading;

  const SelectedMediaPreviewWidget({
    super.key,
    required this.file,
    this.onRemove,
    this.uploadProgress,
    this.isUploading = false,
  });

  IconData _getDocumentIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getDocumentColor(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Colors.red.shade700;
      case 'doc':
      case 'docx':
        return Colors.blue.shade700;
      case 'ppt':
      case 'pptx':
        return Colors.orange.shade800;
      case 'xls':
      case 'xlsx':
        return Colors.green.shade700;
      case 'zip':
      case 'rar':
        return Colors.purple.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content;

    if (file.isImage) {
      Widget imageWidget;
      if (file.bytes != null) {
        imageWidget = Image.memory(
          file.bytes!,
          fit: BoxFit.cover,
          height: 200,
        );
      } else if (file.path != null && !kIsWeb) {
        imageWidget = Image.file(
          File(file.path!),
          fit: BoxFit.cover,
          height: 200,
        );
      } else {
        imageWidget = Container(
          height: 200,
          color: Colors.grey.shade300,
          child: const Center(child: Icon(Icons.image, size: 48, color: Colors.grey)),
        );
      }

      content = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: double.infinity,
          height: 200,
          child: imageWidget,
        ),
      );
    } else if (file.isVideo) {
      content = CampusVideoPlayer(
        filePath: file.path,
        borderRadius: BorderRadius.circular(12),
      );
    } else {
      // Document Card
      final docColor = _getDocumentColor(file.name);
      content = Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: docColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_getDocumentIcon(file.name), color: docColor, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    file.formattedSize,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: content,
        ),

        // Remove Button
        if (onRemove != null && !isUploading)
          Positioned(
            top: 14,
            right: 8,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),

        // Uploading Progress Overlay
        if (isUploading)
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      value: uploadProgress,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      uploadProgress != null
                          ? 'Uploading ${(uploadProgress! * 100).toInt()}%...'
                          : 'Uploading file...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
