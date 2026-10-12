import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/auth_user.dart';

class AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSource(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/api/v1/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data['data'];
  }

  Future<Map<String, dynamic>> register({
    required String collegeId,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? rollNumber,
  }) async {
    final response = await _dio.post('/api/v1/auth/register', data: {
      'collegeId': collegeId,
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'rollNumber': rollNumber,
    });
    return response.data['data'];
  }

  Future<String> forgotPassword(String email) async {
    final response = await _dio.post('/api/v1/auth/forgot-password', data: {
      'email': email,
    });
    return response.data['message'] ?? 'Verification code sent to your email';
  }

  Future<Map<String, dynamic>> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _dio.post('/api/v1/auth/verify-forgot-password-otp', data: {
      'email': email,
      'otp': otp,
    });
    return Map<String, dynamic>.from(response.data['data'] ?? {});
  }

  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await _dio.post('/api/v1/auth/reset-password', data: {
      'token': token,
      'newPassword': newPassword,
    });
    return response.data['message'] ?? 'Password reset successfully';
  }

  Future<Map<String, dynamic>> checkStatus(String email) async {
    final response = await _dio.post('/api/v1/auth/check-status', data: {
      'email': email,
    });
    return Map<String, dynamic>.from(response.data['data'] ?? {});
  }

  Future<Map<String, dynamic>> sendFirstLoginOtp(String email) async {
    final response = await _dio.post('/api/v1/auth/send-first-login-otp', data: {
      'email': email,
    });
    return Map<String, dynamic>.from(response.data['data'] ?? {});
  }

  Future<Map<String, dynamic>> verifyFirstLoginOtp(String email, String otp) async {
    final response = await _dio.post('/api/v1/auth/verify-first-login-otp', data: {
      'email': email,
      'otp': otp,
    });
    return Map<String, dynamic>.from(response.data['data'] ?? {});
  }

  Future<Map<String, dynamic>> setupPassword({
    required String email,
    required String newPassword,
    String? token,
    String? otp,
  }) async {
    final response = await _dio.post('/api/v1/auth/setup-password', data: {
      'email': email,
      'newPassword': newPassword,
      if (token != null) 'token': token,
      if (otp != null) 'otp': otp,
    });
    return Map<String, dynamic>.from(response.data['data'] ?? {});
  }

  Future<AuthUser> getMe() async {
    final response = await _dio.get('/api/v1/auth/me');
    return AuthUser.fromJson(response.data['data']);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post('/api/v1/auth/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}


final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return AuthRemoteDataSource(dio);
});
