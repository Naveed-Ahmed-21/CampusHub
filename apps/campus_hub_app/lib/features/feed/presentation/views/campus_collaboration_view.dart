import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/responsive/responsive_layout.dart';
import '../../../../shared/widgets/async_value_widget.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../../domain/models/post_item.dart';
import '../widgets/feed_post_card_widget.dart';
import '../widgets/comments_sheet.dart';
import '../widgets/create_post_sheet.dart';

final collaborationPostsProvider = FutureProvider.autoDispose.family<List<PostItem>, String>((ref, categoryFilter) async {
  final repo = ref.watch(feedRepositoryProvider);
  final result = await repo.getFeed(
    feedType: 'CROSS_DEPARTMENT',
    page: 1,
    limit: 50,
  );

  return result.when(
    success: (posts) {
      if (categoryFilter.isEmpty || categoryFilter == 'ALL') {
        return posts;
      }
      return posts.where((p) => p.type.toUpperCase() == categoryFilter).toList();
    },
    failure: (err) => throw err,
  );
});

class CampusCollaborationView extends ConsumerStatefulWidget {
  const CampusCollaborationView({super.key});

  @override
  ConsumerState<CampusCollaborationView> createState() => _CampusCollaborationViewState();
}

class _CampusCollaborationViewState extends ConsumerState<CampusCollaborationView> {
  String _selectedCategory = 'ALL';
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openCreatePost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CreatePostSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postsAsync = ref.watch(collaborationPostsProvider(_selectedCategory));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Campus Collaboration',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Create Post',
            onPressed: _openCreatePost,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(collaborationPostsProvider),
          ),
        ],
      ),
      body: ResponsiveLayout(
        mobile: _buildContent(context, theme, postsAsync, isDesktop: false),
        desktop: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 750),
            child: _buildContent(context, theme, postsAsync, isDesktop: true),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    AsyncValue<List<PostItem>> postsAsync, {
    required bool isDesktop,
  }) {
    return Column(
      children: [
        // Informative Header Banner
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.hub_outlined, color: theme.colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inter-Department Collaboration',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Discover opportunities, inter-branch projects, events, and initiatives across all departments on campus.',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search collaboration posts, topics...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: [
              _buildCategoryChip('All Posts', 'ALL', theme),
              _buildCategoryChip('Events & Fests', 'EVENT_PROMO', theme),
              _buildCategoryChip('Placements & Careers', 'PLACEMENT', theme),
              _buildCategoryChip('Academic & Projects', 'ACADEMIC', theme),
              _buildCategoryChip('Announcements', 'ANNOUNCEMENT', theme),
              _buildCategoryChip('General', 'GENERAL', theme),
            ],
          ),
        ),

        const Divider(height: 1),

        // Posts List
        Expanded(
          child: AsyncValueWidget<List<PostItem>>(
            value: postsAsync,
            data: (posts) {
              final filtered = posts.where((p) {
                if (_searchQuery.isEmpty) return true;
                return p.title.toLowerCase().contains(_searchQuery) ||
                    p.content.toLowerCase().contains(_searchQuery) ||
                    p.author.name.toLowerCase().contains(_searchQuery);
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.diversity_3_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No collaboration posts yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Campus-wide initiatives and inter-branch updates will appear here automatically.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: _openCreatePost,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create a Post'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(collaborationPostsProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final post = filtered[index];
                    return FeedPostCardWidget(
                      post: post,
                      onOpenComments: () => PostCommentsSheet.show(context, post.id),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, String value, ThemeData theme) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedCategory = value),
        selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
        checkmarkColor: theme.colorScheme.primary,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
