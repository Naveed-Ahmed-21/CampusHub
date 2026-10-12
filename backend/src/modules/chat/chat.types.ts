import { ChatRoomType, ChatRequestStatus } from '@prisma/client';

export const ALLOWED_REACTIONS = ['❤️', '😂', '😮', '😢', '👍', '👎'] as const;
export type AllowedReactionEmoji = (typeof ALLOWED_REACTIONS)[number];

export interface CreateDirectChatDto {
  targetUserId: string;
}

export interface SendMessageDto {
  roomId: string;
  message: string;
  media_url?: string;
  media_type?: 'IMAGE' | 'DOCUMENT' | 'AUDIO' | 'VIDEO' | 'POST';
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

export interface UpdateChatSettingsDto {
  requireStudentConversationApproval: boolean;
}

export interface CreateChatRequestDto {
  recipientId: string;
  introductoryMessage: string;
}

export type ChatPermissionAction =
  | 'ALLOW_DIRECT_CHAT'
  | 'REQUIRE_CHAT_REQUEST'
  | 'REQUEST_PENDING'
  | 'BLOCKED';

export interface ChatPermissionDto {
  action: ChatPermissionAction;
  roomId?: string;
  requestId?: string;
  isBlockedByYou: boolean;
  isBlockedByThem: boolean;
  targetUser: {
    id: string;
    name: string;
    role: string;
    avatar_url?: string | null;
    department?: string | null;
  };
}

export interface BlockUserDto {
  targetUserId: string;
}
