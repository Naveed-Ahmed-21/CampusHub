import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Search students, clubs, posts, and campus events.'),
          ],
        ),
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
        if (results.students.isNotEmpty) ...[
          _buildCategoryHeader('Students (${results.students.length})'),
          ...results.students.map((item) => ListTile(
                leading: CircleAvatar(
                  child: Text('${item['first_name']?[0] ?? 'S'}'),
                ),
                title: Text('${item['first_name']} ${item['last_name']}'),
                subtitle: Text(item['email'] ?? ''),
                onTap: () => context.push('/portfolio/${item['id']}'),
              )),
          const SizedBox(height: 16),
        ],
        if (results.faculty.isNotEmpty) ...[
          _buildCategoryHeader('Faculty (${results.faculty.length})'),
          ...results.faculty.map((item) => ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.purple,
                  child: Icon(Icons.school, color: Colors.white, size: 18),
                ),
                title: Text('${item['first_name']} ${item['last_name']}'),
                subtitle: Text(item['department']?['name'] ?? 'Faculty'),
                onTap: () => context.push('/portfolio/${item['id']}'),
              )),
          const SizedBox(height: 16),
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
