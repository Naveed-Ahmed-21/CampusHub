import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/models/post_item.dart';
import '../controllers/feed_controller.dart';
import 'post_attachment_renderer.dart';

class FeedPostCardWidget extends ConsumerStatefulWidget {
  final PostItem post;
  final VoidCallback onOpenComments;
  final VoidCallback? onPostDeleted;

  const FeedPostCardWidget({
    super.key,
    required this.post,
    required this.onOpenComments,
    this.onPostDeleted,
  });

  @override
  ConsumerState<FeedPostCardWidget> createState() => _FeedPostCardWidgetState();
}

class _FeedPostCardWidgetState extends ConsumerState<FeedPostCardWidget> {
  final TextEditingController _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  String _formatDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getRoleBadgeColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
      case 'COLLEGE_ADMIN':
      case 'SUPER_ADMIN':
        return Colors.red.shade700;
      case 'FACULTY':
      case 'DEPT_ADMIN':
        return Colors.purple.shade700;
      case 'PLACEMENT_OFFICER':
        return Colors.amber.shade800;
      default:
        return Colors.teal.shade700;
    }
  }

  Color _getPostTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'ANNOUNCEMENT':
        return Colors.red.shade600;
      case 'ACADEMIC':
        return Colors.indigo.shade600;
      case 'EVENT_PROMO':
        return Colors.orange.shade700;
      case 'PLACEMENT':
        return Colors.green.shade700;
      default:
        return Colors.blue.shade600;
    }
  }

  void _showEditPostDialog(BuildContext context, PostItem post) {
    final editTitleCtrl = TextEditingController(text: post.title);
    final editContentCtrl = TextEditingController(text: post.content);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.edit_note, color: Colors.blue),
              SizedBox(width: 8),
              Text('Edit Post'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: editTitleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Post Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: editContentCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Post Content',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final newTitle = editTitleCtrl.text.trim();
                      final newContent = editContentCtrl.text.trim();
                      if (newContent.isEmpty) return;

                      setDialogState(() => isSaving = true);
                      await ref.read(feedControllerProvider.notifier).updatePost(
                            post.id,
                            title: newTitle.isNotEmpty ? newTitle : newContent,
                            content: newContent,
                          );

                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Post updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, PostItem post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Post?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(feedControllerProvider.notifier).deletePost(post.id);
              widget.onPostDeleted?.call();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Post deleted successfully.'),
                    backgroundColor: Colors.black87,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showPostStatsSheet(BuildContext context, PostItem post) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Post Insights & Details', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.favorite, color: Colors.red, size: 24),
                        const SizedBox(height: 4),
                        Text('${post.likesCount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Text('Likes', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.chat_bubble, color: Colors.blue, size: 24),
                        const SizedBox(height: 4),
                        Text('${post.commentsCount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Text('Comments', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.attach_file, color: Colors.teal, size: 24),
                        const SizedBox(height: 4),
                        Text('${post.attachments.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Text('Attachments', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.category_outlined, color: Colors.indigo),
              title: const Text('Post Scope'),
              subtitle: Text(post.type),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule, color: Colors.orange),
              title: const Text('Published Date & Time'),
              subtitle: Text(post.createdAt),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline, color: Colors.purple),
              title: const Text('Author'),
              subtitle: Text('${post.author.name} (${post.author.role})'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAuthorDetails(BuildContext context, PostAuthorItem author) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        title: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: _getRoleBadgeColor(author.role).withValues(alpha: 0.15),
              backgroundImage: author.avatarUrl != null && author.avatarUrl!.isNotEmpty
                  ? NetworkImage(ApiEndpoints.resolveUrl(author.avatarUrl!))
                  : null,
              child: author.avatarUrl == null || author.avatarUrl!.isEmpty
                  ? Text(
                      author.name.isNotEmpty ? author.name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _getRoleBadgeColor(author.role),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getRoleBadgeColor(author.role).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      author.role,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: _getRoleBadgeColor(author.role),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),
            Text(
              "User ID",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      author.id,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    tooltip: 'Copy User ID',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: author.id));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('User ID copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.person_outline, size: 16),
                  label: const Text('View Profile'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    if (author.id.isNotEmpty) {
                      context.push('/profile/${author.id}');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPostOptionsMenu(BuildContext context) {
    final user = ref.read(authControllerProvider).asData?.value;
    final post = widget.post;
    final isClubPost = post.clubId != null && post.clubId!.isNotEmpty;

    // For club posts, only admins (or club leaders) can modify/delete. For personal posts, author or admin can.
    final isAuthor = user != null &&
        (user.isAdmin ||
            (!isClubPost && (user.id == post.author.id || (user.firstName.isNotEmpty && post.author.name.contains(user.firstName)))) ||
            (isClubPost && user.isAdmin));

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 1. Post Insights
              ListTile(
                leading: const Icon(Icons.analytics_outlined, color: Colors.blue),
                title: const Text('Post Insights & Details'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showPostStatsSheet(context, post);
                },
              ),

              // 2. Edit Post (Author/Admin only)
              if (isAuthor)
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: Colors.orange),
                  title: const Text('Edit Post'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showEditPostDialog(context, post);
                  },
                ),

              // 3. Delete Post (Author/Admin only)
              if (isAuthor)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Delete Post', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showDeleteConfirmDialog(context, post);
                  },
                ),

              // 4. Bookmark/Save Post
              ListTile(
                leading: Icon(post.isSaved ? Icons.bookmark : Icons.bookmark_border, color: Colors.purple),
                title: Text(post.isSaved ? 'Remove from Saved' : 'Save Post'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ref.read(feedControllerProvider.notifier).toggleSave(post.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(post.isSaved ? 'Post removed from saved.' : 'Post saved!')),
                  );
                },
              ),

              // 5. Share Post
              ListTile(
                leading: const Icon(Icons.share_outlined, color: Colors.teal),
                title: const Text('Share Post Link'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Clipboard.setData(ClipboardData(text: '${ApiEndpoints.baseUrl}/api/v1/posts/${post.id}'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post link copied to clipboard!')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post;
    final hasAttachments = post.attachments.isNotEmpty;
    final isClubPost = post.clubId != null && post.clubId!.isNotEmpty;
    final displayName = isClubPost ? (post.clubName ?? 'Club') : post.author.name;
    final displayRole = isClubPost ? (post.clubCategory ?? 'CLUB') : post.author.role;
    final badgeColor = isClubPost ? Colors.indigo.shade700 : _getRoleBadgeColor(post.author.role);
    final avatarUrl = isClubPost ? post.clubLogoUrl : post.author.avatarUrl;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. POST AUTHOR / CLUB HEADER
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (isClubPost) {
                      context.push('/clubs/${post.clubId}');
                    } else if (post.author.id.isNotEmpty) {
                      context.push('/profile/${post.author.id}');
                    }
                  },
                  onLongPress: isClubPost ? null : () => _showAuthorDetails(context, post.author),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: badgeColor.withValues(alpha: 0.15),
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(ApiEndpoints.resolveUrl(avatarUrl))
                        : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? (isClubPost
                            ? Icon(Icons.groups_rounded, color: badgeColor, size: 22)
                            : Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                style: TextStyle(
                                  color: badgeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ))
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: GestureDetector(
                              onTap: () {
                                if (isClubPost) {
                                  context.push('/clubs/${post.clubId}');
                                } else if (post.author.id.isNotEmpty) {
                                  context.push('/profile/${post.author.id}');
                                }
                              },
                              onLongPress: isClubPost ? null : () => _showAuthorDetails(context, post.author),
                              child: Text(
                                displayName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: badgeColor.withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isClubPost) ...[
                                  Icon(Icons.verified, size: 11, color: badgeColor),
                                  const SizedBox(width: 3),
                                ],
                                Text(
                                  displayRole,
                                  style: TextStyle(
                                    color: badgeColor,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            _formatDate(post.createdAt),
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: _getPostTypeColor(post.type).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              post.type,
                              style: TextStyle(
                                color: _getPostTypeColor(post.type),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (post.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Icon(Icons.push_pin, size: 18, color: theme.colorScheme.primary),
                  ),

                // Post Options Menu Button
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.grey),
                  onPressed: () => _showPostOptionsMenu(context),
                ),
              ],
            ),
          ),

          // 2. POST TITLE & CONTENT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.title.isNotEmpty && post.title != post.content)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Text(
                      post.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ),
                Text(
                  post.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // 3. REAL ATTACHMENTS (Images, Videos, Documents/PDFs)
          if (hasAttachments)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: PostAttachmentRenderer(
                attachments: post.attachments,
                postAuthorName: post.author.name,
              ),
            ),

          const SizedBox(height: 6),

          // 4. ACTION BAR (Like, Comment, Share, Save)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Like Button
                    IconButton(
                      icon: Icon(
                        post.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: post.isLiked ? Colors.red : theme.colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                      onPressed: () => ref.read(feedControllerProvider.notifier).toggleLike(post.id),
                    ),
                    Text(
                      '${post.likesCount}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Comment Button
                    IconButton(
                      icon: Icon(Icons.chat_bubble_outline, color: theme.colorScheme.onSurfaceVariant, size: 21),
                      onPressed: widget.onOpenComments,
                    ),
                    Text(
                      '${post.commentsCount}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Share Button
                    IconButton(
                      icon: Icon(Icons.share_outlined, color: theme.colorScheme.onSurfaceVariant, size: 21),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: '${ApiEndpoints.baseUrl}/api/v1/posts/${post.id}'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Post link copied to clipboard!')),
                        );
                      },
                    ),
                  ],
                ),
                // Save Button
                IconButton(
                  icon: Icon(
                    post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: post.isSaved ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                  onPressed: () => ref.read(feedControllerProvider.notifier).toggleSave(post.id),
                ),
              ],
            ),
          ),

          // 5. QUICK INLINE COMMENT BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _commentCtrl,
                      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(color: theme.colorScheme.outline, fontSize: 12.5),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onSubmitted: (val) {
                        final text = val.trim();
                        if (text.isNotEmpty) {
                          ref.read(feedControllerProvider.notifier).addComment(post.id, text);
                          _commentCtrl.clear();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, size: 20, color: Colors.blue),
                  onPressed: () {
                    final text = _commentCtrl.text.trim();
                    if (text.isNotEmpty) {
                      ref.read(feedControllerProvider.notifier).addComment(post.id, text);
                      _commentCtrl.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Comment posted!')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
