import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_hub_app/core/theme/app_theme.dart';
import 'package:campus_hub_app/core/widgets/campus_card.dart';
import 'package:campus_hub_app/core/widgets/campus_chip.dart';
import 'package:campus_hub_app/core/widgets/campus_tab_bar.dart';
import 'package:campus_hub_app/core/widgets/campus_search_field.dart';
import 'package:campus_hub_app/core/widgets/campus_dropdown.dart';
import 'package:campus_hub_app/core/widgets/campus_section_header.dart';

void main() {
  group('CampusHub Global Design System Components Test', () {
    testWidgets('CampusCard renders content and handles tap in both light and dark mode', (tester) async {
      bool tapped = false;

      // Light mode test
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CampusCard(
              onTap: () => tapped = true,
              child: const Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      await tester.tap(find.text('Card Content'));
      expect(tapped, isTrue);

      // Dark mode test
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: CampusCard(
              isElevated: true,
              child: const Text('Dark Elevated Card'),
            ),
          ),
        ),
      );

      expect(find.text('Dark Elevated Card'), findsOneWidget);
    });

    testWidgets('CampusChip renders selected and unselected styles properly', (tester) async {
      bool selected = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CampusChip(
                  label: 'Filter Chip',
                  isSelected: selected,
                  onTap: () {
                    setState(() {
                      selected = !selected;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Filter Chip'), findsOneWidget);
      await tester.tap(find.text('Filter Chip'));
      await tester.pumpAndSettle();
      expect(selected, isTrue);
    });

    testWidgets('CampusTabBar renders and allows switching tabs', (tester) async {
      int activeIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DefaultTabController(
              length: 3,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return CampusTabBar(
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Analytics'),
                      Tab(text: 'Settings'),
                    ],
                    onTap: (index) {
                      setState(() {
                        activeIndex = index;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();
      expect(activeIndex, 1);
    });

    testWidgets('CampusSearchField accepts text and clears input', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CampusSearchField(
                  controller: controller,
                  hintText: 'Search records...',
                  onChanged: (val) => setState(() {}),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Search records...'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Naveed');
      await tester.pump();
      expect(controller.text, 'Naveed');

      // Tap clear icon
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(controller.text, isEmpty);
    });

    testWidgets('CampusDropdown renders label, hint and selects item', (tester) async {
      String? selectedVal;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CampusDropdown<String>(
                  label: 'Select Role',
                  hint: 'Choose a role',
                  value: selectedVal,
                  items: const [
                    DropdownMenuItem(value: 'STUDENT', child: Text('Student')),
                    DropdownMenuItem(value: 'FACULTY', child: Text('Faculty')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      selectedVal = val;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Select Role'), findsOneWidget);
      expect(find.text('Choose a role'), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.text('Student'), findsWidgets);
      await tester.tap(find.text('Student').last);
      await tester.pumpAndSettle();

      expect(selectedVal, 'STUDENT');
    });

    testWidgets('CampusSectionHeader renders title, subtitle and action callback', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CampusSectionHeader(
              title: 'Recent Activities',
              subtitle: 'Updated 5 minutes ago',
              actionText: 'View All',
              onActionTap: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('Recent Activities'), findsOneWidget);
      expect(find.text('Updated 5 minutes ago'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);

      await tester.tap(find.text('View All'));
      expect(actionTriggered, isTrue);
    });
  });
}
