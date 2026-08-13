import { z } from 'zod';
import { ChatRoomType } from '@prisma/client';

export const createDirectChatSchema = z.object({
  body: z.object({
    targetUserId: z.string().min(1, 'Target user ID is required'),
  }),
});

export const sendMessageSchema = z.object({
  body: z.object({
    roomId: z.string().min(1, 'Room ID is required'),
    message: z.string().optional().default(''),
    media_url: z.string().optional().nullable(),
    media_type: z.enum(['IMAGE', 'DOCUMENT', 'AUDIO']).optional().nullable(),
    file_name: z.string().optional().nullable(),
    file_size: z.number().optional().nullable(),
  }),
});

export const markReadSchema = z.object({
  body: z.object({
    roomId: z.string().min(1, 'Room ID is required'),
    messageIds: z.array(z.string()).min(1, 'At least one message ID required'),
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
