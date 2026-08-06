import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/post_item.dart';
import '../../data/repositories/feed_repository_impl.dart';

part 'feed_controller.g.dart';

@riverpod
class ActiveFeedType extends _$ActiveFeedType {
  @override
  String build() => 'DEPARTMENT';

  void setFeedType(String type) => state = type;
}

@riverpod
class FeedController extends _$FeedController {
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isFetchingMore = false;

  bool get hasMore => _hasMore;
  bool get isFetchingMore => _isFetchingMore;

  @override
  FutureOr<List<PostItem>> build() async {
    _currentPage = 1;
    _hasMore = true;
    return _fetchPosts(page: 1);
  }

  Future<List<PostItem>> _fetchPosts({required int page}) async {
    final activeType = ref.watch(activeFeedTypeProvider);
    final repository = ref.watch(feedRepositoryProvider);

    final result = await repository.getFeed(feedType: activeType, page: page);

    return result.when(
      success: (posts) {
        if (posts.length < 10) _hasMore = false;
        return posts;
      },
      failure: (error) => throw error,
    );
  }

  Future<void> fetchNextPage() async {
    if (!_hasMore || _isFetchingMore) return;
    _isFetchingMore = true;

    try {
      final nextPage = _currentPage + 1;
      final newPosts = await _fetchPosts(page: nextPage);

      if (newPosts.isNotEmpty) {
        _currentPage = nextPage;
        final currentPosts = state.asData?.value ?? [];
        state = AsyncValue.data([...currentPosts, ...newPosts]);
      }
    } finally {
      _isFetchingMore = false;
    }
  }

  Future<void> createPost({
    required String title,
    required String content,
    String type = 'GENERAL',
    List<Map<String, String>>? attachments,
  }) async {
    final repository = ref.read(feedRepositoryProvider);
    final result = await repository.createPost(
      title: title,
      content: content,
      type: type,
      attachments: attachments,
    );

    result.when(
      success: (newPost) {
        final currentPosts = state.asData?.value ?? [];
        state = AsyncValue.data([newPost, ...currentPosts]);
      },
      failure: (_) {},
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

  Future<void> refreshFeed() async {
    state = const AsyncValue.loading();
    _currentPage = 1;
    _hasMore = true;
    state = await AsyncValue.guard(() => _fetchPosts(page: 1));
  }
}
