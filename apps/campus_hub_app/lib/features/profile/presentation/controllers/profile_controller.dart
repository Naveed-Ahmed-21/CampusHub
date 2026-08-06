import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/user_profile.dart';
import '../../data/repositories/profile_repository_impl.dart';

part 'profile_controller.g.dart';

@riverpod
class ProfileController extends _$ProfileController {
  @override
  FutureOr<UserProfile> build() async {
    return _fetchProfile();
  }

  Future<UserProfile> _fetchProfile() async {
    final repository = ref.watch(profileRepositoryProvider);
    final result = await repository.fetchProfile();

    return result.when(
      success: (data) => data,
      failure: (error) => throw error,
    );
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? bio,
    String? githubUrl,
    String? linkedinUrl,
    String? websiteUrl,
  }) async {
    final repository = ref.read(profileRepositoryProvider);
    final current = state.asData?.value;
    
    final updated = current?.copyWith(
      firstName: firstName ?? current.firstName,
      lastName: lastName ?? current.lastName,
      phone: phone ?? current.phone,
      bio: bio ?? current.bio,
      githubUrl: githubUrl ?? current.githubUrl,
      linkedinUrl: linkedinUrl ?? current.linkedinUrl,
      websiteUrl: websiteUrl ?? current.websiteUrl,
    );

    if (updated != null) state = AsyncValue.data(updated);

    await repository.updateProfile(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      bio: bio,
      githubUrl: githubUrl,
      linkedinUrl: linkedinUrl,
      websiteUrl: websiteUrl,
    );
  }

  Future<void> addSkill(String skillName, String? proficiency) async {
    final repository = ref.read(profileRepositoryProvider);
    final result = await repository.addSkill(skillName, proficiency);

    result.when(
      success: (data) => state = AsyncValue.data(data),
      failure: (_) {},
    );
  }

  Future<void> removeSkill(String skillId) async {
    final repository = ref.read(profileRepositoryProvider);
    final result = await repository.removeSkill(skillId);

    result.when(
      success: (data) => state = AsyncValue.data(data),
      failure: (_) {},
    );
  }

  Future<void> addProject({
    required String title,
    String? description,
    String? projectUrl,
    String? repoUrl,
  }) async {
    final repository = ref.read(profileRepositoryProvider);
    final result = await repository.addProject(
      title: title,
      description: description,
      projectUrl: projectUrl,
      repoUrl: repoUrl,
    );

    result.when(
      success: (data) => state = AsyncValue.data(data),
      failure: (_) {},
    );
  }

  Future<void> removeProject(String projectId) async {
    final repository = ref.read(profileRepositoryProvider);
    final result = await repository.removeProject(projectId);

    result.when(
      success: (data) => state = AsyncValue.data(data),
      failure: (_) {},
    );
  }

  Future<void> refreshProfile() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProfile());
  }
}
