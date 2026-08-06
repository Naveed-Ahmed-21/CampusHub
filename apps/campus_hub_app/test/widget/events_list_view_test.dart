import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_hub_app/features/events/presentation/views/events_list_view.dart';
import 'package:campus_hub_app/features/events/presentation/providers/events_provider.dart';

void main() {
  testWidgets('EventsListView renders search bar and tab bar cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventsListProvider.overrideWith((ref) => Future.value([])),
          userEventRegistrationsProvider.overrideWith((ref) => Future.value([])),
        ],
        child: const MaterialApp(
          home: EventsListView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Campus Events'), findsOneWidget);
    expect(find.text('College'), findsOneWidget);
  });
}
