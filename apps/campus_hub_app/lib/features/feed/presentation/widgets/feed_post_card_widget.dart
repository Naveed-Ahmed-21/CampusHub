import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/post_item.dart';
import '../controllers/feed_controller.dart';

class FeedPostCardWidget extends ConsumerStatefulWidget {
  final PostItem post;
  final VoidCallback onOpenComments;

  const FeedPostCardWidget({
    super.key,
    required this.post,
    required this.onOpenComments,
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

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day} May • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '2h ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post;

    final isEventPromo = post.type == 'EVENT_PROMO' || post.title.toLowerCase().contains('event') || post.title.toLowerCase().contains('ai');
    final hasAttachments = post.attachments.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 0.5),
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER ROW (Avatar, Name, Verification, Subtitle, Menu)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.indigo.shade900,
                  backgroundImage: post.author.avatarUrl != null ? NetworkImage(post.author.avatarUrl!) : null,
                  child: post.author.avatarUrl == null
                      ? Text(
                          post.author.name.isNotEmpty ? post.author.name[0].toUpperCase() : 'C',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.author.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Colors.blue, size: 16),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatDate(post.createdAt)} • GCEE Campus',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.grey),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post options')),
                    );
                  },
                ),
              ],
            ),
          ),

          // 2. TEXT CONTENT & BLUE HASHTAGS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.content,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: const [
                    Text('#TechTalk', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('#AI', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('#CampusHub', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('#GCEECampus', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. RICH MEDIA BANNER / EVENT OVERLAY CARD
          if (hasAttachments || isEventPromo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Background Image
                    Image.network(
                      hasAttachments ? post.attachments.first.fileUrl : 'https://images.unsplash.com/photo-1562774053-701939374585',
                      height: 260,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 220,
                        color: Colors.indigo.shade900,
                        child: const Center(
                          child: Icon(Icons.apartment, size: 64, color: Colors.white70),
                        ),
                      ),
                    ),

                    // Dark Gradient Overlay for text contrast
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.1),
                              Colors.black.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),

                    // Media Counter (Top Right e.g. 1/3)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '1/3',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    // Overlaid Event Info Text & Metadata
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tag Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Tech Talk',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            post.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          // Metadata Row (Date, Time, Location)
                          Row(
                            children: const [
                              Icon(Icons.calendar_today, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('16 May, 2025', style: TextStyle(color: Colors.white, fontSize: 12)),
                              SizedBox(width: 12),
                              Icon(Icons.access_time, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('10:00 AM', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: const [
                              Icon(Icons.location_on_outlined, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Seminar Hall', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. ACTION BAR (Like, Comment, Share, Save)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        post.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: post.isLiked ? Colors.red : Colors.black87,
                        size: 24,
                      ),
                      onPressed: () => ref.read(feedControllerProvider.notifier).toggleLike(post.id),
                    ),
                    Text('${post.likesCount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.black87, size: 22),
                      onPressed: widget.onOpenComments,
                    ),
                    Text('${post.commentsCount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.send_outlined, color: Colors.black87, size: 22),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share link copied to clipboard!')),
                        );
                      },
                    ),
                    const Text('8', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: post.isSaved ? theme.colorScheme.primary : Colors.black87,
                    size: 24,
                  ),
                  onPressed: () => ref.read(feedControllerProvider.notifier).toggleSave(post.id),
                ),
              ],
            ),
          ),

          // 5. LIKED BY & COMMENT ENGAGEMENT INFO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 44,
                      height: 20,
                      child: Stack(
                        children: const [
                          Positioned(
                            left: 0,
                            child: CircleAvatar(radius: 9, backgroundColor: Colors.indigo, child: Text('R', style: TextStyle(fontSize: 8, color: Colors.white))),
                          ),
                          Positioned(
                            left: 10,
                            child: CircleAvatar(radius: 9, backgroundColor: Colors.teal, child: Text('A', style: TextStyle(fontSize: 8, color: Colors.white))),
                          ),
                          Positioned(
                            left: 20,
                            child: CircleAvatar(radius: 9, backgroundColor: Colors.orange, child: Text('S', style: TextStyle(fontSize: 8, color: Colors.white))),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black87, fontSize: 13),
                        children: const [
                          TextSpan(text: 'Liked by '),
                          TextSpan(text: 'rahul_08', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: ' and others'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: widget.onOpenComments,
                  child: Text(
                    'View all ${post.commentsCount} comments',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 10),

                // Compact Comment Input Bar
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.teal,
                      child: Text('N', style: TextStyle(fontSize: 10, color: Colors.white)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _commentCtrl,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const Text('🔥', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    const Text('🙌', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        final text = _commentCtrl.text.trim();
                        if (text.isNotEmpty) {
                          ref.read(feedControllerProvider.notifier).addComment(post.id, text);
                          _commentCtrl.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Comment added!')),
                          );
                        }
                      },
                      child: const Icon(Icons.add_circle_outline, color: Colors.grey, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}
