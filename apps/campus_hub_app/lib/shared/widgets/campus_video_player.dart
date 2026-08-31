import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/api_endpoints.dart';

class CampusVideoPlayer extends StatefulWidget {
  final String? videoUrl;
  final String? filePath;
  final bool autoPlay;
  final bool looping;
  final bool showControls;
  final double? aspectRatio;
  final BorderRadius? borderRadius;

  const CampusVideoPlayer({
    super.key,
    this.videoUrl,
    this.filePath,
    this.autoPlay = false,
    this.looping = false,
    this.showControls = true,
    this.aspectRatio,
    this.borderRadius,
  }) : assert(videoUrl != null || filePath != null, 'Provide either videoUrl or filePath');

  @override
  State<CampusVideoPlayer> createState() => _CampusVideoPlayerState();
}

class _CampusVideoPlayerState extends State<CampusVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControlsOverlay = true;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant CampusVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl || oldWidget.filePath != widget.filePath) {
      _controller?.dispose();
      _isInitialized = false;
      _hasError = false;
      _initController();
    }
  }

  Future<void> _initController() async {
    try {
      if (widget.filePath != null && widget.filePath!.isNotEmpty && !kIsWeb) {
        _controller = VideoPlayerController.file(File(widget.filePath!));
      } else if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
        final resolved = ApiEndpoints.resolveUrl(widget.videoUrl!);
        _controller = VideoPlayerController.networkUrl(Uri.parse(resolved));
      }

      if (_controller != null) {
        await _controller!.initialize();
        _controller!.setLooping(widget.looping);
        if (widget.autoPlay) {
          _controller!.play();
        }
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content;

    if (_hasError) {
      content = Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: widget.borderRadius,
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off, color: Colors.white70, size: 36),
              SizedBox(height: 8),
              Text(
                'Unable to play video',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    } else if (!_isInitialized || _controller == null) {
      content = Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: widget.borderRadius,
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    } else {
      final aspect = widget.aspectRatio ?? _controller!.value.aspectRatio;

      content = GestureDetector(
        onTap: () {
          setState(() {
            _showControlsOverlay = !_showControlsOverlay;
          });
        },
        child: AspectRatio(
          aspectRatio: aspect > 0 ? aspect : 16 / 9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller!),

              // Controls Overlay
              if (widget.showControls)
                AnimatedOpacity(
                  opacity: _showControlsOverlay || !_controller!.value.isPlaying ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: widget.borderRadius,
                    ),
                    child: Stack(
                      children: [
                        // Center Play / Pause Button
                        Center(
                          child: IconButton(
                            iconSize: 52,
                            icon: Icon(
                              _controller!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                if (_controller!.value.isPlaying) {
                                  _controller!.pause();
                                } else {
                                  _controller!.play();
                                }
                              });
                            },
                          ),
                        ),

                        // Bottom Scrubber Bar & Timers
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 8,
                          child: ValueListenableBuilder(
                            valueListenable: _controller!,
                            builder: (context, VideoPlayerValue value, child) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  VideoProgressIndicator(
                                    _controller!,
                                    allowScrubbing: true,
                                    colors: VideoProgressColors(
                                      playedColor: theme.colorScheme.primary,
                                      bufferedColor: Colors.white38,
                                      backgroundColor: Colors.white24,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(value.position),
                                        style: const TextStyle(color: Colors.white, fontSize: 11),
                                      ),
                                      Text(
                                        _formatDuration(value.duration),
                                        style: const TextStyle(color: Colors.white, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: content,
      );
    }

    return content;
  }
}
