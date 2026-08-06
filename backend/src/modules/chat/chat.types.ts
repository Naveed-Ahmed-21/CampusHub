import { ChatRoomType } from '@prisma/client';

export interface CreateDirectChatDto {
  targetUserId: string;
}

export interface SendMessageDto {
  roomId: string;
  message: string;
  media_url?: string;
  media_type?: 'IMAGE' | 'DOCUMENT' | 'AUDIO';
  file_name?: string;
  file_size?: number;
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
