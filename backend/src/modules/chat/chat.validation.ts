import { z } from 'zod';
import { ChatRoomType } from '@prisma/client';
import { ALLOWED_REACTIONS } from './chat.types';

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
    media_type: z.enum(['IMAGE', 'DOCUMENT', 'AUDIO', 'VIDEO', 'POST']).optional().nullable(),
    file_name: z.string().optional().nullable(),
    file_size: z.number().optional().nullable(),
    reply_to_message_id: z.string().optional().nullable(),
  }),
});

export const addReactionSchema = z.object({
  body: z.object({
    emoji: z.enum(ALLOWED_REACTIONS as unknown as [string, ...string[]]),
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

export const updateChatSettingsSchema = z.object({
  body: z.object({
    requireStudentConversationApproval: z.boolean(),
  }),
});

export const createChatRequestSchema = z.object({
  body: z.object({
    recipientId: z.string().min(1, 'Recipient user ID is required'),
    introductoryMessage: z
      .string()
      .trim()
      .min(1, 'Introductory message cannot be empty')
      .max(300, 'Introductory message cannot exceed 300 characters'),
  }),
});

export const blockUserSchema = z.object({
  body: z.object({
    targetUserId: z.string().min(1, 'Target user ID is required'),
  }),
});
