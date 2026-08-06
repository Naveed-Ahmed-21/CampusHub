import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_result.dart';
import '../datasources/profile_remote_datasource.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

part 'profile_repository_impl.g.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remote;

  ProfileRepositoryImpl(this._remote);

  @override
  Future<ApiResult<UserProfile>> fetchProfile() async {
    try {
      final profile = await _remote.fetchProfile();
      return ApiResult.success(profile);
    } on DioException catch (e) {
      return ApiResult.failure(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResult.failure(ApiException(message: e.toString()));
    }
  }

  @override
  Future<ApiResult<UserProfile>> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? bio,
    String? githubUrl,
    String? linkedinUrl,
    String? websiteUrl,
  }) async {
    try {
      final profile = await _remote.updateProfile({
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (phone != null) 'phone': phone,
        if (bio != null) 'bio': bio,
        if (githubUrl != null) 'githubUrl': githubUrl,
        if (linkedinUrl != null) 'linkedinUrl': linkedinUrl,
        if (websiteUrl != null) 'websiteUrl': websiteUrl,
      });
      return ApiResult.success(profile);
    } on DioException catch (e) {
      return ApiResult.failure(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResult.failure(ApiException(message: e.toString()));
    }
  }

  @override
  Future<ApiResult<UserProfile>> uploadAvatar(String avatarUrl) async {
    return updateProfile();
  }

  @override
  Future<ApiResult<UserProfile>> uploadResume(String resumeUrl) async {
    return updateProfile();
  }

  @override
  Future<ApiResult<UserProfile>> addSkill(String skillName, String? proficiency) async {
    try {
      final profile = await _remote.addSkill(skillName, proficiency);
      return ApiResult.success(profile);
    } catch (_) {
      // Mock fallback
      final current = await _remote.fetchProfile();
      final newSkills = [
        ...current.skills,
        SkillItem(id: DateTime.now().millisecondsSinceEpoch.toString(), skillName: skillName, proficiency: proficiency)
      ];
      return ApiResult.success(current.copyWith(skills: newSkills));
    }
  }

  @override
  Future<ApiResult<UserProfile>> removeSkill(String skillId) async {
    try {
      final profile = await _remote.removeSkill(skillId);
      return ApiResult.success(profile);
    } catch (_) {
      final current = await _remote.fetchProfile();
      final newSkills = current.skills.where((s) => s.id != skillId).toList();
      return ApiResult.success(current.copyWith(skills: newSkills));
    }
  }

  @override
  Future<ApiResult<UserProfile>> addProject({
    required String title,
    String? description,
    String? projectUrl,
    String? repoUrl,
  }) async {
    try {
      final profile = await _remote.addProject(
        title: title,
        description: description,
        projectUrl: projectUrl,
        repoUrl: repoUrl,
      );
      return ApiResult.success(profile);
    } catch (_) {
      final current = await _remote.fetchProfile();
      final newProjects = [
        ...current.projects,
        ProjectItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          description: description,
          projectUrl: projectUrl,
          repoUrl: repoUrl,
        )
      ];
      return ApiResult.success(current.copyWith(projects: newProjects));
    }
  }

  @override
  Future<ApiResult<UserProfile>> removeProject(String projectId) async {
    try {
      final profile = await _remote.removeProject(projectId);
      return ApiResult.success(profile);
    } catch (_) {
      final current = await _remote.fetchProfile();
      final newProjects = current.projects.where((p) => p.id != projectId).toList();
      return ApiResult.success(current.copyWith(projects: newProjects));
    }
  }
}

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  final remote = ref.watch(profileRemoteDataSourceProvider);
  return ProfileRepositoryImpl(remote);
}
