import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_hub_app/features/admin/presentation/views/admin_panel_view.dart';
import 'package:campus_hub_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:campus_hub_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:campus_hub_app/features/auth/domain/models/auth_user.dart';
import '../mocks/mock_data.dart';

class MockAdminAuthController extends AuthController {
  final AuthUser? _mockUser;
  MockAdminAuthController(this._mockUser);

  @override
  Future<AuthUser?> build() async => _mockUser;
}

void main() {
  final mockCollege = {
    'id': 'col-1',
    'name': 'National Institute of Technology',
    'code': 'NIT',
    'domain': 'nit.edu',
    'address': 'Campus Road 1, Tech City',
    'is_active': true,
    '_count': {
      'departments': 8,
      'users': 1420,
      'academic_programs': 12,
      'academic_classes': 36,
      'rooms': 45,
      'drives': 15,
      'clubs': 14,
      'events': 22,
    },
  };

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

  testWidgets('AdminPanelView renders Settings & Governance tab with Institutional Profile and Role Governance', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminMetricsProvider.overrideWith((ref) => Future.value(MockData.mockAdminMetrics)),
          adminAuditReportsProvider.overrideWith((ref) => Future.value([])),
          adminCollegeSettingsProvider.overrideWith((ref) => Future.value(mockCollege)),
          adminAuditReportsFilteredProvider.overrideWith((ref, filter) => Future.value([])),
        ],
        child: const MaterialApp(
          home: AdminPanelView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final settingsTab = find.text('Settings & Governance');
    await tester.ensureVisible(settingsTab);
    await tester.tap(settingsTab);
    await tester.pumpAndSettle();

    // Verify SegmentedButton options
    expect(find.text('Institutional Profile'), findsOneWidget);
    expect(find.text('Audit Logs & CSV'), findsOneWidget);
    expect(find.text('Role Governance'), findsOneWidget);

    // Verify institutional profile details
    expect(find.text('National Institute of Technology'), findsOneWidget);
    expect(find.text('Code: NIT'), findsOneWidget);
    expect(find.text('Domain: nit.edu'), findsOneWidget);
    expect(find.text('Edit Institutional Profile'), findsOneWidget);

    // Switch to Role Governance segment
    await tester.ensureVisible(find.text('Role Governance'));
    await tester.tap(find.text('Role Governance'));
    await tester.pumpAndSettle();
    expect(find.text('ADMIN'), findsOneWidget);
    expect(find.text('DEPT_ADMIN'), findsOneWidget);
    expect(find.text('FACULTY'), findsOneWidget);
    expect(find.text('PLACEMENT'), findsOneWidget);
    expect(find.text('STUDENT'), findsOneWidget);
  });

  testWidgets('AdminPanelView renders adaptive NavigationRail on wide screens (>= 900px)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminMetricsProvider.overrideWith((ref) => Future.value(MockData.mockAdminMetrics)),
          adminAuditReportsProvider.overrideWith((ref) => Future.value([])),
          adminCollegeSettingsProvider.overrideWith((ref) => Future.value(mockCollege)),
        ],
        child: const MaterialApp(
          home: AdminPanelView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
  });

  testWidgets('AdminPanelView Users tab hides the currently logged in admin user', (WidgetTester tester) async {
    const loggedInAdmin = AuthUser(
      id: 'admin_logged_in_01',
      email: 'current.admin@campushub.edu',
      firstName: 'Current',
      lastName: 'Admin',
      role: 'ADMIN',
      collegeId: 'col-1',
    );

    final mockUsersList = [
      {
        'id': 'admin_logged_in_01',
        'email': 'current.admin@campushub.edu',
        'first_name': 'Current',
        'last_name': 'Admin',
        'role': 'COLLEGE_ADMIN',
        'status': 'ACTIVE',
        'department': {'name': 'Administration'},
      },
      {
        'id': 'user_student_02',
        'email': 'jane.doe@campushub.edu',
        'first_name': 'Jane',
        'last_name': 'Doe',
        'role': 'STUDENT',
        'status': 'ACTIVE',
        'roll_number': 'CS-2026-002',
        'department': {'name': 'Computer Science'},
      },
      {
        'id': 'user_faculty_03',
        'email': 'john.smith@campushub.edu',
        'first_name': 'John',
        'last_name': 'Smith',
        'role': 'FACULTY',
        'status': 'ACTIVE',
        'department': {'name': 'Electronics'},
      },
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => MockAdminAuthController(loggedInAdmin)),
          adminMetricsProvider.overrideWith((ref) => Future.value(MockData.mockAdminMetrics)),
          adminAuditReportsProvider.overrideWith((ref) => Future.value([])),
          adminCollegeSettingsProvider.overrideWith((ref) => Future.value(mockCollege)),
          adminUsersProvider.overrideWith((ref, filter) => Future.value(mockUsersList)),
        ],
        child: const MaterialApp(
          home: AdminPanelView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on Users tab
    final usersTab = find.text('Users');
    await tester.ensureVisible(usersTab);
    await tester.tap(usersTab);
    await tester.pumpAndSettle();

    // Jane Doe and John Smith must be shown
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('jane.doe@campushub.edu'), findsOneWidget);
    expect(find.text('John Smith'), findsOneWidget);
    expect(find.text('john.smith@campushub.edu'), findsOneWidget);

    // Currently logged-in admin MUST NOT be shown in the users tab list
    expect(find.text('Current Admin'), findsNothing);
    expect(find.text('current.admin@campushub.edu'), findsNothing);
  });
}
