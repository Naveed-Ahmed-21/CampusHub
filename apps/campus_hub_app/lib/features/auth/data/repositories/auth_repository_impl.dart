import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_repository_impl.g.dart';

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

@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) {
  final remote = ref.watch(authRemoteDataSourceProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return AuthRepositoryImpl(remote, storage);
}
