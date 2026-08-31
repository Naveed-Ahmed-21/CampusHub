import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
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
                                gradient: hasUserStory && (userStoryGroup?.hasUnseenStories ?? false)
                                    ? const LinearGradient(
                                        colors: [Colors.purple, Colors.pink, Colors.orange],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                border: hasUserStory && !(userStoryGroup?.hasUnseenStories ?? true)
                                    ? Border.all(color: Colors.grey.shade400, width: 1.5)
                                    : (!hasUserStory ? Border.all(color: Colors.grey.shade300, width: 1.5) : null),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(1.5),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Colors.teal.shade100,
                                  backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                                      ? NetworkImage(ApiEndpoints.resolveUrl(user.avatarUrl!))
                                      : null,
                                  child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                                      ? Text(
                                          user != null && user.firstName.isNotEmpty
                                              ? user.firstName[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.teal,
                                          ),
                                        )
                                      : null,
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
                                    color: Colors.blue.shade600,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.add, color: Colors.white, size: 14),
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
                          gradient: group.hasUnseenStories
                              ? const LinearGradient(
                                  colors: [Colors.purple, Colors.pink, Colors.orange],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          border: !group.hasUnseenStories
                              ? Border.all(color: Colors.grey.shade400, width: 1.5)
                              : null,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(1.5),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.indigo.shade100,
                            backgroundImage: group.userAvatar != null && group.userAvatar!.isNotEmpty
                                ? NetworkImage(ApiEndpoints.resolveUrl(group.userAvatar!))
                                : null,
                            child: group.userAvatar == null || group.userAvatar!.isEmpty
                                ? Text(
                                    group.userName.isNotEmpty ? group.userName[0].toUpperCase() : 'C',
                                    style: const TextStyle(
                                      color: Colors.indigo,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  )
                                : null,
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
