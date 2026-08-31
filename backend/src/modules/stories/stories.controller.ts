import { Request, Response } from 'express';
import { StoriesService } from './stories.service';
import { asyncHandler } from '../../shared/utils/async-handler.util';

export class StoriesController {
  constructor(private readonly storiesService: StoriesService) {}

  getStories = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const stories = await this.storiesService.getStories(user.collegeId, user.userId);
    res.status(200).json({ success: true, data: stories });
  });

  createStory = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const story = await this.storiesService.createStory(user.userId, user.collegeId, req.body);
    res.status(201).json({ success: true, data: story });
  });

  markViewed = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const storyId = req.params.storyId;
    await this.storiesService.markStoryViewed(storyId, user.userId);
    res.status(200).json({ success: true, message: 'Story marked as viewed' });
  });

  deleteStory = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const storyId = req.params.storyId;
    await this.storiesService.deleteStory(storyId, user.userId, user.role);
    res.status(200).json({ success: true, message: 'Story deleted successfully' });
  });
}
