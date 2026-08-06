import '../../../../core/network/api_result.dart';
import '../models/auth_user.dart';

abstract class AuthRepository {
  Future<ApiResult<AuthUser>> login({
    required String email,
    required String password,
  });

  Future<ApiResult<AuthUser>> register({
    required String collegeId,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? rollNumber,
  });

  Future<ApiResult<String>> forgotPassword({required String email});

  Future<ApiResult<AuthUser?>> autoLogin();

  Future<void> logout();
}
