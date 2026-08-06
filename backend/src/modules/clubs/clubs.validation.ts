import { z } from 'zod';
import { ClubRole, ClubStatus, PostType } from '@prisma/client';

export const createClubSchema = z.object({
  body: z.object({
    name: z.string().min(2, 'Name must be at least 2 characters').max(150),
    category: z.string().min(2, 'Category is required').max(100),
    description: z.string().optional(),
    logo_url: z.string().url('Invalid logo URL').optional().or(z.literal('')),
    is_cross_department: z.boolean().optional().default(true),
  }),
});

export const verifyClubSchema = z.object({
  body: z.object({
    status: z.enum([ClubStatus.APPROVED, ClubStatus.REJECTED]),
    rejection_reason: z.string().optional(),
  }),
});

export const updateClubMemberSchema = z.object({
  body: z.object({
    role: z.nativeEnum(ClubRole),
  }),
});

export const createClubPostSchema = z.object({
  body: z.object({
    title: z.string().min(3, 'Title must be at least 3 characters').max(255),
    content: z.string().min(5, 'Content must be at least 5 characters'),
    type: z.nativeEnum(PostType).optional().default(PostType.GENERAL),
  }),
});

export const createClubEventSchema = z.object({
  body: z.object({
    title: z.string().min(3, 'Title is required').max(255),
    description: z.string().optional(),
    venue: z.string().optional(),
    start_time: z.string().datetime('Start time must be a valid ISO date'),
    end_time: z.string().datetime('End time must be a valid ISO date'),
    banner_url: z.string().url().optional().or(z.literal('')),
  }),
});

export const createClubResourceSchema = z.object({
  body: z.object({
    title: z.string().min(2, 'Title is required').max(255),
    description: z.string().optional(),
    file_url: z.string().min(1, 'File URL is required'),
    file_name: z.string().min(1, 'File name is required'),
    file_type: z.string().min(1, 'File type is required'),
  }),
});

export const sendClubChatMessageSchema = z.object({
  body: z.object({
    message: z.string().min(1, 'Message cannot be empty'),
  }),
});

export const queryClubsSchema = z.object({
  query: z.object({
    category: z.string().optional(),
    status: z.nativeEnum(ClubStatus).optional(),
    search: z.string().optional(),
    is_cross_department: z
      .string()
      .transform((val) => val === 'true')
      .optional(),
    page: z
      .string()
      .transform((val) => parseInt(val, 10))
      .optional(),
    limit: z
      .string()
      .transform((val) => parseInt(val, 10))
      .optional(),
  }),
});
