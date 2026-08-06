import { Router } from 'express';
import { PostsRepository } from './posts.repository';
import { PostsService } from './posts.service';
import { PostsController } from './posts.controller';
import { authenticate } from '../../shared/middlewares/auth.middleware';
import { validateRequest } from '../../shared/middlewares/validate.middleware';
import { createPostSchema, addCommentSchema, queryPostsSchema } from './posts.validation';

const postsRepository = new PostsRepository();
const postsService = new PostsService(postsRepository);
const postsController = new PostsController(postsService);

export const postsRouter = Router();

postsRouter.use(authenticate);

postsRouter.get('/', validateRequest(queryPostsSchema), postsController.getFeed);
postsRouter.post('/', validateRequest(createPostSchema), postsController.createPost);
postsRouter.post('/:postId/like', postsController.toggleLike);
postsRouter.post('/:postId/save', postsController.toggleSave);
postsRouter.get('/:postId/comments', postsController.getComments);
postsRouter.post('/:postId/comments', validateRequest(addCommentSchema), postsController.addComment);
