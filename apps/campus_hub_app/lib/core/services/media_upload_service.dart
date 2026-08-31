import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';
import 'media_picker_service.dart';

class UploadedMediaResult {
  final String url;
  final String fullUrl;
  final String fileName;
  final String fileType;
  final int fileSize;

  const UploadedMediaResult({
    required this.url,
    required this.fullUrl,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
  });

  factory UploadedMediaResult.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['url'] as String? ?? '';
    return UploadedMediaResult(
      url: rawUrl,
      fullUrl: ApiEndpoints.resolveUrl(rawUrl),
      fileName: json['fileName'] as String? ?? 'file',
      fileType: json['fileType'] as String? ?? 'application/octet-stream',
      fileSize: json['fileSize'] as int? ?? 0,
    );
  }
}

class MediaUploadService {
  final Dio _dio;

  MediaUploadService(this._dio);

  Future<UploadedMediaResult> uploadSelectedFile(
    SelectedMediaFile file, {
    ProgressCallback? onProgress,
  }) async {
    // If bytes are available, use FormData with bytes
    if (file.bytes != null) {
      return uploadFileBytes(
        bytes: file.bytes!,
        fileName: file.name,
        mimeType: file.mimeType,
        onProgress: onProgress,
      );
    }

    // Otherwise use path if available
    if (file.path != null && file.path!.isNotEmpty && !kIsWeb) {
      return uploadFilePath(
        filePath: file.path!,
        fileName: file.name,
        mimeType: file.mimeType,
        onProgress: onProgress,
      );
    }

    throw Exception('No file data available to upload.');
  }

  Future<UploadedMediaResult> uploadFilePath({
    required String filePath,
    required String fileName,
    required String mimeType,
    ProgressCallback? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '/api/v1/media/upload',
        data: formData,
        onSendProgress: onProgress,
      );
      return UploadedMediaResult.fromJson(response.data['data']);
    } catch (e) {
      debugPrint('Error uploading file path: $e');
      rethrow;
    }
  }

  Future<UploadedMediaResult> uploadFileBytes({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    ProgressCallback? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });

      final response = await _dio.post(
        '/api/v1/media/upload',
        data: formData,
        onSendProgress: onProgress,
      );
      return UploadedMediaResult.fromJson(response.data['data']);
    } catch (e) {
      // Direct base64 fallback
      final base64String = base64Encode(bytes);
      final response = await _dio.post(
        '/api/v1/media/upload',
        data: {
          'base64': 'data:$mimeType;base64,$base64String',
          'fileName': fileName,
          'mimeType': mimeType,
        },
      );
      return UploadedMediaResult.fromJson(response.data['data']);
    }
  }
}

final mediaUploadServiceProvider = Provider<MediaUploadService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return MediaUploadService(dio);
});
