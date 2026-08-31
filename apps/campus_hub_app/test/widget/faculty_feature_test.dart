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

      expect(find.text('CampusHub Faculty'), findsOneWidget);
      expect(find.text('Welcome back, Dr. Sarah Connor'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Subjects Handled'), findsOneWidget);
      expect(find.text('Assigned Mentees'), findsOneWidget);
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
  });
}
