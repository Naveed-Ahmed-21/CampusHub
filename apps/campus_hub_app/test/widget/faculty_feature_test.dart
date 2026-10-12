import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_hub_app/features/faculty/presentation/views/faculty_home_view.dart';
import 'package:campus_hub_app/features/faculty/presentation/views/faculty_teaching_view.dart';
import 'package:campus_hub_app/features/faculty/presentation/views/subject_detail_view.dart';
import 'package:campus_hub_app/features/faculty/presentation/widgets/faculty_schedule_card.dart';
import 'package:campus_hub_app/features/faculty/presentation/controllers/faculty_controller.dart';
import 'package:campus_hub_app/features/faculty/domain/models/faculty_models.dart';
import 'package:campus_hub_app/features/feed/presentation/controllers/feed_controller.dart';
import 'package:campus_hub_app/features/feed/presentation/widgets/feed_filter_tabs_widget.dart';
import 'package:campus_hub_app/features/events/presentation/providers/events_provider.dart';
import 'package:campus_hub_app/features/clubs/presentation/providers/club_provider.dart';
import 'package:campus_hub_app/features/faculty/presentation/views/faculty_campus_view.dart';
import 'package:campus_hub_app/features/feed/domain/models/post_item.dart';

class MockFeedController extends FeedController {
  @override
  Future<List<PostItem>> build() async => [];
}

void main() {
  final mockDashboard = FacultyDashboard(
    faculty: const FacultyInfo(
      id: 'fac_1',
      name: 'Dr. Sarah Connor',
      email: 'faculty@campushub.edu',
      designation: 'Associate Professor & Academic Head',
      department: 'Department of Computer Science & Engineering',
    ),
    stats: const FacultyStats(
      totalSubjects: 2,
      totalMentees: 4,
      todayClassesCount: 2,
      upcomingEventsCount: 1,
      publishedAnnouncementsCount: 3,
    ),
    todaySchedule: const [
      ClassScheduleSlot(
        id: 'sch_1',
        subjectCode: 'CS301',
        subjectName: 'Data Structures & Algorithms',
        roomOrVenue: 'Lecture Hall 204',
        startTime: '09:00 AM',
        endTime: '10:00 AM',
        semester: 'Semester 5',
        section: 'A',
        dayOfWeek: 'MONDAY',
      ),
    ],
    recentAnnouncements: [
      SubjectAnnouncement(
        id: 'anc_1',
        subjectName: 'Data Structures',
        title: 'Midterm schedule',
        content: 'Practical on Friday',
        authorName: 'Dr. Sarah Connor',
        createdAt: DateTime.now(),
      ),
    ],
    upcomingEvents: const [],
  );

  final mockSubjects = [
    const FacultySubject(
      id: 'sbj_1001',
      code: 'CS301',
      name: 'Data Structures & Algorithms',
      department: 'Computer Science',
      semester: 'Semester 5',
      section: 'A',
      credits: 4,
      resourcesCount: 2,
      announcementsCount: 1,
      studentsCount: 48,
    ),
  ];

  final mockSubjectDetail = FacultySubject(
    id: 'sbj_1001',
    code: 'CS301',
    name: 'Data Structures & Algorithms',
    department: 'Computer Science',
    semester: 'Semester 5',
    section: 'A',
    credits: 4,
    description: 'Core concepts in linear and hierarchical data structures.',
    resourcesCount: 1,
    announcementsCount: 1,
    studentsCount: 48,
    resources: [
      SubjectResource(
        id: 'res_1',
        subjectId: 'sbj_1001',
        title: 'Unit 1 Lecture Notes.pdf',
        fileUrl: 'https://ik.imagekit.io/notes.pdf',
        fileType: 'PDF',
        uploadedByName: 'Dr. Sarah Connor',
        createdAt: DateTime.now(),
      ),
    ],
    announcements: [
      SubjectAnnouncement(
        id: 'anc_1',
        subjectId: 'sbj_1001',
        title: 'Midterm Practical Evaluation',
        content: 'Bring your journals',
        authorName: 'Dr. Sarah Connor',
        createdAt: DateTime.now(),
      ),
    ],
  );

  group('Faculty V1 Feature Widget Tests', () {
    testWidgets('FacultyScheduleCard displays class slot items', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FacultyScheduleCard(slots: mockDashboard.todaySchedule),
          ),
        ),
      );

      expect(find.text("Today's Schedule"), findsOneWidget);
      expect(find.text('CS301'), findsOneWidget);
      expect(find.text('Data Structures & Algorithms'), findsOneWidget);
      expect(find.text('09:00 AM'), findsOneWidget);
    });

    testWidgets('FacultyHomeView renders dashboard and quick actions cleanly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            facultyDashboardProvider.overrideWith((ref) => Future.value(mockDashboard)),
            feedControllerProvider.overrideWith(() => MockFeedController()),
          ],
          child: const MaterialApp(
            home: FacultyHomeView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Faculty Hub'), findsOneWidget);
      expect(find.textContaining('Dr. Sarah Connor'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('My Subjects'), findsOneWidget);
      expect(find.text('Mentees'), findsOneWidget);
    });

    testWidgets('FacultyTeachingView renders teaching hub tabs and subject card', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            facultySubjectsProvider.overrideWith((ref) => Future.value(mockSubjects)),
            facultyScheduleProvider.overrideWith((ref) => Future.value(mockDashboard.todaySchedule)),
            facultyMenteesProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: FacultyTeachingView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Teaching Hub'), findsOneWidget);
      expect(find.text('My Subjects'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Mentoring'), findsOneWidget);
      expect(find.text('CS301'), findsOneWidget);
      expect(find.text('Data Structures & Algorithms'), findsOneWidget);
    });

    testWidgets('SubjectDetailView renders course overview, tabs and syllabus', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            facultySubjectDetailProvider('sbj_1001').overrideWith((ref) => Future.value(mockSubjectDetail)),
          ],
          child: const MaterialApp(
            home: SubjectDetailView(subjectId: 'sbj_1001'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Study Materials'), findsOneWidget);
      expect(find.text('Announcements'), findsOneWidget);
      expect(find.text('Enrolled Students'), findsOneWidget);
      expect(find.text('4 Academic Credits'), findsOneWidget);
    });

    testWidgets('FacultyCampusView renders without scanner and with segmented tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedControllerProvider.overrideWith(() => MockFeedController()),
            eventsListProvider.overrideWith((ref) => Future.value([])),
            userEventRegistrationsProvider.overrideWith((ref) => Future.value([])),
            approvedClubsProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: FacultyCampusView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify AppBar title is clean 'Campus'
      expect(find.text('Campus'), findsOneWidget);
      expect(find.text('College Ecosystem'), findsOneWidget);

      // Verify Scanner icon is NOT in the AppBar
      expect(find.byIcon(Icons.qr_code_scanner), findsNothing);

      // Verify 3 equal-width segmented tabs
      expect(find.text('Feed'), findsOneWidget);
      expect(find.text('Events'), findsWidgets);
      expect(find.text('Clubs'), findsWidgets);

      // Tap Events tab and verify no crashes
      await tester.tap(find.text('Events').first);
      await tester.pumpAndSettle();

      // Tap Clubs tab and verify no crashes
      await tester.tap(find.text('Clubs').first);
      await tester.pumpAndSettle();
    });

    testWidgets('FacultyTeachingView updates FAB to Add Schedule when switching tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            facultySubjectsProvider.overrideWith((ref) => Future.value(mockSubjects)),
            facultyScheduleProvider.overrideWith((ref) => Future.value(mockDashboard.todaySchedule)),
            facultyMenteesProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: FacultyTeachingView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially on Subjects tab
      expect(find.text('Add Subject'), findsWidgets);

      // Switch to Schedule tab
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();

      // FAB and action should now say Add Schedule
      expect(find.text('Add Schedule'), findsWidgets);

      // Switch to Mentoring tab
      await tester.tap(find.text('Mentoring'));
      await tester.pumpAndSettle();

      expect(find.text('Add Schedule'), findsWidgets);
    });

    testWidgets('FeedFilterTabsWidget displays Department label and zero overflow on 360 width', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedFilterTabsWidget(
              activeFeedType: 'forYou',
              onSelectTab: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('For You'), findsOneWidget);
      expect(find.text('Following'), findsOneWidget);
      expect(find.text('Department'), findsOneWidget);
      expect(find.text('Related'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SubjectDetailView attendance session renders cleanly on narrow screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockSession = AttendanceSession(
        id: 'sess_1',
        subjectId: 'sbj_1001',
        facultyId: 'fac_1',
        sessionDate: '2026-10-08',
        totalStudents: 1,
        presentCount: 1,
        status: 'OPEN',
        section: 'A',
        createdAt: DateTime.now(),
        records: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            facultySubjectDetailProvider('sbj_1001').overrideWith((ref) => Future.value(mockSubjectDetail)),
            facultyAttendanceSessionsProvider('sbj_1001').overrideWith((ref) => Future.value([mockSession])),
          ],
          child: const MaterialApp(
            home: SubjectDetailView(subjectId: 'sbj_1001', initialTab: 5),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Session Date: 2026-10-08'), findsOneWidget);
      expect(find.text('100% Present'), findsOneWidget);
      expect(find.text('OPEN'), findsOneWidget);
      expect(find.textContaining('1 of 1 students attended'), findsOneWidget);
      expect(find.text('Mark / View Roster'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
