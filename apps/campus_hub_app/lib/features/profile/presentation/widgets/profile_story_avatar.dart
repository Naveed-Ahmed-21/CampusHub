import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../../../stories/presentation/providers/stories_provider.dart';
import '../../../stories/presentation/views/story_viewer_screen.dart';

/// Reusable profile avatar widget that displays a story ring when the user has
/// active 24-hour stories, allowing direct tapping to view stories, or falling back
/// to standard full-screen viewer or upload callbacks.
class ProfileStoryAvatar extends ConsumerWidget {
  final String userId;
  final String? avatarUrl;
  final String? name;
  final double radius;
  final String? heroTag;
  final VoidCallback? fallbackOnTap;
  final bool showCameraBadge;
  final VoidCallback? onCameraTap;

  const ProfileStoryAvatar({
    super.key,
    required this.userId,
    this.avatarUrl,
    this.name,
    this.radius = 42,
    this.heroTag,
    this.fallbackOnTap,
    this.showCameraBadge = false,
    this.onCameraTap,
  });

  void _openStoryViewer(
    BuildContext context,
    List<dynamic> storyGroups,
    int groupIndex,
  ) {
    if (storyGroups.isEmpty || groupIndex < 0 || groupIndex >= storyGroups.length) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => StoryViewerScreen(
          storyGroups: storyGroups.cast(),
          initialGroupIndex: groupIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final storiesAsync = ref.watch(storiesProvider);
    final storyGroups = storiesAsync.asData?.value ?? [];

    final groupIndex = userId.isNotEmpty
        ? storyGroups.indexWhere((g) => g.userId == userId && g.stories.isNotEmpty)
        : -1;
    final hasStory = groupIndex != -1;
    final userStoryGroup = hasStory ? storyGroups[groupIndex] : null;
    final hasUnseen = userStoryGroup?.hasUnseenStories ?? false;

    // Monochromatic ring colors matching X-like design
    final unseenRingColor = isDark ? Colors.white : Colors.black;
    final seenRingColor = isDark ? const Color(0xFF333639) : const Color(0xFFCFD9DE);
    final ringBgColor = isDark ? Colors.black : Colors.white;

    Widget avatarCore = CampusAvatar(
      imageUrl: avatarUrl,
      name: name ?? '',
      radius: radius,
      heroTag: heroTag,
      onTap: () {
        if (hasStory) {
          _openStoryViewer(context, storyGroups, groupIndex);
        } else if (fallbackOnTap != null) {
          fallbackOnTap!();
        }
      },
    );

    Widget avatarWithRing;
    if (hasStory) {
      avatarWithRing = Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: hasUnseen ? unseenRingColor : seenRingColor,
            width: 2.5,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ringBgColor,
          ),
          child: avatarCore,
        ),
      );
    } else {
      avatarWithRing = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.4),
            width: 2.0,
          ),
        ),
        child: avatarCore,
      );
    }

    if (!showCameraBadge) {
      return avatarWithRing;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatarWithRing,
        Positioned(
          bottom: 0,
          right: 0,
          child: Material(
            color: isDark ? Colors.white : Colors.black,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onCameraTap ?? fallbackOnTap,
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: (radius * 0.38).clamp(14.0, 20.0),
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
