import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      ref.read(searchNotifierProvider.notifier).performSearch(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search campus, students, clubs, events...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchNotifierProvider.notifier).performSearch('');
                    },
                  )
                : null,
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
          const Divider(height: 1),

          // Main Search Body
          Expanded(
            child: _buildSearchBody(context, searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, String currentType) {
    final isSelected = value == currentType;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (_) {
          ref.read(searchNotifierProvider.notifier).setType(value);
        },
      ),
    );
  }

  Widget _buildSearchBody(BuildContext context, SearchState state) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching CampusHub...'),
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
            Text(state.errorMessage!),
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

    if (state.query.isEmpty) {
      final discoverUsers = state.results?.users ?? [];
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 18, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Discover People',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
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
                    Icon(Icons.people_outline, size: 56, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 12),
                    Text(
                      'Search campus members by name, email, or user ID.',
                      style: TextStyle(color: Theme.of(context).colorScheme.outline),
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
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No results matching "${state.query}"'),
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
                onTap: () => context.push('/feed/posts/${item['id']}'),
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

  Widget _buildUserCard(BuildContext context, SearchUserItem user) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/profile/${user.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                    ? NetworkImage(user.avatarUrl!)
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
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              user.isFollowing
                  ? OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(color: theme.colorScheme.primary),
                      ),
                      onPressed: () {
                        ref.read(searchNotifierProvider.notifier).toggleFollow(user.id);
                      },
                      icon: const Icon(Icons.check, size: 14),
                      label: const Text('Following', style: TextStyle(fontSize: 12)),
                    )
                  : FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        ref.read(searchNotifierProvider.notifier).toggleFollow(user.id);
                      },
                      icon: const Icon(Icons.person_add_alt_1, size: 14),
                      label: const Text('Follow', style: TextStyle(fontSize: 12)),
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
