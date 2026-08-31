import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../domain/models/post_item.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../controllers/feed_controller.dart';

class PostCommentsSheet extends ConsumerStatefulWidget {
  final String postId;

  const PostCommentsSheet({
    super.key,
    required this.postId,
  });

  static Future<void> show(BuildContext context, String postId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PostCommentsSheet(postId: postId),
    );
  }

  @override
  ConsumerState<PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends ConsumerState<PostCommentsSheet> {
  final TextEditingController _commentCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  List<PostCommentItem> _comments = [];
  final Set<String> _expandedCommentIds = {};
  bool _isLoading = true;
  bool _isSending = false;
  PostCommentItem? _replyingTo;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _focusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    final result = await ref.read(feedRepositoryProvider).getComments(widget.postId);
    result.when(
      success: (data) {
        if (mounted) {
          setState(() {
            _comments = data;
            _isLoading = false;
          });
        }
      },
      failure: (_) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  void _onReplyTap(PostCommentItem comment) {
    setState(() {
      _replyingTo = comment;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  void _toggleReplies(String commentId) {
    setState(() {
      if (_expandedCommentIds.contains(commentId)) {
        _expandedCommentIds.remove(commentId);
      } else {
        _expandedCommentIds.add(commentId);
      }
    });
  }

  Future<void> _toggleCommentLike(String commentId, bool isReply, {String? parentId}) async {
    setState(() {
      if (!isReply) {
        _comments = _comments.map((c) {
          if (c.id == commentId) {
            final nextLiked = !c.isLiked;
            return c.copyWith(
              isLiked: nextLiked,
              likesCount: nextLiked ? c.likesCount + 1 : (c.likesCount > 0 ? c.likesCount - 1 : 0),
            );
          }
          return c;
        }).toList();
      } else if (parentId != null) {
        _comments = _comments.map((parent) {
          if (parent.id == parentId) {
            final updatedReplies = parent.replies.map((r) {
              if (r.id == commentId) {
                final nextLiked = !r.isLiked;
                return r.copyWith(
                  isLiked: nextLiked,
                  likesCount: nextLiked ? r.likesCount + 1 : (r.likesCount > 0 ? r.likesCount - 1 : 0),
                );
              }
              return r;
            }).toList();
            return parent.copyWith(replies: updatedReplies);
          }
          return parent;
        }).toList();
      }
    });

    await ref.read(feedRepositoryProvider).toggleCommentLike(commentId);
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    final parentId = _replyingTo?.id;

    final result = await ref.read(feedRepositoryProvider).addComment(
      widget.postId,
      text,
      parentCommentId: parentId,
    );

    result.when(
      success: (newComment) {
        if (mounted) {
          setState(() {
            _commentCtrl.clear();
            _isSending = false;
            if (parentId != null) {
              _expandedCommentIds.add(parentId); // auto-expand to show new reply
              _comments = _comments.map((parent) {
                if (parent.id == parentId) {
                  return parent.copyWith(
                    repliesCount: parent.repliesCount + 1,
                    replies: [...parent.replies, newComment],
                  );
                }
                return parent;
              }).toList();
            } else {
              _comments = [..._comments, newComment];
            }
            _replyingTo = null;
          });

          // Also refresh post list comments count
          ref.read(feedControllerProvider.notifier).refreshFeed();
        }
      },
      failure: (error) {
        if (mounted) {
          setState(() => _isSending = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to post comment: ${error.message}')),
          );
        }
      },
    );
  }

  void _navigateToProfile(BuildContext context, String userId) {
    if (userId.trim().isEmpty) return;
    context.push('/profile/${userId.trim()}');
  }

  void _showAuthorDetails(BuildContext context, PostAuthorItem author) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: author.avatarUrl != null && author.avatarUrl!.isNotEmpty
                  ? NetworkImage(ApiEndpoints.resolveUrl(author.avatarUrl!))
                  : null,
              child: author.avatarUrl == null || author.avatarUrl!.isEmpty
                  ? Text(
                      author.name.isNotEmpty ? author.name[0].toUpperCase() : 'U',
                      style: TextStyle(
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
                  Text(
                    author.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    author.role,
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
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
                    _navigateToProfile(context, author.id);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final totalCount = _comments.fold<int>(
      _comments.length,
      (sum, c) => sum + c.replies.length,
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Comments ($totalCount)',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Comments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.forum_outlined, size: 48, color: theme.colorScheme.outline),
                            const SizedBox(height: 12),
                            Text(
                              'No comments yet.',
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Start the conversation!',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _comments.length,
                        itemBuilder: (ctx, i) {
                          final comment = _comments[i];
                          return _buildCommentItem(comment, isReply: false);
                        },
                      ),
          ),

          // Replying to banner
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              child: Row(
                children: [
                  Icon(Icons.reply, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replying to @${_replyingTo!.author.name}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: _cancelReply,
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.close, size: 16),
                    ),
                  ),
                ],
              ),
            ),

          // Bottom Input Bar
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: bottomInset > 0 ? bottomInset + 10 : 16,
            ),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _commentCtrl,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 4,
                      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: _replyingTo != null
                            ? 'Reply to @${_replyingTo!.author.name}...'
                            : 'Write a comment...',
                        hintStyle: TextStyle(color: theme.colorScheme.outline, fontSize: 13.5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _submitComment(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  onPressed: _isSending ? null : _submitComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(PostCommentItem comment, {required bool isReply, String? parentId}) {
    final theme = Theme.of(context);
    final hasReplies = !isReply && comment.replies.isNotEmpty;
    final isExpanded = _expandedCommentIds.contains(comment.id);

    return Padding(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 8,
        left: isReply ? 40 : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar (tappable to view author profile, long-press for ID)
              GestureDetector(
                onTap: () => _navigateToProfile(context, comment.author.id),
                onLongPress: () => _showAuthorDetails(context, comment.author),
                child: CircleAvatar(
                  radius: isReply ? 14 : 17,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: comment.author.avatarUrl != null && comment.author.avatarUrl!.isNotEmpty
                      ? NetworkImage(ApiEndpoints.resolveUrl(comment.author.avatarUrl!))
                      : null,
                  child: comment.author.avatarUrl == null || comment.author.avatarUrl!.isEmpty
                      ? Text(
                          comment.author.name.isNotEmpty ? comment.author.name[0].toUpperCase() : 'U',
                          style: TextStyle(
                            fontSize: isReply ? 11 : 13,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 10),

              // Comment Content & Actions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header (Name + Time) - Name is tappable to navigate to profile
                    Row(
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: () => _navigateToProfile(context, comment.author.id),
                            onLongPress: () => _showAuthorDetails(context, comment.author),
                            child: Text(
                              comment.author.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(comment.createdAt),
                          style: TextStyle(color: theme.colorScheme.outline, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Content
                    Text(
                      comment.content,
                      style: TextStyle(fontSize: 13.5, color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 5),

                    // Actions row: Reply + Show/Hide replies
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _onReplyTap(
                            isReply && parentId != null
                                ? _comments.firstWhere((p) => p.id == parentId, orElse: () => comment)
                                : comment,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                            child: Text(
                              'Reply',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        if (hasReplies) ...[
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () => _toggleReplies(comment.id),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    isExpanded ? 'Hide replies' : 'Show replies (${comment.replies.length})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Like button at the end / trailing side of the comment row
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _toggleCommentLike(
                  comment.id,
                  isReply,
                  parentId: parentId,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        comment.isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: comment.isLiked ? Colors.red : theme.colorScheme.outline,
                      ),
                      if (comment.likesCount > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${comment.likesCount}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: comment.isLiked ? Colors.red : theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Render threaded replies only when expanded!
          if (hasReplies && isExpanded) ...[
            const SizedBox(height: 4),
            ...comment.replies.map((reply) => _buildCommentItem(
                  reply,
                  isReply: true,
                  parentId: comment.id,
                )),
          ],
        ],
      ),
    );
  }
}
