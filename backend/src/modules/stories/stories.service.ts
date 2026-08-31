import { StoriesRepository } from './stories.repository';
import { CreateStoryDTO, UserStoriesGroupDTO } from './stories.types';
import { NotFoundError, ForbiddenError } from '../../shared/errors/AppError';

export class StoriesService {
  constructor(private readonly storiesRepo: StoriesRepository) {}

  async getStories(collegeId: string, currentUserId: string): Promise<UserStoriesGroupDTO[]> {
    return this.storiesRepo.getActiveStoriesGroupedByUser(collegeId, currentUserId);
  }

  async createStory(userId: string, collegeId: string, dto: CreateStoryDTO) {
    return this.storiesRepo.createStory(userId, collegeId, dto);
  }

  async markStoryViewed(storyId: string, userId: string) {
    return this.storiesRepo.markAsViewed(storyId, userId);
  }

  async deleteStory(storyId: string, userId: string, role: string) {
    const isAdmin = role === 'ADMIN' || role === 'COLLEGE_ADMIN' || role === 'SUPER_ADMIN';
    const deleted = await this.storiesRepo.deleteStory(storyId, userId, isAdmin);
    if (!deleted) {
      throw new ForbiddenError('Story not found or you do not have permission to delete it');
    }
    return deleted;
  }
}
