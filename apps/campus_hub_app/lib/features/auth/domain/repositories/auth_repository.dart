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

  Future<ApiResult<Map<String, dynamic>>> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  });

  Future<ApiResult<String>> resetPassword({
    required String token,
    required String newPassword,
  });

  Future<ApiResult<Map<String, dynamic>>> checkStatus({required String email});

  Future<ApiResult<Map<String, dynamic>>> sendFirstLoginOtp({required String email});

  Future<ApiResult<Map<String, dynamic>>> verifyFirstLoginOtp({
    required String email,
    required String otp,
  });

  Future<ApiResult<AuthUser>> setupPassword({
    required String email,
    required String newPassword,
    String? token,
    String? otp,
  });

  Future<ApiResult<AuthUser?>> autoLogin();

  Future<void> logout();
}

