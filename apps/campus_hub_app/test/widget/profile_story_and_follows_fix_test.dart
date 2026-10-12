import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_hub_app/features/profile/presentation/widgets/profile_story_avatar.dart';
import 'package:campus_hub_app/features/stories/presentation/providers/stories_provider.dart';
import 'package:campus_hub_app/features/stories/presentation/views/story_viewer_screen.dart';
import 'package:campus_hub_app/features/stories/domain/story_model.dart';
import 'package:campus_hub_app/features/profile/presentation/views/user_follows_view.dart';
import 'package:campus_hub_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:campus_hub_app/features/search/data/search_repository.dart';
import 'package:campus_hub_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:campus_hub_app/features/auth/domain/models/auth_user.dart';
import 'package:campus_hub_app/features/academics/presentation/views/student_timetable_view.dart';
import 'package:campus_hub_app/features/academics/presentation/controllers/academics_controller.dart';
import 'package:campus_hub_app/features/academics/domain/models/academic_models.dart';

class _MockHttpOverrides extends HttpOverrides {
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
    return super.noSuchMethod(invocation);
  }
}

class _MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => 0;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  group('ProfileStoryAvatar Widget Tests', () {
    testWidgets('renders avatar without story ring when no story exists', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storiesProvider.overrideWith((ref) async => <UserStoriesGroup>[]),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ProfileStoryAvatar(
                userId: 'user_1',
                name: 'Alice Johnson',
                avatarUrl: null,
                radius: 40,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AJ'), findsOneWidget);
      expect(find.byType(ProfileStoryAvatar), findsOneWidget);
      expect(find.byType(StoryViewerScreen), findsNothing);
    });

    testWidgets('renders story ring when active story exists and opens viewer on tap', (tester) async {
      final mockGroups = [
        UserStoriesGroup(
          userId: 'user_story_1',
          userName: 'Story Creator',
          userAvatar: null,
          userRole: 'STUDENT',
          hasUnseenStories: true,
          latestStoryCreatedAt: DateTime.now(),
          stories: [
            StoryItemModel(
              id: 'story_item_1',
              mediaUrl: 'https://example.com/story.jpg',
              mediaType: 'IMAGE',
              createdAt: DateTime.now(),
              expiresAt: DateTime.now().add(const Duration(hours: 24)),
              isViewed: false,
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storiesProvider.overrideWith((ref) async => mockGroups),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ProfileStoryAvatar(
                userId: 'user_story_1',
                name: 'Story Creator',
                avatarUrl: null,
                radius: 40,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProfileStoryAvatar), findsOneWidget);

      // Tap on the avatar to open StoryViewerScreen
      await tester.tap(find.byType(ProfileStoryAvatar));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(StoryViewerScreen), findsOneWidget);
      expect(find.text('Story Creator'), findsWidgets);
    });
  });

  group('UserFollowsView & Following Tab Tests', () {
    testWidgets('renders Following tab and shows users with monochromatic buttons', (tester) async {
      final mockFollowedUsers = <SearchUserItem>[
        SearchUserItem(
          id: 'user_f1',
          firstName: 'Followed',
          lastName: 'One',
          fullName: 'Followed One',
          email: 'one@campus.edu',
          username: 'one',
          role: 'STUDENT',
          isFollowing: true,
        ),
        SearchUserItem(
          id: 'user_f2',
          firstName: 'Followed',
          lastName: 'Two',
          fullName: 'Followed Two',
          email: 'two@campus.edu',
          username: 'two',
          role: 'FACULTY',
          isFollowing: true,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userFollowingProvider('my_id').overrideWith((ref) async => mockFollowedUsers),
            userFollowersProvider('my_id').overrideWith((ref) async => <SearchUserItem>[]),
            storiesProvider.overrideWith((ref) async => <UserStoriesGroup>[]),
            authControllerProvider.overrideWith(() => _MockAuthControllerStatic(
                  const AuthUser(
                    id: 'my_id',
                    email: 'me@campus.edu',
                    firstName: 'Me',
                    lastName: 'User',
                    role: 'STUDENT',
                    collegeId: 'college-1',
                  ),
                )),
          ],
          child: const MaterialApp(
            home: UserFollowsView(
              userId: 'my_id',
              userName: 'My Profile',
              initialIndex: 1, // Start on Following tab
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Followed One'), findsOneWidget);
      expect(find.text('Followed Two'), findsOneWidget);
      // 1 tab header + 2 user button labels = 3 widgets with "Following"
      expect(find.text('Following'), findsNWidgets(3));

    });
  });

  group('StudentTimetable TabBar RenderFlex Test', () {
    testWidgets('renders timetable tabs without bottom RenderFlex overflow', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentTodayTimetableProvider.overrideWith((ref) async => <StudentTimetableSlot>[]),
            studentTimetableProvider.overrideWith((ref) async => <StudentTimetableSlot>[]),
          ],
          child: const MaterialApp(
            home: StudentTimetableView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Today's Classes"), findsOneWidget);
      expect(find.text('Weekly Agenda'), findsOneWidget);
      // Verify no RenderFlex overflow exception
      expect(tester.takeException(), isNull);
    });
  });
}

class _MockAuthControllerStatic extends AuthController {
  final AuthUser? _user;
  _MockAuthControllerStatic(this._user);

  @override
  Future<AuthUser?> build() async => _user;
}
