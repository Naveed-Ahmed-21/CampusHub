import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/media_storage_service.dart';
import '../../../../core/services/file_open_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../feed/presentation/widgets/feed_post_card_widget.dart';
import '../../../feed/presentation/widgets/comments_sheet.dart';
import '../../../chat/data/chat_repository.dart';
import '../../domain/models/user_profile.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../controllers/profile_controller.dart';
import 'user_follows_view.dart';
import '../../../../shared/widgets/full_screen_image_viewer.dart';

class UserProfileDetailView extends ConsumerStatefulWidget {
  final String userId;

  const UserProfileDetailView({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<UserProfileDetailView> createState() => _UserProfileDetailViewState();
}

class _UserProfileDetailViewState extends ConsumerState<UserProfileDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;
  bool _hasInitializedFollow = false;
  bool _isTogglingFollow = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleToggleFollow(UserProfile profile) async {
    if (_isTogglingFollow) return;
    setState(() {
      _isTogglingFollow = true;
      _isFollowing = !_isFollowing;
    });

    final repo = ref.read(profileRepositoryProvider);
    final result = await repo.toggleFollow(profile.id);

    result.when(
      success: (serverIsFollowing) {
        if (mounted) {
          setState(() {
            _isFollowing = serverIsFollowing;
            _isTogglingFollow = false;
          });
        }
        ref.invalidate(userProfileProvider(profile.id));
        ref.invalidate(profileControllerProvider);
        ref.invalidate(userFollowersProvider(profile.id));
      },
      failure: (_) {
        if (mounted) {
          setState(() {
            _isFollowing = !_isFollowing;
            _isTogglingFollow = false;
          });
        }
      },
    );
  }

  Future<void> _startDirectChat(UserProfile profile) async {
    try {
      final chatRepo = ref.read(chatRepositoryProvider);
      final room = await chatRepo.getOrCreateDirectChat(profile.id);
      if (mounted) {
        context.push('/chat/room/${room.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open chat: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider(widget.userId));
    final currentAuthUser = ref.watch(authControllerProvider).asData?.value;
    final isSelf = currentAuthUser?.id == widget.userId;

    return profileAsync.when(
      data: (profile) {
        if (!_hasInitializedFollow) {
          _isFollowing = profile.isFollowing;
          _hasInitializedFollow = true;
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: Text(profile.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: () {
                  ref.invalidate(userProfileProvider(widget.userId));
                  ref.invalidate(userPostsProvider(widget.userId));
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userProfileProvider(widget.userId));
              ref.invalidate(userPostsProvider(widget.userId));
            },
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Avatar, Name, Username, Bio, Follow Actions
                          _buildProfileHeader(context, profile, isSelf),
                          const SizedBox(height: 14),
                          // Stats Bar (Posts, Followers, Following)
                          _buildStatsBar(context, profile),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      TabBar(
                        controller: _tabController,
                        indicatorColor: theme.colorScheme.primary,
                        indicatorWeight: 3,
                        labelColor: theme.colorScheme.primary,
                        unselectedLabelColor: theme.colorScheme.outline,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        tabs: const [
                          Tab(icon: Icon(Icons.article_outlined, size: 20), text: 'Posts'),
                          Tab(icon: Icon(Icons.person_outline, size: 20), text: 'About & Skills'),
                        ],
                      ),
                      backgroundColor: theme.scaffoldBackgroundColor,
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _UserPostsTab(userId: profile.id),
                  _UserAboutPortfolioTab(profile: profile),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('User Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(
          title: const Text('User Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off_outlined, size: 64, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                const Text(
                  'User Not Found',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'The user profile you are looking for could not be loaded or may no longer exist.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Go Back'),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      onPressed: () => ref.invalidate(userProfileProvider(widget.userId)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserProfile profile, bool isSelf) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 2.5,
                  ),
                ),
                child: GestureDetector(
                  onTap: () {
                    if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
                      FullScreenImageViewer.openSingle(
                        context,
                        imageUrl: profile.avatarUrl!,
                        heroTag: 'user_detail_avatar_${profile.id}',
                        title: profile.fullName,
                        subtitle: profile.bio ?? profile.role,
                      );
                    }
                  },
                  child: Hero(
                    tag: 'user_detail_avatar_${profile.id}',
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                          ? NetworkImage(ApiEndpoints.resolveUrl(profile.avatarUrl!))
                          : null,
                      child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                          ? Text(
                              profile.firstName.isNotEmpty ? profile.firstName[0].toUpperCase() : 'U',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            profile.role,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: profile.displayUsername));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Username copied to clipboard!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            profile.displayUsername,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.copy, size: 12, color: theme.colorScheme.primary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.department != null && profile.department!.isNotEmpty
                          ? '${profile.role} • ${profile.department}'
                          : profile.role,
                      style: TextStyle(fontSize: 12.5, color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                profile.bio!,
                style: TextStyle(fontSize: 13.5, height: 1.35, color: theme.colorScheme.onSurface),
              ),
            ),
          ],
          if (!isSelf) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _isFollowing
                      ? OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: theme.colorScheme.primary),
                          ),
                          onPressed: () => _handleToggleFollow(profile),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Following', style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      : FilledButton.icon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _handleToggleFollow(profile),
                          icon: const Icon(Icons.person_add_alt_1, size: 16),
                          label: const Text('Follow', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                ),
                const SizedBox(width: 10),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _startDirectChat(profile),
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Message'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsBar(BuildContext context, UserProfile profile) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatColumn(
            context,
            count: profile.postsCount.toString(),
            label: 'Posts',
            onTap: () {
              _tabController.animateTo(0);
            },
          ),
          Container(width: 1, height: 28, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          _buildStatColumn(
            context,
            count: profile.followersCount.toString(),
            label: 'Followers',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => UserFollowsView(
                    userId: profile.id,
                    userName: profile.fullName,
                    initialIndex: 0,
                  ),
                ),
              );
            },
          ),
          Container(width: 1, height: 28, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          _buildStatColumn(
            context,
            count: profile.followingCount.toString(),
            label: 'Following',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => UserFollowsView(
                    userId: profile.id,
                    userName: profile.fullName,
                    initialIndex: 1,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context, {
    required String count,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserPostsTab extends ConsumerWidget {
  final String userId;

  const _UserPostsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(userPostsProvider(userId));

    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article_outlined, size: 56, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text(
                    'No posts published yet.',
                    style: TextStyle(fontSize: 14.5, color: Theme.of(context).colorScheme.outline),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: posts.length,
          itemBuilder: (ctx, idx) {
            final post = posts[idx];
            return FeedPostCardWidget(
              key: ValueKey(post.id),
              post: post,
              onOpenComments: () => PostCommentsSheet.show(context, post.id),
              onPostDeleted: () => ref.invalidate(userPostsProvider(userId)),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Failed to load posts: $err'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(userPostsProvider(userId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserAboutPortfolioTab extends ConsumerWidget {
  final UserProfile profile;

  const _UserAboutPortfolioTab({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (profile.skills.isNotEmpty) ...[
          Text('Technical Skills', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.skills.map((s) {
              return Chip(
                label: Text(s.proficiency != null && s.proficiency!.isNotEmpty ? '${s.skillName} • ${s.proficiency}' : s.skillName, style: const TextStyle(fontSize: 12.5)),
                backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        if (profile.projects.isNotEmpty) ...[
          Text('Featured Projects', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...profile.projects.map((proj) {
            final hasRepo = proj.repoUrl != null && proj.repoUrl!.isNotEmpty;
            final hasDemo = proj.projectUrl != null && proj.projectUrl!.isNotEmpty;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(proj.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  if (proj.description != null && proj.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(proj.description!, style: TextStyle(fontSize: 12.5, color: theme.colorScheme.onSurfaceVariant)),
                  ],
                  if (hasRepo || hasDemo) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (hasRepo)
                          ActionChip(
                            avatar: const Icon(Icons.code, size: 14),
                            label: const Text('Repository', style: TextStyle(fontSize: 11.5)),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: proj.repoUrl!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Repository link copied!'), duration: Duration(seconds: 1)),
                              );
                            },
                          ),
                        if (hasDemo)
                          ActionChip(
                            avatar: const Icon(Icons.open_in_new, size: 14),
                            label: const Text('Live Demo', style: TextStyle(fontSize: 11.5)),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: proj.projectUrl!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Demo link copied!'), duration: Duration(seconds: 1)),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
        ],

        if (profile.githubUrl != null || profile.linkedinUrl != null || profile.websiteUrl != null || profile.resumeUrl != null) ...[
          Text('Links & Documents', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (profile.resumeUrl != null && profile.resumeUrl!.isNotEmpty)
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: theme.colorScheme.surfaceContainer,
              leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
              title: Text('${profile.firstName}\'s Resume / CV', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('Tap to view and open resume document', style: TextStyle(fontSize: 12)),
              trailing: FilledButton.tonalIcon(
                onPressed: () async {
                  try {
                    final storage = ref.read(mediaStorageServiceProvider);
                    final cacheKey = 'user_resume_${profile.id}';
                    String? localPath = storage.isMessageMediaDownloaded(cacheKey) ? storage.getDownloadedPathForMessage(cacheKey) : null;
                    if (localPath == null || !File(localPath).existsSync()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Downloading resume...'), duration: Duration(seconds: 1)),
                      );
                      localPath = await storage.downloadAndSaveFile(
                        fileUrl: profile.resumeUrl!,
                        messageId: cacheKey,
                        fileName: '${profile.firstName}_Resume.pdf',
                      );
                    }
                    if (localPath != null && context.mounted) {
                      await FileOpenService.openLocalFile(localPath, context: context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not open resume: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 14),
                label: const Text('View', style: TextStyle(fontSize: 12)),
              ),
            ),
          const SizedBox(height: 6),
          if (profile.githubUrl != null && profile.githubUrl!.isNotEmpty)
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: theme.colorScheme.surfaceContainer,
              leading: const Icon(Icons.code),
              title: const Text('GitHub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(profile.githubUrl!, style: const TextStyle(fontSize: 12)),
              trailing: IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: profile.githubUrl!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('GitHub link copied!'), duration: Duration(seconds: 1)),
                  );
                },
              ),
            ),
          const SizedBox(height: 6),
          if (profile.linkedinUrl != null && profile.linkedinUrl!.isNotEmpty)
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: theme.colorScheme.surfaceContainer,
              leading: const Icon(Icons.work_outline),
              title: const Text('LinkedIn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(profile.linkedinUrl!, style: const TextStyle(fontSize: 12)),
              trailing: IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: profile.linkedinUrl!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('LinkedIn link copied!'), duration: Duration(seconds: 1)),
                  );
                },
              ),
            ),
          const SizedBox(height: 6),
          if (profile.websiteUrl != null && profile.websiteUrl!.isNotEmpty)
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: theme.colorScheme.surfaceContainer,
              leading: const Icon(Icons.language),
              title: const Text('Website / Portfolio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(profile.websiteUrl!, style: const TextStyle(fontSize: 12)),
              trailing: IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: profile.websiteUrl!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Website link copied!'), duration: Duration(seconds: 1)),
                  );
                },
              ),
            ),
        ],

        if (profile.skills.isEmpty && profile.projects.isEmpty && profile.bio == null && profile.resumeUrl == null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No additional portfolio information provided.',
                style: TextStyle(color: theme.colorScheme.outline),
              ),
            ),
          ),
      ],
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this._tabBar, {required this.backgroundColor});

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
