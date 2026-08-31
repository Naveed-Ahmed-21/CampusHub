import { Router } from 'express';
import { PostsRepository } from './posts.repository';
import { PostsService } from './posts.service';
import { PostsController } from './posts.controller';
import { requireAuth, requireRole } from '../../shared/middlewares/auth.middleware';
import { validateRequest } from '../../shared/middlewares/validate.middleware';
import { createPostSchema, updatePostSchema, addCommentSchema, queryPostsSchema } from './posts.validation';

const postsRepository = new PostsRepository();
const postsService = new PostsService(postsRepository);
const postsController = new PostsController(postsService);

export const postsRouter = Router();

postsRouter.use(requireAuth());

postsRouter.get('/', validateRequest(queryPostsSchema), postsController.getFeed);
postsRouter.post('/', requireRole('STUDENT', 'FACULTY', 'PLACEMENT_OFFICER', 'ADMIN'), validateRequest(createPostSchema), postsController.createPost);
postsRouter.patch('/:postId', validateRequest(updatePostSchema), postsController.updatePost);
postsRouter.delete('/:postId', postsController.deletePost);
postsRouter.post('/:postId/like', postsController.toggleLike);
postsRouter.post('/:postId/save', postsController.toggleSave);
postsRouter.get('/:postId/comments', postsController.getComments);
postsRouter.post('/:postId/comments', validateRequest(addCommentSchema), postsController.addComment);
postsRouter.post('/comments/:commentId/like', postsController.toggleCommentLike);
postsRouter.post('/:postId/comments/:commentId/like', postsController.toggleCommentLike);
