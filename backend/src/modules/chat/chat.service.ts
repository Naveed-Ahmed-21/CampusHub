import { ChatRepository } from './chat.repository';
import { CreateDirectChatDto, SendMessageDto, MarkReadDto } from './chat.types';
import { NotFoundError, ForbiddenError, BadRequestError } from '../../shared/errors/AppError';
import { prisma } from '../../config/database';
import { ChatRoomType, Role } from '@prisma/client';

export class ChatService {
  constructor(private readonly chatRepository: ChatRepository) {}

  async getUserRooms(userId: string, collegeId: string, type?: ChatRoomType, search?: string) {
    return this.chatRepository.findUserRooms(userId, collegeId, type, search);
  }

  async getPublicGroups(collegeId: string, currentUserId: string, query?: string, limit?: number) {
    return this.chatRepository.findPublicGroups(collegeId, currentUserId, query, limit);
  }

  async getOrCreateDirectChat(userId: string, collegeId: string, dto: CreateDirectChatDto) {
    if (userId === dto.targetUserId) {
      throw new BadRequestError('Cannot start a direct chat with yourself');
    }

    const targetUser = await prisma.user.findUnique({
      where: { id: dto.targetUserId },
      select: { id: true, college_id: true, first_name: true, last_name: true, status: true },
    });

    if (!targetUser || targetUser.college_id !== collegeId || targetUser.status !== 'ACTIVE') {
      throw new NotFoundError('Target user not found in this college');
    }

    let room = await this.chatRepository.findDirectChatRoom(userId, dto.targetUserId, collegeId);
    if (!room) {
      room = await this.chatRepository.createDirectChatRoom(userId, dto.targetUserId, collegeId);
    }
    return room;
  }

  async getOrCreateDepartmentChat(userId: string, collegeId: string, departmentId?: string | null) {
    let targetDeptId = departmentId;
    if (!targetDeptId) {
      const user = await prisma.user.findUnique({
        where: { id: userId },
        select: { department_id: true },
      });
      targetDeptId = user?.department_id;
    }

    if (!targetDeptId) {
      throw new NotFoundError('User has no department assigned');
    }

    const dept = await prisma.department.findUnique({
      where: { id: targetDeptId },
    });
    if (!dept || dept.college_id !== collegeId) {
      throw new NotFoundError('Department not found in this college');
    }

    const room = await this.chatRepository.findOrCreateDepartmentChatRoom(targetDeptId, collegeId, dept.name);
    await this.chatRepository.addParticipantToRoom(room.id, userId);
    return room;
  }

  async getOrCreateClubChat(userId: string, collegeId: string, clubId: string, userRole?: string) {
    const club = await prisma.club.findUnique({
      where: { id: clubId },
      include: {
        members: { where: { user_id: userId } },
      },
    });

    if (!club || club.college_id !== collegeId) {
      throw new NotFoundError('Club not found');
    }

    const isAdmin = [Role.ADMIN, Role.COLLEGE_ADMIN, Role.SUPER_ADMIN, Role.DEPT_ADMIN, 'ADMIN'].includes(userRole as any);
    const isMember = club.members.length > 0;

    if (!isMember && !isAdmin) {
      throw new ForbiddenError('Only club members can access club chat');
    }

    const userClubRole = club.members[0]?.role;
    const roomRole = userClubRole === 'LEAD' || userClubRole === 'FACULTY_ADVISOR' ? 'ADMIN' : 'MEMBER';

    const room = await this.chatRepository.findOrCreateClubChatRoom(clubId, collegeId, club.name, club.logo_url);
    await this.chatRepository.addParticipantToRoom(room.id, userId, roomRole);
    return room;
  }

  async getRoomDetails(roomId: string, userId: string) {
    const room = await this.chatRepository.findRoomById(roomId);
    if (!room) {
      throw new NotFoundError('Chat room not found');
    }

    const isMember = room.participants.some((p) => p.user_id === userId && p.status === 'ACTIVE');

    if (!isMember && room.is_private) {
      throw new ForbiddenError('Access denied: This is a private group');
    }

    const activeParticipants = room.participants.filter((p: any) => p.status === 'ACTIVE');
    const onlineParticipants = activeParticipants.filter((p: any) => p.user?.is_online);

    return {
      ...room,
      isMember,
      memberCount: room._count?.participants ?? activeParticipants.length,
      onlineMemberCount: onlineParticipants.length,
      participants: room.participants.map((p: any) => ({
        ...p,
        user: {
          ...p.user,
          username: p.user.username
            ? (p.user.username.startsWith('@') ? p.user.username : `@${p.user.username}`)
            : `@${p.user.email.split('@')[0].toLowerCase()}`,
        },
      })),
    };
  }

  async getRoomMessages(roomId: string, userId: string, page: number = 1, limit: number = 50) {
    const room = await this.chatRepository.findRoomById(roomId);
    if (!room) {
      throw new NotFoundError('Chat room not found');
    }

    const isParticipant = room.participants.some((p) => p.user_id === userId && p.status === 'ACTIVE');
    if (!isParticipant) {
      throw new ForbiddenError('You must join this group before you can access messages');
    }

    return this.chatRepository.getRoomMessages(roomId, userId, page, limit);
  }

  async sendMessage(senderId: string, collegeId: string, dto: SendMessageDto) {
    const room = await this.chatRepository.findRoomById(dto.roomId);
    if (!room) {
      throw new NotFoundError('Chat room not found');
    }

    if (room.college_id !== collegeId) {
      throw new ForbiddenError('Unauthorized: room belongs to another college');
    }

    const isParticipant = room.participants.some((p) => p.user_id === senderId && p.status === 'ACTIVE');
    if (!isParticipant) {
      throw new ForbiddenError('You must be an active member of this chat to send messages');
    }

    if (dto.reply_to_message_id) {
      const replyTarget = await this.chatRepository.findMessageById(dto.reply_to_message_id);
      if (!replyTarget || replyTarget.room_id !== dto.roomId) {
        throw new BadRequestError('Invalid reply target message');
      }
    }

    return this.chatRepository.createMessage(senderId, dto);
  }

  async addOrToggleReaction(messageId: string, userId: string, emoji: string) {
    const allowed = ['❤️', '😂', '😮', '😢', '👍', '👎'];
    if (!allowed.includes(emoji)) {
      throw new BadRequestError(`Invalid emoji. Allowed emojis: ${allowed.join(' ')}`);
    }

    const message = await this.chatRepository.findMessageById(messageId);
    if (!message) {
      throw new NotFoundError('Message not found');
    }

    const isParticipant = (message as any).room?.participants?.some(
      (p: any) => p.user_id === userId && p.status === 'ACTIVE'
    );
    if (!isParticipant) {
      throw new ForbiddenError('You must be an active member of this chat to react to messages');
    }

    if (message.is_deleted_for_everyone) {
      throw new BadRequestError('Cannot react to deleted messages');
    }

    return this.chatRepository.addOrToggleReaction(messageId, userId, emoji);
  }

  async removeReaction(messageId: string, userId: string, emoji: string) {
    const message = await this.chatRepository.findMessageById(messageId);
    if (!message) {
      throw new NotFoundError('Message not found');
    }

    const isParticipant = (message as any).room?.participants?.some(
      (p: any) => p.user_id === userId && p.status === 'ACTIVE'
    );
    if (!isParticipant) {
      throw new ForbiddenError('You must be an active member of this chat to remove reactions');
    }

    return this.chatRepository.removeReaction(messageId, userId, emoji);
  }

  async deleteMessageForMe(messageId: string, userId: string) {
    const message = await this.chatRepository.findMessageById(messageId);
    if (!message) {
      throw new NotFoundError('Message not found');
    }

    const isParticipant = (message as any).room?.participants?.some(
      (p: any) => p.user_id === userId && p.status === 'ACTIVE'
    );
    if (!isParticipant) {
      throw new ForbiddenError('You must be a member of this chat to delete messages');
    }

    return this.chatRepository.deleteMessageForMe(messageId, userId);
  }

  async deleteMessageForEveryone(messageId: string, userId: string) {
    const message = await this.chatRepository.findMessageById(messageId);
    if (!message) {
      throw new NotFoundError('Message not found');
    }

    if (message.sender_id !== userId) {
      throw new ForbiddenError('Only the original sender can delete this message for everyone');
    }

    if (message.is_deleted_for_everyone) {
      return message;
    }

    // 24-HOUR BUSINESS RULE ENFORCEMENT ON BACKEND
    const now = new Date();
    const sentAt = new Date(message.created_at);
    const diffHours = (now.getTime() - sentAt.getTime()) / (1000 * 60 * 60);

    if (diffHours > 24) {
      throw new BadRequestError('Messages can only be deleted for everyone within 24 hours of being sent');
    }

    return this.chatRepository.deleteMessageForEveryone(messageId);
  }

  async createGroupRoom(
    creatorId: string,
    collegeId: string,
    dto: { name: string; description?: string | null; isPrivate?: boolean; memberIds?: string[]; avatarUrl?: string | null }
  ) {
    if (!dto.name || dto.name.trim().length === 0) {
      throw new BadRequestError('Group name is required');
    }

    return this.chatRepository.createGroupRoom(
      collegeId,
      creatorId,
      dto.name.trim(),
      dto.description?.trim() || null,
      Boolean(dto.isPrivate),
      dto.memberIds || [],
      dto.avatarUrl || null
    );
  }

  async updateGroupAvatar(roomId: string, userId: string, avatarUrl: string | null) {
    const room = await this.chatRepository.findRoomById(roomId);
    if (!room) {
      throw new NotFoundError('Chat room not found');
    }

    if (room.type !== ChatRoomType.GROUP) {
      throw new BadRequestError('Only group conversations can have a group image updated');
    }

    const participant = room.participants.find((p) => p.user_id === userId && p.status === 'ACTIVE');
    const isCreator = room.created_by_id === userId;
    const isAdmin = participant?.role === 'ADMIN' || isCreator;

    if (room.is_private) {
      if (!isAdmin) {
        throw new ForbiddenError('Only group admins can modify the group image of a private group');
      }
    } else {
      if (!participant && !isCreator) {
        throw new ForbiddenError('You must be an active member of this public group to modify its image');
      }
    }

    await this.chatRepository.updateRoomAvatar(roomId, avatarUrl);
    return this.getRoomDetails(roomId, userId);
  }

  async joinPublicGroup(roomId: string, userId: string) {
    const room = await this.chatRepository.findRoomById(roomId);
    if (!room) {
      throw new NotFoundError('Group not found');
    }

    if (room.type !== ChatRoomType.GROUP) {
      throw new BadRequestError('Only group chats can be joined');
    }

    if (room.is_private) {
      throw new ForbiddenError('This is a private group. An admin invitation is required to join.');
    }

    await this.chatRepository.addParticipantToRoom(roomId, userId, 'MEMBER');

    const updatedRoom = await this.chatRepository.findRoomById(roomId);
    return {
      roomId,
      userId,
      isMember: true,
      memberCount: updatedRoom?._count?.participants || 1,
      message: 'Joined group successfully',
    };
  }

  async leaveGroup(roomId: string, userId: string) {
    const room = await this.chatRepository.findRoomById(roomId);
    if (!room) {
      throw new NotFoundError('Group not found');
    }

    await this.chatRepository.removeParticipantFromRoom(roomId, userId);

    return {
      roomId,
      userId,
      isMember: false,
      message: 'Left group successfully',
    };
  }

  async addRoomMember(roomId: string, actorId: string, targetUserId: string) {
    const room = await this.chatRepository.findRoomById(roomId);
    if (!room) {
      throw new NotFoundError('Group not found');
    }

    const actorParticipant = room.participants.find((p) => p.user_id === actorId && p.status === 'ACTIVE');
    const isActorAdmin = actorParticipant?.role === 'ADMIN' || room.created_by_id === actorId;

    if (!isActorAdmin) {
      throw new ForbiddenError('Only group admins can add members to this group');
    }

    await this.chatRepository.addParticipantToRoom(roomId, targetUserId, 'MEMBER');
    return { roomId, userId: targetUserId, success: true, message: 'Member added successfully' };
  }

  async removeRoomMember(roomId: string, actorId: string, targetUserId: string) {
    const room = await this.chatRepository.findRoomById(roomId);
    if (!room) {
      throw new NotFoundError('Group not found');
    }

    const isSelfLeave = actorId === targetUserId;
    const actorParticipant = room.participants.find((p) => p.user_id === actorId && p.status === 'ACTIVE');
    const isActorAdmin = actorParticipant?.role === 'ADMIN' || room.created_by_id === actorId;

    if (!isSelfLeave && !isActorAdmin) {
      throw new ForbiddenError('Only group admins can remove members');
    }

    await this.chatRepository.removeParticipantFromRoom(roomId, targetUserId);
    return { roomId, userId: targetUserId, success: true, message: 'Member removed successfully' };
  }

  async searchCampusUsers(collegeId: string, currentUserId: string, query?: string) {
    return this.chatRepository.searchCampusUsers(collegeId, currentUserId, query);
  }

  async markRead(userId: string, dto: MarkReadDto) {
    const room = await this.chatRepository.findRoomById(dto.roomId);
    if (!room) {
      throw new NotFoundError('Chat room not found');
    }

    const isParticipant = room.participants.some((p) => p.user_id === userId && p.status === 'ACTIVE');
    if (!isParticipant) {
      throw new ForbiddenError('You are not an active participant in this chat room');
    }

    return this.chatRepository.markMessagesAsRead(dto.roomId, userId, dto.messageIds);
  }
}
