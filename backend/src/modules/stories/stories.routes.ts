import { Router } from 'express';
import { StoriesRepository } from './stories.repository';
import { StoriesService } from './stories.service';
import { StoriesController } from './stories.controller';
import { requireAuth } from '../../shared/middlewares/auth.middleware';
import { validateRequest } from '../../shared/middlewares/validate.middleware';
import { createStorySchema } from './stories.validation';

const storiesRepository = new StoriesRepository();
const storiesService = new StoriesService(storiesRepository);
const storiesController = new StoriesController(storiesService);

export const storiesRouter = Router();

storiesRouter.use(requireAuth());

storiesRouter.get('/', storiesController.getStories);
storiesRouter.post('/', validateRequest(createStorySchema), storiesController.createStory);
storiesRouter.post('/:storyId/view', storiesController.markViewed);
storiesRouter.delete('/:storyId', storiesController.deleteStory);
