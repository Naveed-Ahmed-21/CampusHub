import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/stories_repository.dart';
import '../../domain/story_model.dart';

final storiesProvider = FutureProvider<List<UserStoriesGroup>>((ref) async {
  final repo = ref.watch(storiesRepositoryProvider);
  return repo.getStories();
});

class StoriesController extends Notifier<void> {
  @override
  void build() {}

  Future<void> createStory({
    required String mediaUrl,
    String mediaType = 'IMAGE',
    String? caption,
    int duration = 5,
  }) async {
    final repo = ref.read(storiesRepositoryProvider);
    await repo.createStory(
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      caption: caption,
      duration: duration,
    );
    ref.invalidate(storiesProvider);
  }

  Future<void> markStoryViewed(String storyId) async {
    final repo = ref.read(storiesRepositoryProvider);
    await repo.markStoryViewed(storyId);
  }

  Future<void> deleteStory(String storyId) async {
    final repo = ref.read(storiesRepositoryProvider);
    await repo.deleteStory(storyId);
    ref.invalidate(storiesProvider);
  }
}

final storiesControllerProvider = NotifierProvider<StoriesController, void>(StoriesController.new);
