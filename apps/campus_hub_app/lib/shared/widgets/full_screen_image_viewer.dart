import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/services/media_storage_service.dart';
import '../../features/chat/presentation/widgets/download_media_button.dart';
import 'campus_network_image.dart';

class FullScreenImageData {
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final String? heroTag;
  final Uint8List? bytes;
  final String? filePath;
  final String? blurredThumbnailUrl;
  final bool isDownloaded;
  final String? messageId;

  const FullScreenImageData({
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.heroTag,
    this.bytes,
    this.filePath,
    this.blurredThumbnailUrl,
    this.isDownloaded = true,
    this.messageId,
  });

  factory FullScreenImageData.fromUrl(
    String url, {
    String? title,
    String? subtitle,
    String? heroTag,
    bool isDownloaded = true,
    String? messageId,
  }) {
    return FullScreenImageData(
      imageUrl: url,
      title: title,
      subtitle: subtitle,
      heroTag: heroTag,
      isDownloaded: isDownloaded,
      messageId: messageId,
    );
  }
}

class FullScreenImageViewer extends StatefulWidget {
  final List<FullScreenImageData> images;
  final int initialIndex;
  final String? customTitle;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.customTitle,
  }) : assert(images.length > 0, 'Must provide at least one image');

  static Future<void> open(
    BuildContext context, {
    required List<FullScreenImageData> images,
    int initialIndex = 0,
    String? customTitle,
  }) {
    if (images.isEmpty) return Future.value();
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (ctx, animation, secondaryAnimation) => FullScreenImageViewer(
          images: images,
          initialIndex: initialIndex,
          customTitle: customTitle,
        ),
        transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  static Future<void> openSingle(
    BuildContext context, {
    required String imageUrl,
    String? heroTag,
    String? title,
    String? subtitle,
    String? filePath,
    bool isDownloaded = true,
    String? messageId,
  }) {
    return open(
      context,
      images: [
        FullScreenImageData(
          imageUrl: imageUrl,
          heroTag: heroTag,
          title: title,
          subtitle: subtitle,
          filePath: filePath,
          isDownloaded: isDownloaded,
          messageId: messageId,
        ),
      ],
      initialIndex: 0,
    );
  }

  static Future<void> openUrls(
    BuildContext context, {
    required List<String> urls,
    int initialIndex = 0,
    String? heroTagPrefix,
    String? titlePrefix,
  }) {
    final list = urls.asMap().entries.map((entry) {
      final idx = entry.key;
      final url = entry.value;
      return FullScreenImageData(
        imageUrl: url,
        heroTag: heroTagPrefix != null ? '${heroTagPrefix}_$idx' : null,
        title: titlePrefix != null ? '$titlePrefix ${idx + 1}' : null,
      );
    }).toList();

    return open(
      context,
      images: list,
      initialIndex: initialIndex,
    );
  }

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  bool _showOverlay = true;
  bool _isZoomed = false;
  double _dragOffsetY = 0.0;
  late AnimationController _dismissController;
  Animation<double>? _dragAnimation;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.images.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    _dismissController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        if (_dragAnimation != null) {
          setState(() {
            _dragOffsetY = _dragAnimation!.value;
          });
        }
      });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _dismissController.dispose();
    super.dispose();
  }

  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
    });
  }

  void _onZoomChanged(bool zoomed) {
    if (_isZoomed != zoomed) {
      setState(() {
        _isZoomed = zoomed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalImages = widget.images.length;
    final bgOpacity = (1.0 - (_dragOffsetY / 350.0)).clamp(0.0, 1.0);
    final overlayOpacity = _showOverlay ? (1.0 - (_dragOffsetY / 120.0)).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: bgOpacity),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Drag-to-dismiss gesture container
          GestureDetector(
            onVerticalDragStart: _isZoomed
                ? null
                : (details) {
                    _dismissController.stop();
                  },
            onVerticalDragUpdate: _isZoomed
                ? null
                : (details) {
                    if (details.delta.dy > 0 || _dragOffsetY > 0) {
                      setState(() {
                        _dragOffsetY = (_dragOffsetY + details.delta.dy).clamp(0.0, 500.0);
                      });
                    }
                  },
            onVerticalDragEnd: _isZoomed
                ? null
                : (details) {
                    if (_dragOffsetY > 110 || (details.primaryVelocity ?? 0) > 750) {
                      Navigator.of(context).pop();
                    } else if (_dragOffsetY > 0) {
                      _dragAnimation = Tween<double>(begin: _dragOffsetY, end: 0.0).animate(
                        CurvedAnimation(parent: _dismissController, curve: Curves.easeOutCubic),
                      );
                      _dismissController.forward(from: 0);
                    }
                  },
            child: Transform.translate(
              offset: Offset(0, _dragOffsetY),
              child: Transform.scale(
                scale: (1.0 - (_dragOffsetY / 1200.0)).clamp(0.75, 1.0),
                child: PageView.builder(
                  controller: _pageController,
                  physics: _isZoomed
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  itemCount: totalImages,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                      _isZoomed = false;
                    });
                  },
                  itemBuilder: (context, index) {
                    final imgData = widget.images[index];
                    return _ZoomableImageItem(
                      key: ValueKey('zoom_img_${imgData.imageUrl}_$index'),
                      imageData: imgData,
                      onTap: _toggleOverlay,
                      onZoomChanged: _onZoomChanged,
                    );
                  },
                ),
              ),
            ),
          ),

          // Minimal Top Header & Back Button Overlay
          if (overlayOpacity > 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: overlayOpacity,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    bottom: 12,
                    left: 16,
                    right: 16,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black54,
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.black38,
                        radius: 20,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const Spacer(),
                      if (totalImages > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: Text(
                            '${_currentIndex + 1} / $totalImages',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // Minimal Bottom Dots Indicator for Multi-Image Galleries
          if (totalImages > 1 && totalImages <= 10 && overlayOpacity > 0)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: overlayOpacity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalImages, (idx) {
                    final isActive = idx == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 6,
                      width: isActive ? 16 : 6,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.white38,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ZoomableImageItem extends StatefulWidget {
  final FullScreenImageData imageData;
  final VoidCallback onTap;
  final ValueChanged<bool> onZoomChanged;

  const _ZoomableImageItem({
    super.key,
    required this.imageData,
    required this.onTap,
    required this.onZoomChanged,
  });

  @override
  State<_ZoomableImageItem> createState() => _ZoomableImageItemState();
}

class _ZoomableImageItemState extends State<_ZoomableImageItem>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  TapDownDetails? _doubleTapDetails;
  bool _isZoomed = false;
  String? _downloadedLocalPath;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);

    if (widget.imageData.filePath != null && !kIsWeb) {
      if (File(widget.imageData.filePath!).existsSync()) {
        _downloadedLocalPath = widget.imageData.filePath;
      }
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        if (_animation != null) {
          _transformationController.value = _animation!.value;
        }
      });
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.05;
    if (_isZoomed != zoomed) {
      setState(() {
        _isZoomed = zoomed;
      });
      widget.onZoomChanged(zoomed);
    }
  }

  void _handleDoubleTap() {
    final matrix = _transformationController.value;
    final currentScale = matrix.getMaxScaleOnAxis();

    Matrix4 endMatrix;

    if (currentScale > 1.2) {
      // Zoom out to normal
      endMatrix = Matrix4.identity();
    } else {
      // Zoom in to 2.5x centered at double-tap position
      final position = _doubleTapDetails?.localPosition ?? const Offset(0, 0);
      final double x = -position.dx * 1.5;
      final double y = -position.dy * 1.5;

      endMatrix = Matrix4.identity()
        ..translateByDouble(x, y, 0.0, 1.0)
        ..scaleByDouble(2.5, 2.5, 1.0, 1.0);
    }

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.imageData;
    final isLocallyAvailable = (_downloadedLocalPath != null && File(_downloadedLocalPath!).existsSync()) ||
        (data.filePath != null && File(data.filePath!).existsSync());

    // If receiver has not downloaded the image and local file does not exist:
    // Show only blurred preview and Download button. Original clear image is NEVER requested.
    if (!data.isDownloaded && !isLocallyAvailable && data.bytes == null) {
      final blurredUrl = data.blurredThumbnailUrl ?? MediaStorageService.getBlurredThumbnailUrl(data.imageUrl);

      return Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: CampusNetworkImage(
                imageUrl: blurredUrl,
                fit: BoxFit.contain,
                cacheWidth: 100,
                cacheHeight: 100,
              ),
            ),
            Container(color: Colors.black45),
            if (data.messageId != null)
              DownloadMediaButton(
                messageId: data.messageId!,
                imageUrl: data.imageUrl,
                fileName: data.title,
                onDownloadComplete: () {
                  final storage = MediaStorageService();
                  final path = storage.getDownloadedPathForMessage(data.messageId!);
                  if (path != null && mounted) {
                    setState(() {
                      _downloadedLocalPath = path;
                    });
                  }
                },
              ),
          ],
        ),
      );
    }

    Widget imageContent;

    if (data.bytes != null) {
      imageContent = Image.memory(
        data.bytes!,
        fit: BoxFit.contain,
      );
    } else if (_downloadedLocalPath != null && !kIsWeb && File(_downloadedLocalPath!).existsSync()) {
      imageContent = Image.file(
        File(_downloadedLocalPath!),
        fit: BoxFit.contain,
      );
    } else if (data.filePath != null && !kIsWeb && File(data.filePath!).existsSync()) {
      imageContent = Image.file(
        File(data.filePath!),
        fit: BoxFit.contain,
      );
    } else {
      // Clear image for sender
      imageContent = CampusNetworkImage(
        imageUrl: data.imageUrl,
        fit: BoxFit.contain,
        placeholder: const Center(
          child: SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          ),
        ),
        errorWidget: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image_outlined, size: 56, color: Colors.white54),
              const SizedBox(height: 12),
              const Text(
                'Unable to load full-resolution image',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  setState(() {});
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    Widget content = Center(
      child: data.heroTag != null && data.heroTag!.isNotEmpty
          ? Hero(
              tag: data.heroTag!,
              child: imageContent,
            )
          : imageContent,
    );

    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTapDown: (details) => _doubleTapDetails = details,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1.0,
        maxScale: 4.5,
        panEnabled: _isZoomed,
        scaleEnabled: true,
        child: content,
      ),
    );
  }
}
