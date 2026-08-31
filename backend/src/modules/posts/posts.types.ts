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
  MY_POSTS = 'MY_POSTS',
  SAVED = 'SAVED',
  AUTHOR = 'AUTHOR',
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
  clubId?: string | null;
  clubName?: string | null;
  clubLogoUrl?: string | null;
  clubCategory?: string | null;
  club?: {
    id: string;
    name: string;
    logo_url?: string | null;
    category?: string | null;
  } | null;
  attachments: Array<{ id: string; fileName: string; fileUrl: string; fileType: string }>;
  likesCount: number;
  commentsCount: number;
  isLiked: boolean;
  isSaved: boolean;
}

export interface CommentResponseDTO {
  id: string;
  postId: string;
  authorId: string;
  parentCommentId?: string | null;
  content: string;
  createdAt: Date;
  updatedAt: Date;
  author: {
    id: string;
    name: string;
    avatarUrl?: string | null;
  };
  likesCount: number;
  isLiked: boolean;
  repliesCount: number;
  replies?: CommentResponseDTO[];
}
