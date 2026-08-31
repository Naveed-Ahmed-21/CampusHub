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
    return response.data['message'];
  }

  Future<AuthUser> getMe() async {
    final response = await _dio.get('/api/v1/auth/me');
    return AuthUser.fromJson(response.data['data']);
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return AuthRemoteDataSource(dio);
});
