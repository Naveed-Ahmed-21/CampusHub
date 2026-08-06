import { z } from 'zod';
import { ChatRoomType } from '@prisma/client';

export const createDirectChatSchema = z.object({
  body: z.object({
    targetUserId: z.string().uuid('Invalid target user ID'),
  }),
});

export const sendMessageSchema = z.object({
  body: z.object({
    roomId: z.string().uuid('Invalid room ID'),
    message: z.string().default(''),
    media_url: z.string().url().optional().or(z.literal('')),
    media_type: z.enum(['IMAGE', 'DOCUMENT', 'AUDIO']).optional(),
    file_name: z.string().optional(),
    file_size: z.number().int().optional(),
  }),
});

export const markReadSchema = z.object({
  body: z.object({
    roomId: z.string().uuid('Invalid room ID'),
    messageIds: z.array(z.string().uuid()).min(1, 'At least one message ID required'),
  }),
});

export const queryRoomsSchema = z.object({
  query: z.object({
    type: z.nativeEnum(ChatRoomType).optional(),
    search: z.string().optional(),
    page: z.string().transform((v) => parseInt(v, 10)).optional(),
    limit: z.string().transform((v) => parseInt(v, 10)).optional(),
  }),
});
