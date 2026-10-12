import 'dart:async';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/auth_user.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../../notifications/data/notifications_repository.dart';
import '../../../chat/data/socket_chat_service.dart';
class AuthController extends AsyncNotifier<AuthUser?> {
  void _clearUserSessionState() {
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (_) {}
  }
  @override
  FutureOr<AuthUser?> build() async {
    // Auto-login check on app bootstrap
    final repository = ref.watch(authRepositoryProvider);
    final result = await repository.autoLogin();

    return result.when(
      success: (user) {
        // Connect socket on successful auto-login
        try {
          ref.read(socketChatServiceProvider).connect();
        } catch (_) {}
        return user;
      },
      failure: (_) => null,
    );
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(authRepositoryProvider);
      final result = await repository.login(email: email, password: password);

      final isSuccess = result.when(
        success: (user) {
          _clearUserSessionState();
          state = AsyncValue.data(user);
          // Connect live notification and chat socket
          try {
            ref.read(socketChatServiceProvider).connect();
          } catch (_) {}
          // Non-blocking device token registration
          try {
            ref
                .read(notificationsRepositoryProvider)
                .registerFcmToken('fcm_token_$email');
          } catch (_) {}
          return true;
        },
        failure: (error) {
          state = AsyncValue.error(error, StackTrace.current);
          return false;
        },
      );
      return isSuccess;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
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
    try {
      final repository = ref.read(authRepositoryProvider);
      final result = await repository.register(
        collegeId: collegeId,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        rollNumber: rollNumber,
      );

      final isSuccess = result.when(
        success: (user) {
          _clearUserSessionState();
          state = AsyncValue.data(user);
          return true;
        },
        failure: (error) {
          state = AsyncValue.error(error, StackTrace.current);
          return false;
        },
      );
      return isSuccess;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<String?> forgotPassword(String email) async {
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.forgotPassword(email: email);

    return result.when(
      success: (msg) => msg,
      failure: (err) => throw err,
    );
  }

  Future<Map<String, dynamic>?> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.verifyForgotPasswordOtp(email: email, otp: otp);

    return result.when(
      success: (data) => data,
      failure: (err) => throw err,
    );
  }

  Future<String?> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.resetPassword(token: token, newPassword: newPassword);

    return result.when(
      success: (msg) => msg,
      failure: (err) => throw err,
    );
  }

  Future<Map<String, dynamic>?> checkAccountStatus(String email) async {
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.checkStatus(email: email);
    return result.when(
      success: (data) => data,
      failure: (_) => null,
    );
  }

  Future<Map<String, dynamic>?> sendFirstLoginOtp(String email) async {
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.sendFirstLoginOtp(email: email);
    return result.when(
      success: (data) => data,
      failure: (error) {
        state = AsyncValue.error(error, StackTrace.current);
        return null;
      },
    );
  }

  Future<Map<String, dynamic>?> verifyFirstLoginOtp({
    required String email,
    required String otp,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.verifyFirstLoginOtp(email: email, otp: otp);
    return result.when(
      success: (data) => data,
      failure: (error) {
        state = AsyncValue.error(error, StackTrace.current);
        return null;
      },
    );
  }

  Future<bool> setupPassword({
    required String email,
    required String newPassword,
    String? token,
    String? otp,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(authRepositoryProvider);
      final result = await repository.setupPassword(
        email: email,
        newPassword: newPassword,
        token: token,
        otp: otp,
      );

      final isSuccess = result.when(
        success: (user) {
          _clearUserSessionState();
          state = AsyncValue.data(user);
          try {
            ref.read(socketChatServiceProvider).connect();
          } catch (_) {}
          return true;
        },
        failure: (error) {
          state = AsyncValue.error(error, StackTrace.current);
          return false;
        },
      );
      return isSuccess;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void updateUser(AuthUser user) {
    state = AsyncValue.data(user);
  }


  Future<void> logout() async {
    try {
      final user = state.asData?.value;
      if (user != null) {
        await ref
            .read(notificationsRepositoryProvider)
            .unregisterFcmToken('fcm_token_${user.email}');
      }
    } catch (_) {}
    try {
      ref.read(socketChatServiceProvider).disconnect();
    } catch (_) {}
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.logout();
    } catch (_) {}
    _clearUserSessionState();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthUser?>(AuthController.new);
