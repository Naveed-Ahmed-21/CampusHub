import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/user_profile.dart';
import '../../../search/data/search_repository.dart';

class ProfileRemoteDataSource {
  final Dio _dio;

  ProfileRemoteDataSource(this._dio);

  Future<UserProfile> fetchProfile() async {
    final response = await _dio.get('/api/v1/profile');
    return UserProfile.fromJson(response.data['data']);
  }

  Future<UserProfile> fetchUserProfile(String userId) async {
    final response = await _dio.get('/api/v1/profile/$userId');
    return UserProfile.fromJson(response.data['data']);
  }

  Future<bool> toggleFollow(String userId) async {
    final response = await _dio.post('/api/v1/profile/$userId/follow');
    return response.data['data']['isFollowing'] ?? false;
  }

  Future<UserProfile> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.patch('/api/v1/profile', data: data);
    return UserProfile.fromJson(response.data['data']);
  }

  Future<UserProfile> uploadAvatar(String avatarUrl) async {
    final response = await _dio.post('/api/v1/profile/avatar', data: {'avatarUrl': avatarUrl});
    return UserProfile.fromJson(response.data['data']);
  }

  Future<UserProfile> uploadResume(String resumeUrl) async {
    final response = await _dio.post('/api/v1/profile/resume', data: {'resumeUrl': resumeUrl});
    return UserProfile.fromJson(response.data['data']);
  }

  Future<UserProfile> addSkill(String skillName, String? proficiency) async {
    final response = await _dio.post('/api/v1/profile/skills', data: {
      'skillName': skillName,
      'proficiency': proficiency,
    });
    return UserProfile.fromJson(response.data['data']);
  }

  Future<UserProfile> removeSkill(String skillId) async {
    final response = await _dio.delete('/api/v1/profile/skills/$skillId');
    return UserProfile.fromJson(response.data['data']);
  }

  Future<UserProfile> addProject({
    required String title,
    String? description,
    String? projectUrl,
    String? repoUrl,
  }) async {
    final response = await _dio.post('/api/v1/profile/projects', data: {
      'title': title,
      'description': description,
      'projectUrl': projectUrl,
      'repoUrl': repoUrl,
    });
    return UserProfile.fromJson(response.data['data']);
  }

  Future<UserProfile> removeProject(String projectId) async {
    final response = await _dio.delete('/api/v1/profile/projects/$projectId');
    return UserProfile.fromJson(response.data['data']);
  }

  Future<List<SearchUserItem>> fetchFollowers(String userId) async {
    final response = await _dio.get('/api/v1/profile/$userId/followers');
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data.map((json) => SearchUserItem.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<SearchUserItem>> fetchFollowing(String userId) async {
    final response = await _dio.get('/api/v1/profile/$userId/following');
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data.map((json) => SearchUserItem.fromJson(json as Map<String, dynamic>)).toList();
  }
}

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ProfileRemoteDataSource(dio);
});
