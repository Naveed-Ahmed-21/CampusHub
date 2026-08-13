import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

enum MediaCategory {
  profileImage,
  postImage,
  clubLogo,
  clubResource,
  chatImage,
  chatDocument,
  eventMedia,
  eventDocument,
  careerResource,
  resume,
  certificate,
  portfolioImage,
  portfolioDocument,
}

class MediaAssetModel {
  final String id;
  final String category;
  final String fileType;
  final String mimeType;
  final String originalName;
  final String fileName;
  final int fileSize;
  final String url;
  final String? thumbnailUrl;
  final String imagekitFileId;
  final String folderPath;

  MediaAssetModel({
    required this.id,
    required this.category,
    required this.fileType,
    required this.mimeType,
    required this.originalName,
    required this.fileName,
    required this.fileSize,
    required this.url,
    this.thumbnailUrl,
    required this.imagekitFileId,
    required this.folderPath,
  });

  factory MediaAssetModel.fromJson(Map<String, dynamic> json) {
    return MediaAssetModel(
      id: json['id'] ?? '',
      category: json['category'] ?? 'POST_IMAGE',
      fileType: json['file_type'] ?? 'IMAGE',
      mimeType: json['mime_type'] ?? 'image/jpeg',
      originalName: json['original_name'] ?? 'file',
      fileName: json['file_name'] ?? 'file',
      fileSize: json['file_size'] ?? 0,
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      imagekitFileId: json['imagekit_file_id'] ?? '',
      folderPath: json['folder_path'] ?? '/campushub/',
    );
  }
}

class ImageKitMediaService {
  final Dio _dio;

  ImageKitMediaService(this._dio);

  /// Validates file size limit according to category
  int _getMaxSizeBytes(MediaCategory category) {
    switch (category) {
      case MediaCategory.profileImage:
      case MediaCategory.clubLogo:
        return 5 * 1024 * 1024; // 5 MB
      case MediaCategory.postImage:
      case MediaCategory.chatImage:
      case MediaCategory.eventMedia:
      case MediaCategory.resume:
      case MediaCategory.certificate:
        return 10 * 1024 * 1024; // 10 MB
      case MediaCategory.chatDocument:
        return 20 * 1024 * 1024; // 20 MB
      case MediaCategory.clubResource:
      case MediaCategory.careerResource:
      case MediaCategory.portfolioDocument:
        return 25 * 1024 * 1024; // 25 MB
      default:
        return 10 * 1024 * 1024;
    }
  }

  String _getFolderPath(MediaCategory category, String? entityId) {
    final id = entityId ?? 'general';
    switch (category) {
      case MediaCategory.profileImage:
      case MediaCategory.resume:
        return '/campushub/users/$id/profile/';
      case MediaCategory.postImage:
        return '/campushub/posts/$id/';
      case MediaCategory.clubLogo:
        return '/campushub/clubs/$id/logo/';
      case MediaCategory.clubResource:
        return '/campushub/clubs/$id/resources/';
      case MediaCategory.chatImage:
        return '/campushub/chat/$id/images/';
      case MediaCategory.chatDocument:
        return '/campushub/chat/$id/documents/';
      case MediaCategory.eventMedia:
      case MediaCategory.eventDocument:
        return '/campushub/events/$id/';
      default:
        return '/campushub/media/';
    }
  }

  Future<MediaAssetModel> uploadFile({
    required File file,
    required MediaCategory category,
    String? entityId,
    ProgressCallback? onProgress,
  }) async {
    final fileSize = await file.length();
    final maxSizeBytes = _getMaxSizeBytes(category);

    if (fileSize > maxSizeBytes) {
      final maxMb = maxSizeBytes ~/ (1024 * 1024);
      throw Exception('File size exceeds the limit of ${maxMb}MB for this category');
    }

    // Step 1: Fetch ImageKit upload credentials from CampusHub backend
    final authResponse = await _dio.get('/api/v1/media/auth');
    final authData = authResponse.data['data'];

    final String token = authData['token'];
    final int expire = authData['expire'];
    final String signature = authData['signature'];
    final String publicKey = authData['publicKey'];

    final String folderPath = _getFolderPath(category, entityId);
    final String originalName = file.path.split('/').last;

    // Step 2: Upload direct to ImageKit API via Multipart FormData
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: originalName),
      'fileName': '${category.name.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}_$originalName',
      'publicKey': publicKey,
      'signature': signature,
      'expire': expire,
      'token': token,
      'folder': folderPath,
      'useUniqueFileName': 'true',
    });

    final imageKitResponse = await Dio().post(
      'https://upload.imagekit.io/api/v1/files/upload',
      data: formData,
      onSendProgress: onProgress,
    );

    final ikData = imageKitResponse.data;
    final String ikFileId = ikData['fileId'];
    final String ikUrl = ikData['url'];
    final String? ikThumbnailUrl = ikData['thumbnailUrl'];
    final int ikWidth = ikData['width'] ?? 0;
    final int ikHeight = ikData['height'] ?? 0;
    final isDoc = category == MediaCategory.chatDocument || category == MediaCategory.clubResource || category == MediaCategory.resume;

    final categoryKey = _categoryToKey(category);

    // Step 3: Save asset reference in CampusHub PostgreSQL database
    final metaResponse = await _dio.post(
      '/api/v1/media/metadata',
      data: {
        'category': categoryKey,
        'fileType': isDoc ? 'DOCUMENT' : 'IMAGE',
        'mimeType': isDoc ? 'application/pdf' : 'image/jpeg',
        'originalName': originalName,
        'fileName': ikData['name'] ?? originalName,
        'fileSize': fileSize,
        'url': ikUrl,
        'thumbnailUrl': ikThumbnailUrl,
        'imagekitFileId': ikFileId,
        'folderPath': folderPath,
        if (ikWidth > 0) 'width': ikWidth,
        if (ikHeight > 0) 'height': ikHeight,
      },
    );

    return MediaAssetModel.fromJson(metaResponse.data['data']);
  }

  String _categoryToKey(MediaCategory category) {
    switch (category) {
      case MediaCategory.profileImage: return 'PROFILE_IMAGE';
      case MediaCategory.postImage: return 'POST_IMAGE';
      case MediaCategory.clubLogo: return 'CLUB_LOGO';
      case MediaCategory.clubResource: return 'CLUB_RESOURCE';
      case MediaCategory.chatImage: return 'CHAT_IMAGE';
      case MediaCategory.chatDocument: return 'CHAT_DOCUMENT';
      case MediaCategory.eventMedia: return 'EVENT_MEDIA';
      case MediaCategory.eventDocument: return 'EVENT_DOCUMENT';
      case MediaCategory.careerResource: return 'CAREER_RESOURCE';
      case MediaCategory.resume: return 'RESUME';
      case MediaCategory.certificate: return 'CERTIFICATE';
      case MediaCategory.portfolioImage: return 'PORTFOLIO_IMAGE';
      case MediaCategory.portfolioDocument: return 'PORTFOLIO_DOCUMENT';
    }
  }

  /// Direct URL uploader helper (when media already uploaded)
  Future<MediaAssetModel> saveUrlMetadata({
    required String url,
    required MediaCategory category,
    required String fileName,
  }) async {
    final metaResponse = await _dio.post(
      '/api/v1/media/metadata',
      data: {
        'category': _categoryToKey(category),
        'fileType': 'IMAGE',
        'mimeType': 'image/jpeg',
        'originalName': fileName,
        'fileName': fileName,
        'fileSize': 1024 * 100,
        'url': url,
        'imagekitFileId': 'ik_url_${DateTime.now().millisecondsSinceEpoch}',
        'folderPath': '/campushub/',
      },
    );

    return MediaAssetModel.fromJson(metaResponse.data['data']);
  }
}

final imageKitMediaServiceProvider = Provider<ImageKitMediaService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ImageKitMediaService(dio);
});
