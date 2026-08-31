import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/responsive/responsive_layout.dart';
import '../../../../shared/widgets/async_value_widget.dart';
import '../controllers/feed_controller.dart';
import '../../domain/models/post_item.dart';
import '../widgets/campus_top_app_bar.dart';
import '../widgets/student_drawer_widget.dart';
import '../widgets/stories_section_widget.dart';
import '../widgets/create_post_bar_widget.dart';
import '../widgets/feed_filter_tabs_widget.dart';
import '../widgets/feed_post_card_widget.dart';
import '../widgets/bottom_search_bar_widget.dart';
import '../widgets/create_post_sheet.dart';
import '../widgets/comments_sheet.dart';

class FeedView extends ConsumerStatefulWidget {
  const FeedView({super.key});

  @override
  ConsumerState<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends ConsumerState<FeedView> with AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.hasClients &&
          _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 250) {
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

  void _openCreatePost(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CreatePostSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final activeFeedType = ref.watch(activeFeedTypeProvider);
    final feedAsync = ref.watch(feedControllerProvider);

    return Scaffold(
      key: _scaffoldKey,
      appBar: CampusTopAppBar(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: const StudentDrawerWidget(),
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
      key: const PageStorageKey<String>('feed_custom_scroll_view'),
      controller: _scrollController,
      slivers: [
        // 1. Real Stories Section
        const SliverToBoxAdapter(
          child: StoriesSectionWidget(),
        ),

        // 2. Compact Create Post Bar
        SliverToBoxAdapter(
          child: CreatePostBarWidget(
            onTap: () => _openCreatePost(context),
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      activeFeedType == 'FOLLOWING' ? Icons.people_outline : Icons.dynamic_feed,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      activeFeedType == 'FOLLOWING'
                          ? 'You are not following anyone yet.'
                          : 'No campus posts found in this feed yet.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activeFeedType == 'FOLLOWING'
                          ? 'Follow people from your campus to see their posts here.'
                          : 'Be the first to share an update with your campus community!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 18),
                    if (activeFeedType == 'FOLLOWING') ...[
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: () => context.push('/search'),
                            icon: const Icon(Icons.person_search, size: 18),
                            label: const Text('Discover People to Follow'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _onSelectTab('MY_FEED'),
                            icon: const Icon(Icons.dynamic_feed, size: 18),
                            label: const Text('Explore For You Feed'),
                          ),
                        ],
                      ),
                    ] else
                      ElevatedButton.icon(
                        onPressed: () => _openCreatePost(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Create the first post'),
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
                    onOpenComments: () => PostCommentsSheet.show(context, post.id),
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
