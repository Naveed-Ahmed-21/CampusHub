import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_hub_app/features/profile/presentation/views/institutional_student_profile_view.dart';
import 'package:campus_hub_app/features/profile/presentation/providers/student_profile_provider.dart';
import 'package:campus_hub_app/features/profile/domain/models/detailed_student_profile.dart';

void main() {
  final mockProfile = DetailedStudentProfile(
    overview: const ProfileOverview(
      userId: 'usr_student_01',
      email: 'alex.vance@campushub.edu',
      fullName: 'Alex Vance',
      avatarUrl: null,
      role: 'STUDENT',
      status: 'ACTIVE',
      isProfileCompleted: true,
      completionPercentage: 92,
      badges: ['DEAN_LIST', 'HACKATHON_WINNER'],
    ),
    officialIdentity: const OfficialIdentity(
      rollNumber: 'CS2026-10092',
      registrationNumber: 'REG-2022-CS-042',
      departmentName: 'Computer Science & Engineering',
      departmentCode: 'CSE',
      programName: 'B.Tech Computer Science',
      batchName: '2022-2026',
      section: 'Section A',
      currentStatus: 'ENROLLED',
      admissionYear: 2022,
    ),
    personal: const PersonalInfo(
      firstName: 'Alex',
      lastName: 'Vance',
      dob: '2003-05-14',
      age: 21,
      bloodGroup: 'O+',
      phone: '+91 9876543210',
      email: 'alex.vance@campushub.edu',
    ),
    family: const FamilyInfo(
      fatherName: 'Eli Vance',
      fatherPhone: '+91 9876543211',
      motherName: 'Azian Vance',
      motherPhone: '+91 9876543212',
    ),
    address: const AddressInfo(
      permanentAddress: '123 Campus Boulevard',
      permanentCity: 'Tech City',
      permanentState: 'Karnataka',
      permanentPincode: '560001',
      currentAddress: 'Hostel Block 4, Room 204',
    ),
    emergency: const EmergencyInfo(
      contactName: 'Eli Vance',
      contactRelation: 'Father',
      contactPhone: '+91 9876543211',
    ),
    education: const EducationInfo(
      tenthPercentage: 94.5,
      twelfthPercentage: 91.2,
    ),
    career: const CareerInfo(
      bio: 'Aspiring software architect and distributed systems enthusiast.',
      skills: [
        CareerSkill(id: '1', skillName: 'Flutter'),
        CareerSkill(id: '2', skillName: 'TypeScript'),
        CareerSkill(id: '3', skillName: 'PostgreSQL'),
      ],
      projects: [],
      githubUrl: 'https://github.com/alexvance',
      linkedinUrl: 'https://linkedin.com/in/alexvance',
      websiteUrl: null,
      resumeUrl: null,
    ),
    fieldPolicies: {
      'rollNumber': 'LOCKED',
      'email': 'LOCKED',
      'departmentName': 'LOCKED',
      'fatherName': 'REQUIRES_APPROVAL',
      'phone': 'REQUIRES_APPROVAL',
      'bio': 'SELF_EDIT',
      'skills': 'SELF_EDIT',
    },
  );

  testWidgets('InstitutionalStudentProfileView renders admin-style layout and records cleanly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentDetailedProfileProvider.overrideWith((ref) => Future.value(mockProfile)),
          studentChangeRequestsProvider.overrideWith((ref) => Future.value([])),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: InstitutionalStudentProfileView(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AdminPageHeader title & badge
    expect(find.text('Institutional Student Identity'), findsOneWidget);
    expect(find.text('VERIFIED ENROLLED STUDENT'), findsOneWidget);

    // Verify Student Identity Card
    expect(find.text('Alex Vance'), findsWidgets);
    expect(find.text('alex.vance@campushub.edu'), findsWidgets);
    expect(find.text('B.Tech Computer Science'), findsWidgets);

    // Verify Academic & Institutional Information Card
    expect(find.text('Academic & Institutional Information'), findsOneWidget);
    expect(find.text('CS2026-10092'), findsWidgets);
    expect(find.text('REG-2022-CS-042'), findsOneWidget);
    expect(find.text('Computer Science & Engineering'), findsWidgets);

    // Verify Institutional Privileges Matrix
    expect(find.text('Institutional Privileges & Academic Clearance'), findsOneWidget);
    expect(find.text('Course Materials & LMS Access'), findsOneWidget);
    expect(find.text('Examination & Academic Ledger'), findsOneWidget);
    expect(find.text('Campus Social Feed & Announcements'), findsOneWidget);

    // Verify Tabs are present
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Official Identity (Locked 🔒)'), findsOneWidget);
    expect(find.text('Personal & Family'), findsOneWidget);
    expect(find.text('Education & Address'), findsOneWidget);
    expect(find.text('Career & Placement'), findsOneWidget);
    expect(find.text('Change Requests'), findsOneWidget);

    // Verify Overview content
    expect(find.text('Profile Completion Progress'), findsOneWidget);
    expect(find.text('92%'), findsOneWidget);

    // Tap on Official Identity tab
    await tester.tap(find.text('Official Identity (Locked 🔒)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('These official records are locked by campus administration'), findsOneWidget);

    // Tap on Personal & Family tab
    await tester.tap(find.text('Personal & Family'));
    await tester.pumpAndSettle();
    expect(find.text('Personal Identity (Approval Required)'), findsOneWidget);
    expect(find.text('Eli Vance'), findsWidgets);

    // Tap on Career & Placement tab
    await tester.ensureVisible(find.text('Career & Placement'));
    await tester.tap(find.text('Career & Placement'));
    await tester.pumpAndSettle();
    expect(find.text('Directly Editable Career Data (No Approval Needed)'), findsOneWidget);
    expect(find.text('Flutter'), findsWidgets);
  });
}
