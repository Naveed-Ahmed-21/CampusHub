import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_hub_app/features/dept_admin/domain/models/dept_admin_models.dart';
import 'package:campus_hub_app/features/dept_admin/presentation/providers/dept_admin_provider.dart';
import 'package:campus_hub_app/features/dept_admin/presentation/views/dept_admin_home_view.dart';
import 'package:campus_hub_app/features/dept_admin/presentation/views/dept_students_view.dart';
import 'package:campus_hub_app/features/dept_admin/presentation/views/dept_academics_view.dart';
import 'package:campus_hub_app/features/dept_admin/presentation/views/dept_placement_view.dart';
import 'package:campus_hub_app/features/dept_admin/presentation/views/dept_admin_profile_view.dart';
import 'package:campus_hub_app/features/dept_admin/presentation/views/dept_reports_view.dart';
import 'package:campus_hub_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:campus_hub_app/features/auth/domain/models/auth_user.dart';
import 'package:campus_hub_app/features/feed/presentation/controllers/feed_controller.dart';
import 'package:campus_hub_app/features/feed/domain/models/post_item.dart';

class MockFeedController extends FeedController {
  @override
  Future<List<PostItem>> build() async => [];
}

class MockAuthController extends AuthController {
  final AuthUser? user;
  MockAuthController(this.user);

  @override
  FutureOr<AuthUser?> build() async => user;
}

void main() {
  final mockDashboard = DeptDashboardData(
    department: const DeptInfo(
      id: 'it-dept-id',
      name: 'Information Technology',
      code: 'IT',
      degree: 'B.Tech',
      collegeName: 'Government College of Engineering, Erode',
    ),
    academicYear: '2026-2027',
    semester: 'Even Semester',
    kpis: const DeptKpis(
      totalStudents: 248,
      totalFaculty: 18,
      totalClasses: 6,
      totalSubjects: 14,
      avgAttendance: 86,
      activePlacementDrives: 6,
      eligibleStudents: 142,
    ),
    alerts: const DeptAlerts(
      lowAttendanceCount: 14,
      activeDrivesCount: 6,
      upcomingAssessmentsCount: 3,
      assignmentsDeadlinesCount: 5,
      recentAnnouncementsCount: 2,
    ),
  );

  final mockStudents = [
    const DeptStudent(
      id: 'st-1',
      name: 'Karthik Raja S',
      rollNumber: '730423105001',
      regNumber: '730423105001',
      email: 'karthik.it@gcee.ac.in',
      year: 3,
      yearLabel: '3rd Year',
      batch: '2023-2027',
      section: 'A',
      cgpa: 8.74,
      attendance: 88,
      placementStatus: 'ELIGIBLE',
    ),
    const DeptStudent(
      id: 'st-2',
      name: 'Priya Dharshini V',
      rollNumber: '730423105002',
      regNumber: '730423105002',
      email: 'priya.it@gcee.ac.in',
      year: 3,
      yearLabel: '3rd Year',
      batch: '2023-2027',
      section: 'A',
      cgpa: 9.12,
      attendance: 94,
      placementStatus: 'PLACED',
    ),
  ];

  final mockAcademics = DeptAcademicsData(
    department: const DeptInfo(
      id: 'it-dept-id',
      name: 'Information Technology',
      code: 'IT',
      degree: 'B.Tech',
      collegeName: 'Government College of Engineering, Erode',
    ),
    academicYear: '2026-2027',
    semester: 'Even Semester',
    batches: [
      const DeptBatch(
        id: 'b-1',
        name: '2023-2027',
        yearLabel: '3rd Year',
        admissionYear: 2023,
        graduationYear: 2027,
      ),
    ],
    classes: [
      const DeptClass(
        id: 'c-1',
        name: 'IT-A',
        section: 'A',
        yearOfStudy: 3,
        studentCount: 62,
      ),
    ],
    subjects: [
      const DeptSubject(
        id: 'sub-1',
        code: 'CCS341',
        name: 'Database Management Systems',
        credits: 3,
        facultyName: 'Dr. Naveen Kumar',
        classesCount: 2,
        studentCount: 62,
      ),
    ],
  );

  final mockPlacement = const DeptPlacementSummary(
    activeDrives: 8,
    eligibleStudents: 142,
    applications: 119,
    selected: 26,
    recentDrives: [
      DeptPlacementDrive(
        id: 'd-1',
        companyName: 'Zoho Corporation',
        roleTitle: 'Software Development Engineer',
        packageCtc: '8.4 LPA',
        status: 'ACTIVE',
        deadline: '15 Apr 2026',
      ),
    ],
  );

  final mockUser = const AuthUser(
    id: 'dept-admin-id',
    email: 'deptadmin.it@gcee.ac.in',
    firstName: 'Naveen',
    lastName: 'Kumar',
    role: 'DEPT_ADMIN',
    departmentId: 'it-dept-id',
    collegeId: 'college-id',
  );

  Widget createTestWidget(Widget child, {List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        feedControllerProvider.overrideWith(() => MockFeedController()),
        authControllerProvider.overrideWith(() => MockAuthController(mockUser)),
        ...overrides,
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('DeptAdminHomeView renders department header, KPIs, and alerts', (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        const DeptAdminHomeView(),
        overrides: [
          deptDashboardProvider.overrideWith((ref) async => mockDashboard),
        ],
      ),
    );

    await tester.pumpAndSettle();

    // Verify Department branding & HOD
    expect(find.text('Naveen Kumar'), findsWidgets);
    expect(find.text('HOD • B.Tech Information Technology'), findsOneWidget);
    expect(find.text('B.Tech • IT'), findsOneWidget);
    expect(find.text('2026-2027 • Even Semester'), findsOneWidget);

    // Verify KPIs
    expect(find.text('248'), findsOneWidget); // Total students
    expect(find.text('18'), findsOneWidget); // Total faculty
    expect(find.text('86%'), findsOneWidget); // Attendance

    // Verify Alerts
    expect(find.text('14 Students Below 75% Attendance'), findsOneWidget);
    expect(find.text('6 Active Placement Drives for IT'), findsOneWidget);
  });

  testWidgets('DeptStudentsView displays student cards with roll numbers and CGPA', (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        const DeptStudentsView(),
        overrides: [
          deptStudentsListProvider.overrideWith((ref) async => mockStudents),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Karthik Raja S'), findsOneWidget);
    expect(find.text('Priya Dharshini V'), findsOneWidget);
    expect(find.text('730423105001 • A'), findsOneWidget);
    expect(find.text('8.74 CGPA'), findsOneWidget);
    expect(find.text('PLACED'), findsOneWidget);
  });

  testWidgets('DeptAcademicsView renders Batches, Classes, and Curriculum Subjects', (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        const DeptAcademicsView(),
        overrides: [
          deptAcademicsProvider.overrideWith((ref) async => mockAcademics),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Academics & Batches'), findsOneWidget);
    expect(find.text('3rd Year'), findsOneWidget);
    expect(find.text('IT-A'), findsOneWidget);
    expect(find.text('CCS341'), findsOneWidget);
    expect(find.text('Database Management Systems'), findsOneWidget);
  });

  testWidgets('DeptPlacementView displays placement KPIs and drive cards', (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        const DeptPlacementView(),
        overrides: [
          deptPlacementProvider.overrideWith((ref) async => mockPlacement),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Zoho Corporation'), findsOneWidget);
    expect(find.text('Software Development Engineer'), findsOneWidget);
    expect(find.text('8.4 LPA'), findsOneWidget);
  });

  testWidgets('DeptAdminProfileView renders HOD details and institutional department card', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      createTestWidget(
        const DeptAdminProfileView(),
        overrides: [
          deptDashboardProvider.overrideWith((ref) async => mockDashboard),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Naveen Kumar'), findsWidgets);
    expect(find.text('deptadmin.it@gcee.ac.in'), findsOneWidget);
    expect(find.text('B.Tech Information Technology'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
  });

  testWidgets('DeptReportsView renders KPI metrics and Export Accreditation PDF Report button', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockReports = DeptReportsData(
      academicYear: '2026 - 2027',
      metrics: const DeptReportMetrics(
        students: 248,
        faculty: 18,
        avgCgpa: 8.42,
        attendance: 88,
      ),
      studentsByYear: const [
        DeptYearMetric(year: '1st Year', count: 62),
        DeptYearMetric(year: '2nd Year', count: 64),
        DeptYearMetric(year: '3rd Year', count: 60),
        DeptYearMetric(year: '4th Year', count: 62),
      ],
      placementStatus: const DeptPlacementBreakdown(
        placed: 52,
        shortlisted: 8,
        applied: 58,
        eligible: 4,
        total: 62,
      ),
    );

    await tester.pumpWidget(
      createTestWidget(
        const DeptReportsView(),
        overrides: [
          deptReportsProvider.overrideWith((ref) async => mockReports),
          deptDashboardProvider.overrideWith((ref) async => mockDashboard),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Reports & Analytics'), findsOneWidget);
    expect(find.text('Total Students'), findsOneWidget);
    expect(find.text('248'), findsOneWidget);
    expect(find.text('Export Accreditation PDF Report'), findsOneWidget);
  });
}
