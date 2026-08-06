import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_hub_app/features/admin/presentation/views/admin_panel_view.dart';
import 'package:campus_hub_app/features/admin/presentation/providers/admin_provider.dart';
import '../mocks/mock_data.dart';

void main() {
  testWidgets('AdminPanelView renders dashboard tab and KPI metrics cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminMetricsProvider.overrideWith((ref) => Future.value(MockData.mockAdminMetrics)),
          adminAuditReportsProvider.overrideWith((ref) => Future.value([])),
        ],
        child: const MaterialApp(
          home: AdminPanelView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('CampusHub Admin Panel'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Total Users'), findsOneWidget);
    expect(find.text('1420'), findsOneWidget);
  });
}
