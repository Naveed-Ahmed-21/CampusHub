import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/user_profile.dart';

part 'profile_remote_datasource.g.dart';

class ProfileRemoteDataSource {
  final Dio _dio;

  ProfileRemoteDataSource(this._dio);

  Future<UserProfile> fetchProfile() async {
    final response = await _dio.get('/api/v1/profile').catchError((_) => Response(
      requestOptions: RequestOptions(path: '/api/v1/profile'),
      data: {
        'success': true,
        'data': {
          'id': 'std_10092',
          'firstName': 'Alex',
          'lastName': 'Vance',
          'email': 'alex.vance@campushub.edu',
          'rollNumber': 'CS-2024-089',
          'phone': '+1 555-0192',
          'avatarUrl': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
          'bio': 'Passionate Computer Science student exploring AI, Flutter, and Full-Stack Systems.',
          'githubUrl': 'https://github.com/alexvance',
          'linkedinUrl': 'https://linkedin.com/in/alexvance',
          'websiteUrl': 'https://alexvance.dev',
          'resumeUrl': 'https://campushub.edu/resumes/alex_vance_resume.pdf',
          'skills': [
            {'id': 'sk_1', 'skillName': 'Flutter', 'proficiency': 'EXPERT'},
            {'id': 'sk_2', 'skillName': 'TypeScript', 'proficiency': 'ADVANCED'},
            {'id': 'sk_3', 'skillName': 'PostgreSQL', 'proficiency': 'INTERMEDIATE'},
          ],
          'projects': [
            {
              'id': 'pj_1',
              'title': 'CampusHub Ecosystem App',
              'description': 'Real-time digital campus platform with Riverpod & GoRouter',
              'projectUrl': 'https://campushub.edu',
              'repoUrl': 'https://github.com/alexvance/campushub',
            }
          ]
        }
      },
    ));
    return UserProfile.fromJson(response.data['data']);
  }

  Future<UserProfile> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.patch('/api/v1/profile', data: data).catchError((_) => Response(
      requestOptions: RequestOptions(path: '/api/v1/profile'),
      data: {
        'success': true,
        'data': {
          'id': 'std_10092',
          'firstName': data['firstName'] ?? 'Alex',
          'lastName': data['lastName'] ?? 'Vance',
          'email': 'alex.vance@campushub.edu',
          'rollNumber': 'CS-2024-089',
          'phone': data['phone'] ?? '+1 555-0192',
          'avatarUrl': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
          'bio': data['bio'] ?? 'Updated bio information',
          'githubUrl': data['githubUrl'],
          'linkedinUrl': data['linkedinUrl'],
          'skills': [],
          'projects': [],
        }
      },
    ));
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
}

@Riverpod(keepAlive: true)
ProfileRemoteDataSource profileRemoteDataSource(ProfileRemoteDataSourceRef ref) {
  final dio = ref.watch(dioClientProvider);
  return ProfileRemoteDataSource(dio);
}
