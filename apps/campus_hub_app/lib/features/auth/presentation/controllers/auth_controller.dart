import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/auth_user.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../../notifications/data/notifications_repository.dart';

class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  FutureOr<AuthUser?> build() async {
    // Auto-login check on app bootstrap
    final repository = ref.watch(authRepositoryProvider);
    final result = await repository.autoLogin();

    return result.when(
      success: (user) => user,
      failure: (_) => null,
    );
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.login(email: email, password: password);

    return result.when(
      success: (user) {
        state = AsyncValue.data(user);
        // Non-blocking device token registration
        try {
          ref.read(notificationsRepositoryProvider).registerFcmToken('fcm_token_$email');
        } catch (_) {}
        return true;
      },
      failure: (error) {
        state = AsyncValue.error(error, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> register({
    required String collegeId,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? rollNumber,
  }) async {
    state = const AsyncValue.loading();
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.register(
      collegeId: collegeId,
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      rollNumber: rollNumber,
    );

    return result.when(
      success: (user) {
        state = AsyncValue.data(user);
        return true;
      },
      failure: (error) {
        state = AsyncValue.error(error, StackTrace.current);
        return false;
      },
    );
  }

  Future<String?> forgotPassword(String email) async {
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.forgotPassword(email: email);

    return result.when(
      success: (msg) => msg,
      failure: (err) => throw err,
    );
  }

  void updateUser(AuthUser user) {
    state = AsyncValue.data(user);
  }

  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.logout();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(AuthController.new);
