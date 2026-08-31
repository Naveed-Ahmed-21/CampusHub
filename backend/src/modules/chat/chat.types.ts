import { ChatRoomType } from '@prisma/client';

export const ALLOWED_REACTIONS = ['❤️', '😂', '😮', '😢', '👍', '👎'] as const;
export type AllowedReactionEmoji = (typeof ALLOWED_REACTIONS)[number];

export interface CreateDirectChatDto {
  targetUserId: string;
}

export interface SendMessageDto {
  roomId: string;
  message: string;
  media_url?: string;
  media_type?: 'IMAGE' | 'DOCUMENT' | 'AUDIO' | 'VIDEO';
  file_name?: string;
  file_size?: number;
  reply_to_message_id?: string;
}

export interface AddReactionDto {
  emoji: string;
}

export interface MarkReadDto {
  roomId: string;
  messageIds: string[];
}

export interface QueryRoomsDto {
  type?: ChatRoomType;
  search?: string;
  page?: number;
  limit?: number;
}
