import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../chat/presentation/utils/chat_navigation_helper.dart';
import '../../data/search_repository.dart';
import '../providers/search_provider.dart';
import '../../../../core/widgets/campus_bottom_nav.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_chip.dart';
import '../../../../core/theme/app_colors.dart';

class GlobalSearchView extends ConsumerStatefulWidget {
  const GlobalSearchView({super.key});

  @override
  ConsumerState<GlobalSearchView> createState() => _GlobalSearchViewState();
}

class _GlobalSearchViewState extends ConsumerState<GlobalSearchView> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      ref.read(searchNotifierProvider.notifier).performSearch(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(searchNotifierProvider);
    final canPop = CampusBackButton.canPop(context);

    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.primaryText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;
    final searchBoxBg = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.85);
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x990B1B30) : const Color(0xBFFAFBFD),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        if (canPop) ...[
                          CampusBackButton(color: textColor),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: searchBoxBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: borderColor,
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              autofocus: false,
                              onChanged: _onSearchChanged,
                              style: TextStyle(
                                fontSize: 14.5,
                                color: textColor,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search people, clubs, posts...',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: secondaryTextColor,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  size: 20,
                                  color: secondaryTextColor,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.cancel_rounded,
                                          size: 18,
                                          color: secondaryTextColor,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          ref.read(searchNotifierProvider.notifier).performSearch('');
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Filter Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip('all', 'All', searchState.selectedType),
                  _buildFilterChip('students', 'Students', searchState.selectedType),
                  _buildFilterChip('faculty', 'Faculty', searchState.selectedType),
                  _buildFilterChip('clubs', 'Clubs', searchState.selectedType),
                  _buildFilterChip('posts', 'Posts', searchState.selectedType),
                  _buildFilterChip('events', 'Events', searchState.selectedType),
                  _buildFilterChip('career_resources', 'Resources', searchState.selectedType),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),

            // Main Search Body
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  if (searchState.query.isEmpty) {
                    await ref.read(searchNotifierProvider.notifier).loadDiscover();
                  } else {
                    await ref.read(searchNotifierProvider.notifier).performSearch(searchState.query);
                  }
                },
                child: _buildSearchBody(context, searchState),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, String currentType) {
    final isSelected = value == currentType;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: CampusChip(
        label: label,
        isSelected: isSelected,
        onTap: () {
          ref.read(searchNotifierProvider.notifier).setType(value);
        },
      ),
    );
  }

  Widget _buildSearchBody(BuildContext context, SearchState state) {
    final theme = Theme.of(context);

    if (state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Searching CampusHub...',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.errorMessage!, style: TextStyle(color: theme.colorScheme.onSurface)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(searchNotifierProvider.notifier).performSearch(state.query);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // When query is empty: Show Recent Searches and Discover Suggestions
    if (state.query.isEmpty) {
      final discoverUsers = state.results?.users ?? [];
      final recentSearches = state.recentSearches;

      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Recent Searches (if available)
          if (recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Searches',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    ref.read(searchNotifierProvider.notifier).clearAllRecentSearches();
                  },
                  child: Text(
                    'Clear All',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.error),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...recentSearches.map((item) => _buildRecentSearchCard(context, item)),
            const SizedBox(height: 20),
          ],

          // 2. Discover Suggestions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Discover People',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Refresh suggestions',
                onPressed: () {
                  ref.read(searchNotifierProvider.notifier).loadDiscover();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (discoverUsers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.people_outline, size: 56, color: theme.colorScheme.outline),
                    const SizedBox(height: 12),
                    Text(
                      'Search campus members by name, email, or user ID.',
                      style: TextStyle(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
            )
          else
            ...discoverUsers.map((user) => _buildUserCard(context, user)),
        ],
      );
    }

    final results = state.results;
    if (results == null || results.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 60),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: theme.colorScheme.outline),
                const SizedBox(height: 16),
                Text(
                  'No results matching "${state.query}"',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + CampusBottomNav.getBottomClearance(context)),
      children: [
        if (results.users.isNotEmpty) ...[
          _buildCategoryHeader('People (${results.users.length})'),
          ...results.users.map((user) => _buildUserCard(context, user)),
          const SizedBox(height: 16),
        ] else ...[
          if (results.students.isNotEmpty) ...[
            _buildCategoryHeader('Students (${results.students.length})'),
            ...results.students.map((user) => _buildUserCard(context, user)),
            const SizedBox(height: 16),
          ],
          if (results.faculty.isNotEmpty) ...[
            _buildCategoryHeader('Faculty (${results.faculty.length})'),
            ...results.faculty.map((user) => _buildUserCard(context, user)),
            const SizedBox(height: 16),
          ],
        ],
        if (results.clubs.isNotEmpty) ...[
          _buildCategoryHeader('Clubs (${results.clubs.length})'),
          ...results.clubs.map((item) => ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.groups, color: Colors.white, size: 18),
                ),
                title: Text(item['name'] ?? ''),
                subtitle: Text(item['category'] ?? 'Club'),
                onTap: () => context.push('/clubs/${item['id']}'),
              )),
          const SizedBox(height: 16),
        ],
        if (results.posts.isNotEmpty) ...[
          _buildCategoryHeader('Posts (${results.posts.length})'),
          ...results.posts.map((item) => ListTile(
                leading: const Icon(Icons.article_outlined),
                title: Text(item['title'] ?? item['content'] ?? 'Post'),
                subtitle: Text('By ${item['author']?['first_name'] ?? 'User'}'),
                onTap: () {
                  final postId = item['id']?.toString();
                  if (postId != null && postId.isNotEmpty) {
                    context.push('/posts/$postId');
                  }
                },
              )),
          const SizedBox(height: 16),
        ],
        if (results.events.isNotEmpty) ...[
          _buildCategoryHeader('Events (${results.events.length})'),
          ...results.events.map((item) => ListTile(
                leading: const Icon(Icons.event, color: Colors.blue),
                title: Text(item['title'] ?? 'Event'),
                subtitle: Text(item['venue'] ?? 'Campus'),
                onTap: () => context.push('/events/${item['id']}'),
              )),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildRecentSearchCard(BuildContext context, RecentSearchUserItem item) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: CampusAvatar(
          imageUrl: item.avatarUrl,
          name: item.name,
          radius: 18,
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: item.username != null
            ? Text(item.username!, style: TextStyle(fontSize: 12, color: theme.colorScheme.outline))
            : null,
        trailing: IconButton(
          icon: Icon(Icons.close, size: 16, color: theme.colorScheme.outline),
          onPressed: () {
            ref.read(searchNotifierProvider.notifier).removeRecentSearch(item.id);
          },
        ),
        onTap: () {
          final currentUserId = ref.read(authControllerProvider).asData?.value?.id;
          if (item.id == currentUserId) {
            final role = ref.read(authControllerProvider).asData?.value?.role ?? 'STUDENT';
            if (role == 'FACULTY') {
              context.go('/faculty/profile');
            } else {
              context.go('/profile');
            }
          } else {
            context.push('/profile/${item.id}');
          }
        },
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, SearchUserItem user) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          ref.read(searchNotifierProvider.notifier).addRecentSearch(user);
          final currentUserId = ref.read(authControllerProvider).asData?.value?.id;
          if (user.id == currentUserId) {
            final role = ref.read(authControllerProvider).asData?.value?.role ?? 'STUDENT';
            if (role == 'FACULTY') {
              context.go('/faculty/profile');
            } else {
              context.go('/profile');
            }
          } else {
            context.push('/profile/${user.id}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CampusAvatar(
                imageUrl: user.avatarUrl,
                name: user.fullName,
                radius: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.displayUsername,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.departmentName != null && user.departmentName!.isNotEmpty
                          ? '${user.role} • ${user.departmentName}'
                          : (user.rollNumber != null ? '${user.role} • ${user.rollNumber}' : '${user.role} • ${user.email}'),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.bio != null && user.bio!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        user.bio!.trim(),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(6),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    tooltip: 'Message ${user.firstName}',
                    onPressed: () async {
                      await ChatNavigationHelper.startOrOpenDirectChat(
                        context,
                        ref,
                        targetUserId: user.id,
                        targetUserName: user.fullName,
                        targetUserAvatar: user.avatarUrl,
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  user.isFollowing
                      ? OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            visualDensity: VisualDensity.compact,
                            side: BorderSide(color: theme.colorScheme.primary),
                          ),
                          onPressed: () {
                            ref.read(searchNotifierProvider.notifier).toggleFollow(user.id);
                          },
                          child: const Text('Following', style: TextStyle(fontSize: 12)),
                        )
                      : FilledButton(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () {
                            ref.read(searchNotifierProvider.notifier).toggleFollow(user.id);
                          },
                          child: const Text('Follow', style: TextStyle(fontSize: 12)),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
