import { Request, Response } from 'express';
import { ChatService } from './chat.service';
import { asyncHandler } from '../../shared/utils/async-handler.util';
import { ResponseUtil } from '../../shared/utils/api-response.util';
import { ChatRoomType } from '@prisma/client';

export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  getUserRooms = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const type = req.query.type as ChatRoomType | undefined;
    const search = (req.query.search || req.query.query || req.query.q) as string | undefined;
    const rooms = await this.chatService.getUserRooms(user.userId, user.collegeId, type, search);
    ResponseUtil.success(res, rooms, 'User chat rooms retrieved successfully');
  });

  getPublicGroups = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const query = (req.query.query || req.query.search || req.query.q) as string | undefined;
    const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 30;
    const groups = await this.chatService.getPublicGroups(user.collegeId, user.userId, query, limit);
    ResponseUtil.success(res, groups, 'Public groups retrieved successfully');
  });

  getRoomDetails = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { roomId } = req.params;
    const room = await this.chatService.getRoomDetails(roomId, user.userId);
    ResponseUtil.success(res, room, 'Chat room details retrieved');
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

  getClubChat = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { clubId } = req.params;
    const room = await this.chatService.getOrCreateClubChat(user.userId, user.collegeId, clubId, user.role);
    ResponseUtil.success(res, room, 'Club chat room retrieved successfully');
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
    try {
      const { SocketServer } = await import('../../infrastructure/socket/socket.server');
      SocketServer.getInstance().emitToRoom(req.body.roomId, 'new_message', message);
    } catch (_) {}
    ResponseUtil.success(res, message, 'Message sent successfully', 201);
  });

  createGroupChat = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { name, description, isPrivate, memberIds, avatarUrl, avatar_url } = req.body;
    const room = await this.chatService.createGroupRoom(user.userId, user.collegeId, {
      name,
      description,
      isPrivate: Boolean(isPrivate),
      memberIds: memberIds || [],
      avatarUrl: avatarUrl || avatar_url || null,
    });
    ResponseUtil.success(res, room, 'Group chat created successfully', 201);
  });

  updateGroupAvatar = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { roomId } = req.params;
    const avatarUrl = req.body?.avatarUrl !== undefined ? req.body.avatarUrl : (req.body?.avatar_url !== undefined ? req.body.avatar_url : null);
    const room = await this.chatService.updateGroupAvatar(roomId, user.userId, avatarUrl);
    ResponseUtil.success(res, room, 'Group image updated successfully');
  });

  joinGroup = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { roomId } = req.params;
    const result = await this.chatService.joinPublicGroup(roomId, user.userId);
    ResponseUtil.success(res, result, 'Joined group successfully');
  });

  leaveGroup = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { roomId } = req.params;
    const result = await this.chatService.leaveGroup(roomId, user.userId);
    ResponseUtil.success(res, result, 'Left group successfully');
  });

  addRoomMember = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { roomId } = req.params;
    const { userId } = req.body;
    const result = await this.chatService.addRoomMember(roomId, user.userId, userId);
    ResponseUtil.success(res, result, 'Member added to chat room');
  });

  removeRoomMember = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { roomId, userId } = req.params;
    const result = await this.chatService.removeRoomMember(roomId, user.userId, userId);
    ResponseUtil.success(res, result, 'Member removed from chat room');
  });

  searchUsers = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const query = (req.query.query || req.query.search || req.query.q) as string | undefined;
    const users = await this.chatService.searchCampusUsers(user.collegeId, user.userId, query);
    ResponseUtil.success(res, users, 'Campus users retrieved successfully');
  });

  markRead = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const result = await this.chatService.markRead(user.userId, req.body);
    ResponseUtil.success(res, result, 'Messages marked as read');
  });

  addReaction = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { messageId } = req.params;
    const { emoji } = req.body;
    const message = await this.chatService.addOrToggleReaction(messageId, user.userId, emoji);

    try {
      const { SocketServer } = await import('../../infrastructure/socket/socket.server');
      SocketServer.getInstance().emitToRoom(message!.room_id, 'message_reaction_updated', {
        roomId: message!.room_id,
        messageId: message!.id,
        reactions: (message as any).reactions,
      });
    } catch (_) {}

    ResponseUtil.success(res, message, 'Reaction updated successfully');
  });

  removeReaction = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { messageId, emoji } = req.params;
    const message = await this.chatService.removeReaction(messageId, user.userId, decodeURIComponent(emoji));

    try {
      const { SocketServer } = await import('../../infrastructure/socket/socket.server');
      SocketServer.getInstance().emitToRoom(message!.room_id, 'message_reaction_updated', {
        roomId: message!.room_id,
        messageId: message!.id,
        reactions: (message as any).reactions,
      });
    } catch (_) {}

    ResponseUtil.success(res, message, 'Reaction removed successfully');
  });

  deleteMessageForMe = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { messageId } = req.params;
    const result = await this.chatService.deleteMessageForMe(messageId, user.userId);
    ResponseUtil.success(res, result, 'Message deleted for you');
  });

  deleteMessageForEveryone = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { messageId } = req.params;
    const message = await this.chatService.deleteMessageForEveryone(messageId, user.userId);

    try {
      const { SocketServer } = await import('../../infrastructure/socket/socket.server');
      SocketServer.getInstance().emitToRoom(message.room_id, 'message_deleted_everyone', {
        roomId: message.room_id,
        messageId: message.id,
      });
    } catch (_) {}

    ResponseUtil.success(res, message, 'Message deleted for everyone');
  });
}
