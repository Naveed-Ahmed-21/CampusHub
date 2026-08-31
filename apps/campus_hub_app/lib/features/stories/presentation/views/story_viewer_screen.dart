import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/widgets/campus_network_image.dart';
import '../../../../shared/widgets/campus_video_player.dart';
import '../../domain/story_model.dart';
import '../providers/stories_provider.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  final List<UserStoriesGroup> storyGroups;
  final int initialGroupIndex;

  const StoryViewerScreen({
    super.key,
    required this.storyGroups,
    this.initialGroupIndex = 0,
  });

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late int _currentGroupIndex;
  late int _currentStoryIndex;
  late AnimationController _progressController;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _currentGroupIndex = widget.initialGroupIndex.clamp(0, widget.storyGroups.length - 1);
    _currentStoryIndex = 0;

    _progressController = AnimationController(vsync: this);
    _startCurrentStory();
  }

  void _startCurrentStory() {
    _progressController.stop();
    _progressController.reset();

    final currentStory = _getCurrentStory();
    if (currentStory == null) {
      Navigator.of(context).pop();
      return;
    }

    final durationSecs = currentStory.duration > 0 ? currentStory.duration : 5;
    _progressController.duration = Duration(seconds: durationSecs);

    // Mark current story as viewed
    ref.read(storiesControllerProvider.notifier).markStoryViewed(currentStory.id);

    _progressController.forward().whenComplete(() {
      if (mounted) {
        _nextStory();
      }
    });
  }

  StoryItemModel? _getCurrentStory() {
    if (_currentGroupIndex >= widget.storyGroups.length) return null;
    final group = widget.storyGroups[_currentGroupIndex];
    if (_currentStoryIndex >= group.stories.length) return null;
    return group.stories[_currentStoryIndex];
  }

  void _nextStory() {
    final group = widget.storyGroups[_currentGroupIndex];
    if (_currentStoryIndex < group.stories.length - 1) {
      setState(() {
        _currentStoryIndex++;
      });
      _startCurrentStory();
    } else if (_currentGroupIndex < widget.storyGroups.length - 1) {
      setState(() {
        _currentGroupIndex++;
        _currentStoryIndex = 0;
      });
      _startCurrentStory();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
      });
      _startCurrentStory();
    } else if (_currentGroupIndex > 0) {
      setState(() {
        _currentGroupIndex--;
        _currentStoryIndex = widget.storyGroups[_currentGroupIndex].stories.length - 1;
      });
      _startCurrentStory();
    } else {
      _startCurrentStory();
    }
  }

  void _pause() {
    if (!_isPaused) {
      _isPaused = true;
      _progressController.stop();
    }
  }

  void _resume() {
    if (_isPaused) {
      _isPaused = false;
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    if (_currentGroupIndex >= widget.storyGroups.length) {
      return const SizedBox.shrink();
    }

    final currentGroup = widget.storyGroups[_currentGroupIndex];
    final currentStory = _getCurrentStory();

    if (currentStory == null) {
      return const SizedBox.shrink();
    }

    final resolvedMediaUrl = ApiEndpoints.resolveUrl(currentStory.mediaUrl);
    final isVideo = currentStory.mediaType.toUpperCase() == 'VIDEO';

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth * 0.35) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Story Media View
            Center(
              child: isVideo
                  ? CampusVideoPlayer(
                      videoUrl: resolvedMediaUrl,
                      autoPlay: true,
                      looping: true,
                      showControls: false,
                    )
                  : CampusNetworkImage(
                      imageUrl: resolvedMediaUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                      errorWidget: Container(
                        color: Colors.grey.shade900,
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 64, color: Colors.white54),
                        ),
                      ),
                    ),
            ),

            // 2. Top Vignette Gradient Overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 140,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // 3. Top Progress Indicators & Author Header
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Segmented Progress Bar
                    Row(
                      children: List.generate(currentGroup.stories.length, (index) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                height: 3,
                                color: Colors.white.withValues(alpha: 0.3),
                                child: index == _currentStoryIndex
                                    ? AnimatedBuilder(
                                        animation: _progressController,
                                        builder: (context, child) {
                                          return LinearProgressIndicator(
                                            value: _progressController.value,
                                            backgroundColor: Colors.transparent,
                                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: index < _currentStoryIndex
                                            ? Colors.white
                                            : Colors.transparent,
                                      ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),

                    // User Info Bar
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.teal.shade700,
                          backgroundImage: currentGroup.userAvatar != null &&
                                  currentGroup.userAvatar!.isNotEmpty
                              ? NetworkImage(ApiEndpoints.resolveUrl(currentGroup.userAvatar!))
                              : null,
                          child: currentGroup.userAvatar == null ||
                                  currentGroup.userAvatar!.isEmpty
                              ? Text(
                                  currentGroup.userName.isNotEmpty
                                      ? currentGroup.userName[0].toUpperCase()
                                      : 'C',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
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
                                      currentGroup.userName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.blue.withValues(alpha: 0.5), width: 0.8),
                                    ),
                                    child: Text(
                                      currentGroup.userRole,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _formatTimeAgo(currentStory.createdAt),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 24),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 4. Bottom Caption Overlay
            if (currentStory.caption != null && currentStory.caption!.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 32,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    currentStory.caption!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
