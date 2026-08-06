import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_hub_app/app.dart';

void main() {
  group('CampusHub App Flow Integration Test', () {
    testWidgets('Verify complete CampusHubApp initialization', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: CampusHubApp(),
        ),
      );

      await tester.pump();
      expect(find.byType(CampusHubApp), findsOneWidget);
    });
  });
}
