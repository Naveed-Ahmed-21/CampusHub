import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_hub_app/app.dart';

void main() {
  testWidgets('CampusHub app initialization smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CampusHubApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('CampusHub Portal'), findsOneWidget);
  });
}
