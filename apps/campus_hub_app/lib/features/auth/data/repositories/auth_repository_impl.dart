import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _storage;

  AuthRepositoryImpl(this._remoteDataSource, this._storage);

  @override
  Future<ApiResult<AuthUser>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _remoteDataSource.login(email, password);
      final user = AuthUser.fromJson(res['user']);
      final tokens = res['tokens'];

      await _storage.saveAccessToken(tokens['accessToken'] ?? tokens['access_token']);
      await _storage.saveRefreshToken(tokens['refreshToken'] ?? tokens['refresh_token']);
      await _storage.saveUserId(user.id);

      return ApiResult.success(user);
    } on DioException catch (e) {
      return ApiResult.failure(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResult.failure(ApiException(message: e.toString()));
    }
  }

  @override
  Future<ApiResult<AuthUser>> register({
    required String collegeId,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? rollNumber,
  }) async {
    try {
      final res = await _remoteDataSource.register(
        collegeId: collegeId,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        rollNumber: rollNumber,
      );
      final user = AuthUser.fromJson(res['user']);
      final tokens = res['tokens'];

      await _storage.saveAccessToken(tokens['accessToken'] ?? tokens['access_token']);
      await _storage.saveRefreshToken(tokens['refreshToken'] ?? tokens['refresh_token']);
      await _storage.saveUserId(user.id);

      return ApiResult.success(user);
    } on DioException catch (e) {
      return ApiResult.failure(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResult.failure(ApiException(message: e.toString()));
    }
  }

  @override
  Future<ApiResult<String>> forgotPassword({required String email}) async {
    try {
      final message = await _remoteDataSource.forgotPassword(email);
      return ApiResult.success(message);
    } on DioException catch (e) {
      return ApiResult.failure(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResult.failure(ApiException(message: e.toString()));
    }
  }

  @override
  Future<ApiResult<Map<String, dynamic>>> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final res = await _remoteDataSource.verifyForgotPasswordOtp(email: email, otp: otp);
      return ApiResult.success(res);
    } on DioException catch (e) {
      return ApiResult.failure(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResult.failure(ApiException(message: e.toString()));
    }
  }

  @override
  Future<ApiResult<String>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final message = await _remoteDataSource.resetPassword(token: token, newPassword: newPassword);
      return ApiResult.success(message);
    } on DioException catch (e) {
      return ApiResult.failure(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResult.failure(ApiException(message: e.toString()));
    }
  }

  @override
  Future<ApiResult<Map<String, dynamic>>> checkStatus({required String email}) async {
    try {
      final res = await _remoteDataSource.checkStatus(email);
      return ApiResult.success(res);
    } on DioException catch (e) {
      return ApiResult.failure(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResult.failure(ApiException(message: e.toString()));
    }
  }

  @override
  Future<ApiResult<Map<String, dynamic>>> sendFirstLoginOtp({required String email}) async {
    try {
      final res = await _remoteDataSource.sendFirstLoginOtp(email);
      return ApiResult.success(res);
    } on DioException catch (e) {
      return ApiResult.failure(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResult.failure(ApiException(message: e.toString()));
    }
  }

  @override
  Future<ApiResult<Map<String, dynamic>>> verifyFirstLoginOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final res = await _remoteDataSource.verifyFirstLoginOtp(email, otp);
      return ApiResult.success(res);
    } on DioException catch (e) {
      return ApiResult.failure(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResult.failure(ApiException(message: e.toString()));
    }
  }

  @override
  Future<ApiResult<AuthUser>> setupPassword({
    required String email,
    required String newPassword,
    String? token,
    String? otp,
  }) async {
    try {
      final res = await _remoteDataSource.setupPassword(
        email: email,
        newPassword: newPassword,
        token: token,
        otp: otp,
      );
      final user = AuthUser.fromJson(res['user']);
      final tokens = res['tokens'];

      await _storage.saveAccessToken(tokens['accessToken'] ?? tokens['access_token']);
      await _storage.saveRefreshToken(tokens['refreshToken'] ?? tokens['refresh_token']);
      await _storage.saveUserId(user.id);

      return ApiResult.success(user);
    } on DioException catch (e) {
      return ApiResult.failure(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResult.failure(ApiException(message: e.toString()));
    }
  }

  @override
  Future<ApiResult<AuthUser?>> autoLogin() async {

    try {
      final token = await _storage.getAccessToken();
      if (token == null || token.isEmpty) {
        return const ApiResult.success(null);
      }
      final user = await _remoteDataSource.getMe();
      return ApiResult.success(user);
    } catch (_) {
      await _storage.clearAll();
      return const ApiResult.success(null);
    }
  }

  @override
  Future<void> logout() async {
    await _storage.clearAll();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remote = ref.watch(authRemoteDataSourceProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return AuthRepositoryImpl(remote, storage);
});
