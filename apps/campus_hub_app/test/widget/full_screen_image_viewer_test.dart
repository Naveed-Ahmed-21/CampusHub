import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_hub_app/shared/widgets/full_screen_image_viewer.dart';

void main() {
  group('FullScreenImageViewer Widget Tests', () {
    testWidgets('renders minimal clean image viewer correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FullScreenImageViewer(
            images: const [
              FullScreenImageData(
                imageUrl: 'https://example.com/image1.jpg',
                title: 'Photo 1',
              ),
            ],
            initialIndex: 0,
          ),
        ),
      );

      // Back button exists
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      // For single image, counter pill is hidden
      expect(find.text('1 / 1'), findsNothing);
      // Copy link option is removed
      expect(find.text('Copy Link'), findsNothing);
      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('renders multi-image gallery with page counter and indicators', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FullScreenImageViewer(
            images: const [
              FullScreenImageData(imageUrl: 'https://example.com/img1.jpg'),
              FullScreenImageData(imageUrl: 'https://example.com/img2.jpg'),
              FullScreenImageData(imageUrl: 'https://example.com/img3.jpg'),
            ],
            initialIndex: 1,
          ),
        ),
      );

      // Should show initial index 2 / 3
      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('swiping page updates the current index and counter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FullScreenImageViewer(
            images: const [
              FullScreenImageData(imageUrl: 'https://example.com/img1.jpg'),
              FullScreenImageData(imageUrl: 'https://example.com/img2.jpg'),
            ],
            initialIndex: 0,
          ),
        ),
      );

      expect(find.text('1 / 2'), findsOneWidget);

      // Fling left to move to next image
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('2 / 2'), findsOneWidget);
    });

    testWidgets('drag down past threshold dismisses image viewer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    FullScreenImageViewer.openSingle(
                      context,
                      imageUrl: 'https://example.com/img.jpg',
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Drag downward by 200px
      await tester.drag(find.byType(PageView), const Offset(0, 200));
      await tester.pumpAndSettle();

      // Should be dismissed and show the opening button again
      expect(find.text('Open'), findsOneWidget);
    });
  });
}
