import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

class FileOpenService {
  /// Opens a local file using the device's default application handler.
  /// Shows user-friendly feedback on failure.
  static Future<bool> openLocalFile(
    String filePath, {
    BuildContext? context,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File not found on device. Please download it again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return false;
      }

      final result = await OpenFilex.open(filePath);

      switch (result.type) {
        case ResultType.done:
          return true;

        case ResultType.noAppToOpen:
          if (context != null && context.mounted) {
            final ext = filePath.split('.').last.toUpperCase();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'No app found to open $ext files. Please install a compatible viewer from the store.',
                ),
                backgroundColor: Colors.blueGrey,
              ),
            );
          }
          return false;

        case ResultType.fileNotFound:
          if (context != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File not found. Please re-download.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return false;

        case ResultType.permissionDenied:
          if (context != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permission denied to open this file.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return false;

        case ResultType.error:
          if (context != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not open file: ${result.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return false;
      }
    } catch (e) {
      debugPrint('Error in FileOpenService.openLocalFile: $e');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Determines the document icon and accent color based on extension
  static ({IconData icon, Color color, String typeLabel}) getDocumentTypeInfo(String? fileName) {
    if (fileName == null || fileName.isEmpty) {
      return (icon: Icons.insert_drive_file, color: Colors.blueGrey, typeLabel: 'FILE');
    }

    final ext = fileName.split('.').last.toLowerCase();

    switch (ext) {
      case 'pdf':
        return (icon: Icons.picture_as_pdf, color: Colors.redAccent, typeLabel: 'PDF');

      case 'doc':
      case 'docx':
        return (icon: Icons.description, color: Colors.blue.shade700, typeLabel: 'WORD');

      case 'xls':
      case 'xlsx':
        return (icon: Icons.grid_on_rounded, color: Colors.green.shade700, typeLabel: 'EXCEL');

      case 'csv':
        return (icon: Icons.table_chart_rounded, color: Colors.teal.shade700, typeLabel: 'CSV');

      case 'ppt':
      case 'pptx':
        return (icon: Icons.slideshow_rounded, color: Colors.deepOrange, typeLabel: 'PPT');

      case 'txt':
        return (icon: Icons.article_rounded, color: Colors.amber.shade800, typeLabel: 'TEXT');

      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return (icon: Icons.folder_zip_rounded, color: Colors.indigo, typeLabel: 'ARCHIVE');

      case 'mp4':
      case 'mov':
      case 'avi':
      case 'webm':
      case 'mkv':
        return (icon: Icons.video_file_rounded, color: Colors.deepPurple, typeLabel: 'VIDEO');

      default:
        return (icon: Icons.insert_drive_file_rounded, color: Colors.blueGrey, typeLabel: ext.toUpperCase());
    }
  }
}
