import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

enum MediaTypeOption {
  image,
  video,
  document,
  all,
}

class SelectedMediaFile {
  final String? path;
  final Uint8List? bytes;
  final String name;
  final int size;
  final String mediaType; // 'IMAGE', 'VIDEO', 'DOCUMENT'
  final String mimeType;

  const SelectedMediaFile({
    this.path,
    this.bytes,
    required this.name,
    required this.size,
    required this.mediaType,
    required this.mimeType,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isImage => mediaType == 'IMAGE';
  bool get isVideo => mediaType == 'VIDEO';
  bool get isDocument => mediaType == 'DOCUMENT';
}

class MediaPickerService {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Pick single image from Camera
  static Future<SelectedMediaFile?> pickImageFromCamera({
    int imageQuality = 85,
    double maxWidth = 1920,
    double maxHeight = 1920,
  }) async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      if (file == null) return null;
      final bytes = await file.readAsBytes();
      final size = await file.length();
      return SelectedMediaFile(
        path: file.path,
        bytes: bytes,
        name: file.name.isNotEmpty ? file.name : 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg',
        size: size,
        mediaType: 'IMAGE',
        mimeType: file.mimeType ?? 'image/jpeg',
      );
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      return null;
    }
  }

  /// Pick single image from Gallery
  static Future<SelectedMediaFile?> pickImageFromGallery({
    int imageQuality = 85,
    double maxWidth = 1920,
    double maxHeight = 1920,
  }) async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      if (file == null) return null;
      final bytes = await file.readAsBytes();
      final size = await file.length();
      return SelectedMediaFile(
        path: file.path,
        bytes: bytes,
        name: file.name.isNotEmpty ? file.name : 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        size: size,
        mediaType: 'IMAGE',
        mimeType: file.mimeType ?? 'image/jpeg',
      );
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Pick multiple images from Gallery
  static Future<List<SelectedMediaFile>> pickMultipleImages({
    int imageQuality = 85,
    double maxWidth = 1920,
    double maxHeight = 1920,
  }) async {
    try {
      final List<XFile> files = await _imagePicker.pickMultiImage(
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      final List<SelectedMediaFile> results = [];
      for (final file in files) {
        final bytes = await file.readAsBytes();
        final size = await file.length();
        results.add(SelectedMediaFile(
          path: file.path,
          bytes: bytes,
          name: file.name,
          size: size,
          mediaType: 'IMAGE',
          mimeType: file.mimeType ?? 'image/jpeg',
        ));
      }
      return results;
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      return [];
    }
  }

  /// Record video from Camera
  static Future<SelectedMediaFile?> recordVideo({
    Duration maxDuration = const Duration(minutes: 3),
  }) async {
    try {
      final XFile? file = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: maxDuration,
      );
      if (file == null) return null;
      final bytes = await file.readAsBytes();
      final size = await file.length();
      return SelectedMediaFile(
        path: file.path,
        bytes: bytes,
        name: file.name.isNotEmpty ? file.name : 'video_${DateTime.now().millisecondsSinceEpoch}.mp4',
        size: size,
        mediaType: 'VIDEO',
        mimeType: file.mimeType ?? 'video/mp4',
      );
    } catch (e) {
      debugPrint('Error recording video: $e');
      return null;
    }
  }

  /// Pick video from Gallery
  static Future<SelectedMediaFile?> pickVideoFromGallery({
    Duration maxDuration = const Duration(minutes: 5),
  }) async {
    try {
      final XFile? file = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: maxDuration,
      );
      if (file == null) return null;
      final bytes = await file.readAsBytes();
      final size = await file.length();
      return SelectedMediaFile(
        path: file.path,
        bytes: bytes,
        name: file.name.isNotEmpty ? file.name : 'video_${DateTime.now().millisecondsSinceEpoch}.mp4',
        size: size,
        mediaType: 'VIDEO',
        mimeType: file.mimeType ?? 'video/mp4',
      );
    } catch (e) {
      debugPrint('Error picking video from gallery: $e');
      return null;
    }
  }

  /// Pick Documents / Files using file_picker
  static Future<List<SelectedMediaFile>> pickDocuments({
    List<String>? allowedExtensions,
    bool allowMultiple = true,
  }) async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: allowedExtensions != null && allowedExtensions.isNotEmpty
            ? FileType.custom
            : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return [];

      final List<SelectedMediaFile> files = [];
      for (final pFile in result.files) {
        final bytes = pFile.bytes ?? (pFile.path != null ? await File(pFile.path!).readAsBytes() : null);
        final extension = (pFile.extension ?? '').toLowerCase();
        
        String mediaType = 'DOCUMENT';
        String mimeType = 'application/octet-stream';
        
        if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(extension)) {
          mediaType = 'IMAGE';
          mimeType = 'image/$extension';
        } else if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension)) {
          mediaType = 'VIDEO';
          mimeType = 'video/$extension';
        } else if (extension == 'pdf') {
          mimeType = 'application/pdf';
        } else if (['doc', 'docx'].contains(extension)) {
          mimeType = 'application/msword';
        } else if (['ppt', 'pptx'].contains(extension)) {
          mimeType = 'application/vnd.ms-powerpoint';
        } else if (['xls', 'xlsx'].contains(extension)) {
          mimeType = 'application/vnd.ms-excel';
        } else if (extension == 'txt') {
          mimeType = 'text/plain';
        } else if (extension == 'zip') {
          mimeType = 'application/zip';
        }

        files.add(SelectedMediaFile(
          path: pFile.path,
          bytes: bytes,
          name: pFile.name,
          size: pFile.size,
          mediaType: mediaType,
          mimeType: mimeType,
        ));
      }
      return files;
    } catch (e) {
      debugPrint('Error picking documents: $e');
      return [];
    }
  }

  /// Show standard bottom sheet for media selection across CampusHub
  static Future<SelectedMediaFile?> showMediaPickerSheet(
    BuildContext context, {
    String title = 'Add Media',
    bool enableCamera = true,
    bool enableGallery = true,
    bool enableVideoCamera = false,
    bool enableVideoGallery = false,
    bool enableDocuments = false,
    bool enableRemove = false,
    List<String>? documentExtensions,
  }) async {
    final theme = Theme.of(context);

    return showModalBottomSheet<SelectedMediaFile?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(null),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Options Grid / List
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  if (enableCamera)
                    _buildOptionTile(
                      context,
                      icon: Icons.camera_alt,
                      color: Colors.blue,
                      label: 'Take Photo',
                      onTap: () async {
                        final file = await pickImageFromCamera();
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop(file);
                        }
                      },
                    ),

                  if (enableGallery)
                    _buildOptionTile(
                      context,
                      icon: Icons.photo_library,
                      color: Colors.purple,
                      label: 'Choose Photo',
                      onTap: () async {
                        final file = await pickImageFromGallery();
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop(file);
                        }
                      },
                    ),

                  if (enableVideoCamera)
                    _buildOptionTile(
                      context,
                      icon: Icons.videocam,
                      color: Colors.red,
                      label: 'Record Video',
                      onTap: () async {
                        final file = await recordVideo();
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop(file);
                        }
                      },
                    ),

                  if (enableVideoGallery)
                    _buildOptionTile(
                      context,
                      icon: Icons.video_library,
                      color: Colors.orange,
                      label: 'Choose Video',
                      onTap: () async {
                        final file = await pickVideoFromGallery();
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop(file);
                        }
                      },
                    ),

                  if (enableDocuments)
                    _buildOptionTile(
                      context,
                      icon: Icons.insert_drive_file,
                      color: Colors.teal,
                      label: 'Choose File',
                      onTap: () async {
                        final files = await pickDocuments(
                          allowedExtensions: documentExtensions,
                          allowMultiple: false,
                        );
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop(files.isNotEmpty ? files.first : null);
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 95,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
