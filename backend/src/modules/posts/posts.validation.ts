import { z } from 'zod';

export const createPostSchema = z.object({
  body: z.object({
    title: z.string().min(2, 'Title must be at least 2 characters'),
    content: z.string().min(5, 'Content must be at least 5 characters'),
    type: z.enum(['ANNOUNCEMENT', 'GENERAL', 'ACADEMIC', 'EVENT_PROMO', 'PLACEMENT']).default('GENERAL'),
    scope: z.enum(['DEPARTMENT', 'CROSS_DEPARTMENT']).optional(),
    isCrossDepartment: z.boolean().optional(),
    departmentId: z.string().uuid().optional().nullable(),
    clubId: z.string().optional().nullable(),
    club_id: z.string().optional().nullable(),
    attachments: z.array(z.object({
      fileName: z.string(),
      fileUrl: z.string().min(1, 'File URL is required'),
      fileType: z.string(),
    })).optional().nullable(),
  }),
});

export const updatePostSchema = z.object({
  body: z.object({
    title: z.string().min(2, 'Title must be at least 2 characters').optional(),
    content: z.string().min(5, 'Content must be at least 5 characters').optional(),
    type: z.enum(['ANNOUNCEMENT', 'GENERAL', 'ACADEMIC', 'EVENT_PROMO', 'PLACEMENT']).optional(),
  }),
});

export const addCommentSchema = z.object({
  body: z.object({
    content: z.string().min(1, 'Comment cannot be empty'),
    parentCommentId: z.string().uuid().optional().nullable(),
  }),
});

export const queryPostsSchema = z.object({
  query: z.object({
    feedType: z.enum(['MY_FEED', 'DEPARTMENT', 'CROSS_DEPARTMENT', 'CLUB', 'FOLLOWING', 'MY_POSTS', 'SAVED', 'AUTHOR']).default('DEPARTMENT'),
    page: z.string().transform((val) => parseInt(val, 10)).default('1'),
    limit: z.string().transform((val) => parseInt(val, 10)).default('10'),
    authorId: z.string().optional(),
    clubId: z.string().optional(),
    departmentId: z.string().optional(),
    search: z.string().optional(),
  }),
});
