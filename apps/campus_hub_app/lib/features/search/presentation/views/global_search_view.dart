import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../chat/data/chat_repository.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../feed/presentation/widgets/comments_sheet.dart';
import '../../data/search_repository.dart';
import '../providers/search_provider.dart';

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
    final canPop = context.canPop();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: canPop ? 0 : 16,
        leading: canPop
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
                onPressed: () {
                  if (context.canPop()) context.pop();
                },
              )
            : null,
        title: Container(
          height: 44,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: false,
            onChanged: _onSearchChanged,
            style: TextStyle(
              fontSize: 14.5,
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Search people, clubs, posts...',
              hintStyle: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              prefixIcon: Icon(
                Icons.search,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.cancel_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(searchNotifierProvider.notifier).performSearch('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
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
            child: _buildSearchBody(context, searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, String currentType) {
    final theme = Theme.of(context);
    final isSelected = value == currentType;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        selectedColor: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        checkmarkColor: theme.colorScheme.onPrimary,
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (_) {
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
      return Center(
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
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
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
                    PostCommentsSheet.show(context, postId);
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
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: item.avatarUrl != null && item.avatarUrl!.isNotEmpty
              ? NetworkImage(ApiEndpoints.resolveUrl(item.avatarUrl!))
              : null,
          child: item.avatarUrl == null || item.avatarUrl!.isEmpty
              ? Text(
                  item.name.isNotEmpty ? item.name[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                )
              : null,
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
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                    ? NetworkImage(ApiEndpoints.resolveUrl(user.avatarUrl!))
                    : null,
                onBackgroundImageError: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                    ? (_, __) {}
                    : null,
                child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                    ? Text(
                        user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user.displayUsername,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.departmentName != null && user.departmentName!.isNotEmpty
                          ? '${user.role} • ${user.departmentName}'
                          : (user.rollNumber != null ? '${user.role} • ${user.rollNumber}' : '${user.role} • ${user.email}'),
                      style: TextStyle(
                        fontSize: 12.5,
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
                      try {
                        final repo = ref.read(chatRepositoryProvider);
                        final room = await repo.getOrCreateDirectChat(user.id);
                        ref.invalidate(userChatRoomsProvider);
                        if (context.mounted) {
                          context.push('/chat/room/${room.id}');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Cannot start conversation: $e')),
                          );
                        }
                      }
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
