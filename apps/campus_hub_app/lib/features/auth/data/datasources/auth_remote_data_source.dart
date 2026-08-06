import 'package:dio/dio.dart';
import '../../domain/models/user_model.dart';

class AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSource(this.dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data['data'];
  }

  Future<Map<String, dynamic>> register({
    required String collegeCode,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final response = await dio.post('/auth/register', data: {
      'collegeCode': collegeCode,
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
    });
    return response.data['data'];
  }

  Future<UserModel> getProfile() async {
    final response = await dio.get('/auth/me');
    return UserModel.fromJson(response.data['data']['user']);
  }
}
