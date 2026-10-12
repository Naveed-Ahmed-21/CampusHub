import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/campus_empty_state.dart';
import '../../../../core/widgets/campus_bottom_nav.dart';
import '../../../../shared/responsive/responsive_layout.dart';
import '../../../auth/domain/models/auth_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../faculty/presentation/widgets/faculty_drawer_widget.dart';
import '../../../admin/presentation/widgets/admin_drawer_widget.dart';
import '../../domain/models/post_item.dart';
import '../controllers/feed_controller.dart';
import '../widgets/bottom_search_bar_widget.dart';
import '../widgets/campus_top_app_bar.dart';
import '../widgets/comments_sheet.dart';
import '../widgets/create_post_bar_widget.dart';
import '../widgets/create_post_sheet.dart';
import '../widgets/feed_filter_tabs_widget.dart';
import '../widgets/feed_post_card_widget.dart';
import '../widgets/stories_section_widget.dart';
import '../widgets/student_drawer_widget.dart';

class FeedView extends ConsumerStatefulWidget {
  final bool showAppBar;

  const FeedView({super.key, this.showAppBar = true});

  @override
  ConsumerState<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends ConsumerState<FeedView>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.hasClients &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 250) {
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
      useRootNavigator: true,
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
    final user = ref.watch(authControllerProvider).asData?.value;
    final isFaculty = user?.isFaculty == true;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      appBar: widget.showAppBar
          ? CampusTopAppBar(
              onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
            )
          : null,
      drawer: widget.showAppBar
          ? (user?.isAdmin == true
              ? const AdminDrawerWidget()
              : (isFaculty
                  ? const FacultyDrawerWidget()
                  : const StudentDrawerWidget()))
          : null,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(feedControllerProvider.notifier).refreshFeed(),
        child: ResponsiveLayout(
          mobile: _buildFeedLayout(
            context,
            feedAsync,
            activeFeedType,
            user,
            isDesktop: false,
          ),
          desktop: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 780),
              child: _buildFeedLayout(
                context,
                feedAsync,
                activeFeedType,
                user,
                isDesktop: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedLayout(
    BuildContext context,
    AsyncValue<List<PostItem>> feedAsync,
    String activeFeedType,
    AuthUser? user, {
    required bool isDesktop,
  }) {
    final posts = feedAsync.valueOrNull;
    final isLoading = feedAsync.isLoading;
    final hasError = feedAsync.hasError && posts == null;

    return CustomScrollView(
      key: const PageStorageKey<String>('feed_custom_scroll_view'),
      controller: _scrollController,
      slivers: [
        // 2. Real Stories Section
        const SliverToBoxAdapter(
          child: StoriesSectionWidget(),
        ),

        // 3. Compact Create Post Bar
        SliverToBoxAdapter(
          child: CreatePostBarWidget(
            onTap: () => _openCreatePost(context),
          ),
        ),

        // 4. Feed Filter Tabs
        SliverToBoxAdapter(
          child: FeedFilterTabsWidget(
            activeFeedType: (user?.isAdmin == true &&
                    (activeFeedType == 'myDepartment' ||
                        activeFeedType == 'related'))
                ? 'forYou'
                : activeFeedType,
            isAdmin: user?.isAdmin == true,
            onSelectTab: _onSelectTab,
          ),
        ),

        // Subtle linear loading bar when switching tabs or refreshing
        if (isLoading && posts != null)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: LinearProgressIndicator(minHeight: 2.5),
            ),
          ),

        // 5. Feed Posts List, Async Loading, or Empty State
        if (posts == null && isLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (hasError)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
              child: CampusEmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Unable to Load Feed',
                description: 'Failed to connect to the campus stream. Please try again.',
                actionLabel: 'Retry',
                onAction: () =>
                    ref.read(feedControllerProvider.notifier).refreshFeed(),
              ),
            ),
          )
        else if (posts == null || posts.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: CampusEmptyState(
                icon: activeFeedType.toLowerCase() == 'following'
                    ? Icons.people_outline_rounded
                    : Icons.dynamic_feed_rounded,
                title: activeFeedType.toLowerCase() == 'following'
                    ? 'No Following Updates'
                    : 'Campus Feed Is Quiet',
                description: activeFeedType.toLowerCase() == 'following'
                    ? 'Follow classmates and professors to see their announcements and posts here.'
                    : 'Be the first to share an academic or campus update with your GCEE community!',
                actionLabel: activeFeedType.toLowerCase() == 'following'
                    ? 'Discover Campus Members'
                    : 'Create First Post',
                onAction: () {
                  if (activeFeedType.toLowerCase() == 'following') {
                    context.push('/search');
                  } else {
                    _openCreatePost(context);
                  }
                },
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < posts.length) {
                  final post = posts[index];
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(feedControllerProvider.notifier).markPostsAsSeen([post.id]);
                  });
                  return FeedPostCardWidget(
                    post: post,
                    onOpenComments: () =>
                        PostCommentsSheet.show(context, post.id),
                  );
                } else {
                  final hasMore =
                      ref.watch(feedControllerProvider.notifier).hasMore;
                  return hasMore
                      ? const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              'You have reached the end of the campus stream.',
                              style: AppTypography.caption.copyWith(color: AppColors.secondaryText),
                            ),
                          ),
                        );
                }
              },
              childCount: posts.length + 1,
            ),
          ),

        // 6. Global Search Bar above bottom navigation
        const SliverToBoxAdapter(
          child: BottomSearchBarWidget(),
        ),

        // 7. Dynamic Clearance for Floating Glass Bottom Navigation
        const SliverCampusBottomNavSpacer(),
      ],
    );
  }
}
