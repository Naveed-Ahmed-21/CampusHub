import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_hub_app/core/services/media_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MediaStorageService Unit Tests', () {
    test('getBlurredThumbnailUrl generates ImageKit low-resolution transformation URL', () {
      const original = 'https://ik.imagekit.io/campushub/users/user1/image.jpg';
      final blurred = MediaStorageService.getBlurredThumbnailUrl(original);

      expect(blurred.contains('tr:w-40,bl-8,q-20') || blurred.contains('tr=w-40,bl-8,q-20'), true);
      expect(blurred.contains('image.jpg'), true);
    });

    test('getBlurredThumbnailUrl generates generic server low-resolution query URL', () {
      const original = 'https://api.campushub.edu/uploads/media/photo.png';
      final blurred = MediaStorageService.getBlurredThumbnailUrl(original);

      expect(blurred.contains('thumbnail=blur_lowres'), true);
      expect(blurred.contains('w=40'), true);
      expect(blurred.contains('bl=8'), true);
    });

    test('isMessageMediaDownloaded returns false for non-existent file path', () {
      final service = MediaStorageService();

      // Record a non-existent fake local file path
      service.recordDownloadedMessage('fake-msg-id', '/tmp/non_existent_ch_file_12345.jpg');

      // Since file does not exist on disk, isMessageMediaDownloaded must return false
      // and invalidate the entry
      final isDownloaded = service.isMessageMediaDownloaded('fake-msg-id');
      expect(isDownloaded, false);

      final path = service.getDownloadedPathForMessage('fake-msg-id');
      expect(path, isNull);
    });

    test('isMessageMediaDownloaded returns true when valid file exists on disk', () {
      final service = MediaStorageService();

      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/test_downloaded_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
      tempFile.writeAsStringSync('dummy image data');

      try {
        service.recordDownloadedMessage('valid-msg-id', tempFile.path);

        expect(service.isMessageMediaDownloaded('valid-msg-id'), true);
        expect(service.getDownloadedPathForMessage('valid-msg-id'), tempFile.path);

        // Delete the file and verify state reverts to false
        tempFile.deleteSync();
        expect(service.isMessageMediaDownloaded('valid-msg-id'), false);
        expect(service.getDownloadedPathForMessage('valid-msg-id'), isNull);
      } finally {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      }
    });
  });
}
