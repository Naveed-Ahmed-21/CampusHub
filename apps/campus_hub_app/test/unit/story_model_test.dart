import 'package:flutter_test/flutter_test.dart';
import 'package:campus_hub_app/features/stories/domain/story_model.dart';

void main() {
  group('StoryItemModel Tests', () {
    test('fromJson deserializes correctly', () {
      final json = {
        'id': 'story-123',
        'mediaUrl': 'https://example.com/photo.jpg',
        'mediaType': 'IMAGE',
        'caption': 'Campus Fest 2026',
        'duration': 5,
        'createdAt': '2026-08-18T10:00:00.000Z',
        'expiresAt': '2026-08-19T10:00:00.000Z',
        'isViewed': false,
        'viewsCount': 12,
      };

      final story = StoryItemModel.fromJson(json);

      expect(story.id, 'story-123');
      expect(story.mediaUrl, 'https://example.com/photo.jpg');
      expect(story.mediaType, 'IMAGE');
      expect(story.caption, 'Campus Fest 2026');
      expect(story.duration, 5);
      expect(story.isViewed, false);
      expect(story.viewsCount, 12);
    });

    test('UserStoriesGroup fromJson parses stories correctly', () {
      final json = {
        'userId': 'user-1',
        'userName': 'Naveed Ahmed',
        'userAvatar': 'https://example.com/avatar.jpg',
        'userRole': 'STUDENT',
        'hasUnseenStories': true,
        'latestStoryCreatedAt': '2026-08-18T12:00:00.000Z',
        'stories': [
          {
            'id': 'story-1',
            'mediaUrl': 'https://example.com/img1.jpg',
            'mediaType': 'IMAGE',
            'caption': 'Story 1',
            'duration': 5,
            'createdAt': '2026-08-18T12:00:00.000Z',
            'expiresAt': '2026-08-19T12:00:00.000Z',
            'isViewed': false,
            'viewsCount': 3,
          }
        ],
      };

      final group = UserStoriesGroup.fromJson(json);

      expect(group.userId, 'user-1');
      expect(group.userName, 'Naveed Ahmed');
      expect(group.hasUnseenStories, true);
      expect(group.stories.length, 1);
      expect(group.stories.first.id, 'story-1');
    });
  });
}
