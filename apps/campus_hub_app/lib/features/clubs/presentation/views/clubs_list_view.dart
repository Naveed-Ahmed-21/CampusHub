import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/club_provider.dart';
import 'create_club_dialog.dart';

class ClubsListView extends ConsumerStatefulWidget {
  const ClubsListView({super.key});

  @override
  ConsumerState<ClubsListView> createState() => _ClubsListViewState();
}

class _ClubsListViewState extends ConsumerState<ClubsListView> {
  final _searchController = TextEditingController();
  final List<String> _categories = [
    'ALL',
    'Technical',
    'Cultural',
    'Sports',
    'Academic',
    'Social Service',
    'Innovation & E-Cell',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateClubDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateClubDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clubsAsync = ref.watch(approvedClubsProvider);
    final filter = ref.watch(clubFilterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Clubs & Communities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.fact_check_outlined),
            tooltip: 'Pending Verifications (Admin)',
            onPressed: () => context.push('/clubs/pending'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(approvedClubsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateClubDialog,
        icon: const Icon(Icons.add),
        label: const Text('Create Club'),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search clubs by name or keywords...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(clubFilterProvider.notifier).state =
                                  filter.copyWith(searchQuery: '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) {
                    ref.read(clubFilterProvider.notifier).state =
                        filter.copyWith(searchQuery: val.trim());
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Cross-Dept Only: ', style: TextStyle(fontWeight: FontWeight.w600)),
                    Switch(
                      value: filter.isCrossDepartment ?? false,
                      onChanged: (val) {
                        ref.read(clubFilterProvider.notifier).state = filter.copyWith(
                          isCrossDepartment: val ? true : null,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Category Chips
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = filter.category == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: theme.colorScheme.primaryContainer,
                        onSelected: (selected) {
                          if (selected) {
                            ref.read(clubFilterProvider.notifier).state =
                                filter.copyWith(category: cat);
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Clubs List
          Expanded(
            child: clubsAsync.when(
              data: (clubs) {
                if (clubs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.groups_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No clubs found.',
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _showCreateClubDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Be the first to create one!'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: clubs.length,
                  itemBuilder: (context, index) {
                    final club = clubs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.push('/clubs/${club.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.blue.shade100,
                                    backgroundImage:
                                        club.logoUrl != null ? NetworkImage(club.logoUrl!) : null,
                                    child: club.logoUrl == null
                                        ? Text(
                                            club.name.substring(0, 1).toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          club.name,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 6,
                                          children: [
                                            Chip(
                                              label: Text(
                                                club.category,
                                                style: const TextStyle(fontSize: 10),
                                              ),
                                              visualDensity: VisualDensity.compact,
                                              padding: EdgeInsets.zero,
                                            ),
                                            if (club.isCrossDepartment)
                                              Chip(
                                                avatar: const Icon(Icons.public, size: 12),
                                                label: const Text(
                                                  'Cross-Dept',
                                                  style: TextStyle(fontSize: 10),
                                                ),
                                                backgroundColor: Colors.teal.withValues(alpha: 0.1),
                                                visualDensity: VisualDensity.compact,
                                                padding: EdgeInsets.zero,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                ],
                              ),
                              if (club.description != null && club.description!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  club.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text('${club.memberCount} Members',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.event_outlined, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text('${club.eventCount} Events',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                  Text(
                                    'View Details',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Failed to load clubs: $err'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(approvedClubsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
