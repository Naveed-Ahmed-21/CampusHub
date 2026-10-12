import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/api_endpoints.dart';
import '../theme/app_colors.dart';
import 'file_open_service.dart';
import 'local_notification_service.dart';

/// Centralized service for downloading resources, lecture notes, lab manuals,
/// and media files directly into local device storage with notification feedback.
class CampusDownloadService {
  static final Dio _dio = Dio();

  /// Gets the best user-accessible storage directory on the device:
  /// - Android: /storage/emulated/0/Download/CampusHub (standard Downloads)
  /// - Fallback Android: ExternalStorage/CampusHub
  /// - iOS / Desktop: App Documents/CampusHub
  static Future<Directory> getDownloadDirectory({String subFolder = 'Resources'}) async {
    if (!kIsWeb && Platform.isAndroid) {
      // 1. Try public Download folder on Android
      try {
        final publicDownloadDir = Directory('/storage/emulated/0/Download/CampusHub/$subFolder');
        if (!await publicDownloadDir.exists()) {
          await publicDownloadDir.create(recursive: true);
        }
        return publicDownloadDir;
      } catch (_) {
        // Fallback to app external storage
      }

      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final campusExt = Directory('${extDir.path}/CampusHub/$subFolder');
          if (!await campusExt.exists()) {
            await campusExt.create(recursive: true);
          }
          return campusExt;
        }
      } catch (_) {}
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final fallbackDir = Directory('${docsDir.path}/CampusHub/$subFolder');
    if (!await fallbackDir.exists()) {
      await fallbackDir.create(recursive: true);
    }
    return fallbackDir;
  }

  /// Downloads any resource or file from [fileUrl], saves to device storage,
  /// fires a local system notification, and displays an action snackbar with "Open".
  static Future<String?> downloadResource({
    required BuildContext context,
    required String fileUrl,
    required String fileName,
    String? subFolder,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final trimmedUrl = fileUrl.trim();

    if (trimmedUrl.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Download URL is not available for this resource.'),
          backgroundColor: AppColors.error,
        ),
      );
      return null;
    }

    // Sanitize filename
    final sanitizedName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    final cleanFileName = sanitizedName.isNotEmpty ? sanitizedName : 'downloaded_resource';

    // Show initial downloading feedback
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Downloading $cleanFileName...',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );

    try {
      final resolvedUrl = ApiEndpoints.resolveUrl(trimmedUrl);
      final downloadDir = await getDownloadDirectory(subFolder: subFolder ?? 'Resources');
      final targetPath = '${downloadDir.path}/$cleanFileName';

      // Download file
      await _dio.download(
        resolvedUrl,
        targetPath,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );

      final file = File(targetPath);
      if (await file.exists()) {
        // Fire system notification
        await LocalNotificationService.showNotification(
          title: '$cleanFileName Downloaded',
          body: 'Resource saved in ${downloadDir.path}',
          payload: targetPath,
        );

        // Show success snackbar with Open Action
        if (context.mounted) {
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ $cleanFileName downloaded!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Saved to: ${downloadDir.path}',
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'Open File',
                textColor: Colors.white,
                onPressed: () {
                  FileOpenService.openLocalFile(targetPath, context: context);
                },
              ),
            ),
          );
        }

        return targetPath;
      } else {
        throw Exception('File was not written to disk');
      }
    } catch (e) {
      debugPrint('⚠️ [CampusDownloadService] Download error: $e');
      if (context.mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to download $cleanFileName: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return null;
    }
  }
}
