import { Request, Response } from 'express';
import { ChatService } from './chat.service';
import { asyncHandler } from '../../shared/utils/async-handler.util';
import { ResponseUtil } from '../../shared/utils/api-response.util';

export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  getUserRooms = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const rooms = await this.chatService.getUserRooms(user.userId, user.collegeId);
    ResponseUtil.success(res, rooms, 'User chat rooms retrieved successfully');
  });

  createDirectChat = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const room = await this.chatService.getOrCreateDirectChat(user.userId, user.collegeId, req.body);
    ResponseUtil.success(res, room, 'Direct chat room ready', 201);
  });

  getDepartmentChat = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const room = await this.chatService.getOrCreateDepartmentChat(user.userId, user.collegeId, user.departmentId);
    ResponseUtil.success(res, room, 'Department chat room retrieved');
  });

  getRoomMessages = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { roomId } = req.params;
    const page = req.query.page ? parseInt(req.query.page as string, 10) : 1;
    const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 50;

    const messages = await this.chatService.getRoomMessages(roomId, user.userId, page, limit);
    ResponseUtil.success(res, messages, 'Chat messages retrieved successfully');
  });

  sendMessage = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const message = await this.chatService.sendMessage(user.userId, user.collegeId, req.body);
    ResponseUtil.success(res, message, 'Message sent successfully', 201);
  });

  createGroupChat = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { name, memberIds } = req.body;
    const room = await this.chatService.createGroupRoom(user.userId, user.collegeId, name || 'Group Chat', memberIds || []);
    ResponseUtil.success(res, room, 'Group chat created successfully', 201);
  });

  addRoomMember = asyncHandler(async (req: Request, res: Response) => {
    const { roomId } = req.params;
    const { userId } = req.body;
    const result = await this.chatService.addRoomMember(roomId, userId);
    ResponseUtil.success(res, result, 'Member added to chat room');
  });

  removeRoomMember = asyncHandler(async (req: Request, res: Response) => {
    const { roomId, userId } = req.params;
    const result = await this.chatService.removeRoomMember(roomId, userId);
    ResponseUtil.success(res, result, 'Member removed from chat room');
  });

  searchUsers = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const query = req.query.query as string | undefined;
    const users = await this.chatService.searchCampusUsers(user.collegeId, query);
    ResponseUtil.success(res, users, 'Campus users retrieved successfully');
  });

  markRead = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const result = await this.chatService.markRead(user.userId, req.body);
    ResponseUtil.success(res, result, 'Messages marked as read');
  });
}
