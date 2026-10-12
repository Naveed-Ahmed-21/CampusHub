import '../../../../core/widgets/campus_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../stories/presentation/providers/stories_provider.dart';
import '../../../stories/presentation/views/story_viewer_screen.dart';
import '../../../stories/presentation/widgets/story_upload_sheet.dart';

class StoriesSectionWidget extends ConsumerWidget {
  const StoriesSectionWidget({super.key});

  void _openStoryUpload(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const StoryUploadSheet(),
    );
  }

  void _openStoryViewer(BuildContext context, List<dynamic> groups, int initialIndex) {
    if (groups.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => StoryViewerScreen(
          storyGroups: groups.cast(),
          initialGroupIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final storiesAsync = ref.watch(storiesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unseenRingColor = isDark ? Colors.white : Colors.black;
    final seenRingColor = isDark ? const Color(0xFF2F3336) : const Color(0xFFEFF3F4);
    final ringBgColor = isDark ? Colors.black : Colors.white;

    return Container(
      height: 98,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: storiesAsync.when(
        data: (storyGroups) {
          // Check if current user has an active story
          final currentUserGroupIndex = user != null
              ? storyGroups.indexWhere((g) => g.userId == user.id)
              : -1;
          final hasUserStory = currentUserGroupIndex != -1;
          final userStoryGroup = hasUserStory ? storyGroups[currentUserGroupIndex] : null;

          // Other users' story groups (excluding current user to avoid duplicate avatar)
          final otherGroups = user != null
              ? storyGroups.where((g) => g.userId != user.id).toList()
              : storyGroups;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: 1 + otherGroups.length,
            itemBuilder: (context, index) {
              if (index == 0) {
                // 1. "Your story" avatar card with '+' badge
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      if (hasUserStory) {
                        _openStoryViewer(context, storyGroups, currentUserGroupIndex);
                      } else {
                        _openStoryUpload(context);
                      }
                    },
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              padding: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: hasUserStory && (userStoryGroup?.hasUnseenStories ?? false)
                                      ? unseenRingColor
                                      : seenRingColor,
                                  width: 2.0,
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(1.5),
                                decoration: BoxDecoration(
                                  color: ringBgColor,
                                  shape: BoxShape.circle,
                                ),
                                child: CampusAvatar(
                                  imageUrl: user?.avatarUrl,
                                  name: user?.firstName ?? 'U',
                                  radius: 26,
                                ),
                              ),
                            ),
                            // Plus Badge
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: () => _openStoryUpload(context),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white : Colors.black,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: ringBgColor, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: isDark ? Colors.black : Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          hasUserStory ? 'Your Story' : 'Add Story',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // 2. Real user story groups only
              final group = otherGroups[index - 1];
              final groupIndexInAll = storyGroups.indexOf(group);

              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: GestureDetector(
                  onTap: () => _openStoryViewer(context, storyGroups, groupIndexInAll),
                  child: Column(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: group.hasUnseenStories ? unseenRingColor : seenRingColor,
                            width: 2.0,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            color: ringBgColor,
                            shape: BoxShape.circle,
                          ),
                          child: CampusAvatar(
                            imageUrl: group.userAvatar,
                            name: group.userName,
                            radius: 26,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: 66,
                        child: Text(
                          group.userName,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: 4,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 44,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
        error: (err, stack) => const SizedBox.shrink(),
      ),
    );
  }
}
