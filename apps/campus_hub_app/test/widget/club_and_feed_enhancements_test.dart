import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_hub_app/features/feed/presentation/widgets/feed_filter_tabs_widget.dart';
import 'package:campus_hub_app/features/feed/presentation/widgets/create_post_sheet.dart';
import 'package:campus_hub_app/features/clubs/presentation/views/clubs_list_view.dart';
import 'package:campus_hub_app/features/clubs/presentation/providers/club_provider.dart';

void main() {
  group('Feed Filter Tabs Widget Tests', () {
    testWidgets('displays Cross Department tab and triggers selection', (tester) async {
      String selectedTab = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedFilterTabsWidget(
              activeFeedType: 'MY_FEED',
              onSelectTab: (type) {
                selectedTab = type;
              },
            ),
          ),
        ),
      );

      expect(find.text('For You'), findsOneWidget);
      expect(find.text('Following'), findsOneWidget);
      expect(find.text('My Department'), findsOneWidget);
      expect(find.text('Cross Department'), findsOneWidget);
      expect(find.text('Related'), findsOneWidget);

      await tester.tap(find.text('Cross Department'));
      await tester.pump();

      expect(selectedTab, 'CROSS_DEPARTMENT');
    });
  });

  group('Create Post Sheet Header Tests', () {
    testWidgets('displays club posting header when clubId and clubName are provided', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CreatePostSheet(
                clubId: 'club-123',
                clubName: 'Robotics Club',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Create Club Post'), findsOneWidget);
      expect(find.text('Posting to: Robotics Club'), findsOneWidget);
    });
  });

  group('Clubs List View Tests', () {
    testWidgets('renders Department Only filter switch and search field', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            approvedClubsProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: ClubsListView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Department Only'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
