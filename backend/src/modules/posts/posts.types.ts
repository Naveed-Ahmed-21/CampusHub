import { z } from 'zod';
import { createPostSchema, addCommentSchema, queryPostsSchema } from './posts.validation';

export type CreatePostDTO = z.infer<typeof createPostSchema>['body'];
export type AddCommentDTO = z.infer<typeof addCommentSchema>['body'];
export type QueryPostsDTO = z.infer<typeof queryPostsSchema>['query'];

export enum FeedType {
  MY_FEED = 'MY_FEED',
  DEPARTMENT = 'DEPARTMENT',
  CROSS_DEPARTMENT = 'CROSS_DEPARTMENT',
  CLUB = 'CLUB',
  FOLLOWING = 'FOLLOWING',
}

export interface PostResponseDTO {
  id: string;
  title: string;
  content: string;
  type: string;
  isPinned: boolean;
  createdAt: Date;
  author: {
    id: string;
    name: string;
    avatarUrl?: string | null;
    role: string;
  };
  attachments: Array<{ id: string; fileName: string; fileUrl: string; fileType: string }>;
  likesCount: number;
  commentsCount: number;
  isLiked: boolean;
  isSaved: boolean;
}
