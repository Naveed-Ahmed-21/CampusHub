import { PostsService } from './posts.service';
import { PostsRepository } from './posts.repository';
import { FeedType } from './posts.types';

describe('PostsService', () => {
  let postsService: PostsService;
  let postsRepository: jest.Mocked<PostsRepository>;

  beforeEach(() => {
    postsRepository = {
      getPosts: jest.fn(),
      countPosts: jest.fn(),
      createPost: jest.fn(),
      toggleLike: jest.fn(),
      addComment: jest.fn(),
      getComments: jest.fn(),
      toggleSave: jest.fn(),
    } as unknown as jest.Mocked<PostsRepository>;

    postsService = new PostsService(postsRepository);
  });

  describe('getFeed', () => {
    it('should return feed posts', async () => {
      const mockPosts = [
        {
          id: 'post_1',
          title: 'CampusHack 2026',
          content: 'CampusHack 2026 registration is open!',
          type: 'ANNOUNCEMENT',
          is_pinned: false,
          created_at: new Date(),
          author: { id: 'usr_1', first_name: 'Alex', last_name: 'Vance', avatar_url: null, role: 'STUDENT' },
          attachments: [],
          likes: [],
          saves: [],
          _count: { likes: 12, comments: 4 },
        },
      ];

      postsRepository.getPosts.mockResolvedValue(mockPosts as any);

      const result = await postsService.getFeed({
        userId: 'std_10092',
        collegeId: 'clg_1',
        feedType: FeedType.DEPARTMENT,
        page: 1,
        limit: 10,
      });

      expect(result).toBeDefined();
      expect(result.length).toBeGreaterThan(0);
    });

    it('should query author posts for FeedType.AUTHOR with authorId', async () => {
      const mockPosts = [
        {
          id: 'post_author_1',
          title: 'Student Research Paper',
          content: 'Here is my research on distributed systems',
          type: 'ACADEMIC',
          is_pinned: false,
          created_at: new Date(),
          author: { id: 'std_author_1', first_name: 'Student', last_name: 'Author', avatar_url: null, role: 'STUDENT' },
          attachments: [],
          likes: [],
          saves: [],
          _count: { likes: 5, comments: 2 },
        },
      ];

      postsRepository.getPosts.mockResolvedValue(mockPosts as any);

      const result = await postsService.getFeed({
        userId: 'faculty_1',
        collegeId: 'clg_1',
        feedType: FeedType.AUTHOR,
        authorId: 'std_author_1',
        page: 1,
        limit: 50,
      });

      expect(postsRepository.getPosts).toHaveBeenCalledWith(
        expect.objectContaining({
          authorId: 'std_author_1',
          feedType: FeedType.AUTHOR,
        })
      );
      expect(result).toHaveLength(1);
      expect(result[0].title).toBe('Student Research Paper');
    });

    it('should return clean empty array if repository throws DB error', async () => {
      postsRepository.getPosts.mockRejectedValue(new Error('DB connection refused'));

      const result = await postsService.getFeed({
        userId: 'std_10092',
        collegeId: 'clg_1',
        feedType: FeedType.DEPARTMENT,
        page: 1,
        limit: 10,
      });

      expect(result).toEqual([]);
    });
  });

  describe('toggleLike', () => {
    it('should toggle post like state', async () => {
      postsRepository.toggleLike.mockResolvedValue(true);

      const res = await postsService.toggleLike('post_1', 'std_10092');
      expect(res.isLiked).toBe(true);
    });
  });
});
