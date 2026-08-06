import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/responsive/responsive_layout.dart';
import '../../../../shared/widgets/async_value_widget.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../controllers/feed_controller.dart';
import '../../domain/models/post_item.dart';
import '../../data/repositories/feed_repository_impl.dart';

class FeedView extends ConsumerStatefulWidget {
  const FeedView({super.key});

  @override
  ConsumerState<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends ConsumerState<FeedView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _feedTabs = [
    {'label': 'Department', 'type': 'DEPARTMENT'},
    {'label': 'My Feed', 'type': 'MY_FEED'},
    {'label': 'Cross-Dept', 'type': 'CROSS_DEPARTMENT'},
    {'label': 'Club Feed', 'type': 'CLUB'},
    {'label': 'Following', 'type': 'FOLLOWING'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _feedTabs.length, vsync: this);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(feedControllerProvider.notifier).fetchNextPage();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeFeedType = ref.watch(activeFeedTypeProvider);
    final feedAsync = ref.watch(feedControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Feed'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          onTap: (index) {
            final selectedType = _feedTabs[index]['type']!;
            if (selectedType != activeFeedType) {
              ref.read(activeFeedTypeProvider.notifier).setFeedType(selectedType);
              ref.read(feedControllerProvider.notifier).refreshFeed();
            }
          },
          tabs: _feedTabs.map((t) => Tab(text: t['label'])).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(feedControllerProvider.notifier).refreshFeed(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePostSheet(context, ref),
        icon: const Icon(Icons.edit),
        label: const Text('New Post'),
      ),
      body: AsyncValueWidget<List<PostItem>>(
        value: feedAsync,
        data: (posts) => RefreshIndicator(
          onRefresh: () => ref.read(feedControllerProvider.notifier).refreshFeed(),
          child: ResponsiveLayout(
            mobile: _buildFeedList(context, posts, isDesktop: false),
            desktop: _buildDesktopLayout(context, posts),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, List<PostItem> posts) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: _buildFeedList(context, posts, isDesktop: true),
      ),
    );
  }

  Widget _buildFeedList(BuildContext context, List<PostItem> posts, {required bool isDesktop}) {
    if (posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.dynamic_feed, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No posts found in this feed yet.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: posts.length + 1,
      itemBuilder: (context, index) {
        if (index < posts.length) {
          return _PostCard(post: posts[index]);
        } else {
          final hasMore = ref.watch(feedControllerProvider.notifier).hasMore;
          return hasMore
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('You have reached the end of the feed.')),
                );
        }
      },
    );
  }
}

class _PostCard extends ConsumerWidget {
  final PostItem post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: post.author.avatarUrl != null ? NetworkImage(post.author.avatarUrl!) : null,
                  child: post.author.avatarUrl == null
                      ? Text(post.author.name[0], style: TextStyle(color: theme.colorScheme.onPrimaryContainer))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.author.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        '${post.author.role} • ${_formatDate(post.createdAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(post.type, style: const TextStyle(fontSize: 10)),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Title & Content
            Text(post.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(post.content, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            // Image Attachments
            if (post.attachments.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post.attachments.first.fileUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.image, size: 48, color: Colors.grey)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Action Buttons Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        post.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: post.isLiked ? Colors.red : null,
                      ),
                      onPressed: () => ref.read(feedControllerProvider.notifier).toggleLike(post.id),
                    ),
                    Text('${post.likesCount}'),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.mode_comment_outlined),
                      onPressed: () => _showCommentsSheet(context, ref, post.id),
                    ),
                    Text('${post.commentsCount}'),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: post.isSaved ? theme.colorScheme.primary : null,
                      ),
                      onPressed: () => ref.read(feedControllerProvider.notifier).toggleSave(post.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Post link copied to clipboard!')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return isoString;
    }
  }
}

void _showCreatePostSheet(BuildContext context, WidgetRef ref) {
  final titleCtrl = TextEditingController();
  final contentCtrl = TextEditingController();
  String selectedType = 'GENERAL';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Create New Post', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            CustomTextField(controller: titleCtrl, label: 'Post Title'),
            const SizedBox(height: 12),
            CustomTextField(controller: contentCtrl, label: 'What is on your mind?'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedType,
              decoration: const InputDecoration(labelText: 'Post Type'),
              items: const [
                DropdownMenuItem(value: 'GENERAL', child: Text('General')),
                DropdownMenuItem(value: 'ANNOUNCEMENT', child: Text('Announcement')),
                DropdownMenuItem(value: 'ACADEMIC', child: Text('Academic')),
                DropdownMenuItem(value: 'EVENT_PROMO', child: Text('Event Promo')),
                DropdownMenuItem(value: 'PLACEMENT', child: Text('Placement')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => selectedType = val);
              },
            ),
            const SizedBox(height: 20),
            CustomButton(
              label: 'Publish Post',
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty && contentCtrl.text.trim().isNotEmpty) {
                  ref.read(feedControllerProvider.notifier).createPost(
                        title: titleCtrl.text.trim(),
                        content: contentCtrl.text.trim(),
                        type: selectedType,
                      );
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}

void _showCommentsSheet(BuildContext context, WidgetRef ref, String postId) {
  final commentCtrl = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => FutureBuilder(
      future: ref.read(feedRepositoryProvider).getComments(postId),
      builder: (ctx, snapshot) {
        final result = snapshot.data;
        final comments = result != null
            ? result.when(success: (data) => data, failure: (_) => <PostCommentItem>[])
            : <PostCommentItem>[];

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Comments', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: comments.isEmpty
                    ? const Center(child: Text('No comments yet.'))
                    : ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (ctx, i) => ListTile(
                          title: Text(comments[i].author.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(comments[i].content),
                        ),
                      ),
              ),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(controller: commentCtrl, label: 'Add a comment...'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: () {
                      if (commentCtrl.text.trim().isNotEmpty) {
                        ref.read(feedControllerProvider.notifier).addComment(postId, commentCtrl.text.trim());
                        Navigator.pop(ctx);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}
