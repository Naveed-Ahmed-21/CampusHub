import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_hub_app/features/profile/presentation/views/profile_view.dart';
import 'package:campus_hub_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:campus_hub_app/features/profile/domain/models/user_profile.dart';
import 'package:campus_hub_app/features/profile/presentation/providers/student_profile_provider.dart';
import 'package:campus_hub_app/features/profile/domain/models/detailed_student_profile.dart';
import 'package:campus_hub_app/features/clubs/presentation/providers/club_provider.dart';
import 'package:campus_hub_app/features/auth/domain/models/auth_user.dart';
import 'package:campus_hub_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:campus_hub_app/features/admin/presentation/views/admin_profile_view.dart';
import 'package:campus_hub_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:campus_hub_app/features/faculty/presentation/views/faculty_profile_view.dart';
import 'package:campus_hub_app/features/faculty/presentation/controllers/faculty_controller.dart';
import 'package:campus_hub_app/features/faculty/domain/models/faculty_models.dart';
import 'package:campus_hub_app/shared/widgets/full_screen_image_viewer.dart';
import 'package:campus_hub_app/core/widgets/campus_avatar.dart';
import 'package:campus_hub_app/features/stories/presentation/providers/stories_provider.dart';
import 'package:campus_hub_app/features/stories/domain/story_model.dart';

class MockStudentProfileController extends ProfileController {
  final UserProfile _profile;
  MockStudentProfileController(this._profile);

  @override
  Future<UserProfile> build() async => _profile;
}

class MockAuthController extends AuthController {
  final AuthUser? _initialUser;
  MockAuthController(this._initialUser);

  @override
  FutureOr<AuthUser?> build() async => _initialUser;
}

class _MockImageHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = false;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getUrl || invocation.memberName == #openUrl) {
      return Future.value(_MockHttpClientRequest());
    }
    return super.noSuchMethod(invocation);
  }
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) {
      return Future.value(_MockHttpClientResponse());
    }
    if (invocation.memberName == #headers) {
      return _MockHttpHeaders();
    }
    return super.noSuchMethod(invocation);
  }
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientResponse implements HttpClientResponse {
  static const List<int> _kTransparentImage = [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
    0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
    0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
    0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
    0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
    0x60, 0x82,
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #statusCode) return 200;
    if (invocation.memberName == #contentLength) return _kTransparentImage.length;
    if (invocation.memberName == #compressionState) return HttpClientResponseCompressionState.notCompressed;
    if (invocation.memberName == #listen) {
      return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
        invocation.positionalArguments[0] as void Function(List<int>)?,
        onError: invocation.namedArguments[#onError] as Function?,
        onDone: invocation.namedArguments[#onDone] as void Function()?,
        cancelOnError: invocation.namedArguments[#cancelOnError] as bool?,
      );
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockImageHttpOverrides();
  });

  const mockDetailedProfile = DetailedStudentProfile(
    overview: ProfileOverview(
      userId: 'usr_student_01',
      email: 'alex.vance@campushub.edu',
      fullName: 'Alex Vance',
      avatarUrl: null,
      role: 'STUDENT',
      status: 'ACTIVE',
      isProfileCompleted: true,
      completionPercentage: 92,
      badges: ['STUDENT'],
    ),
    officialIdentity: OfficialIdentity(
      rollNumber: 'CS2026-10092',
      registrationNumber: 'REG-2022-CS-042',
      departmentName: 'Computer Science & Engineering',
      batchName: '2022-2026',
      section: 'A',
      currentStatus: 'ENROLLED',
    ),
    personal: PersonalInfo(
      firstName: 'Alex',
      lastName: 'Vance',
      dob: '2003-05-14',
      age: 21,
      bloodGroup: 'O+',
      phone: '+91 9876543210',
      email: 'alex.vance@campushub.edu',
    ),
    family: FamilyInfo(
      fatherName: 'Eli Vance',
      fatherPhone: '+91 9876543211',
      motherName: 'Azian Vance',
      motherPhone: '+91 9876543212',
    ),
    address: AddressInfo(
      permanentAddress: '123 Campus Boulevard',
      permanentCity: 'Tech City',
      permanentState: 'Tamil Nadu',
      permanentPincode: '638053',
    ),
    emergency: EmergencyInfo(
      contactName: 'Eli Vance',
      contactRelation: 'Father',
      contactPhone: '+91 9876543211',
    ),
    education: EducationInfo(
      tenthPercentage: 94.5,
      twelfthPercentage: 91.2,
    ),
    career: CareerInfo(
      bio: 'Software engineering student passionate about Flutter and distributed systems.',
      skills:  [
        CareerSkill(id: '1', skillName: 'Flutter'),
        CareerSkill(id: '2', skillName: 'Dart'),
        CareerSkill(id: '3', skillName: 'PostgreSQL'),
      ],
      projects:  [],
    ),
    fieldPolicies: {},
  );

  const testStudentProfile = UserProfile(
    id: 'usr_student_01',
    username: 'alexvance',
    firstName: 'Alex',
    lastName: 'Vance',
    email: 'alex.vance@campushub.edu',
    role: 'STUDENT',
    department: 'Computer Science & Engineering',
    rollNumber: 'CS2026-10092',
    phone: '+91 9876543210',
    avatarUrl: null,
    bio: 'Software engineering student passionate about Flutter and distributed systems.',
    githubUrl: 'https://github.com/alexvance',
    linkedinUrl: 'https://linkedin.com/in/alexvance',
    followersCount: 42,
    followingCount: 18,
    postsCount: 7,
    skills: [
      SkillItem(id: 'sk_1', skillName: 'Flutter'),
      SkillItem(id: 'sk_2', skillName: 'Dart'),
      SkillItem(id: 'sk_3', skillName: 'PostgreSQL'),
    ],
    projects: [
      ProjectItem(
        id: 'proj_1',
        title: 'CampusHub Mobile App',
        description: 'Comprehensive college companion mobile client.',
        repoUrl: 'https://github.com/alexvance/campushub',
      ),
    ],
    clubs: [],
  );

  testWidgets('ProfileView renders restored student profile layout with Hero card, Stats bar, and Tabs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileControllerProvider.overrideWith(() => MockStudentProfileController(testStudentProfile)),
          myProposedClubsProvider.overrideWith((ref) => Future.value([])),
          studentDetailedProfileProvider.overrideWith((ref) => Future.value(mockDetailedProfile)),
          studentChangeRequestsProvider.overrideWith((ref) => Future.value([])),
        ],
        child: const MaterialApp(
          home: ProfileView(),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Verify AppBar Title
    expect(find.text('My Profile'), findsOneWidget);

    // Verify Hero Card & Identity
    expect(find.text('Alex Vance'), findsWidgets);
    expect(find.text('STUDENT'), findsOneWidget);
    expect(find.text('@alexvance'), findsOneWidget);
    expect(find.text('alex.vance@campushub.edu'), findsWidgets);
    expect(find.text('Roll No: CS2026-10092'), findsOneWidget);

    // Verify Stats Bar
    expect(find.text('Posts'), findsWidgets);
    expect(find.text('Followers'), findsOneWidget);
    expect(find.text('Following'), findsOneWidget);

    // Verify Action Buttons
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Portfolio'), findsOneWidget);

    // Verify Tabs
    expect(find.text('Official Record'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('My Clubs'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);

    // Verify Tab 1 Official Record Content
    expect(find.text('Official Information (Locked)'), findsOneWidget);
    expect(find.text('Personal Information (Approval Required)'), findsOneWidget);

    // Switch to Overview Tab
    await tester.tap(find.text('Overview'));
    await tester.pumpAndSettle();

    // Verify Tab 2 Overview Content
    expect(find.text('About & Bio'), findsOneWidget);
    expect(find.textContaining('Software engineering student passionate about Flutter'), findsOneWidget);
    expect(find.text('Skills & Tech Stack'), findsOneWidget);
    expect(find.text('Flutter'), findsOneWidget);
    expect(find.text('Dart'), findsOneWidget);
    expect(find.text('Featured Projects'), findsOneWidget);
    expect(find.text('CampusHub Mobile App'), findsOneWidget);
  });

  testWidgets('tapping profile avatar opens FullScreenImageViewer when avatarUrl is present', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    const profileWithAvatar = UserProfile(
      id: 'usr_student_avatar',
      username: 'alexvance',
      firstName: 'Alex',
      lastName: 'Vance',
      email: 'alex.vance@campushub.edu',
      role: 'STUDENT',
      avatarUrl: 'https://example.com/avatar.jpg',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileControllerProvider.overrideWith(() => MockStudentProfileController(profileWithAvatar)),
          myProposedClubsProvider.overrideWith((ref) => Future.value([])),
          studentDetailedProfileProvider.overrideWith((ref) => Future.value(mockDetailedProfile)),
          studentChangeRequestsProvider.overrideWith((ref) => Future.value([])),
        ],
        child: const MaterialApp(
          home: ProfileView(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Find the avatar Hero and tap it
    final avatarFinder = find.byType(CampusAvatar).first;
    expect(avatarFinder, findsOneWidget);
    await tester.tap(avatarFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // FullScreenImageViewer should be pushed to the Navigator
    expect(find.byType(FullScreenImageViewer), findsOneWidget);
  });

  testWidgets('ProfileView immediately renders AdminProfileView when authenticated user is ADMIN', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockAdmin = AuthUser(
      id: 'admin_123',
      email: 'admin@gcee.ac.in',
      firstName: 'College',
      lastName: 'Admin',
      role: 'ADMIN',
      collegeId: 'college-gcee-01',
      status: 'ACTIVE',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => MockAuthController(mockAdmin)),
          // Even if profileControllerProvider has a student profile cached from previous session
          profileControllerProvider.overrideWith(() => MockStudentProfileController(testStudentProfile)),
          adminCollegeSettingsProvider.overrideWith((ref) => Future.value({'name': 'GCEE'})),
        ],
        child: const MaterialApp(
          home: ProfileView(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Must render AdminProfileView immediately
    expect(find.byType(AdminProfileView), findsOneWidget);
  });

  testWidgets('ProfileView immediately renders FacultyProfileView when authenticated user is FACULTY', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockFacultyUser = AuthUser(
      id: 'faculty_123',
      email: 'faculty@gcee.ac.in',
      firstName: 'Dr. Suresh',
      lastName: 'Kumar',
      role: 'FACULTY',
      collegeId: 'college-gcee-01',
      status: 'ACTIVE',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    const mockFacultyProfile = FacultyProfileModel(
      id: 'faculty_123',
      userId: 'usr_faculty_123',
      name: 'Dr. Suresh Kumar',
      email: 'faculty@gcee.ac.in',
      department: 'CSE',
      designation: 'Associate Professor',
      qualification: 'Ph.D in Computer Science',
      specialization: 'Artificial Intelligence',
      bio: 'Faculty member in CSE department',
      officeRoom: 'CS-204',
      officeHours: 'Mon-Fri 2-4 PM',
      avatarUrl: null,
      publications: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => MockAuthController(mockFacultyUser)),
          // Even if profileControllerProvider had a student profile cached
          profileControllerProvider.overrideWith(() => MockStudentProfileController(testStudentProfile)),
          facultyProfileProvider.overrideWith((ref) => Future.value(mockFacultyProfile)),
          facultySubjectsProvider.overrideWith((ref) => Future.value(<FacultySubject>[])),
          storiesProvider.overrideWith((ref) => Future.value(<UserStoriesGroup>[])),
        ],

        child: const MaterialApp(
          home: ProfileView(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Must render FacultyProfileView immediately
    expect(find.byType(FacultyProfileView), findsOneWidget);
  });
}
