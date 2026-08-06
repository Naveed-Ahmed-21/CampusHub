import { Router } from 'express';
import { ChatRepository } from '../chat.repository';
import { ChatService } from '../chat.service';
import { ChatController } from '../chat.controller';
import { authenticate } from '../../../shared/middlewares/auth.middleware';
import { validateRequest } from '../../../shared/middlewares/validate.middleware';
import {
  createDirectChatSchema,
  sendMessageSchema,
  markReadSchema,
  queryRoomsSchema,
} from '../chat.validation';

const chatRepository = new ChatRepository();
const chatService = new ChatService(chatRepository);
const chatController = new ChatController(chatService);

export const chatRouter = Router();

chatRouter.use(authenticate);

// Rooms
chatRouter.get('/rooms', validateRequest(queryRoomsSchema), chatController.getUserRooms);
chatRouter.post('/direct', validateRequest(createDirectChatSchema), chatController.createDirectChat);
chatRouter.get('/department', chatController.getDepartmentChat);

// Messages & Read Receipts
chatRouter.get('/rooms/:roomId/messages', chatController.getRoomMessages);
chatRouter.post('/messages', validateRequest(sendMessageSchema), chatController.sendMessage);
chatRouter.post('/read', validateRequest(markReadSchema), chatController.markRead);

export default chatRouter;
