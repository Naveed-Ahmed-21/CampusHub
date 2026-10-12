import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_error_state.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../data/datasources/feed_remote_datasource.dart';
import '../widgets/feed_post_card_widget.dart';
import '../widgets/comments_sheet.dart';

class PostDetailView extends ConsumerWidget {
  final String postId;

  const PostDetailView({
    super.key,
    required this.postId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final postAsync = ref.watch(postByIdProvider(postId));

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CampusAppBar(
          leading: const CampusBackButton(),
          title: 'Post Details',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Post',
              onPressed: () => ref.invalidate(postByIdProvider(postId)),
            ),
            IconButton(
              icon: const Icon(Icons.mode_comment_outlined),
              tooltip: 'Comments',
              onPressed: () => PostCommentsSheet.show(context, postId),
            ),
          ],
        ),
        body: postAsync.when(
          data: (post) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(postByIdProvider(postId));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FeedPostCardWidget(
                      post: post,
                      onOpenComments: () => PostCommentsSheet.show(context, postId),
                      onPostDeleted: () {
                        if (context.mounted) {
                          context.pop();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Discussion (${post.commentsCount})',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add_comment, size: 16),
                            label: const Text('Add Comment', style: TextStyle(fontSize: 12.5)),
                            onPressed: () => PostCommentsSheet.show(context, postId),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => PostCommentsSheet.show(context, postId),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                              child: Icon(
                                Icons.chat_bubble_outline,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                post.commentsCount > 0
                                    ? 'Tap to view all ${post.commentsCount} comments and join the discussion'
                                    : 'Be the first to leave a comment on this post...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 13,
                              color: theme.colorScheme.outline,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => CampusErrorState(
            title: 'Failed to load post',
            message: err.toString(),
            onRetry: () => ref.invalidate(postByIdProvider(postId)),
          ),
        ),
      ),
    );
  }
}
