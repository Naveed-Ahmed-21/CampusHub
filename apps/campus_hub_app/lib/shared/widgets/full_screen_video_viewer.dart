import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/services/campus_download_service.dart';
import 'campus_video_player.dart';

class FullScreenVideoViewer extends StatefulWidget {
  final String videoUrl;
  final String? title;
  final String? subtitle;
  final String? authorName;

  const FullScreenVideoViewer({
    super.key,
    required this.videoUrl,
    this.title,
    this.subtitle,
    this.authorName,
  });

  static Future<void> open(
    BuildContext context, {
    required String videoUrl,
    String? title,
    String? subtitle,
    String? authorName,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.85),
        pageBuilder: (ctx, animation, secondaryAnimation) => FullScreenVideoViewer(
          videoUrl: videoUrl,
          title: title,
          subtitle: subtitle,
          authorName: authorName,
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

  @override
  State<FullScreenVideoViewer> createState() => _FullScreenVideoViewerState();
}

class _FullScreenVideoViewerState extends State<FullScreenVideoViewer> {
  bool _showOverlay = true;

  String _cleanDisplayTitle() {
    final raw = widget.title ?? '';
    if (raw.isEmpty) return 'Campus Video';
    // If it looks like a hash or raw UUID (e.g. ac6fb609-9c33...)
    final isUuidOrHash = RegExp(r'^[a-f0-9\-]{24,}', caseSensitive: false).hasMatch(raw);
    if (isUuidOrHash) {
      if (widget.authorName != null && widget.authorName!.isNotEmpty) {
        return 'Video by ${widget.authorName}';
      }
      return 'Campus Video';
    }
    return raw;
  }

  String _getDownloadFileName() {
    final raw = widget.title ?? '';
    if (raw.isNotEmpty && raw.toLowerCase().endsWith('.mp4')) {
      return raw;
    }
    return 'CampusHub_Video_${DateTime.now().millisecondsSinceEpoch}.mp4';
  }

  @override
  Widget build(BuildContext context) {
    final displayTitle = _cleanDisplayTitle();
    final resolvedUrl = ApiEndpoints.resolveUrl(widget.videoUrl);

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _showOverlay = !_showOverlay;
            });
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Main Video Player Centered
              Center(
                child: Hero(
                  tag: 'video_${widget.videoUrl.hashCode}',
                  child: CampusVideoPlayer(
                    videoUrl: resolvedUrl,
                    autoPlay: true,
                    looping: true,
                    showControls: true,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              // Sleek Top App Bar Overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: _showOverlay ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      MediaQuery.of(context).padding.top + 8,
                      16,
                      16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        // Glass Close / Back Button
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              color: Colors.white.withValues(alpha: 0.2),
                              child: IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title & Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                displayTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.subtitle != null || widget.authorName != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.subtitle ?? 'Posted by ${widget.authorName}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Download Button
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              color: Colors.white.withValues(alpha: 0.2),
                              child: IconButton(
                                icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                                tooltip: 'Save Video',
                                onPressed: () {
                                  CampusDownloadService.downloadResource(
                                    context: context,
                                    fileUrl: resolvedUrl,
                                    fileName: _getDownloadFileName(),
                                    subFolder: 'Videos',
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
