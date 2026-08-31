import 'dart:async';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_profile.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../feed/data/repositories/feed_repository_impl.dart';
import '../../../feed/domain/models/post_item.dart';
import '../../../feed/presentation/controllers/feed_controller.dart';
import '../../../search/data/search_repository.dart';

class ProfileController extends AsyncNotifier<UserProfile> {
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

  Future<void> refreshProfile() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProfile());
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

    final result = await repository.updateProfile(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      bio: bio,
      githubUrl: githubUrl,
      linkedinUrl: linkedinUrl,
      websiteUrl: websiteUrl,
    );

    result.when(
      success: (data) {
        state = AsyncValue.data(data);
        final authUser = ref.read(authControllerProvider).asData?.value;
        if (authUser != null) {
          ref.read(authControllerProvider.notifier).updateUser(
            authUser.copyWith(
              firstName: data.firstName,
              lastName: data.lastName,
              avatarUrl: data.avatarUrl,
            ),
          );
        }
        ref.invalidate(userProfileProvider(data.id));
        ref.invalidate(feedControllerProvider);
      },
      failure: (_) {},
    );
  }

  Future<void> uploadAvatar(String avatarUrl) async {
    final repository = ref.read(profileRepositoryProvider);
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(avatarUrl: avatarUrl));
    }
    final result = await repository.uploadAvatar(avatarUrl);
    result.when(
      success: (data) {
        state = AsyncValue.data(data);
        final authUser = ref.read(authControllerProvider).asData?.value;
        if (authUser != null) {
          ref.read(authControllerProvider.notifier).updateUser(
            authUser.copyWith(
              avatarUrl: data.avatarUrl,
              firstName: data.firstName,
              lastName: data.lastName,
            ),
          );
        }
        try {
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();
        } catch (_) {}
        ref.invalidate(userProfileProvider(data.id));
        ref.invalidate(userPostsProvider(data.id));
        ref.invalidate(userFollowersProvider(data.id));
        ref.invalidate(userFollowingProvider(data.id));
        ref.invalidate(feedControllerProvider);
        ref.invalidate(userChatRoomsProvider);
      },
      failure: (_) {},
    );
  }

  Future<void> uploadResume(String resumeUrl) async {
    final repository = ref.read(profileRepositoryProvider);
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(resumeUrl: resumeUrl));
    }
    final result = await repository.uploadResume(resumeUrl);
    result.when(
      success: (data) => state = AsyncValue.data(data),
      failure: (_) {},
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
}

final profileControllerProvider = AsyncNotifierProvider<ProfileController, UserProfile>(ProfileController.new);

final userProfileProvider = FutureProvider.autoDispose.family<UserProfile, String>((ref, userId) async {
  final repo = ref.watch(profileRepositoryProvider);
  final result = await repo.fetchUserProfile(userId);
  return result.when(
    success: (data) => data,
    failure: (err) => throw err,
  );
});

final userFollowersProvider = FutureProvider.autoDispose.family<List<SearchUserItem>, String>((ref, userId) async {
  final repo = ref.watch(profileRepositoryProvider);
  final result = await repo.fetchFollowers(userId);
  return result.when(
    success: (data) => data,
    failure: (err) => throw err,
  );
});

final userFollowingProvider = FutureProvider.autoDispose.family<List<SearchUserItem>, String>((ref, userId) async {
  final repo = ref.watch(profileRepositoryProvider);
  final result = await repo.fetchFollowing(userId);
  return result.when(
    success: (data) => data,
    failure: (err) => throw err,
  );
});

final userPostsProvider = FutureProvider.autoDispose.family<List<PostItem>, String>((ref, userId) async {
  final repo = ref.watch(feedRepositoryProvider);
  final result = await repo.getFeed(feedType: 'AUTHOR', authorId: userId, page: 1, limit: 50);
  return result.when(
    success: (posts) => posts,
    failure: (err) => throw err,
  );
});
