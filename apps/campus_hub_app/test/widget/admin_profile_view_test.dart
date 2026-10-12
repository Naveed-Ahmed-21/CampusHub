import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_hub_app/features/admin/presentation/views/admin_profile_view.dart';
import 'package:campus_hub_app/features/admin/presentation/widgets/admin_profile_header.dart';
import 'package:campus_hub_app/features/admin/presentation/widgets/admin_identity_card.dart';
import 'package:campus_hub_app/features/admin/presentation/widgets/admin_scope_card.dart';
import 'package:campus_hub_app/features/admin/presentation/widgets/admin_access_card.dart';
import 'package:campus_hub_app/features/admin/presentation/widgets/admin_security_card.dart';
import 'package:campus_hub_app/features/admin/presentation/widgets/admin_account_info_card.dart';
import 'package:campus_hub_app/features/admin/presentation/widgets/admin_profile_actions.dart';
import 'package:campus_hub_app/features/auth/domain/models/auth_user.dart';
import 'package:campus_hub_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:campus_hub_app/features/profile/domain/models/user_profile.dart';
import 'package:campus_hub_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:campus_hub_app/features/admin/presentation/providers/admin_provider.dart';

void main() {
  final mockAdminUser = AuthUser(
    id: 'f9b7c8d2-1111-2222-3333-444455556666',
    email: 'principal@gcee.ac.in',
    firstName: 'Karthik',
    lastName: 'Ramasamy',
    role: 'ADMIN',
    collegeId: 'college-gcee-01',
    status: 'ACTIVE',
    phone: '+91 9876543210',
    createdAt: DateTime(2026, 1, 15, 10, 30),
    updatedAt: DateTime(2026, 9, 26, 12, 0),
    lastSeen: DateTime(2026, 9, 26, 15, 45),
  );

  final mockDeptAdminUser = AuthUser(
    id: 'a1b2c3d4-5555-6666-7777-888899990000',
    email: 'hod.cse@gcee.ac.in',
    firstName: 'Priya',
    lastName: 'Sundaram',
    role: 'DEPT_ADMIN',
    collegeId: 'college-gcee-01',
    departmentId: 'dept-cse-01',
    status: 'ACTIVE',
    phone: '+91 9840123456',
    createdAt: DateTime(2026, 2, 1, 9, 0),
    updatedAt: DateTime(2026, 9, 25, 18, 30),
    lastSeen: DateTime(2026, 9, 26, 14, 20),
  );

  Widget createTestWidget({
    required AuthUser user,
    Brightness brightness = Brightness.light,
    Size screenSize = const Size(1000, 1600),
  }) {
    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _MockAuthController(user)),
        profileControllerProvider.overrideWith(() => _MockProfileController(user)),
        adminCollegeSettingsProvider.overrideWith(
          (ref) => Future.value({
            'name': 'Government College of Engineering, Erode',
            'code': 'GCEE',
          }),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          brightness: brightness,
        ),
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: const AdminProfileView(),
        ),
      ),
    );
  }

  group('AdminProfileView Tests', () {
    testWidgets('renders all institutional administrator sections with authentic data', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(user: mockAdminUser));
      await tester.pumpAndSettle();

      // Verify modular cards exist
      expect(find.byType(AdminProfileHeader), findsOneWidget);
      expect(find.byType(AdminIdentityCard), findsOneWidget);
      expect(find.byType(AdminScopeCard), findsOneWidget);
      expect(find.byType(AdminAccessCard), findsOneWidget);
      expect(find.byType(AdminSecurityCard), findsOneWidget);
      expect(find.byType(AdminAccountInfoCard), findsOneWidget);
      expect(find.byType(AdminProfileActions), findsOneWidget);

      // Verify authentic user data
      expect(find.text('Karthik Ramasamy'), findsWidgets);
      expect(find.text('principal@gcee.ac.in'), findsOneWidget);
      expect(find.text('Active Administrator'), findsOneWidget);
      expect(find.text('INSTITUTION-WIDE'), findsOneWidget);
      expect(find.text('Institution-wide Administrator'), findsWidgets);
      expect(find.text('All Institutional Departments'), findsOneWidget);
      expect(find.text('ADM-F9B7C8D2'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('renders department administrator scope and role correctly', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(user: mockDeptAdminUser));
      await tester.pumpAndSettle();

      expect(find.text('Priya Sundaram'), findsWidgets);
      expect(find.text('hod.cse@gcee.ac.in'), findsOneWidget);
      expect(find.text('Department Administrator'), findsWidgets);
      expect(find.text('DEPARTMENT SCOPE'), findsOneWidget);
      expect(find.text('dept-cse-01'), findsWidgets);
    });

    testWidgets('renders cleanly on mobile viewport without layout overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(
        user: mockAdminUser,
        screenSize: const Size(390, 844),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(AdminProfileHeader), findsOneWidget);
      expect(find.byType(AdminIdentityCard), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('supports immediate dark mode rendering', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(
        user: mockAdminUser,
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Karthik Ramasamy'), findsWidgets);
      expect(find.text('principal@gcee.ac.in'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

class _MockAuthController extends AuthController {
  final AuthUser _user;
  _MockAuthController(this._user);

  @override
  Future<AuthUser?> build() async => _user;
}

class _MockProfileController extends ProfileController {
  final AuthUser _user;
  _MockProfileController(this._user);

  @override
  Future<UserProfile> build() async {
    return UserProfile(
      id: _user.id,
      firstName: _user.firstName,
      lastName: _user.lastName,
      email: _user.email,
      role: _user.role,
      phone: _user.phone,
      status: _user.status,
      createdAt: _user.createdAt,
      updatedAt: _user.updatedAt,
      lastSeen: _user.lastSeen,
      followersCount: 0,
      followingCount: 0,
      postsCount: 0,
      isFollowing: false,
      skills: const [],
      projects: const [],
      clubs: const [],
    );
  }
}
