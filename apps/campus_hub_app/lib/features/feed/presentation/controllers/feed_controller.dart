import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/post_item.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/presentation/views/user_posts_view.dart';
import '../../../clubs/presentation/providers/club_provider.dart';
import '../../../../core/storage/secure_storage_service.dart';

class ActiveFeedType extends Notifier<String> {
  @override
  String build() => 'forYou';

  void setFeedType(String type) => state = type;
}

final activeFeedTypeProvider = NotifierProvider<ActiveFeedType, String>(ActiveFeedType.new);

class FeedController extends AsyncNotifier<List<PostItem>> {
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isFetchingMore = false;

  bool get hasMore => _hasMore;
  bool get isFetchingMore => _isFetchingMore;

  @override
  FutureOr<List<PostItem>> build() async {
    final userId = ref.watch(authControllerProvider.select((s) => s.asData?.value?.id));
    if (userId == null) {
      _currentPage = 1;
      _hasMore = false;
      return [];
    }
    _currentPage = 1;
    _hasMore = true;
    return _fetchFeed(page: 1);
  }

  Future<List<PostItem>> _fetchFeed({required int page}) async {
    final repository = ref.watch(feedRepositoryProvider);
    final activeType = ref.watch(activeFeedTypeProvider);
    final storage = ref.watch(secureStorageServiceProvider);

    final result = await repository.getFeed(
      feedType: activeType,
      page: page,
      limit: 20,
    );

    return await result.when(
      success: (posts) async {
        if (posts.length < 20) {
          _hasMore = false;
        }
        try {
          final seenIds = await storage.getSeenPostIds();
          final unseen = posts.where((p) => !seenIds.contains(p.id)).toList();
          final seen = posts.where((p) => seenIds.contains(p.id)).toList();
          return [...unseen, ...seen];
        } catch (_) {
          return posts;
        }
      },
      failure: (error) => throw error,
    );
  }

  Future<void> markPostsAsSeen(List<String> postIds) async {
    if (postIds.isEmpty) return;
    final storage = ref.read(secureStorageServiceProvider);
    await storage.markPostsAsSeen(postIds);
  }

  Future<void> refreshFeed() async {
    _currentPage = 1;
    _hasMore = true;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchFeed(page: 1));
  }

  Future<void> fetchNextPage() async {
    if (!_hasMore || _isFetchingMore || state.isLoading) return;

    _isFetchingMore = true;
    try {
      final nextPage = _currentPage + 1;
      final newPosts = await _fetchFeed(page: nextPage);

      _currentPage = nextPage;
      final currentPosts = state.asData?.value ?? [];
      state = AsyncValue.data([...currentPosts, ...newPosts]);
    } catch (_) {
      // Ignored for pagination failure
    } finally {
      _isFetchingMore = false;
    }
  }

  Future<void> createPost({
    required String title,
    required String content,
    String type = 'GENERAL',
    bool isCrossDepartment = false,
    String? scope,
    String? clubId,
    List<Map<String, String>>? attachments,
  }) async {
    final repository = ref.read(feedRepositoryProvider);
    final result = await repository.createPost(
      title: title,
      content: content,
      type: type,
      isCrossDepartment: isCrossDepartment,
      scope: scope,
      clubId: clubId,
      attachments: attachments,
    );

    await result.when(
      success: (newPost) async {
        final currentPosts = state.asData?.value ?? [];
        // Prepend if not already present
        if (!currentPosts.any((p) => p.id == newPost.id)) {
          state = AsyncValue.data([newPost, ...currentPosts]);
        }
        if (clubId != null && clubId.isNotEmpty) {
          ref.invalidate(clubFeedProvider(clubId));
        }
        await refreshFeed();
      },
      failure: (error) => throw error,
    );
  }

  Future<void> toggleLike(String postId) async {
    final currentPosts = state.asData?.value ?? [];
    state = AsyncValue.data(
      currentPosts.map((p) {
        if (p.id == postId) {
          final isLiked = !p.isLiked;
          return p.copyWith(
            isLiked: isLiked,
            likesCount: isLiked ? p.likesCount + 1 : p.likesCount - 1,
          );
        }
        return p;
      }).toList(),
    );

    final repository = ref.read(feedRepositoryProvider);
    await repository.toggleLike(postId);
  }

  Future<void> toggleSave(String postId) async {
    final currentPosts = state.asData?.value ?? [];
    state = AsyncValue.data(
      currentPosts.map((p) {
        if (p.id == postId) {
          return p.copyWith(isSaved: !p.isSaved);
        }
        return p;
      }).toList(),
    );

    final repository = ref.read(feedRepositoryProvider);
    await repository.toggleSave(postId);
    ref.invalidate(mySavedPostsProvider);
  }

  Future<void> addComment(String postId, String content) async {
    final repository = ref.read(feedRepositoryProvider);
    final result = await repository.addComment(postId, content);

    result.when(
      success: (_) {
        final currentPosts = state.asData?.value ?? [];
        state = AsyncValue.data(
          currentPosts.map((p) {
            if (p.id == postId) {
              return p.copyWith(commentsCount: p.commentsCount + 1);
            }
            return p;
          }).toList(),
        );
      },
      failure: (_) {},
    );
  }

  Future<void> deletePost(String postId) async {
    final currentPosts = state.asData?.value ?? [];
    state = AsyncValue.data(currentPosts.where((p) => p.id != postId).toList());

    final repository = ref.read(feedRepositoryProvider);
    final result = await repository.deletePost(postId);
    result.when(
      success: (_) {},
      failure: (_) async {
        await refreshFeed();
      },
    );
  }

  Future<void> updatePost(String postId, {String? title, String? content}) async {
    final repository = ref.read(feedRepositoryProvider);
    final result = await repository.updatePost(postId, title: title, content: content);

    result.when(
      success: (updatedPost) {
        final currentPosts = state.asData?.value ?? [];
        state = AsyncValue.data(
          currentPosts.map((p) => p.id == postId ? updatedPost : p).toList(),
        );
      },
      failure: (_) {},
    );
  }
}

final feedControllerProvider = AsyncNotifierProvider<FeedController, List<PostItem>>(FeedController.new);
