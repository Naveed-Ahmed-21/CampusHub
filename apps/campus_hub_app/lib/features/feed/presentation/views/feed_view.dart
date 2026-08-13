import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/responsive/responsive_layout.dart';
import '../../../../shared/widgets/async_value_widget.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../controllers/feed_controller.dart';
import '../../domain/models/post_item.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../widgets/campus_top_app_bar.dart';
import '../widgets/student_drawer_widget.dart';
import '../widgets/stories_section_widget.dart';
import '../widgets/create_post_bar_widget.dart';
import '../widgets/feed_filter_tabs_widget.dart';
import '../widgets/feed_post_card_widget.dart';
import '../widgets/bottom_search_bar_widget.dart';

class FeedView extends ConsumerStatefulWidget {
  const FeedView({super.key});

  @override
  ConsumerState<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends ConsumerState<FeedView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 250) {
        ref.read(feedControllerProvider.notifier).fetchNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onSelectTab(String selectedType) {
    final activeFeedType = ref.read(activeFeedTypeProvider);
    if (selectedType != activeFeedType) {
      ref.read(activeFeedTypeProvider.notifier).setFeedType(selectedType);
      ref.read(feedControllerProvider.notifier).refreshFeed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeFeedType = ref.watch(activeFeedTypeProvider);
    final feedAsync = ref.watch(feedControllerProvider);

    return Scaffold(
      key: _scaffoldKey,
      appBar: CampusTopAppBar(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: const StudentDrawerWidget(),
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
            mobile: _buildFeedLayout(context, posts, activeFeedType, isDesktop: false),
            desktop: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 700),
                child: _buildFeedLayout(context, posts, activeFeedType, isDesktop: true),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedLayout(BuildContext context, List<PostItem> posts, String activeFeedType, {required bool isDesktop}) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // 1. Stories Section
        const SliverToBoxAdapter(
          child: StoriesSectionWidget(),
        ),

        // 2. Compact Create Post Bar
        SliverToBoxAdapter(
          child: CreatePostBarWidget(
            onTap: () => _showCreatePostSheet(context, ref),
          ),
        ),

        // 3. Feed Filter Tabs
        SliverToBoxAdapter(
          child: FeedFilterTabsWidget(
            activeFeedType: activeFeedType,
            onSelectTab: _onSelectTab,
          ),
        ),

        // 4. Feed Posts List or Empty State
        if (posts.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.dynamic_feed, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No campus posts found in this feed yet.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < posts.length) {
                  final post = posts[index];
                  return FeedPostCardWidget(
                    post: post,
                    onOpenComments: () => _showCommentsSheet(context, ref, post.id),
                  );
                } else {
                  final hasMore = ref.watch(feedControllerProvider.notifier).hasMore;
                  return hasMore
                      ? const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(child: Text('You have reached the end of the feed.', style: TextStyle(color: Colors.grey))),
                        );
                }
              },
              childCount: posts.length + 1,
            ),
          ),

        // 5. Global Search Bar above bottom navigation
        const SliverToBoxAdapter(
          child: BottomSearchBarWidget(),
        ),
      ],
    );
  }
}

void _showCreatePostSheet(BuildContext context, WidgetRef ref) {
  final titleCtrl = TextEditingController();
  final contentCtrl = TextEditingController();
  final imageUrlCtrl = TextEditingController();
  String selectedType = 'GENERAL';
  bool isSubmitting = false;

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
        child: SingleChildScrollView(
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
              CustomTextField(controller: imageUrlCtrl, label: 'Image URL (Optional)'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Post Scope / Category'),
                items: const [
                  DropdownMenuItem(value: 'GENERAL', child: Text('General Post')),
                  DropdownMenuItem(value: 'ANNOUNCEMENT', child: Text('Announcement')),
                  DropdownMenuItem(value: 'ACADEMIC', child: Text('Academic Discussion')),
                  DropdownMenuItem(value: 'EVENT_PROMO', child: Text('Event Promotion')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => selectedType = val);
                },
              ),
              const SizedBox(height: 20),
              CustomButton(
                label: isSubmitting ? 'Publishing...' : 'Publish Post',
                isLoading: isSubmitting,
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Please enter both title and content.')),
                          );
                          return;
                        }
                        setState(() => isSubmitting = true);
                        try {
                          await ref.read(feedControllerProvider.notifier).createPost(
                                title: titleCtrl.text.trim(),
                                content: contentCtrl.text.trim(),
                                type: selectedType,
                                attachments: imageUrlCtrl.text.trim().isNotEmpty
                                    ? [
                                        {
                                          'fileName': 'attachment.jpg',
                                          'fileUrl': imageUrlCtrl.text.trim().startsWith('http')
                                              ? imageUrlCtrl.text.trim()
                                              : 'https://${imageUrlCtrl.text.trim()}',
                                          'fileType': 'image/jpeg',
                                        }
                                      ]
                                    : null,
                              );
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (_) {
                          if (ctx.mounted) {
                            setState(() => isSubmitting = false);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Failed to publish post. Try again.')),
                            );
                          }
                        }
                      },
              ),
            ],
          ),
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
                height: 220,
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
