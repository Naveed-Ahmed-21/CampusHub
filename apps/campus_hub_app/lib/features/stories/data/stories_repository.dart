import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../domain/story_model.dart';

abstract class StoriesRepository {
  Future<List<UserStoriesGroup>> getStories();
  Future<StoryItemModel> createStory({
    required String mediaUrl,
    String mediaType = 'IMAGE',
    String? caption,
    int duration = 5,
  });
  Future<void> markStoryViewed(String storyId);
  Future<void> deleteStory(String storyId);
}

class StoriesRepositoryImpl implements StoriesRepository {
  final Dio _dio;

  StoriesRepositoryImpl(this._dio);

  @override
  Future<List<UserStoriesGroup>> getStories() async {
    try {
      final response = await _dio.get('/api/v1/stories');
      final data = response.data['data'] as List<dynamic>? ?? [];
      return data.map((json) => UserStoriesGroup.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<StoryItemModel> createStory({
    required String mediaUrl,
    String mediaType = 'IMAGE',
    String? caption,
    int duration = 5,
  }) async {
    final response = await _dio.post('/api/v1/stories', data: {
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      if (caption != null && caption.isNotEmpty) 'caption': caption,
      'duration': duration,
    });
    return StoryItemModel.fromJson(response.data['data']);
  }

  @override
  Future<void> markStoryViewed(String storyId) async {
    try {
      await _dio.post('/api/v1/stories/$storyId/view');
    } catch (_) {}
  }

  @override
  Future<void> deleteStory(String storyId) async {
    await _dio.delete('/api/v1/stories/$storyId');
  }
}

final storiesRepositoryProvider = Provider<StoriesRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return StoriesRepositoryImpl(dio);
});
