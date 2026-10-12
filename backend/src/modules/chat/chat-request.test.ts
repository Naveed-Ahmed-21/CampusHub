import { ChatService } from './chat.service';
import { ChatRepository } from './chat.repository';
import { NotificationsService } from '../notifications/notifications.service';
import { NotFoundError, ForbiddenError, BadRequestError, ConflictError } from '../../shared/errors/AppError';
import { prisma } from '../../config/database';
import { Role, ChatRequestStatus } from '@prisma/client';

jest.mock('../../config/database', () => ({
  prisma: {
    user: {
      findUnique: jest.fn(),
    },
    studentChatSettings: {
      findUnique: jest.fn(),
      upsert: jest.fn(),
    },
    chatRequest: {
      findFirst: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    chatBlock: {
      findFirst: jest.fn(),
      upsert: jest.fn(),
      deleteMany: jest.fn(),
    },
    chatRoom: {
      update: jest.fn(),
    },
    chatMessage: {
      count: jest.fn(),
      create: jest.fn(),
    },
  },
}));

describe('Student Messaging Request System', () => {
  let chatRepository: jest.Mocked<ChatRepository>;
  let notificationsService: jest.Mocked<NotificationsService>;
  let chatService: ChatService;

  const mockCollegeId = 'college-123';
  const studentAId = 'student-aaa';
  const studentBId = 'student-bbb';
  const facultyId = 'faculty-fff';
  const adminId = 'admin-111';
  const mockRoomId = 'room-456';
  const mockRequestId = 'req-789';

  beforeEach(() => {
    jest.clearAllMocks();

    chatRepository = {
      findDirectChatRoom: jest.fn(),
      createDirectChatRoom: jest.fn(),
      getStudentChatSettings: jest.fn(),
      upsertStudentChatSettings: jest.fn(),
      findPendingChatRequest: jest.fn(),
      findChatRequestById: jest.fn(),
      createChatRequest: jest.fn(),
      updateChatRequestStatus: jest.fn(),
      getIncomingChatRequests: jest.fn(),
      getSentChatRequests: jest.fn(),
      isChatBlockedBetween: jest.fn(),
      getBlockRecord: jest.fn(),
      blockUser: jest.fn(),
      unblockUser: jest.fn(),
      getBlockedUsers: jest.fn(),
    } as unknown as jest.Mocked<ChatRepository>;

    notificationsService = {
      sendNotification: jest.fn().mockResolvedValue({} as any),
    } as unknown as jest.Mocked<NotificationsService>;

    chatService = new ChatService(chatRepository, notificationsService);
  });

  describe('Student Chat Settings', () => {
    it('should return settings for student with default false when none exist', async () => {
      chatRepository.getStudentChatSettings.mockResolvedValue(null);

      const result = await chatService.getChatSettings(studentAId, Role.STUDENT);
      expect(result).toEqual({
        requireStudentConversationApproval: false,
        isEligible: true,
      });
    });

    it('should return isEligible: false for non-student roles', async () => {
      const result = await chatService.getChatSettings(facultyId, Role.FACULTY);
      expect(result).toEqual({
        requireStudentConversationApproval: false,
        isEligible: false,
      });
    });

    it('should allow student to update approval setting to true', async () => {
      chatRepository.upsertStudentChatSettings.mockResolvedValue({
        id: 'settings-1',
        student_id: studentAId,
        require_student_conversation_approval: true,
        created_at: new Date(),
        updated_at: new Date(),
      });

      const result = await chatService.updateChatSettings(studentAId, Role.STUDENT, {
        requireStudentConversationApproval: true,
      });

      expect(result).toEqual({
        requireStudentConversationApproval: true,
        isEligible: true,
      });
      expect(chatRepository.upsertStudentChatSettings).toHaveBeenCalledWith(studentAId, true);
    });

    it('should forbid non-student roles from updating student chat settings', async () => {
      await expect(
        chatService.updateChatSettings(facultyId, Role.FACULTY, {
          requireStudentConversationApproval: true,
        })
      ).rejects.toThrow(ForbiddenError);
    });
  });

  describe('Permission Check Matrix (checkChatPermission)', () => {
    beforeEach(() => {
      chatRepository.getBlockRecord.mockResolvedValue(null);
    });

    it('TEST 1: Student A -> Student B with B setting OFF should allow direct chat', async () => {
      (prisma.user.findUnique as jest.Mock)
        .mockResolvedValueOnce({ id: studentAId, role: Role.STUDENT, college_id: mockCollegeId, first_name: 'Naveed', last_name: 'Ahmed' })
        .mockResolvedValueOnce({ id: studentBId, role: Role.STUDENT, college_id: mockCollegeId, first_name: 'Rahul', last_name: 'Kumar' });

      chatRepository.findDirectChatRoom.mockResolvedValue(null);
      chatRepository.getStudentChatSettings.mockResolvedValue({
        id: 's-1',
        student_id: studentBId,
        require_student_conversation_approval: false,
        created_at: new Date(),
        updated_at: new Date(),
      });

      const result = await chatService.checkChatPermission(studentAId, studentBId, mockCollegeId);
      expect(result.action).toBe('ALLOW_DIRECT_CHAT');
      expect(result.isBlockedByYou).toBe(false);
      expect(result.isBlockedByThem).toBe(false);
    });

    it('TEST 2: Student A -> Student B with B setting ON should require chat request', async () => {
      (prisma.user.findUnique as jest.Mock)
        .mockResolvedValueOnce({ id: studentAId, role: Role.STUDENT, college_id: mockCollegeId, first_name: 'Naveed', last_name: 'Ahmed' })
        .mockResolvedValueOnce({ id: studentBId, role: Role.STUDENT, college_id: mockCollegeId, first_name: 'Rahul', last_name: 'Kumar' });

      chatRepository.findDirectChatRoom.mockResolvedValue(null);
      chatRepository.getStudentChatSettings.mockResolvedValue({
        id: 's-1',
        student_id: studentBId,
        require_student_conversation_approval: true,
        created_at: new Date(),
        updated_at: new Date(),
      });
      chatRepository.findPendingChatRequest.mockResolvedValue(null);

      const result = await chatService.checkChatPermission(studentAId, studentBId, mockCollegeId);
      expect(result.action).toBe('REQUIRE_CHAT_REQUEST');
    });

    it('TEST 7/14: Existing active conversation should allow direct chat even if B setting is ON', async () => {
      (prisma.user.findUnique as jest.Mock)
        .mockResolvedValueOnce({ id: studentAId, role: Role.STUDENT, college_id: mockCollegeId, first_name: 'Naveed', last_name: 'Ahmed' })
        .mockResolvedValueOnce({ id: studentBId, role: Role.STUDENT, college_id: mockCollegeId, first_name: 'Rahul', last_name: 'Kumar' });

      chatRepository.findDirectChatRoom.mockResolvedValue({
        id: mockRoomId,
        last_message_at: new Date(),
        messages: [{ id: 'm-1' }],
      } as any);

      const result = await chatService.checkChatPermission(studentAId, studentBId, mockCollegeId);
      expect(result.action).toBe('ALLOW_DIRECT_CHAT');
      expect(result.roomId).toBe(mockRoomId);
      expect(chatRepository.getStudentChatSettings).not.toHaveBeenCalled();
    });

    it('TEST 8: Faculty -> Student with Student setting ON should allow direct chat without request', async () => {
      (prisma.user.findUnique as jest.Mock)
        .mockResolvedValueOnce({ id: facultyId, role: Role.FACULTY, college_id: mockCollegeId, first_name: 'Dr. Arun', last_name: 'Kumar' })
        .mockResolvedValueOnce({ id: studentBId, role: Role.STUDENT, college_id: mockCollegeId, first_name: 'Rahul', last_name: 'Kumar' });

      chatRepository.findDirectChatRoom.mockResolvedValue(null);

      const result = await chatService.checkChatPermission(facultyId, studentBId, mockCollegeId);
      expect(result.action).toBe('ALLOW_DIRECT_CHAT');
      expect(chatRepository.getStudentChatSettings).not.toHaveBeenCalled();
    });

    it('TEST 9: Student -> Faculty should allow direct chat without request', async () => {
      (prisma.user.findUnique as jest.Mock)
        .mockResolvedValueOnce({ id: studentAId, role: Role.STUDENT, college_id: mockCollegeId, first_name: 'Naveed', last_name: 'Ahmed' })
        .mockResolvedValueOnce({ id: facultyId, role: Role.FACULTY, college_id: mockCollegeId, first_name: 'Dr. Arun', last_name: 'Kumar' });

      chatRepository.findDirectChatRoom.mockResolvedValue(null);

      const result = await chatService.checkChatPermission(studentAId, facultyId, mockCollegeId);
      expect(result.action).toBe('ALLOW_DIRECT_CHAT');
    });

    it('TEST 10: Admin -> Student should allow direct chat without request', async () => {
      (prisma.user.findUnique as jest.Mock)
        .mockResolvedValueOnce({ id: adminId, role: Role.ADMIN, college_id: mockCollegeId, first_name: 'Campus', last_name: 'Admin' })
        .mockResolvedValueOnce({ id: studentBId, role: Role.STUDENT, college_id: mockCollegeId, first_name: 'Rahul', last_name: 'Kumar' });

      chatRepository.findDirectChatRoom.mockResolvedValue(null);

      const result = await chatService.checkChatPermission(adminId, studentBId, mockCollegeId);
      expect(result.action).toBe('ALLOW_DIRECT_CHAT');
    });

    it('TEST 12/13: Blocked conversation should return BLOCKED action', async () => {
      (prisma.user.findUnique as jest.Mock)
        .mockResolvedValueOnce({ id: studentAId, role: Role.STUDENT, college_id: mockCollegeId, first_name: 'Naveed', last_name: 'Ahmed' })
        .mockResolvedValueOnce({ id: studentBId, role: Role.STUDENT, college_id: mockCollegeId, first_name: 'Rahul', last_name: 'Kumar' });

      chatRepository.getBlockRecord.mockResolvedValue({
        id: 'blk-1',
        blocker_id: studentBId,
        blocked_id: studentAId,
        created_at: new Date(),
      });

      const result = await chatService.checkChatPermission(studentAId, studentBId, mockCollegeId);
      expect(result.action).toBe('BLOCKED');
      expect(result.isBlockedByYou).toBe(false);
      expect(result.isBlockedByThem).toBe(true);
    });

    it('TEST 15: Pending request already exists should return REQUEST_PENDING', async () => {
      (prisma.user.findUnique as jest.Mock)
        .mockResolvedValueOnce({ id: studentAId, role: Role.STUDENT, college_id: mockCollegeId, first_name: 'Naveed', last_name: 'Ahmed' })
        .mockResolvedValueOnce({ id: studentBId, role: Role.STUDENT, college_id: mockCollegeId, first_name: 'Rahul', last_name: 'Kumar' });

      chatRepository.findDirectChatRoom.mockResolvedValue(null);
      chatRepository.getStudentChatSettings.mockResolvedValue({
        id: 's-1',
        student_id: studentBId,
        require_student_conversation_approval: true,
        created_at: new Date(),
        updated_at: new Date(),
      });
      chatRepository.findPendingChatRequest.mockResolvedValue({
        id: mockRequestId,
        status: ChatRequestStatus.PENDING,
      } as any);

      const result = await chatService.checkChatPermission(studentAId, studentBId, mockCollegeId);
      expect(result.action).toBe('REQUEST_PENDING');
      expect(result.requestId).toBe(mockRequestId);
    });
  });

  describe('Chat Request Creation & Validation', () => {
    it('TEST 3: Student A sends one introductory message to Student B', async () => {
      (prisma.user.findUnique as jest.Mock)
        .mockResolvedValueOnce({ id: studentAId, role: Role.STUDENT, college_id: mockCollegeId, first_name: 'Naveed', last_name: 'Ahmed' })
        .mockResolvedValueOnce({ id: studentBId, role: Role.STUDENT, college_id: mockCollegeId, first_name: 'Rahul', last_name: 'Kumar' });

      chatRepository.isChatBlockedBetween.mockResolvedValue(false);
      chatRepository.findDirectChatRoom.mockResolvedValue(null);
      chatRepository.findPendingChatRequest.mockResolvedValue(null);
      chatRepository.createChatRequest.mockResolvedValue({
        id: mockRequestId,
        sender_id: studentAId,
        recipient_id: studentBId,
        introductory_message: 'Hi Rahul, I wanted to discuss the CampusHub project with you.',
        status: ChatRequestStatus.PENDING,
        created_at: new Date(),
        updated_at: new Date(),
      } as any);

      const result = await chatService.createChatRequest(studentAId, mockCollegeId, {
        recipientId: studentBId,
        introductoryMessage: 'Hi Rahul, I wanted to discuss the CampusHub project with you.',
      });

      expect(result.id).toBe(mockRequestId);
      expect(result.status).toBe(ChatRequestStatus.PENDING);
      expect(notificationsService.sendNotification).toHaveBeenCalledWith(
        expect.objectContaining({
          user_id: studentBId,
          title: 'New Chat Request',
        })
      );
    });

    it('TEST 15: Duplicate pending request throws ConflictError (409)', async () => {
      (prisma.user.findUnique as jest.Mock)
        .mockResolvedValueOnce({ id: studentAId, role: Role.STUDENT, college_id: mockCollegeId, first_name: 'Naveed', last_name: 'Ahmed' })
        .mockResolvedValueOnce({ id: studentBId, role: Role.STUDENT, college_id: mockCollegeId, first_name: 'Rahul', last_name: 'Kumar' });

      chatRepository.isChatBlockedBetween.mockResolvedValue(false);
      chatRepository.findDirectChatRoom.mockResolvedValue(null);
      chatRepository.findPendingChatRequest.mockResolvedValue({ id: 'existing-req' } as any);

      await expect(
        chatService.createChatRequest(studentAId, mockCollegeId, {
          recipientId: studentBId,
          introductoryMessage: 'Second attempt message',
        })
      ).rejects.toThrow(ConflictError);
    });

    it('should reject empty or overly long introductory messages', async () => {
      (prisma.user.findUnique as jest.Mock).mockImplementation((args: any) => {
        if (args.where.id === studentAId) {
          return Promise.resolve({ id: studentAId, role: Role.STUDENT, college_id: mockCollegeId, first_name: 'Naveed', last_name: 'Ahmed' });
        }
        if (args.where.id === studentBId) {
          return Promise.resolve({ id: studentBId, role: Role.STUDENT, college_id: mockCollegeId, first_name: 'Rahul', last_name: 'Kumar' });
        }
        return Promise.resolve(null);
      });

      chatRepository.isChatBlockedBetween.mockResolvedValue(false);
      chatRepository.findDirectChatRoom.mockResolvedValue(null);
      chatRepository.findPendingChatRequest.mockResolvedValue(null);

      await expect(
        chatService.createChatRequest(studentAId, mockCollegeId, {
          recipientId: studentBId,
          introductoryMessage: '   ',
        })
      ).rejects.toThrow(BadRequestError);

      await expect(
        chatService.createChatRequest(studentAId, mockCollegeId, {
          recipientId: studentBId,
          introductoryMessage: 'x'.repeat(301),
        })
      ).rejects.toThrow(BadRequestError);
    });
  });

  describe('Accept & Decline Workflow', () => {
    it('TEST 4: Student B accepts request -> creates conversation and posts introductory message', async () => {
      chatRepository.findChatRequestById.mockResolvedValue({
        id: mockRequestId,
        sender_id: studentAId,
        recipient_id: studentBId,
        introductory_message: 'Hi Rahul, let us connect.',
        status: ChatRequestStatus.PENDING,
        sender: { id: studentAId, first_name: 'Naveed', last_name: 'Ahmed' },
        recipient: { id: studentBId, first_name: 'Rahul', last_name: 'Kumar' },
      } as any);

      chatRepository.findDirectChatRoom.mockResolvedValue(null);
      chatRepository.createDirectChatRoom.mockResolvedValue({
        id: mockRoomId,
        college_id: mockCollegeId,
        type: 'DIRECT',
      } as any);
      (prisma.chatMessage.count as jest.Mock).mockResolvedValue(0);
      (prisma.chatMessage.create as jest.Mock).mockResolvedValue({ id: 'msg-first' });
      (prisma.chatRoom.update as jest.Mock).mockResolvedValue({});

      chatRepository.updateChatRequestStatus.mockResolvedValue({
        id: mockRequestId,
        status: ChatRequestStatus.ACCEPTED,
        conversation_id: mockRoomId,
      } as any);

      const result = await chatService.acceptChatRequest(mockRequestId, studentBId, mockCollegeId);
      expect(result.room.id).toBe(mockRoomId);
      expect(result.request.status).toBe(ChatRequestStatus.ACCEPTED);
      expect(prisma.chatMessage.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          room_id: mockRoomId,
          sender_id: studentAId,
          message: 'Hi Rahul, let us connect.',
        }),
      });
      expect(notificationsService.sendNotification).toHaveBeenCalledWith(
        expect.objectContaining({
          user_id: studentAId,
          title: 'Chat Request Accepted',
        })
      );
    });

    it('TEST 5: Student B declines request -> request closed without creating room', async () => {
      chatRepository.findChatRequestById.mockResolvedValue({
        id: mockRequestId,
        sender_id: studentAId,
        recipient_id: studentBId,
        status: ChatRequestStatus.PENDING,
        sender: { id: studentAId, first_name: 'Naveed', last_name: 'Ahmed' },
        recipient: { id: studentBId, first_name: 'Rahul', last_name: 'Kumar' },
      } as any);

      chatRepository.updateChatRequestStatus.mockResolvedValue({
        id: mockRequestId,
        status: ChatRequestStatus.DECLINED,
      } as any);

      const result = await chatService.declineChatRequest(mockRequestId, studentBId);
      expect(result.status).toBe(ChatRequestStatus.DECLINED);
      expect(chatRepository.createDirectChatRoom).not.toHaveBeenCalled();
      expect(notificationsService.sendNotification).toHaveBeenCalledWith(
        expect.objectContaining({
          user_id: studentAId,
          title: 'Chat Request Declined',
        })
      );
    });

    it('should reject unauthorized user attempting to accept or decline', async () => {
      chatRepository.findChatRequestById.mockResolvedValue({
        id: mockRequestId,
        sender_id: studentAId,
        recipient_id: studentBId,
        status: ChatRequestStatus.PENDING,
      } as any);

      // Student A (the sender) tries to accept own request
      await expect(
        chatService.acceptChatRequest(mockRequestId, studentAId, mockCollegeId)
      ).rejects.toThrow(ForbiddenError);

      await expect(
        chatService.declineChatRequest(mockRequestId, studentAId)
      ).rejects.toThrow(ForbiddenError);
    });

    it('should allow sender to cancel a pending request', async () => {
      chatRepository.findChatRequestById.mockResolvedValue({
        id: mockRequestId,
        sender_id: studentAId,
        recipient_id: studentBId,
        status: ChatRequestStatus.PENDING,
      } as any);

      chatRepository.updateChatRequestStatus.mockResolvedValue({
        id: mockRequestId,
        status: ChatRequestStatus.CANCELLED,
      } as any);

      const result = await chatService.cancelChatRequest(mockRequestId, studentAId);
      expect(result.status).toBe(ChatRequestStatus.CANCELLED);
    });
  });

  describe('Chat-Only Blocking (blockUser / unblockUser)', () => {
    it('TEST 12: should block messaging between users without touching other modules', async () => {
      chatRepository.blockUser.mockResolvedValue({
        id: 'blk-1',
        blocker_id: studentAId,
        blocked_id: studentBId,
        created_at: new Date(),
      });

      const result = await chatService.blockUser(studentAId, studentBId);
      expect(result.blocker_id).toBe(studentAId);
      expect(result.blocked_id).toBe(studentBId);
      expect(chatRepository.blockUser).toHaveBeenCalledWith(studentAId, studentBId);
    });

    it('should unblock user when requested by blocker', async () => {
      chatRepository.unblockUser.mockResolvedValue({ count: 1 } as any);

      const result = await chatService.unblockUser(studentAId, studentBId);
      expect(result.success).toBe(true);
      expect(chatRepository.unblockUser).toHaveBeenCalledWith(studentAId, studentBId);
    });
  });
});
