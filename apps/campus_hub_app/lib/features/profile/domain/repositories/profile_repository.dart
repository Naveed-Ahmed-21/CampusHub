import '../../../../core/network/api_result.dart';
import '../models/user_profile.dart';
import '../../../search/data/search_repository.dart';

abstract class ProfileRepository {
  Future<ApiResult<UserProfile>> fetchProfile();

  Future<ApiResult<UserProfile>> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? bio,
    String? githubUrl,
    String? linkedinUrl,
    String? websiteUrl,
  });

  Future<ApiResult<UserProfile>> uploadAvatar(String avatarUrl);

  Future<ApiResult<UserProfile>> uploadResume(String resumeUrl);

  Future<ApiResult<UserProfile>> addSkill(String skillName, String? proficiency);

  Future<ApiResult<UserProfile>> removeSkill(String skillId);

  Future<ApiResult<UserProfile>> addProject({
    required String title,
    String? description,
    String? projectUrl,
    String? repoUrl,
  });

  Future<ApiResult<UserProfile>> removeProject(String projectId);

  Future<ApiResult<UserProfile>> fetchUserProfile(String userId);

  Future<ApiResult<bool>> toggleFollow(String userId);

  Future<ApiResult<List<SearchUserItem>>> fetchFollowers(String userId);

  Future<ApiResult<List<SearchUserItem>>> fetchFollowing(String userId);
}
