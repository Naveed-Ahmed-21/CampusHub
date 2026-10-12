import { Router } from 'express';
import { ChatRepository } from '../chat.repository';
import { ChatService } from '../chat.service';
import { ChatController } from '../chat.controller';
import { authenticate } from '../../../shared/middlewares/auth.middleware';
import { validateRequest } from '../../../shared/middlewares/validate.middleware';
import {
  createDirectChatSchema,
  sendMessageSchema,
  addReactionSchema,
  markReadSchema,
  queryRoomsSchema,
  updateChatSettingsSchema,
  createChatRequestSchema,
  blockUserSchema,
} from '../chat.validation';

const chatRepository = new ChatRepository();
const chatService = new ChatService(chatRepository);
const chatController = new ChatController(chatService);

export const chatRouter = Router();

chatRouter.use(authenticate);

// Student Chat Settings
chatRouter.get('/settings', chatController.getChatSettings);
chatRouter.patch('/settings', validateRequest(updateChatSettingsSchema), chatController.updateChatSettings);

// Chat Permission Check
chatRouter.get('/permission/:targetUserId', chatController.checkChatPermission);

// Chat Requests
chatRouter.post('/requests', validateRequest(createChatRequestSchema), chatController.createChatRequest);
chatRouter.get('/requests/incoming', chatController.getIncomingRequests);
chatRouter.get('/requests/sent', chatController.getSentRequests);
chatRouter.post('/requests/:requestId/accept', chatController.acceptChatRequest);
chatRouter.post('/requests/:requestId/decline', chatController.declineChatRequest);
chatRouter.post('/requests/:requestId/cancel', chatController.cancelChatRequest);

// Chat-Only Blocking
chatRouter.post('/block', validateRequest(blockUserSchema), chatController.blockUser);
chatRouter.post('/unblock', validateRequest(blockUserSchema), chatController.unblockUser);
chatRouter.get('/blocks', chatController.getBlockedUsers);

// Users Directory
chatRouter.get('/users', chatController.searchUsers);

// Rooms
chatRouter.get('/rooms', validateRequest(queryRoomsSchema), chatController.getUserRooms);
chatRouter.get('/groups/public', chatController.getPublicGroups);
chatRouter.get('/rooms/:roomId', chatController.getRoomDetails);
chatRouter.post('/direct', validateRequest(createDirectChatSchema), chatController.createDirectChat);
chatRouter.post('/group', chatController.createGroupChat);
chatRouter.get('/department', chatController.getDepartmentChat);
chatRouter.get('/rooms/club/:clubId', chatController.getClubChat);

// Room Members & Joining
chatRouter.patch('/rooms/:roomId/avatar', chatController.updateGroupAvatar);
chatRouter.put('/rooms/:roomId/avatar', chatController.updateGroupAvatar);
chatRouter.post('/rooms/:roomId/join', chatController.joinGroup);
chatRouter.post('/rooms/:roomId/leave', chatController.leaveGroup);
chatRouter.post('/rooms/:roomId/members', chatController.addRoomMember);
chatRouter.delete('/rooms/:roomId/members/:userId', chatController.removeRoomMember);

// Messages & Read Receipts
chatRouter.get('/rooms/:roomId/messages', chatController.getRoomMessages);
chatRouter.post('/messages', validateRequest(sendMessageSchema), chatController.sendMessage);
chatRouter.post('/read', validateRequest(markReadSchema), chatController.markRead);

// Message Reactions & Deletions
chatRouter.post('/messages/:messageId/reactions', validateRequest(addReactionSchema), chatController.addReaction);
chatRouter.delete('/messages/:messageId/reactions/:emoji', chatController.removeReaction);
chatRouter.delete('/messages/:messageId/for-me', chatController.deleteMessageForMe);
chatRouter.delete('/messages/:messageId/for-everyone', chatController.deleteMessageForEveryone);

export default chatRouter;
