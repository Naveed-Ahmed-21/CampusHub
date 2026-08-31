import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../feed/data/repositories/feed_repository_impl.dart';
import '../../../feed/domain/models/post_item.dart';
import '../../../feed/presentation/widgets/feed_post_card_widget.dart';
import '../../../feed/presentation/widgets/comments_sheet.dart';

final myUserPostsProvider = FutureProvider.autoDispose<List<PostItem>>((ref) async {
  final repo = ref.watch(feedRepositoryProvider);
  final result = await repo.getFeed(feedType: 'MY_POSTS', page: 1, limit: 50);
  return result.when(
    success: (posts) => posts,
    failure: (_) => [],
  );
});

final mySavedPostsProvider = FutureProvider.autoDispose<List<PostItem>>((ref) async {
  final repo = ref.watch(feedRepositoryProvider);
  final result = await repo.getFeed(feedType: 'SAVED', page: 1, limit: 50);
  return result.when(
    success: (posts) => posts,
    failure: (_) => [],
  );
});

class UserPostsView extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const UserPostsView({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<UserPostsView> createState() => _UserPostsViewState();
}

class _UserPostsViewState extends ConsumerState<UserPostsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts & Saved'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.outline,
          tabs: const [
            Tab(icon: Icon(Icons.article_outlined), text: 'My Posts'),
            Tab(icon: Icon(Icons.bookmark_outline), text: 'Saved Posts'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(myUserPostsProvider);
              ref.invalidate(mySavedPostsProvider);
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PostsListTab(
            provider: myUserPostsProvider,
            emptyIcon: Icons.article_outlined,
            emptyTitle: "You haven't published any posts yet.",
            emptySubtitle: 'Share your ideas, research, or announcements on the Campus Feed!',
            onRefresh: () async => ref.invalidate(myUserPostsProvider),
          ),
          _PostsListTab(
            provider: mySavedPostsProvider,
            emptyIcon: Icons.bookmark_border,
            emptyTitle: 'You have not saved any posts yet.',
            emptySubtitle: 'Tap the bookmark icon on any post across the campus feed to save it here.',
            onRefresh: () async => ref.invalidate(mySavedPostsProvider),
          ),
        ],
      ),
    );
  }
}

class _PostsListTab extends ConsumerWidget {
  final AutoDisposeFutureProvider<List<PostItem>> provider;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final Future<void> Function() onRefresh;

  const _PostsListTab({
    required this.provider,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final postsAsync = ref.watch(provider);

    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(emptyIcon, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    emptyTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    emptySubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return FeedPostCardWidget(
                key: ValueKey(post.id),
                post: post,
                onOpenComments: () => PostCommentsSheet.show(context, post.id),
                onPostDeleted: onRefresh,
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text('Failed to load posts: $err'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRefresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
