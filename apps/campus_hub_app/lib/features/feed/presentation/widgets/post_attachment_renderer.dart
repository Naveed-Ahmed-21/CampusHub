import 'package:flutter/material.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/widgets/campus_network_image.dart';
import '../../../../shared/widgets/campus_video_player.dart';
import '../../../../shared/widgets/full_screen_image_viewer.dart';
import '../../domain/models/post_item.dart';

class PostAttachmentRenderer extends StatelessWidget {
  final List<PostAttachmentItem> attachments;
  final String? postAuthorName;

  const PostAttachmentRenderer({
    super.key,
    required this.attachments,
    this.postAuthorName,
  });

  bool _isImage(PostAttachmentItem attachment) {
    final type = attachment.fileType.toLowerCase();
    final url = attachment.fileUrl.toLowerCase();
    final name = attachment.fileName.toLowerCase();
    return type.startsWith('image') ||
        url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.png') ||
        url.endsWith('.webp') ||
        url.endsWith('.gif') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.webp');
  }

  bool _isVideo(PostAttachmentItem attachment) {
    final type = attachment.fileType.toLowerCase();
    final url = attachment.fileUrl.toLowerCase();
    final name = attachment.fileName.toLowerCase();
    return type.startsWith('video') ||
        url.endsWith('.mp4') ||
        url.endsWith('.mov') ||
        url.endsWith('.webm') ||
        url.endsWith('.mkv') ||
        name.endsWith('.mp4') ||
        name.endsWith('.mov') ||
        name.endsWith('.webm');
  }

  void _openImageViewer(BuildContext context, List<PostAttachmentItem> imageAttachments, int initialIndex) {
    final galleryImages = imageAttachments.asMap().entries.map((entry) {
      final idx = entry.key;
      final att = entry.value;
      return FullScreenImageData(
        imageUrl: att.fileUrl,
        heroTag: 'post_img_${att.id.isNotEmpty ? att.id : idx}_${att.fileUrl.hashCode}',
        title: att.fileName.isNotEmpty ? att.fileName : 'Post Photo ${idx + 1}',
        subtitle: postAuthorName != null ? 'Posted by $postAuthorName' : null,
      );
    }).toList();

    FullScreenImageViewer.open(
      context,
      images: galleryImages,
      initialIndex: initialIndex,
    );
  }

  void _showVideoPlayerModal(BuildContext context, String videoUrl, String fileName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: const EdgeInsets.all(12),
        title: Row(
          children: [
            const Icon(Icons.videocam, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                fileName.isNotEmpty ? fileName : 'Campus Video',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CampusVideoPlayer(
              videoUrl: videoUrl,
              autoPlay: true,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, PostAttachmentItem attachment) {
    final theme = Theme.of(context);
    final resolvedUrl = ApiEndpoints.resolveUrl(attachment.fileUrl);
    final fileName = attachment.fileName.isNotEmpty ? attachment.fileName : 'Attachment File';
    final isPdf = fileName.toLowerCase().endsWith('.pdf') || attachment.fileType.contains('pdf');
    final isDoc = fileName.toLowerCase().endsWith('.doc') ||
        fileName.toLowerCase().endsWith('.docx') ||
        attachment.fileType.contains('word');
    final isZip = fileName.toLowerCase().endsWith('.zip') || fileName.toLowerCase().endsWith('.rar');

    IconData docIcon = Icons.insert_drive_file;
    Color docColor = Colors.blue;

    if (isPdf) {
      docIcon = Icons.picture_as_pdf;
      docColor = Colors.red.shade700;
    } else if (isDoc) {
      docIcon = Icons.description;
      docColor = Colors.blue.shade700;
    } else if (isZip) {
      docIcon = Icons.folder_zip;
      docColor = Colors.amber.shade800;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: docColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(docIcon, color: docColor, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isPdf ? 'PDF Document' : (isDoc ? 'Word Document' : 'Campus File Attachment'),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening $fileName ($resolvedUrl)'),
                  backgroundColor: theme.colorScheme.primary,
                ),
              );
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Open', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(60, 32),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesGrid(BuildContext context, List<PostAttachmentItem> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    if (images.length == 1) {
      final img = images.first;
      final heroTag = 'post_img_${img.id.isNotEmpty ? img.id : 0}_${img.fileUrl.hashCode}';
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GestureDetector(
            onTap: () => _openImageViewer(context, images, 0),
            child: Hero(
              tag: heroTag,
              child: CampusNetworkImage(
                imageUrl: img.fileUrl,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      );
    }

    if (images.length == 2) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: SizedBox(
          height: 180,
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                  child: GestureDetector(
                    onTap: () => _openImageViewer(context, images, 0),
                    child: CampusNetworkImage(
                      imageUrl: images[0].fileUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                  child: GestureDetector(
                    onTap: () => _openImageViewer(context, images, 1),
                    child: CampusNetworkImage(
                      imageUrl: images[1].fileUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3 or more images: Grid format
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 220,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: () => _openImageViewer(context, images, 0),
                  child: CampusNetworkImage(
                    imageUrl: images[0].fileUrl,
                    height: double.infinity,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openImageViewer(context, images, 1),
                        child: CampusNetworkImage(
                          imageUrl: images[1].fileUrl,
                          height: double.infinity,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openImageViewer(context, images, 2),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CampusNetworkImage(
                              imageUrl: images[2].fileUrl,
                              height: double.infinity,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            if (images.length > 3)
                              Container(
                                color: Colors.black54,
                                alignment: Alignment.center,
                                child: Text(
                                  '+${images.length - 3}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    final images = attachments.where(_isImage).toList();
    final videos = attachments.where(_isVideo).toList();
    final documents = attachments.where((a) => !_isImage(a) && !_isVideo(a)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Direct Image Attachments Grid
        _buildImagesGrid(context, images),

        // 2. Direct Video Attachments
        if (videos.isNotEmpty)
          ...videos.map(
            (v) => Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onTap: () => _showVideoPlayerModal(
                    context,
                    ApiEndpoints.resolveUrl(v.fileUrl),
                    v.fileName,
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CampusNetworkImage(
                          imageUrl: ApiEndpoints.resolveUrl(v.fileUrl),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: Container(
                            color: Colors.black87,
                            child: const Center(
                              child: Icon(Icons.video_library, size: 48, color: Colors.white54),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.videocam, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text('VIDEO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // 3. Document / PDF Attachments
        if (documents.isNotEmpty)
          ...documents.map((doc) => _buildDocumentCard(context, doc)),
      ],
    );
  }
}
