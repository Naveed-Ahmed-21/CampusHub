import { ChatService } from './chat.service';
import { ChatRepository } from './chat.repository';
import { NotFoundError, ForbiddenError, BadRequestError } from '../../shared/errors/AppError';

describe('ChatService', () => {
  let chatRepository: jest.Mocked<ChatRepository>;
  let chatService: ChatService;

  const mockCollegeId = 'college-123';
  const mockUserId1 = 'user-111';
  const mockUserId2 = 'user-222';
  const mockRoomId = 'room-999';
  const mockMessageId = 'msg-101';

  beforeEach(() => {
    chatRepository = {
      findUserRooms: jest.fn(),
      findDirectChatRoom: jest.fn(),
      createDirectChatRoom: jest.fn(),
      findOrCreateDepartmentChatRoom: jest.fn(),
      findRoomById: jest.fn(),
      findMessageById: jest.fn(),
      addParticipantToRoom: jest.fn(),
      createMessage: jest.fn(),
      getRoomMessages: jest.fn(),
      addOrToggleReaction: jest.fn(),
      removeReaction: jest.fn(),
      deleteMessageForMe: jest.fn(),
      deleteMessageForEveryone: jest.fn(),
      markMessagesAsRead: jest.fn(),
      updateUserOnlineStatus: jest.fn(),
    } as unknown as jest.Mocked<ChatRepository>;

    chatService = new ChatService(chatRepository);
  });

  describe('getOrCreateDirectChat', () => {
    it('should throw BadRequestError if user tries to chat with self', async () => {
      await expect(
        chatService.getOrCreateDirectChat(mockUserId1, mockCollegeId, { targetUserId: mockUserId1 })
      ).rejects.toThrow(BadRequestError);
    });
  });

  describe('getRoomMessages', () => {
    it('should return messages for room participants', async () => {
      chatRepository.findRoomById.mockResolvedValue({
        id: mockRoomId,
        participants: [{ user_id: mockUserId1, status: 'ACTIVE' }],
      } as never);

      chatRepository.getRoomMessages.mockResolvedValue({
        total: 1,
        page: 1,
        limit: 50,
        messages: [{ id: 'msg-1', message: 'Hello' }],
      } as never);

      const result = await chatService.getRoomMessages(mockRoomId, mockUserId1);

      expect(chatRepository.findRoomById).toHaveBeenCalledWith(mockRoomId);
      expect(result.messages.length).toBe(1);
    });

    it('should throw ForbiddenError if user is not a room participant', async () => {
      chatRepository.findRoomById.mockResolvedValue({
        id: mockRoomId,
        participants: [{ user_id: 'other-user', status: 'ACTIVE' }],
      } as never);

      await expect(
        chatService.getRoomMessages(mockRoomId, mockUserId1)
      ).rejects.toThrow(ForbiddenError);
    });
  });

  describe('sendMessage with Reply', () => {
    it('should send a reply message when reply target exists in same room', async () => {
      chatRepository.findRoomById.mockResolvedValue({
        id: mockRoomId,
        college_id: mockCollegeId,
        participants: [{ user_id: mockUserId1, status: 'ACTIVE' }],
      } as never);

      chatRepository.findMessageById.mockResolvedValue({
        id: 'reply-target-1',
        room_id: mockRoomId,
        message: 'Original question',
      } as never);

      chatRepository.createMessage.mockResolvedValue({
        id: 'msg-reply',
        room_id: mockRoomId,
        sender_id: mockUserId1,
        message: 'My answer',
        reply_to_message_id: 'reply-target-1',
      } as never);

      const result = await chatService.sendMessage(mockUserId1, mockCollegeId, {
        roomId: mockRoomId,
        message: 'My answer',
        reply_to_message_id: 'reply-target-1',
      });

      expect(chatRepository.createMessage).toHaveBeenCalled();
      expect(result.reply_to_message_id).toBe('reply-target-1');
    });

    it('should throw BadRequestError if reply target is in a different room', async () => {
      chatRepository.findRoomById.mockResolvedValue({
        id: mockRoomId,
        college_id: mockCollegeId,
        participants: [{ user_id: mockUserId1, status: 'ACTIVE' }],
      } as never);

      chatRepository.findMessageById.mockResolvedValue({
        id: 'reply-target-diff',
        room_id: 'other-room-id',
      } as never);

      await expect(
        chatService.sendMessage(mockUserId1, mockCollegeId, {
          roomId: mockRoomId,
          message: 'My answer',
          reply_to_message_id: 'reply-target-diff',
        })
      ).rejects.toThrow(BadRequestError);
    });
  });

  describe('Message Reactions', () => {
    it('should add or toggle allowed reaction for room participant', async () => {
      chatRepository.findMessageById.mockResolvedValue({
        id: mockMessageId,
        room_id: mockRoomId,
        is_deleted_for_everyone: false,
        room: {
          participants: [{ user_id: mockUserId1, status: 'ACTIVE' }],
        },
      } as never);

      chatRepository.addOrToggleReaction.mockResolvedValue({
        id: mockMessageId,
        room_id: mockRoomId,
        reactions: [{ emoji: '❤️', user_id: mockUserId1 }],
      } as never);

      const result = await chatService.addOrToggleReaction(mockMessageId, mockUserId1, '❤️');
      expect(chatRepository.addOrToggleReaction).toHaveBeenCalledWith(mockMessageId, mockUserId1, '❤️');
      expect(result).toBeDefined();
    });

    it('should reject invalid emoji not in allowed list', async () => {
      await expect(
        chatService.addOrToggleReaction(mockMessageId, mockUserId1, '🔥')
      ).rejects.toThrow(BadRequestError);
    });

    it('should reject reaction to a deleted message', async () => {
      chatRepository.findMessageById.mockResolvedValue({
        id: mockMessageId,
        room_id: mockRoomId,
        is_deleted_for_everyone: true,
        room: {
          participants: [{ user_id: mockUserId1, status: 'ACTIVE' }],
        },
      } as never);

      await expect(
        chatService.addOrToggleReaction(mockMessageId, mockUserId1, '❤️')
      ).rejects.toThrow(BadRequestError);
    });

    it('should remove reaction', async () => {
      chatRepository.findMessageById.mockResolvedValue({
        id: mockMessageId,
        room_id: mockRoomId,
        room: {
          participants: [{ user_id: mockUserId1, status: 'ACTIVE' }],
        },
      } as never);

      chatRepository.removeReaction.mockResolvedValue({
        id: mockMessageId,
        room_id: mockRoomId,
        reactions: [],
      } as never);

      await chatService.removeReaction(mockMessageId, mockUserId1, '❤️');
      expect(chatRepository.removeReaction).toHaveBeenCalledWith(mockMessageId, mockUserId1, '❤️');
    });
  });

  describe('Delete for Me', () => {
    it('should mark message as deleted only for requesting participant', async () => {
      chatRepository.findMessageById.mockResolvedValue({
        id: mockMessageId,
        room_id: mockRoomId,
        room: {
          participants: [{ user_id: mockUserId1, status: 'ACTIVE' }],
        },
      } as never);

      chatRepository.deleteMessageForMe.mockResolvedValue({
        messageId: mockMessageId,
        userId: mockUserId1,
        success: true,
      });

      const result = await chatService.deleteMessageForMe(mockMessageId, mockUserId1);
      expect(result.success).toBe(true);
      expect(chatRepository.deleteMessageForMe).toHaveBeenCalledWith(mockMessageId, mockUserId1);
    });
  });

  describe('Delete for Everyone & 24-Hour Enforcement', () => {
    it('should delete message for everyone if requested by sender within 24 hours', async () => {
      const recentTimestamp = new Date(Date.now() - 2 * 60 * 60 * 1000); // 2 hours ago

      chatRepository.findMessageById.mockResolvedValue({
        id: mockMessageId,
        room_id: mockRoomId,
        sender_id: mockUserId1,
        created_at: recentTimestamp,
        is_deleted_for_everyone: false,
      } as never);

      chatRepository.deleteMessageForEveryone.mockResolvedValue({
        id: mockMessageId,
        room_id: mockRoomId,
        is_deleted_for_everyone: true,
        message: 'This message was deleted',
      } as never);

      const result = await chatService.deleteMessageForEveryone(mockMessageId, mockUserId1);
      expect(result.is_deleted_for_everyone).toBe(true);
      expect(chatRepository.deleteMessageForEveryone).toHaveBeenCalledWith(mockMessageId);
    });

    it('should reject Delete for Everyone if requested by non-sender', async () => {
      chatRepository.findMessageById.mockResolvedValue({
        id: mockMessageId,
        room_id: mockRoomId,
        sender_id: mockUserId2, // different sender
        created_at: new Date(),
      } as never);

      await expect(
        chatService.deleteMessageForEveryone(mockMessageId, mockUserId1)
      ).rejects.toThrow(ForbiddenError);
    });

    it('should reject Delete for Everyone if message was sent more than 24 hours ago', async () => {
      const oldTimestamp = new Date(Date.now() - 25 * 60 * 60 * 1000); // 25 hours ago

      chatRepository.findMessageById.mockResolvedValue({
        id: mockMessageId,
        room_id: mockRoomId,
        sender_id: mockUserId1,
        created_at: oldTimestamp,
        is_deleted_for_everyone: false,
      } as never);

      await expect(
        chatService.deleteMessageForEveryone(mockMessageId, mockUserId1)
      ).rejects.toThrow(BadRequestError);
    });
  });

  describe('Video & Document Message Support', () => {
    it('should successfully send a VIDEO message with metadata', async () => {
      chatRepository.findRoomById.mockResolvedValue({
        id: mockRoomId,
        college_id: mockCollegeId,
        participants: [{ user_id: mockUserId1, status: 'ACTIVE' }],
      } as never);

      chatRepository.createMessage.mockResolvedValue({
        id: 'msg-video-1',
        room_id: mockRoomId,
        sender_id: mockUserId1,
        message: 'Check out this video demo',
        media_url: 'https://ik.imagekit.io/campushub/video.mp4',
        media_type: 'VIDEO',
        file_name: 'demo_recording.mp4',
        file_size: 15420000,
      } as never);

      const result = await chatService.sendMessage(mockUserId1, mockCollegeId, {
        roomId: mockRoomId,
        message: 'Check out this video demo',
        media_url: 'https://ik.imagekit.io/campushub/video.mp4',
        media_type: 'VIDEO',
        file_name: 'demo_recording.mp4',
        file_size: 15420000,
      });

      expect(result.id).toBe('msg-video-1');
      expect(result.media_type).toBe('VIDEO');
      expect(result.file_name).toBe('demo_recording.mp4');
      expect(chatRepository.createMessage).toHaveBeenCalledWith(mockUserId1, {
        roomId: mockRoomId,
        message: 'Check out this video demo',
        media_url: 'https://ik.imagekit.io/campushub/video.mp4',
        media_type: 'VIDEO',
        file_name: 'demo_recording.mp4',
        file_size: 15420000,
        reply_to_message_id: undefined,
      });
    });

    it('should validate sendMessageSchema with VIDEO and DOCUMENT media_types', async () => {
      const { sendMessageSchema } = await import('./chat.validation');

      const videoPayload = {
        body: {
          roomId: mockRoomId,
          message: 'Video message',
          media_url: 'https://example.com/video.mp4',
          media_type: 'VIDEO',
          file_name: 'lecture.mp4',
          file_size: 5000000,
        },
      };

      const docPayload = {
        body: {
          roomId: mockRoomId,
          message: 'Document attachment',
          media_url: 'https://example.com/notes.pdf',
          media_type: 'DOCUMENT',
          file_name: 'notes.pdf',
          file_size: 200000,
        },
      };

      expect(() => sendMessageSchema.parse(videoPayload)).not.toThrow();
      expect(() => sendMessageSchema.parse(docPayload)).not.toThrow();
    });
  });
});
