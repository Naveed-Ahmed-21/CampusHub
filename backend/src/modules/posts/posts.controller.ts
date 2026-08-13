import { Request, Response } from 'express';
import { PostsService } from './posts.service';
import { asyncHandler } from '../../shared/utils/async-handler.util';
import { FeedType } from './posts.types';
import { ForbiddenError } from '../../shared/errors/AppError';

export class PostsController {
  constructor(private readonly postsService: PostsService) {}

  getFeed = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const feedType = (req.query.feedType as FeedType) || FeedType.DEPARTMENT;
    const page = parseInt(req.query.page as string, 10) || 1;
    const limit = parseInt(req.query.limit as string, 10) || 10;

    const posts = await this.postsService.getFeed({
      userId: user.userId,
      collegeId: user.collegeId,
      feedType,
      page,
      limit,
    });

    res.status(200).json({ success: true, data: posts, page, limit });
  });

  createPost = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const post = await this.postsService.createPost(user.userId, user.collegeId, user.departmentId, req.body);
    res.status(201).json({ success: true, data: post });
  });

  toggleLike = asyncHandler(async (req: Request, res: Response) => {
    const postId = req.params.postId;
    const result = await this.postsService.toggleLike(postId, req.user!.userId);
    res.status(200).json({ success: true, data: result });
  });

  toggleSave = asyncHandler(async (req: Request, res: Response) => {
    const postId = req.params.postId;
    const result = await this.postsService.toggleSave(postId, req.user!.userId);
    res.status(200).json({ success: true, data: result });
  });

  addComment = asyncHandler(async (req: Request, res: Response) => {
    const postId = req.params.postId;
    const comment = await this.postsService.addComment(postId, req.user!.userId, req.body.content);
    res.status(201).json({ success: true, data: comment });
  });

  getComments = asyncHandler(async (req: Request, res: Response) => {
    const postId = req.params.postId;
    const comments = await this.postsService.getComments(postId);
    res.status(200).json({ success: true, data: comments });
  });

  deletePost = asyncHandler(async (req: Request, res: Response) => {
    const postId = req.params.postId;
    const user = req.user!;

    const isAuthorOrAdmin = await this.postsService.checkOwnershipOrAdmin(postId, user.userId, user.role);
    if (!isAuthorOrAdmin) {
      throw new ForbiddenError('You do not have permission to perform this action');
    }

    await this.postsService.deletePost(postId);
    res.status(200).json({ success: true, message: 'Post deleted successfully' });
  });
}
