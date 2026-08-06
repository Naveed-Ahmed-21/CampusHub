import { ChatService } from './chat.service';
import { ChatRepository } from './chat.repository';
import { ChatRoomType } from '@prisma/client';
import { NotFoundError, ForbiddenError, BadRequestError } from '../../shared/errors/AppError';

describe('ChatService', () => {
  let chatRepository: jest.Mocked<ChatRepository>;
  let chatService: ChatService;

  const mockCollegeId = 'college-123';
  const mockUserId1 = 'user-111';
  const mockUserId2 = 'user-222';
  const mockRoomId = 'room-999';

  beforeEach(() => {
    chatRepository = {
      findUserRooms: jest.fn(),
      findDirectChatRoom: jest.fn(),
      createDirectChatRoom: jest.fn(),
      findOrCreateDepartmentChatRoom: jest.fn(),
      findRoomById: jest.fn(),
      addParticipantToRoom: jest.fn(),
      createMessage: jest.fn(),
      getRoomMessages: jest.fn(),
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
        participants: [{ user_id: mockUserId1 }],
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
        participants: [{ user_id: 'other-user' }],
      } as never);

      await expect(
        chatService.getRoomMessages(mockRoomId, mockUserId1)
      ).rejects.toThrow(ForbiddenError);
    });
  });
});
