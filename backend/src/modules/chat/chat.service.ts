import { ChatRepository } from './chat.repository';
import {
  CreateDirectChatDto,
  SendMessageDto,
  MarkReadDto,
  UpdateChatSettingsDto,
  CreateChatRequestDto,
  ChatPermissionDto,
} from './chat.types';
import { NotFoundError, ForbiddenError, BadRequestError, ConflictError } from '../../shared/errors/AppError';
import { prisma } from '../../config/database';
import { ChatRoomType, Role, ChatRequestStatus } from '@prisma/client';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationsRepository } from '../notifications/notifications.repository';

export class ChatService {
  private readonly notificationsService: NotificationsService;

  constructor(
    private readonly chatRepository: ChatRepository,
    notificationsService?: NotificationsService
  ) {
    this.notificationsService = notificationsService ?? new NotificationsService(new NotificationsRepository());
  }

  async getUserRooms(userId: string, collegeId: string, type?: ChatRoomType, search?: string) {
    try {
      // 1. Ensure user is enrolled into Whole College Chat
      await this.chatRepository.addUserToWholeCollegeChat(collegeId, userId);

      // 2. Fetch user information for Department & Batch groups
      const user = await prisma.user.findUnique({
        where: { id: userId },
        select: {
          role: true,
          department_id: true,
          department: { select: { id: true, name: true } },
          academic_profile: { select: { batch_name: true, admission_year: true } },
        },
      });

      if (user) {
        // Auto-join Department Chat
        if (user.department_id && user.department?.name) {
          await this.chatRepository.addUserToDepartmentChat(
            user.department_id,
            collegeId,
            user.department.name,
            userId
          );
        }

        // Determine batch name
        let batchName: string | null = null;
        if (user.academic_profile?.batch_name) {
          batchName = user.academic_profile.batch_name;
        } else if (user.academic_profile?.admission_year) {
          batchName = `${user.academic_profile.admission_year}-${user.academic_profile.admission_year + 4}`;
        } else if (user.role === Role.STUDENT) {
          batchName = '2023-2027';
        }

        if (batchName) {
          // Auto-join College-wide Batch Chat (all departments in this batch)
          await this.chatRepository.addUserToBatchChat(collegeId, batchName, userId);

          // Auto-join Batch-wise Department Chat (only this department in this batch)
          if (user.department_id && user.department?.name) {
            await this.chatRepository.addUserToBatchDepartmentChat(
              user.department_id,
              collegeId,
              user.department.name,
              batchName,
              userId
            );
          }
        }
      }
    } catch (_) {}

    return this.chatRepository.findUserRooms(userId, collegeId, type, search);
  }

  async ensureWholeCollegeChat(collegeId: string, currentUserId?: string) {
    if (currentUserId) {
      return this.chatRepository.addUserToWholeCollegeChat(collegeId, currentUserId);
    }
    return this.chatRepository.findOrCreateWholeCollegeChatRoom(collegeId);
  }

  async getPublicGroups(collegeId: string, currentUserId: string, query?: string, limit?: number) {
    return this.chatRepository.findPublicGroups(collegeId, currentUserId, query, limit);
  }

  async getOrCreateDirectChat(userId: string, collegeId: string, dto: CreateDirectChatDto) {
    if (userId === dto.targetUserId) {
      throw new BadRequestError('Cannot start a direct chat with yourself');
    }

    const isBlocked = await this.chatRepository.isChatBlockedBetween(userId, dto.targetUserId);
    if (isBlocked) {
      throw new ForbiddenError('Messaging is blocked between you and this user');
    }

    const [currentUser, targetUser] = await Promise.all([
      prisma.user.findUnique({
        where: { id: userId },
        select: { id: true, role: true, college_id: true, status: true },
      }),
      prisma.user.findUnique({
        where: { id: dto.targetUserId },
        select: { id: true, college_id: true, first_name: true, last_name: true, status: true, role: true },
      }),
    ]);

    if (!targetUser || targetUser.college_id !== collegeId || targetUser.status !== 'ACTIVE') {
      throw new NotFoundError('Target user not found in this college');
    }

    let room = await this.chatRepository.findDirectChatRoom(userId, dto.targetUserId, collegeId);

    // If no existing conversation with activity exists, check if recipient requires approval
    const hasMessages = room && ((room as any).messages?.length > 0 || room.last_message_at !== null);
    if (!hasMessages && currentUser?.role === Role.STUDENT && targetUser.role === Role.STUDENT) {
      const settings = await this.chatRepository.getStudentChatSettings(dto.targetUserId);
      if (settings?.require_student_conversation_approval) {
        throw new ForbiddenError(
          'Chat request required: this student requires approval before starting a new conversation'
        );
      }
    }

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

    const isAdmin = userRole === Role.ADMIN || (userRole as string) === 'ADMIN';
    const isMember = club.members.length > 0;

    if (!isMember && !isAdmin) {
      throw new ForbiddenError('Only club members can access club chat');
    }

    if (club.status !== 'APPROVED' && !isAdmin) {
      throw new ForbiddenError('Club chat is unavailable until this club is approved by college administration');
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

    if (room.type === ChatRoomType.DIRECT) {
      const otherParticipant = room.participants.find((p) => p.user_id !== senderId);
      if (otherParticipant) {
        const isBlocked = await this.chatRepository.isChatBlockedBetween(senderId, otherParticipant.user_id);
        if (isBlocked) {
          throw new ForbiddenError('Messaging is disabled because a user has blocked messages');
        }
      }
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

    if (room.name === 'Whole College') {
      const user = await prisma.user.findUnique({ where: { id: userId }, select: { role: true } });
      if (user?.role !== Role.ADMIN) {
        throw new ForbiddenError('Only the College Principal / Administrator can modify Whole College settings');
      }
    }

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

  private isInstitutionalRoom(room: { name: string | null; department_id?: string | null }): boolean {
    if (!room.name) return false;
    const name = room.name.trim();
    if (name === 'Whole College') return true;
    if (name.startsWith('Batch ')) return true;
    if (name.includes('Department')) return true;
    if (room.department_id !== null && room.department_id !== undefined) return true;
    return false;
  }

  async leaveGroup(roomId: string, userId: string) {
    const room = await this.chatRepository.findRoomById(roomId);
    if (!room) {
      throw new NotFoundError('Group not found');
    }

    if (this.isInstitutionalRoom(room)) {
      throw new ForbiddenError(
        'Leaving official institutional groups (Whole College, Department, or Batch groups) is restricted.'
      );
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

    if (this.isInstitutionalRoom(room)) {
      throw new ForbiddenError('Members cannot be removed from official institutional groups.');
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

  // ==========================================
  // Student Chat Settings
  // ==========================================
  async getChatSettings(userId: string, role: string) {
    if (role !== Role.STUDENT) {
      return {
        requireStudentConversationApproval: false,
        isEligible: false,
      };
    }
    const settings = await this.chatRepository.getStudentChatSettings(userId);
    return {
      requireStudentConversationApproval: settings?.require_student_conversation_approval ?? false,
      isEligible: true,
    };
  }

  async updateChatSettings(userId: string, role: string, dto: UpdateChatSettingsDto) {
    if (role !== Role.STUDENT) {
      throw new ForbiddenError('Only students can configure student conversation approval settings');
    }
    const settings = await this.chatRepository.upsertStudentChatSettings(
      userId,
      dto.requireStudentConversationApproval
    );
    return {
      requireStudentConversationApproval: settings.require_student_conversation_approval,
      isEligible: true,
    };
  }

  // ==========================================
  // Permission & Pre-Conversation Validation
  // ==========================================
  async checkChatPermission(
    currentUserId: string,
    targetUserId: string,
    collegeId: string
  ): Promise<ChatPermissionDto> {
    if (currentUserId === targetUserId) {
      throw new BadRequestError('Cannot start a conversation with yourself');
    }

    const [currentUser, targetUser] = await Promise.all([
      prisma.user.findUnique({
        where: { id: currentUserId },
        select: { id: true, role: true, first_name: true, last_name: true, college_id: true },
      }),
      prisma.user.findUnique({
        where: { id: targetUserId },
        select: {
          id: true,
          role: true,
          first_name: true,
          last_name: true,
          avatar_url: true,
          college_id: true,
          department: { select: { name: true, code: true } },
        },
      }),
    ]);

    if (!currentUser || !targetUser || targetUser.college_id !== collegeId) {
      throw new NotFoundError('Target user not found');
    }

    const blockRecord = await this.chatRepository.getBlockRecord(currentUserId, targetUserId);
    const isBlockedByYou = blockRecord?.blocker_id === currentUserId;
    const isBlockedByThem = blockRecord?.blocker_id === targetUserId;

    const targetUserInfo = {
      id: targetUser.id,
      name: `${targetUser.first_name} ${targetUser.last_name}`.trim(),
      role: targetUser.role,
      avatar_url: targetUser.avatar_url,
      department: targetUser.department?.name,
    };

    if (blockRecord) {
      return {
        action: 'BLOCKED',
        isBlockedByYou,
        isBlockedByThem,
        targetUser: targetUserInfo,
      };
    }

    // Check if an active direct conversation already exists
    const existingRoom = await this.chatRepository.findDirectChatRoom(currentUserId, targetUserId, collegeId);
    if (existingRoom) {
      const hasActivity =
        (existingRoom as any).messages?.length > 0 || existingRoom.last_message_at !== null;
      if (hasActivity) {
        return {
          action: 'ALLOW_DIRECT_CHAT',
          roomId: existingRoom.id,
          isBlockedByYou: false,
          isBlockedByThem: false,
          targetUser: targetUserInfo,
        };
      }
    }

    // Role-based check:
    // Restriction applies ONLY to STUDENT -> STUDENT first-time conversations.
    // Faculty -> Student, Student -> Faculty, Admin -> Student, Placement -> Student: all DIRECT.
    const isSenderStudent = currentUser.role === Role.STUDENT;
    const isTargetStudent = targetUser.role === Role.STUDENT;

    if (!isSenderStudent || !isTargetStudent) {
      return {
        action: 'ALLOW_DIRECT_CHAT',
        roomId: existingRoom?.id,
        isBlockedByYou: false,
        isBlockedByThem: false,
        targetUser: targetUserInfo,
      };
    }

    // Both are students and no active conversation exists.
    // Check recipient's setting:
    const settings = await this.chatRepository.getStudentChatSettings(targetUserId);
    const requireApproval = settings?.require_student_conversation_approval ?? false;

    if (!requireApproval) {
      return {
        action: 'ALLOW_DIRECT_CHAT',
        roomId: existingRoom?.id,
        isBlockedByYou: false,
        isBlockedByThem: false,
        targetUser: targetUserInfo,
      };
    }

    // Recipient requires approval. Check if there's already a PENDING request
    const pendingRequest = await this.chatRepository.findPendingChatRequest(currentUserId, targetUserId);
    if (pendingRequest) {
      return {
        action: 'REQUEST_PENDING',
        requestId: pendingRequest.id,
        isBlockedByYou: false,
        isBlockedByThem: false,
        targetUser: targetUserInfo,
      };
    }

    return {
      action: 'REQUIRE_CHAT_REQUEST',
      isBlockedByYou: false,
      isBlockedByThem: false,
      targetUser: targetUserInfo,
    };
  }

  // ==========================================
  // Chat Request Workflow
  // ==========================================
  async createChatRequest(senderId: string, collegeId: string, dto: CreateChatRequestDto) {
    if (senderId === dto.recipientId) {
      throw new BadRequestError('Cannot send a chat request to yourself');
    }

    const [sender, recipient] = await Promise.all([
      prisma.user.findUnique({
        where: { id: senderId },
        select: { id: true, role: true, first_name: true, last_name: true, college_id: true },
      }),
      prisma.user.findUnique({
        where: { id: dto.recipientId },
        select: { id: true, role: true, first_name: true, last_name: true, college_id: true },
      }),
    ]);

    if (!sender || !recipient || recipient.college_id !== collegeId) {
      throw new NotFoundError('Recipient user not found');
    }

    // Verify both are students
    if (sender.role !== Role.STUDENT || recipient.role !== Role.STUDENT) {
      throw new BadRequestError('Chat requests apply only to student-to-student conversations');
    }

    // Verify not blocked
    const isBlocked = await this.chatRepository.isChatBlockedBetween(senderId, dto.recipientId);
    if (isBlocked) {
      throw new ForbiddenError('Cannot send chat request: messaging is blocked');
    }

    // Verify no active conversation already exists
    const existingRoom = await this.chatRepository.findDirectChatRoom(senderId, dto.recipientId, collegeId);
    if (existingRoom && ((existingRoom as any).messages?.length > 0 || existingRoom.last_message_at !== null)) {
      throw new BadRequestError('An active conversation already exists between you and this student');
    }

    // Check for duplicate pending requests
    const pendingRequest = await this.chatRepository.findPendingChatRequest(senderId, dto.recipientId);
    if (pendingRequest) {
      throw new ConflictError('Chat request already pending');
    }

    const introMsg = dto.introductoryMessage.trim();
    if (introMsg.length === 0) {
      throw new BadRequestError('Introductory message cannot be empty');
    }
    if (introMsg.length > 300) {
      throw new BadRequestError('Introductory message cannot exceed 300 characters');
    }

    const chatRequest = await this.chatRepository.createChatRequest(senderId, dto.recipientId, introMsg);

    // In-app Notification for recipient
    const senderName = `${sender.first_name} ${sender.last_name}`.trim();
    try {
      await this.notificationsService.sendNotification({
        user_id: dto.recipientId,
        title: 'New Chat Request',
        body: `${senderName} wants to start a conversation with you.`,
        type: 'CHAT_MESSAGE' as any,
        category: 'Chat',
        deep_link: '/chat/requests',
        metadata: {
          type: 'CHAT_REQUEST',
          requestId: chatRequest.id,
          senderId,
        },
      });
    } catch (_) {}

    // Real-time socket event
    try {
      const { SocketServer } = await import('../../infrastructure/socket/socket.server');
      SocketServer.getInstance().emitToUser(dto.recipientId, 'chat.request.created', chatRequest);
    } catch (_) {}

    return chatRequest;
  }

  async getIncomingChatRequests(userId: string) {
    return this.chatRepository.getIncomingChatRequests(userId, ChatRequestStatus.PENDING);
  }

  async getSentChatRequests(userId: string) {
    return this.chatRepository.getSentChatRequests(userId);
  }

  async acceptChatRequest(requestId: string, userId: string, collegeId: string) {
    const request = await this.chatRepository.findChatRequestById(requestId);
    if (!request) {
      throw new NotFoundError('Chat request not found');
    }

    if (request.recipient_id !== userId) {
      throw new ForbiddenError('You are not authorized to accept this chat request');
    }

    if (request.status !== ChatRequestStatus.PENDING) {
      throw new BadRequestError(`Cannot accept request with status ${request.status}`);
    }

    // Create or find direct room
    let room = await this.chatRepository.findDirectChatRoom(request.sender_id, request.recipient_id, collegeId);
    if (!room) {
      room = await this.chatRepository.createDirectChatRoom(request.sender_id, request.recipient_id, collegeId);
    }

    // Add introductory message as the first message if no messages yet
    const messageCount = await prisma.chatMessage.count({
      where: { room_id: room.id },
    });

    if (messageCount === 0) {
      await prisma.chatMessage.create({
        data: {
          room_id: room.id,
          sender_id: request.sender_id,
          message: request.introductory_message,
        },
      });

      await prisma.chatRoom.update({
        where: { id: room.id },
        data: { last_message_at: new Date() },
      });
    }

    const updatedRequest = await this.chatRepository.updateChatRequestStatus(
      requestId,
      ChatRequestStatus.ACCEPTED,
      room.id
    );

    // Notify sender
    const recipientName = `${request.recipient.first_name} ${request.recipient.last_name}`.trim();
    try {
      await this.notificationsService.sendNotification({
        user_id: request.sender_id,
        title: 'Chat Request Accepted',
        body: `${recipientName} accepted your chat request.`,
        type: 'CHAT_MESSAGE' as any,
        category: 'Chat',
        deep_link: `/chat/room/${room.id}`,
        metadata: {
          type: 'CHAT_REQUEST_ACCEPTED',
          requestId: request.id,
          roomId: room.id,
        },
      });
    } catch (_) {}

    // Emit real-time socket event
    try {
      const { SocketServer } = await import('../../infrastructure/socket/socket.server');
      SocketServer.getInstance().emitToUser(request.sender_id, 'chat.request.accepted', {
        requestId: request.id,
        roomId: room.id,
        room,
      });
    } catch (_) {}

    return { request: updatedRequest, room };
  }

  async declineChatRequest(requestId: string, userId: string) {
    const request = await this.chatRepository.findChatRequestById(requestId);
    if (!request) {
      throw new NotFoundError('Chat request not found');
    }

    if (request.recipient_id !== userId) {
      throw new ForbiddenError('You are not authorized to decline this chat request');
    }

    if (request.status !== ChatRequestStatus.PENDING) {
      throw new BadRequestError(`Cannot decline request with status ${request.status}`);
    }

    const updatedRequest = await this.chatRepository.updateChatRequestStatus(
      requestId,
      ChatRequestStatus.DECLINED
    );

    const recipientName = `${request.recipient.first_name} ${request.recipient.last_name}`.trim();
    try {
      await this.notificationsService.sendNotification({
        user_id: request.sender_id,
        title: 'Chat Request Declined',
        body: `${recipientName} declined your chat request.`,
        type: 'CHAT_MESSAGE' as any,
        category: 'Chat',
        metadata: {
          type: 'CHAT_REQUEST_DECLINED',
          requestId: request.id,
        },
      });
    } catch (_) {}

    try {
      const { SocketServer } = await import('../../infrastructure/socket/socket.server');
      SocketServer.getInstance().emitToUser(request.sender_id, 'chat.request.declined', {
        requestId: request.id,
      });
    } catch (_) {}

    return updatedRequest;
  }

  async cancelChatRequest(requestId: string, userId: string) {
    const request = await this.chatRepository.findChatRequestById(requestId);
    if (!request) {
      throw new NotFoundError('Chat request not found');
    }

    if (request.sender_id !== userId) {
      throw new ForbiddenError('You are not authorized to cancel this chat request');
    }

    if (request.status !== ChatRequestStatus.PENDING) {
      throw new BadRequestError(`Cannot cancel request with status ${request.status}`);
    }

    const updatedRequest = await this.chatRepository.updateChatRequestStatus(
      requestId,
      ChatRequestStatus.CANCELLED
    );

    try {
      const { SocketServer } = await import('../../infrastructure/socket/socket.server');
      SocketServer.getInstance().emitToUser(request.recipient_id, 'chat.request.cancelled', {
        requestId: request.id,
      });
    } catch (_) {}

    return updatedRequest;
  }

  // ==========================================
  // Chat-Only Blocking
  // ==========================================
  async blockUser(currentUserId: string, targetUserId: string) {
    if (currentUserId === targetUserId) {
      throw new BadRequestError('Cannot block yourself');
    }

    const block = await this.chatRepository.blockUser(currentUserId, targetUserId);

    try {
      const { SocketServer } = await import('../../infrastructure/socket/socket.server');
      SocketServer.getInstance().emitToUser(targetUserId, 'chat.blocked', { blockerId: currentUserId });
      SocketServer.getInstance().emitToUser(currentUserId, 'chat.blocked', { blockedId: targetUserId });
    } catch (_) {}

    return block;
  }

  async unblockUser(currentUserId: string, targetUserId: string) {
    if (currentUserId === targetUserId) {
      throw new BadRequestError('Cannot unblock yourself');
    }

    await this.chatRepository.unblockUser(currentUserId, targetUserId);

    try {
      const { SocketServer } = await import('../../infrastructure/socket/socket.server');
      SocketServer.getInstance().emitToUser(targetUserId, 'chat.unblocked', { unblockerId: currentUserId });
      SocketServer.getInstance().emitToUser(currentUserId, 'chat.unblocked', { unblockedId: targetUserId });
    } catch (_) {}

    return { success: true, message: 'User unblocked successfully' };
  }

  async getBlockedUsers(userId: string) {
    return this.chatRepository.getBlockedUsers(userId);
  }
}
