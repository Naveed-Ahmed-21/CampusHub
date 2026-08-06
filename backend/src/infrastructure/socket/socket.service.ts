import { Server as HttpServer } from 'http';
import { Server, Socket } from 'socket.io';
import { logger } from '../logger/logger.service.js';
import { env } from '../../config/env.config.js';

export class SocketService {
  private static instance: SocketService;
  private io: Server | null = null;

  private constructor() {}

  public static getInstance(): SocketService {
    if (!SocketService.instance) {
      SocketService.instance = new SocketService();
    }
    return SocketService.instance;
  }

  public init(httpServer: HttpServer): Server {
    const origins = env.CORS_ORIGIN === '*' ? '*' : env.CORS_ORIGIN.split(',');

    this.io = new Server(httpServer, {
      cors: {
        origin: origins,
        methods: ['GET', 'POST'],
        credentials: true,
      },
      path: '/socket.io/',
    });

    this.io.on('connection', (socket: Socket) => {
      logger.info({ socketId: socket.id }, '🔌 Socket client connected');

      socket.on('join_room', (room: string) => {
        socket.join(room);
        logger.debug({ socketId: socket.id, room }, 'Client joined socket room');
      });

      socket.on('leave_room', (room: string) => {
        socket.leave(room);
        logger.debug({ socketId: socket.id, room }, 'Client left socket room');
      });

      socket.on('disconnect', (reason: string) => {
        logger.info({ socketId: socket.id, reason }, '🔌 Socket client disconnected');
      });
    });

    logger.info('✅ Socket.IO service initialized');
    return this.io;
  }

  public getIO(): Server {
    if (!this.io) {
      throw new Error('Socket.IO instance has not been initialized.');
    }
    return this.io;
  }

  public emitToRoom(room: string, event: string, data: any): void {
    if (this.io) {
      this.io.to(room).emit(event, data);
    }
  }
}

export const socketService = SocketService.getInstance();
