import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/api_endpoints.dart';

final mediaStorageServiceProvider = Provider<MediaStorageService>((ref) {
  final service = MediaStorageService();
  service.init();
  return service;
});

class MediaStorageService {
  final Dio _dio;
  static bool _isInitialized = false;
  static final Map<String, String> _downloadedMessagesCache = {};

  MediaStorageService({Dio? dio}) : _dio = dio ?? Dio();

  /// Loads downloaded messages cache from persistent disk storage
  Future<void> init() async {
    if (_isInitialized || kIsWeb) return;
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/media_downloads.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> jsonMap = jsonDecode(content);
        for (final entry in jsonMap.entries) {
          _downloadedMessagesCache[entry.key] = entry.value.toString();
        }
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error loading media downloads registry: $e');
    }
  }

  /// Persists download registry to disk
  Future<void> _persistRegistry() async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/media_downloads.json');
      await file.writeAsString(jsonEncode(_downloadedMessagesCache), flush: true);
    } catch (e) {
      debugPrint('Error persisting media downloads registry: $e');
    }
  }

  /// Generates a low-resolution blurred thumbnail URL for ImageKit or server media
  static String getBlurredThumbnailUrl(String originalUrl) {
    if (originalUrl.isEmpty) return '';
    final resolved = ApiEndpoints.resolveUrl(originalUrl);

    if (resolved.contains('ik.imagekit.io')) {
      try {
        final uri = Uri.parse(resolved);
        final segments = List<String>.from(uri.pathSegments);
        if (segments.isNotEmpty) {
          final last = segments.removeLast();
          segments.add('tr:w-40,bl-8,q-20');
          segments.add(last);
          return uri.replace(pathSegments: segments).toString();
        }
      } catch (_) {}
      return '$resolved?tr=w-40,bl-8,q-20';
    }

    if (resolved.contains('?')) {
      return '$resolved&thumbnail=blur_lowres&w=40&bl=8&q=20';
    }
    return '$resolved?thumbnail=blur_lowres&w=40&bl=8&q=20';
  }

  /// Gets or creates the CampusHub media directory on the device
  Future<Directory?> getCampusHubDirectory() async {
    if (kIsWeb) return null;

    try {
      Directory? baseDir;

      if (Platform.isAndroid) {
        try {
          baseDir = await getExternalStorageDirectory();
        } catch (_) {}
      } else if (Platform.isIOS || Platform.isMacOS) {
        baseDir = await getApplicationDocumentsDirectory();
      } else {
        baseDir = await getApplicationSupportDirectory();
      }

      baseDir ??= await getApplicationDocumentsDirectory();

      final campusHubDir = Directory('${baseDir.path}/CampusHub');
      if (!await campusHubDir.exists()) {
        await campusHubDir.create(recursive: true);
      }

      return campusHubDir;
    } catch (e) {
      debugPrint('Error getting CampusHub directory: $e');
      return null;
    }
  }

  /// Automatically saves camera captured image to CampusHub directory
  Future<String?> saveCameraImageToCampusHub({
    required String originalPath,
    String? preferredName,
  }) async {
    if (kIsWeb) return originalPath;

    try {
      final campusDir = await getCampusHubDirectory();
      if (campusDir == null) return originalPath;

      final originalFile = File(originalPath);
      if (!await originalFile.exists()) return originalPath;

      final name = preferredName ??
          'IMG_${DateTime.now().millisecondsSinceEpoch}_${originalFile.uri.pathSegments.last}';
      final targetPath = '${campusDir.path}/$name';

      final savedFile = await originalFile.copy(targetPath);
      return savedFile.path;
    } catch (e) {
      debugPrint('Error saving camera image to CampusHub: $e');
      return originalPath;
    }
  }

  /// Save raw bytes to CampusHub folder
  Future<String?> saveBytesToCampusHub({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (kIsWeb) return null;

    try {
      final campusDir = await getCampusHubDirectory();
      if (campusDir == null) return null;

      final targetPath = '${campusDir.path}/$fileName';
      final file = File(targetPath);
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      debugPrint('Error saving bytes to CampusHub: $e');
      return null;
    }
  }

  /// Downloads image from URL with progress reporting and stores in CampusHub folder
  Future<String?> downloadAndSaveImage({
    required String imageUrl,
    required String messageId,
    String? fileName,
    void Function(double progress)? onProgress,
  }) async {
    if (kIsWeb) return null;

    try {
      final campusDir = await getCampusHubDirectory();
      if (campusDir == null) return null;

      final resolvedUrl = ApiEndpoints.resolveUrl(imageUrl);
      final extension = imageUrl.split('?').first.split('.').last;
      final cleanExt = extension.length <= 4 && extension.isNotEmpty ? extension : 'jpg';
      final name = fileName ?? 'CH_${messageId}_${DateTime.now().millisecondsSinceEpoch}.$cleanExt';
      final targetPath = '${campusDir.path}/$name';

      await _dio.download(
        resolvedUrl,
        targetPath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      final file = File(targetPath);
      if (await file.exists()) {
        recordDownloadedMessage(messageId, targetPath);
        return targetPath;
      }
      return null;
    } catch (e) {
      debugPrint('Error downloading media to CampusHub: $e');
      return null;
    }
  }

  /// Downloads any document, video, or generic file with progress reporting and preserves original extension
  Future<String?> downloadAndSaveFile({
    required String fileUrl,
    required String messageId,
    String? fileName,
    void Function(double progress)? onProgress,
  }) async {
    if (kIsWeb) return null;

    try {
      final campusDir = await getCampusHubDirectory();
      if (campusDir == null) return null;

      final resolvedUrl = ApiEndpoints.resolveUrl(fileUrl);

      // Determine clean filename preserving extension
      String targetFileName;
      if (fileName != null && fileName.isNotEmpty) {
        // Sanitize filename to prevent path traversal
        final sanitized = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
        targetFileName = 'CH_${messageId}_$sanitized';
      } else {
        final urlExt = fileUrl.split('?').first.split('.').last;
        final cleanExt = urlExt.length <= 5 && urlExt.isNotEmpty ? urlExt : 'bin';
        targetFileName = 'CH_${messageId}_${DateTime.now().millisecondsSinceEpoch}.$cleanExt';
      }

      final targetPath = '${campusDir.path}/$targetFileName';

      await _dio.download(
        resolvedUrl,
        targetPath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      final file = File(targetPath);
      if (await file.exists()) {
        recordDownloadedMessage(messageId, targetPath);
        return targetPath;
      }
      return null;
    } catch (e) {
      debugPrint('Error downloading file to CampusHub: $e');
      return null;
    }
  }

  /// Checks if message media is downloaded locally and verifies file exists on disk
  bool isMessageMediaDownloaded(String messageId) {
    final cachedPath = _downloadedMessagesCache[messageId];
    if (cachedPath != null && !kIsWeb) {
      final exists = File(cachedPath).existsSync();
      if (!exists) {
        // File was manually deleted: invalidate cached state
        _downloadedMessagesCache.remove(messageId);
        _persistRegistry();
        return false;
      }
      return true;
    }
    return false;
  }

  /// Gets local path for downloaded message media if file exists on disk
  String? getDownloadedPathForMessage(String messageId) {
    if (isMessageMediaDownloaded(messageId)) {
      return _downloadedMessagesCache[messageId];
    }
    return null;
  }

  /// Records downloaded message in persistent cache
  void recordDownloadedMessage(String messageId, String localPath) {
    _downloadedMessagesCache[messageId] = localPath;
    _persistRegistry();
  }

  /// Manually clears cached download state for testing or cache reset
  void clearDownloadCache() {
    _downloadedMessagesCache.clear();
    _persistRegistry();
  }
}
