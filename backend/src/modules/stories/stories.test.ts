import { StoriesService } from './stories.service';
import { StoriesRepository } from './stories.repository';

describe('StoriesService', () => {
  let storiesService: StoriesService;
  let storiesRepository: jest.Mocked<StoriesRepository>;

  beforeEach(() => {
    storiesRepository = {
      getActiveStoriesGroupedByUser: jest.fn(),
      createStory: jest.fn(),
      markAsViewed: jest.fn(),
      deleteStory: jest.fn(),
    } as unknown as jest.Mocked<StoriesRepository>;

    storiesService = new StoriesService(storiesRepository);
  });

  describe('getStories', () => {
    it('should return active stories grouped by user', async () => {
      const mockStories = [
        {
          userId: 'user_1',
          userName: 'Alex Vance',
          userAvatar: null,
          userRole: 'STUDENT',
          hasUnseenStories: true,
          latestStoryCreatedAt: new Date(),
          stories: [
            {
              id: 'story_1',
              mediaUrl: 'https://example.com/story.jpg',
              mediaType: 'IMAGE',
              caption: 'Morning Hackathon',
              duration: 5,
              createdAt: new Date(),
              expiresAt: new Date(Date.now() + 86400000),
              isViewed: false,
              viewsCount: 5,
            },
          ],
        },
      ];

      storiesRepository.getActiveStoriesGroupedByUser.mockResolvedValue(mockStories as any);

      const result = await storiesService.getStories('college_1', 'user_1');
      expect(result).toHaveLength(1);
      expect(result[0].userName).toBe('Alex Vance');
      expect(result[0].stories).toHaveLength(1);
      expect(result[0].hasUnseenStories).toBe(true);
    });
  });

  describe('createStory', () => {
    it('should create a new story successfully', async () => {
      const mockCreated = {
        id: 'story_new',
        college_id: 'college_1',
        user_id: 'user_1',
        media_url: 'https://example.com/new.jpg',
        media_type: 'IMAGE',
        caption: 'Campus sunset',
        duration: 5,
        expires_at: new Date(Date.now() + 86400000),
        created_at: new Date(),
        user: {
          id: 'user_1',
          first_name: 'Alex',
          last_name: 'Vance',
          avatar_url: null,
          role: 'STUDENT',
        },
      };

      storiesRepository.createStory.mockResolvedValue(mockCreated as any);

      const result = await storiesService.createStory('user_1', 'college_1', {
        mediaUrl: 'https://example.com/new.jpg',
        mediaType: 'IMAGE',
        caption: 'Campus sunset',
        duration: 5,
      });

      expect(result.id).toBe('story_new');
      expect(result.media_url).toBe('https://example.com/new.jpg');
    });
  });

  describe('markStoryViewed', () => {
    it('should mark story as viewed in repository', async () => {
      storiesRepository.markAsViewed.mockResolvedValue({ id: 'view_1', story_id: 'story_1', user_id: 'user_1', viewed_at: new Date() } as any);

      await storiesService.markStoryViewed('story_1', 'user_1');
      expect(storiesRepository.markAsViewed).toHaveBeenCalledWith('story_1', 'user_1');
    });
  });
});
