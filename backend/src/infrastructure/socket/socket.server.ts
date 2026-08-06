import { Server as HttpServer } from 'http';
import { Server, Socket } from 'socket.io';
import { env } from '../../config/env.config';
import { verifyAccessToken } from '../../shared/utils/jwt.util';
import { logger } from '../logger/logger';
import { ChatRepository } from '../../modules/chat/chat.repository';

const chatRepository = new ChatRepository();

export class SocketServer {
  private static instance: SocketServer;
  private io: Server;

  private constructor(httpServer: HttpServer) {
    this.io = new Server(httpServer, {
      cors: { origin: env.CORS_ORIGIN, credentials: true },
      pingTimeout: 60000,
    });

    this.setupAuthMiddleware();
    this.setupEventHandlers();
  }

  public static initialize(httpServer: HttpServer): SocketServer {
    if (!SocketServer.instance) {
      SocketServer.instance = new SocketServer(httpServer);
    }
    return SocketServer.instance;
  }

  public static getInstance(): SocketServer {
    if (!SocketServer.instance) {
      throw new Error('SocketServer has not been initialized');
    }
    return SocketServer.instance;
  }

  private setupAuthMiddleware(): void {
    this.io.use((socket: Socket, next) => {
      const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.split(' ')[1];
      if (!token) return next(new Error('Authentication token required'));

      try {
        const payload = verifyAccessToken(token);
        socket.data.user = payload;
        return next();
      } catch {
        return next(new Error('Invalid authentication token'));
      }
    });
  }

  private setupEventHandlers(): void {
    this.io.on('connection', async (socket: Socket) => {
      const user = socket.data.user;
      logger.info({ userId: user.userId, socketId: socket.id }, 'Socket Client Connected');

      socket.join(`user:${user.userId}`);
      socket.join(`college:${user.collegeId}`);

      // Update online status
      try {
        await chatRepository.updateUserOnlineStatus(user.userId, true);
        this.emitToCollege(user.collegeId, 'presence_change', {
          userId: user.userId,
          isOnline: true,
        });
      } catch (err) {
        logger.error(err, 'Failed to update online status on connect');
      }

      // Room Joining & Leaving
      socket.on('join_room', (roomId: string) => {
        socket.join(`room:${roomId}`);
        logger.debug({ userId: user.userId, roomId }, 'User joined socket room');
      });

      socket.on('leave_room', (roomId: string) => {
        socket.leave(`room:${roomId}`);
        logger.debug({ userId: user.userId, roomId }, 'User left socket room');
      });

      // Typing Indicators
      socket.on('typing_start', (data: { roomId: string; userName?: string }) => {
        socket.to(`room:${data.roomId}`).emit('user_typing', {
          roomId: data.roomId,
          userId: user.userId,
          userName: data.userName || 'User',
        });
      });

      socket.on('typing_stop', (data: { roomId: string }) => {
        socket.to(`room:${data.roomId}`).emit('user_stop_typing', {
          roomId: data.roomId,
          userId: user.userId,
        });
      });

      // Real-time Messages
      socket.on('send_message', async (data: {
        roomId: string;
        message: string;
        media_url?: string;
        media_type?: 'IMAGE' | 'DOCUMENT' | 'AUDIO';
        file_name?: string;
        file_size?: number;
      }) => {
        try {
          const message = await chatRepository.createMessage(user.userId, {
            roomId: data.roomId,
            message: data.message || '',
            media_url: data.media_url,
            media_type: data.media_type,
            file_name: data.file_name,
            file_size: data.file_size,
          });

          // Emit to all users in the room
          this.io.to(`room:${data.roomId}`).emit('new_message', message);
        } catch (err) {
          logger.error(err, 'Error handling socket send_message');
          socket.emit('error', { message: 'Failed to send message' });
        }
      });

      // Read Receipts
      socket.on('mark_read', async (data: { roomId: string; messageIds: string[] }) => {
        try {
          if (!data.messageIds || data.messageIds.length === 0) return;
          const result = await chatRepository.markMessagesAsRead(data.roomId, user.userId, data.messageIds);
          this.io.to(`room:${data.roomId}`).emit('messages_read', result);
        } catch (err) {
          logger.error(err, 'Error handling socket mark_read');
        }
      });

      // Disconnect
      socket.on('disconnect', async () => {
        logger.info({ userId: user.userId, socketId: socket.id }, 'Socket Client Disconnected');
        try {
          const updated = await chatRepository.updateUserOnlineStatus(user.userId, false);
          this.emitToCollege(user.collegeId, 'presence_change', {
            userId: user.userId,
            isOnline: false,
            lastSeen: updated.last_seen,
          });
        } catch (err) {
          logger.error(err, 'Failed to update online status on disconnect');
        }
      });
    });
  }

  public emitToUser(userId: string, event: string, data: unknown): void {
    this.io.to(`user:${userId}`).emit(event, data);
  }

  public emitToCollege(collegeId: string, event: string, data: unknown): void {
    this.io.to(`college:${collegeId}`).emit(event, data);
  }

  public emitToRoom(roomId: string, event: string, data: unknown): void {
    this.io.to(`room:${roomId}`).emit(event, data);
  }
}
