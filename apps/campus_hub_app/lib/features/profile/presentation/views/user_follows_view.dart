import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../search/data/search_repository.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../controllers/profile_controller.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName.isNotEmpty ? widget.userName : 'Connections'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.outline,
          tabs: const [
            Tab(text: 'Followers'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FollowersListTab(userId: widget.userId),
          _FollowingListTab(userId: widget.userId),
        ],
      ),
    );
  }
}

class _FollowersListTab extends ConsumerWidget {
  final String userId;

  const _FollowersListTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followersAsync = ref.watch(userFollowersProvider(userId));

    return followersAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return const _EmptyFollowsView(
            icon: Icons.people_outline,
            message: 'No followers yet.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userFollowersProvider(userId));
          },
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              return _FollowUserItemCard(
                user: users[idx],
                targetProfileUserId: userId,
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
              onPressed: () => ref.invalidate(userFollowersProvider(userId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowingListTab extends ConsumerWidget {
  final String userId;

  const _FollowingListTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followingAsync = ref.watch(userFollowingProvider(userId));

    return followingAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return const _EmptyFollowsView(
            icon: Icons.person_add_disabled_outlined,
            message: 'Not following anyone yet.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userFollowingProvider(userId));
          },
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              return _FollowUserItemCard(
                user: users[idx],
                targetProfileUserId: userId,
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
              onPressed: () => ref.invalidate(userFollowingProvider(userId)),
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

  const _FollowUserItemCard({
    required this.user,
    required this.targetProfileUserId,
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
    _isFollowing = widget.user.isFollowing;
  }

  @override
  void didUpdateWidget(covariant _FollowUserItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.isFollowing != widget.user.isFollowing) {
      _isFollowing = widget.user.isFollowing;
    }
  }

  Future<void> _handleToggleFollow() async {
    if (_isToggling) return;
    setState(() {
      _isToggling = true;
      _isFollowing = !_isFollowing;
    });

    final repo = ref.read(profileRepositoryProvider);
    final result = await repo.toggleFollow(widget.user.id);

    result.when(
      success: (serverIsFollowing) {
        if (mounted) {
          setState(() {
            _isFollowing = serverIsFollowing;
            _isToggling = false;
          });
        }
        ref.invalidate(profileControllerProvider);
        ref.invalidate(userProfileProvider(widget.user.id));
        ref.invalidate(userFollowersProvider(widget.targetProfileUserId));
        ref.invalidate(userFollowingProvider(widget.targetProfileUserId));
      },
      failure: (_) {
        if (mounted) {
          setState(() {
            _isFollowing = !_isFollowing;
            _isToggling = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentAuthUser = ref.watch(authControllerProvider).asData?.value;
    final isSelf = currentAuthUser?.id == widget.user.id;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
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
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: widget.user.avatarUrl != null && widget.user.avatarUrl!.isNotEmpty
                    ? NetworkImage(ApiEndpoints.resolveUrl(widget.user.avatarUrl!))
                    : null,
                child: widget.user.avatarUrl == null || widget.user.avatarUrl!.isEmpty
                    ? Text(
                        widget.user.firstName.isNotEmpty ? widget.user.firstName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      )
                    : null,
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
                            color: theme.colorScheme.primary,
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
                    ? OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(color: theme.colorScheme.primary),
                        ),
                        onPressed: _handleToggleFollow,
                        icon: const Icon(Icons.check, size: 13),
                        label: const Text('Following', style: TextStyle(fontSize: 11.5)),
                      )
                    : FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: _handleToggleFollow,
                        icon: const Icon(Icons.person_add_alt_1, size: 13),
                        label: const Text('Follow', style: TextStyle(fontSize: 11.5)),
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
