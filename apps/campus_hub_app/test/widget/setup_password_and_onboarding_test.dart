import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:campus_hub_app/core/network/api_client.dart';
import 'package:campus_hub_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:campus_hub_app/features/auth/domain/models/auth_user.dart';
import 'package:campus_hub_app/features/auth/presentation/views/setup_password_view.dart';
import 'package:campus_hub_app/features/onboarding/presentation/views/student_onboarding_view.dart';

class MockAuthController extends AuthController {
  final AuthUser? _mockUser;
  MockAuthController(this._mockUser);

  @override
  Future<AuthUser?> build() async => _mockUser;
}

void main() {
  final testUser = AuthUser.fromJson({
    'id': 'std_101',
    'email': 'student@campushub.edu',
    'firstName': 'Alex',
    'lastName': 'Vance',
    'role': 'STUDENT',
    'collegeId': 'clg_1',
    'isProfileCompleted': false,
    'firstLoginCompleted': false,
  });

  late Dio fakeDio;

  setUp(() {
    fakeDio = Dio();
    fakeDio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.path.contains('/api/v1/profile/onboarding-context')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': {
                'firstName': 'Alex',
                'lastName': 'Vance',
                'departmentName': 'Computer Science',
                'programName': 'B.Tech',
                'rollNumber': 'CS101',
                'registrationNumber': 'REG2026101',
                'batchName': '2023 - 2027',
                'section': 'A',
              }
            },
          ));
        }
        return handler.next(options);
      },
    ));
  });

  group('SetupPasswordView and StudentOnboardingView Widget Tests', () {
    testWidgets('SetupPasswordView renders full text labels and email verification action', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => MockAuthController(null)),
          ],
          child: const MaterialApp(
            home: SetupPasswordView(initialEmail: 'student@campushub.edu'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Check full text labels
      expect(find.text('Institutional Campus Email Address'), findsOneWidget);
      expect(find.text('Send Verification Code & Magic Link to Email'), findsOneWidget);
      expect(find.text('New Account Password (Min 8 Characters)'), findsOneWidget);
      expect(find.text('Confirm New Account Password'), findsOneWidget);
      expect(find.text('Verify OTP & Activate Account'), findsOneWidget);
    });

    testWidgets('StudentOnboardingView renders with full text labels and clean one by one layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => MockAuthController(testUser)),
            dioClientProvider.overrideWithValue(fakeDio),
          ],
          child: const MaterialApp(
            home: StudentOnboardingView(),
          ),
        ),
      );

      // Pump to resolve future and render form
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify Personal details step fields
      expect(find.text('Personal & Family Details'), findsOneWidget);
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Student Mobile Number (10 Digits)'), findsOneWidget);
      expect(find.text('Blood Group (ABO & Rh Factor)'), findsOneWidget);
      expect(find.text('Father Full Name'), findsOneWidget);
      expect(find.text('Father Mobile Number (10 Digits)'), findsOneWidget);
      expect(find.text('Mother Full Name'), findsOneWidget);
      expect(find.text('Mother Mobile Number (10 Digits)'), findsOneWidget);
      expect(find.text('Emergency Contact Person Name'), findsOneWidget);
      expect(find.text('Relationship to Student (e.g. Parent, Guardian, Sibling)'), findsOneWidget);
      expect(find.text('Emergency Contact Phone Number (10 Digits)'), findsOneWidget);
    });

    testWidgets('StudentOnboardingView Step 4 Review renders cleanly without RenderFlex overflow on small screens with text scaling', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => MockAuthController(testUser)),
            dioClientProvider.overrideWithValue(fakeDio),
          ],
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 800),
                textScaler: TextScaler.linear(1.3),
              ),
              child: const StudentOnboardingView(initialStep: 3),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify Review headers and cards render without overflow exceptions
      expect(find.text('Review & Institutional Confirmation'), findsOneWidget);
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Family & Emergency Contacts'), findsOneWidget);
      expect(find.text('Academic Assignment'), findsOneWidget);
      expect(find.text('Address & Education'), findsOneWidget);
      expect(find.text('Complete Onboarding'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
    });
  });
}
