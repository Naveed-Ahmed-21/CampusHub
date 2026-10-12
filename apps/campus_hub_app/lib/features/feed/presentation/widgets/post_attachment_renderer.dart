import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/campus_download_service.dart';
import '../../../../shared/widgets/campus_network_image.dart';
import '../../../../shared/widgets/full_screen_image_viewer.dart';
import '../../../../shared/widgets/full_screen_video_viewer.dart';
import '../../domain/models/post_item.dart';

class PostAttachmentRenderer extends StatefulWidget {
  final List<PostAttachmentItem> attachments;
  final String? postAuthorName;

  const PostAttachmentRenderer({
    super.key,
    required this.attachments,
    this.postAuthorName,
  });

  @override
  State<PostAttachmentRenderer> createState() => _PostAttachmentRendererState();
}

class _PostAttachmentRendererState extends State<PostAttachmentRenderer> {
  int _currentCarouselIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
        subtitle: widget.postAuthorName != null ? 'Posted by ${widget.postAuthorName}' : null,
      );
    }).toList();

    FullScreenImageViewer.open(
      context,
      images: galleryImages,
      initialIndex: initialIndex,
    );
  }

  void _openVideoViewer(BuildContext context, String videoUrl, String fileName) {
    FullScreenVideoViewer.open(
      context,
      videoUrl: videoUrl,
      title: fileName,
      authorName: widget.postAuthorName,
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
          FilledButton.tonalIcon(
            onPressed: () {
              CampusDownloadService.downloadResource(
                context: context,
                fileUrl: resolvedUrl,
                fileName: fileName,
                subFolder: 'Documents',
              );
            },
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Download', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(60, 32),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleImage(BuildContext context, PostAttachmentItem img) {
    final heroTag = 'post_img_${img.id.isNotEmpty ? img.id : 0}_${img.fileUrl.hashCode}';
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onTap: () => _openImageViewer(context, [img], 0),
          child: Hero(
            tag: heroTag,
            child: CampusNetworkImage(
              imageUrl: img.fileUrl,
              height: 260,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSingleVideo(BuildContext context, PostAttachmentItem video) {
    final resolvedUrl = ApiEndpoints.resolveUrl(video.fileUrl);
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onTap: () => _openVideoViewer(context, resolvedUrl, video.fileName),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CampusNetworkImage(
                  imageUrl: resolvedUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    color: Colors.black87,
                    child: const Center(
                      child: Icon(Icons.videocam_rounded, size: 48, color: Colors.white54),
                    ),
                  ),
                ),
                Container(
                  color: Colors.black.withValues(alpha: 0.25),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1.5),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'VIDEO',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMixedMediaCarousel(BuildContext context, List<PostAttachmentItem> visualMedia) {
    final total = visualMedia.length;
    final imagesOnly = visualMedia.where(_isImage).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 280,
          color: Colors.black87,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: total,
                onPageChanged: (idx) {
                  setState(() {
                    _currentCarouselIndex = idx;
                  });
                },
                itemBuilder: (ctx, index) {
                  final item = visualMedia[index];
                  final isVid = _isVideo(item);

                  if (isVid) {
                    final resolvedUrl = ApiEndpoints.resolveUrl(item.fileUrl);
                    return GestureDetector(
                      onTap: () => _openVideoViewer(context, resolvedUrl, item.fileName),
                      child: Stack(
                        fit: StackFit.expand,
                        alignment: Alignment.center,
                        children: [
                          CampusNetworkImage(
                            imageUrl: resolvedUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorWidget: Container(
                              color: Colors.black87,
                              child: const Center(
                                child: Icon(Icons.videocam_rounded, size: 48, color: Colors.white54),
                              ),
                            ),
                          ),
                          Container(color: Colors.black.withValues(alpha: 0.3)),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24, width: 1.5),
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.videocam, color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'VIDEO',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    final imageIdx = imagesOnly.indexOf(item);
                    return GestureDetector(
                      onTap: () => _openImageViewer(
                        context,
                        imagesOnly,
                        imageIdx >= 0 ? imageIdx : 0,
                      ),
                      child: CampusNetworkImage(
                        imageUrl: item.fileUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    );
                  }
                },
              ),

              // Page indicator counter pill in top-right
              Positioned(
                top: 10,
                right: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      color: Colors.black.withValues(alpha: 0.55),
                      child: Text(
                        '${_currentCarouselIndex + 1} / $total',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom dot indicators
              if (total > 1)
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(total, (i) {
                      final isSelected = i == _currentCarouselIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        height: 5,
                        width: isSelected ? 16 : 5,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
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
    if (widget.attachments.isEmpty) return const SizedBox.shrink();

    final visualMedia = widget.attachments.where((a) => _isImage(a) || _isVideo(a)).toList();
    final documents = widget.attachments.where((a) => !_isImage(a) && !_isVideo(a)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Visual Media (Single or Slidable Carousel)
        if (visualMedia.length == 1) ...[
          if (_isImage(visualMedia.first))
            _buildSingleImage(context, visualMedia.first)
          else
            _buildSingleVideo(context, visualMedia.first),
        ] else if (visualMedia.length > 1) ...[
          _buildMixedMediaCarousel(context, visualMedia),
        ],

        // Document / PDF / Archive Attachments
        if (documents.isNotEmpty)
          ...documents.map((doc) => _buildDocumentCard(context, doc)),
      ],
    );
  }
}
