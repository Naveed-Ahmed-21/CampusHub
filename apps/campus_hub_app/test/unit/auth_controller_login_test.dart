import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_hub_app/core/network/api_result.dart';
import 'package:campus_hub_app/core/network/api_exception.dart';
import 'package:campus_hub_app/features/auth/domain/models/auth_user.dart';
import 'package:campus_hub_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:campus_hub_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:campus_hub_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:campus_hub_app/features/chat/data/socket_chat_service.dart';
import 'package:campus_hub_app/features/notifications/data/notifications_repository.dart';
import 'package:campus_hub_app/features/profile/domain/models/user_profile.dart';
import 'package:campus_hub_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:campus_hub_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:campus_hub_app/features/profile/presentation/controllers/profile_controller.dart';

class MockSuccessAuthRepository implements AuthRepository {
  final AuthUser mockUser;
  MockSuccessAuthRepository(this.mockUser);

  @override
  Future<ApiResult<AuthUser>> login({
    required String email,
    required String password,
  }) async {
    return ApiResult.success(mockUser);
  }

  @override
  Future<ApiResult<AuthUser?>> autoLogin() async {
    return const ApiResult.success(null);
  }

  @override
  Future<void> logout() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFailureAuthRepository implements AuthRepository {
  final ApiException error;
  MockFailureAuthRepository(this.error);

  @override
  Future<ApiResult<AuthUser>> login({
    required String email,
    required String password,
  }) async {
    return ApiResult.failure(error);
  }

  @override
  Future<ApiResult<AuthUser?>> autoLogin() async {
    return const ApiResult.success(null);
  }

  @override
  Future<void> logout() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSocketChatService implements SocketChatService {
  @override
  Future<void> connect() async {}

  @override
  void disconnect() {}

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockNotificationsRepository implements NotificationsRepository {
  @override
  Future<void> registerFcmToken(String fcmToken, {String? deviceType}) async {}

  @override
  Future<void> unregisterFcmToken([String? fcmToken]) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockProfileRepository implements ProfileRepository {
  @override
  Future<ApiResult<UserProfile>> fetchProfile() async {
    return const ApiResult.success(UserProfile(
      id: 'usr_student_01',
      firstName: 'Alex',
      lastName: 'Vance',
      email: 'alex.vance@campushub.edu',
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testUser = AuthUser(
    id: 'usr_student_01',
    email: 'alex.vance@campushub.edu',
    firstName: 'Alex',
    lastName: 'Vance',
    role: 'STUDENT',
    collegeId: 'college-gcee-01',
    status: 'ACTIVE',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  group('AuthController Login & Session State Lifecycle', () {
    test('login succeeds without CircularDependencyError even when dependent profileController is active', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockSuccessAuthRepository(testUser)),
          socketChatServiceProvider.overrideWithValue(MockSocketChatService()),
          notificationsRepositoryProvider.overrideWithValue(MockNotificationsRepository()),
          profileRepositoryProvider.overrideWithValue(MockProfileRepository()),
        ],
      );
      addTearDown(container.dispose);

      // Listen to profileControllerProvider to ensure dependent is mounted in Riverpod graph
      final profileSub = container.listen(profileControllerProvider, (_, __) {});
      addTearDown(profileSub.close);

      final authNotifier = container.read(authControllerProvider.notifier);
      final result = await authNotifier.login('alex.vance@campushub.edu', 'Password123!');

      expect(result, isTrue);
      final authState = container.read(authControllerProvider);
      expect(authState.isLoading, isFalse);
      expect(authState.hasValue, isTrue);
      expect(authState.value?.id, equals('usr_student_01'));
      expect(authState.value?.role, equals('STUDENT'));
    });

    test('login failure resets isLoading to false and populates error state', () async {
      const error = ApiException(message: 'Invalid email or password', statusCode: 401);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockFailureAuthRepository(error)),
          socketChatServiceProvider.overrideWithValue(MockSocketChatService()),
          notificationsRepositoryProvider.overrideWithValue(MockNotificationsRepository()),
        ],
      );
      addTearDown(container.dispose);

      final authNotifier = container.read(authControllerProvider.notifier);
      final result = await authNotifier.login('alex.vance@campushub.edu', 'WrongPassword');

      expect(result, isFalse);
      final authState = container.read(authControllerProvider);
      expect(authState.isLoading, isFalse);
      expect(authState.hasError, isTrue);
    });

    test('logout transitions auth state to null and resets loading flag', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockSuccessAuthRepository(testUser)),
          socketChatServiceProvider.overrideWithValue(MockSocketChatService()),
          notificationsRepositoryProvider.overrideWithValue(MockNotificationsRepository()),
          profileRepositoryProvider.overrideWithValue(MockProfileRepository()),
        ],
      );
      addTearDown(container.dispose);

      final authNotifier = container.read(authControllerProvider.notifier);
      await authNotifier.login('alex.vance@campushub.edu', 'Password123!');
      expect(container.read(authControllerProvider).value?.id, equals('usr_student_01'));

      await authNotifier.logout();
      final loggedOutState = container.read(authControllerProvider);
      expect(loggedOutState.isLoading, isFalse);
      expect(loggedOutState.value, isNull);
    });
  });
}
