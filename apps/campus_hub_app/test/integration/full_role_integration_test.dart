import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_hub_app/routing/app_router.dart';
import 'package:campus_hub_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:campus_hub_app/features/auth/domain/models/auth_user.dart';
import 'package:campus_hub_app/features/faculty/presentation/controllers/faculty_controller.dart';
import 'package:campus_hub_app/features/faculty/domain/models/faculty_models.dart';
import 'package:campus_hub_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:campus_hub_app/features/feed/presentation/controllers/feed_controller.dart';
import 'package:campus_hub_app/features/feed/domain/models/post_item.dart';
import 'package:campus_hub_app/features/placement/presentation/providers/placement_provider.dart';

class MockFeedController extends FeedController {
  @override
  Future<List<PostItem>> build() async => [];
}

class MockAuthController extends AuthController {
  final AuthUser? _mockUser;
  MockAuthController(this._mockUser);

  @override
  Future<AuthUser?> build() async => _mockUser;
}

void main() {
  final studentUser = AuthUser.fromJson({
    'id': 'usr_student',
    'email': 'student@campushub.edu',
    'firstName': 'Alex',
    'lastName': 'Vance',
    'role': 'STUDENT',
    'collegeId': 'clg_1',
    'collegeName': 'Institute of Engineering',
  });

  final placementUser = AuthUser.fromJson({
    'id': 'usr_po',
    'email': 'po@campushub.edu',
    'firstName': 'David',
    'lastName': 'Miller',
    'role': 'PLACEMENT_OFFICER',
    'collegeId': 'clg_1',
    'collegeName': 'Institute of Engineering',
  });

  final adminUser = AuthUser.fromJson({
    'id': 'usr_admin',
    'email': 'admin@campushub.edu',
    'firstName': 'System',
    'lastName': 'Admin',
    'role': 'ADMIN',
    'collegeId': 'clg_1',
    'collegeName': 'Institute of Engineering',
  });

  final facultyUser = AuthUser.fromJson({
    'id': 'usr_faculty',
    'email': 'faculty@campushub.edu',
    'firstName': 'Sarah',
    'lastName': 'Connor',
    'role': 'FACULTY',
    'collegeId': 'clg_1',
    'collegeName': 'Institute of Engineering',
  });

  final mockFacultyDashboard = FacultyDashboard(
    faculty: const FacultyInfo(
      id: 'usr_faculty',
      name: 'Dr. Sarah Connor',
      email: 'faculty@campushub.edu',
      designation: 'Associate Professor',
      department: 'CSE',
    ),
    stats: const FacultyStats(
      totalSubjects: 3,
      totalMentees: 5,
      todayClassesCount: 2,
      upcomingEventsCount: 1,
      publishedAnnouncementsCount: 2,
    ),
    todaySchedule: const [],
    recentAnnouncements: const [],
    upcomingEvents: const [],
  );

  group('Full Role Integration Tests', () {
    testWidgets('1. Student Role - routes to Feed and displays student navigation', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => MockAuthController(studentUser)),
            feedControllerProvider.overrideWith(() => MockFeedController()),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(appRouterProvider);
              return MaterialApp.router(
                routerConfig: router,
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Home'), findsWidgets);
      expect(find.text('Search'), findsWidgets);
      expect(find.text('Clubs'), findsWidgets);
    });

    testWidgets('2. Faculty Role - routes to /faculty and displays teaching navigation', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => MockAuthController(facultyUser)),
            facultyDashboardProvider.overrideWith((ref) => Future.value(mockFacultyDashboard)),
            feedControllerProvider.overrideWith(() => MockFeedController()),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(appRouterProvider);
              return MaterialApp.router(
                routerConfig: router,
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Teaching'), findsWidgets);
      expect(find.text('Campus'), findsWidgets);
      expect(find.text('CampusHub Faculty'), findsOneWidget);
    });

    testWidgets('3. Admin Role - routes to /admin with metrics panel', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => MockAuthController(adminUser)),
            adminMetricsProvider.overrideWith((ref) => Future.value({
              'totalUsers': 1200,
              'totalDepartments': 5,
              'approvedClubs': 10,
              'pendingClubs': 1,
              'totalEvents': 15,
              'totalDrives': 6,
              'placedCount': 50,
            })),
            adminAuditReportsProvider.overrideWith((ref) => Future.value([])),
            adminDepartmentsProvider.overrideWith((ref) => Future.value([])),
            adminAnalyticsProvider.overrideWith((ref) => Future.value({})),
            adminUsersProvider.overrideWith((ref, filter) => Future.value([])),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(appRouterProvider);
              return MaterialApp.router(
                routerConfig: router,
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('CampusHub Admin Panel'), findsOneWidget);
      expect(find.text('Total Users'), findsOneWidget);
    });

    testWidgets('4. Placement Officer Role - routes to /placement with recruitment tools', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => MockAuthController(placementUser)),
            placementDrivesProvider.overrideWith((ref) => Future.value([])),
            studentDashboardProvider.overrideWith((ref) => Future.value({'myApplications': [], 'totalApplied': 0})),
            officerDashboardProvider.overrideWith((ref) => Future.value({
              'totalDrives': 12,
              'activeDrives': 4,
              'totalApplicants': 140,
              'placedStudents': 45,
            })),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(appRouterProvider);
              return MaterialApp.router(
                routerConfig: router,
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Placement & Career Drives'), findsOneWidget);
      expect(find.text('Officer Hub'), findsOneWidget);
    });
  });
}
