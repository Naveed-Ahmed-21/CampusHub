import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../search/data/search_repository.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_story_avatar.dart';

class UserFollowsView extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final int initialIndex;

  const UserFollowsView({
    super.key,
    required this.userId,
    required this.userName,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<UserFollowsView> createState() => _UserFollowsViewState();
}

class _UserFollowsViewState extends ConsumerState<UserFollowsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CampusAppBar(
        leading: const CampusBackButton(),
        title: widget.userName.isNotEmpty ? widget.userName : 'Connections',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Container(
              height: 42,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.4),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: isDark ? Colors.black : Colors.white,
                unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: isDark ? Colors.white : Colors.black,
                ),
                tabs: const [
                  Tab(text: 'Followers'),
                  Tab(text: 'Following'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _FollowersListTab(userId: widget.userId),
                _FollowingListTab(userId: widget.userId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowersListTab extends ConsumerStatefulWidget {
  final String userId;

  const _FollowersListTab({required this.userId});

  @override
  ConsumerState<_FollowersListTab> createState() => _FollowersListTabState();
}

class _FollowersListTabState extends ConsumerState<_FollowersListTab> {
  List<SearchUserItem>? _cachedUsers;
  final Map<String, bool> _followStatusMap = {};

  @override
  Widget build(BuildContext context) {
    final followersAsync = ref.watch(userFollowersProvider(widget.userId));

    return followersAsync.when(
      data: (users) {
        if (_cachedUsers == null) {
          _cachedUsers = List.of(users);
          for (final u in users) {
            _followStatusMap[u.id] = u.isFollowing;
          }
        }

        final displayList = _cachedUsers!;
        if (displayList.isEmpty) {
          return const _EmptyFollowsView(
            icon: Icons.people_outline,
            message: 'No followers yet.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _cachedUsers = null;
              _followStatusMap.clear();
            });
            ref.invalidate(userFollowersProvider(widget.userId));
            await ref.read(userFollowersProvider(widget.userId).future);
          },

          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: displayList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              final user = displayList[idx];
              final isFollowing = _followStatusMap[user.id] ?? user.isFollowing;
              return _FollowUserItemCard(
                key: ValueKey('followers_user_${user.id}'),
                user: user,
                targetProfileUserId: widget.userId,
                isFollowingOverride: isFollowing,
                onFollowToggled: (newStatus) {
                  setState(() {
                    _followStatusMap[user.id] = newStatus;
                  });
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Failed to load followers: $err'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _cachedUsers = null;
                  _followStatusMap.clear();
                });
                ref.invalidate(userFollowersProvider(widget.userId));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowingListTab extends ConsumerStatefulWidget {
  final String userId;

  const _FollowingListTab({required this.userId});

  @override
  ConsumerState<_FollowingListTab> createState() => _FollowingListTabState();
}

class _FollowingListTabState extends ConsumerState<_FollowingListTab> {
  List<SearchUserItem>? _cachedUsers;
  final Map<String, bool> _followStatusMap = {};

  @override
  Widget build(BuildContext context) {
    final followingAsync = ref.watch(userFollowingProvider(widget.userId));

    return followingAsync.when(
      data: (users) {
        if (_cachedUsers == null) {
          _cachedUsers = List.of(users);
          for (final u in users) {
            _followStatusMap[u.id] = u.isFollowing;
          }
        }

        final displayList = _cachedUsers!;
        if (displayList.isEmpty) {
          return const _EmptyFollowsView(
            icon: Icons.person_add_disabled_outlined,
            message: 'Not following anyone yet.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _cachedUsers = null;
              _followStatusMap.clear();
            });
            ref.invalidate(userFollowingProvider(widget.userId));
            await ref.read(userFollowingProvider(widget.userId).future);
          },

          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: displayList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              final user = displayList[idx];
              final isFollowing = _followStatusMap[user.id] ?? user.isFollowing;
              return _FollowUserItemCard(
                key: ValueKey('following_user_${user.id}'),
                user: user,
                targetProfileUserId: widget.userId,
                isFollowingOverride: isFollowing,
                onFollowToggled: (newStatus) {
                  setState(() {
                    _followStatusMap[user.id] = newStatus;
                  });
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Failed to load following: $err'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _cachedUsers = null;
                  _followStatusMap.clear();
                });
                ref.invalidate(userFollowingProvider(widget.userId));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowUserItemCard extends ConsumerStatefulWidget {
  final SearchUserItem user;
  final String targetProfileUserId;
  final bool? isFollowingOverride;
  final ValueChanged<bool>? onFollowToggled;

  const _FollowUserItemCard({
    super.key,
    required this.user,
    required this.targetProfileUserId,
    this.isFollowingOverride,
    this.onFollowToggled,
  });

  @override
  ConsumerState<_FollowUserItemCard> createState() => _FollowUserItemCardState();
}

class _FollowUserItemCardState extends ConsumerState<_FollowUserItemCard> {
  late bool _isFollowing;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.isFollowingOverride ?? widget.user.isFollowing;
  }

  @override
  void didUpdateWidget(covariant _FollowUserItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFollowingOverride != null && widget.isFollowingOverride != _isFollowing) {
      _isFollowing = widget.isFollowingOverride!;
    } else if (oldWidget.user.id != widget.user.id) {
      _isFollowing = widget.isFollowingOverride ?? widget.user.isFollowing;
    }
  }

  Future<void> _handleToggleFollow() async {
    if (_isToggling) return;
    final previousStatus = _isFollowing;
    final nextStatus = !previousStatus;
    setState(() {
      _isToggling = true;
      _isFollowing = nextStatus;
    });
    widget.onFollowToggled?.call(nextStatus);

    final repo = ref.read(profileRepositoryProvider);
    final result = await repo.toggleFollow(widget.user.id);

    result.when(
      success: (serverIsFollowing) {
        if (mounted) {
          setState(() {
            _isFollowing = serverIsFollowing;
            _isToggling = false;
          });
          widget.onFollowToggled?.call(serverIsFollowing);
        }
        ref.invalidate(profileControllerProvider);
        ref.invalidate(userProfileProvider(widget.user.id));
        // NOTE: We deliberately do NOT invalidate userFollowingProvider or userFollowersProvider
        // here so the user row remains visible until the user explicitly refreshes.
      },
      failure: (_) {
        if (mounted) {
          setState(() {
            _isFollowing = previousStatus;
            _isToggling = false;
          });
          widget.onFollowToggled?.call(previousStatus);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentAuthUser = ref.watch(authControllerProvider).asData?.value;
    final isSelf = currentAuthUser?.id == widget.user.id;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          context.push('/profile/${widget.user.id}');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              ProfileStoryAvatar(
                userId: widget.user.id,
                avatarUrl: widget.user.avatarUrl,
                name: widget.user.fullName,
                radius: 22,
                fallbackOnTap: () {
                  context.push('/profile/${widget.user.id}');
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.user.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.user.displayUsername,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.user.departmentName != null && widget.user.departmentName!.isNotEmpty
                          ? '${widget.user.role} • ${widget.user.departmentName}'
                          : '${widget.user.role} • ${widget.user.email}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!isSelf) ...[
                const SizedBox(width: 8),
                _isFollowing
                    ? OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          visualDensity: VisualDensity.compact,
                          shape: const StadiumBorder(),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF536471) : const Color(0xFFCFD9DE),
                          ),
                          foregroundColor: isDark ? Colors.white : Colors.black,
                        ),
                        onPressed: _handleToggleFollow,
                        child: const Text(
                          'Following',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      )
                    : FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          visualDensity: VisualDensity.compact,
                          shape: const StadiumBorder(),
                          backgroundColor: isDark ? Colors.white : Colors.black,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                        ),
                        onPressed: _handleToggleFollow,
                        child: const Text(
                          'Follow',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFollowsView extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyFollowsView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
