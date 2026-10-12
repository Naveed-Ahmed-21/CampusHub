import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/club_provider.dart';
import 'create_club_dialog.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/widgets/campus_bottom_nav.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_segmented_control.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/theme/app_colors.dart';

class ClubsListView extends ConsumerStatefulWidget {
  final bool showAppBar;

  const ClubsListView({super.key, this.showAppBar = true});

  @override
  ConsumerState<ClubsListView> createState() => _ClubsListViewState();
}

class _ClubsListViewState extends ConsumerState<ClubsListView>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
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
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final filter = ref.read(clubFilterProvider);
      ref.read(clubFilterProvider.notifier).state =
          filter.copyWith(searchQuery: val.trim());
    });
  }

  void _showCreateClubDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateClubDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final clubsAsync = ref.watch(approvedClubsProvider);
    final filter = ref.watch(clubFilterProvider);
    final theme = Theme.of(context);
    final authUser = ref.watch(authControllerProvider).asData?.value;
    final isAdmin = authUser?.role == 'ADMIN' ||
        authUser?.role == 'COLLEGE_ADMIN' ||
        authUser?.role == 'SUPER_ADMIN';
    final isDepartmentOnly =
        filter.departmentOnly || filter.isCrossDepartment == false;

    return Scaffold(
      appBar: widget.showAppBar
          ? CampusAppBar(
              title: 'Campus Clubs & Communities',
              actions: [
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.fact_check_outlined),
                    tooltip: 'Pending Verifications (Admin)',
                    onPressed: () => context.push('/admin/clubs/pending'),
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: () => ref.invalidate(approvedClubsProvider),
                ),
              ],
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _showCreateClubDialog,
        icon: const Icon(Icons.add),
        label: const Text('Create Club'),
      ),
      body: AtmosphericBackground(
        child: Column(
          children: [
            // Scope Selector Tabs & Search Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  // Top Scope Tabs: [ All Clubs ] [ My Department ]
                  CampusSegmentedControl(
                    selectedIndex: isDepartmentOnly ? 1 : 0,
                    items: const [
                      CampusSegmentItem(label: 'All Clubs'),
                      CampusSegmentItem(label: 'My Department'),
                    ],
                    onValueChanged: (idx) {
                      final deptOnly = idx == 1;
                      ref.read(clubFilterProvider.notifier).state =
                          filter.copyWith(
                        departmentOnly: deptOnly,
                        isCrossDepartment: deptOnly ? false : null,
                        clearCrossDepartment: !deptOnly,
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // Search Bar with Debounce
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? AppColors.darkSurface.withValues(alpha: 0.6)
                          : AppColors.lightSurface.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Search clubs by name or keywords...',
                        hintStyle: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                        prefixIcon: Icon(Icons.search, size: 18, color: theme.colorScheme.onSurfaceVariant),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(clubFilterProvider.notifier).state =
                                      filter.copyWith(searchQuery: '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  const SizedBox(height: 8),

                // Category Chips
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = filter.category == cat;
                      return ChoiceChip(
                        label: Text(cat, style: const TextStyle(fontSize: 12)),
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
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isDepartmentOnly
                                ? Icons.domain_disabled_outlined
                                : Icons.groups_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isDepartmentOnly
                                ? 'No clubs found for your department or cross-department.'
                                : 'No clubs found matching your criteria.',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _showCreateClubDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Be the first to create one!'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  key: const PageStorageKey<String>('clubs_list_scroll_key'),
                  padding: EdgeInsets.fromLTRB(16, 6, 16, CampusBottomNav.getBottomClearance(context)),
                  itemCount: clubs.length,
                  itemBuilder: (context, index) {
                    final club = clubs[index];
                    final deptLabel =
                        club.departmentCode ?? club.departmentName;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CampusGlassCard(
                        onTap: () => context.push('/clubs/${club.id}'),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CampusAvatar(
                                  imageUrl: club.logoUrl,
                                  name: club.name,
                                  radius: 26,
                                ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          club.name,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            // Category Badge
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme
                                                    .surfaceContainerHighest,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                club.category,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                            ),
                                            // Classification Badge: Cross Department vs Department
                                            if (club.isCrossDepartment)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.teal
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.public,
                                                        size: 12,
                                                        color: Colors.teal),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Cross Department',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.teal,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            else
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.indigo
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.domain,
                                                        size: 12,
                                                        color: Colors.indigo),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      deptLabel != null &&
                                                              deptLabel
                                                                  .isNotEmpty
                                                          ? deptLabel
                                                          : 'Department',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.indigo,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios,
                                      size: 14, color: Colors.grey),
                                ],
                              ),
                              if (club.description != null &&
                                  club.description!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  club.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.8),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.people_outline,
                                          size: 15,
                                          color: theme.colorScheme.outline),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${club.memberCount} Members',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: theme.colorScheme.outline),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(Icons.event_outlined,
                                          size: 15,
                                          color: theme.colorScheme.outline),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${club.eventCount} Events',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: theme.colorScheme.outline),
                                      ),
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
      ),
    );
  }
}
