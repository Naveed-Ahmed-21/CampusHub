import { env } from './config/env.config';
import http from 'http';
import { createApp } from './app';
import { logger } from './infrastructure/logger/logger';
import { SocketServer } from './infrastructure/socket/socket.server';
import { initFirebaseAdmin } from './infrastructure/firebase/firebase.config';
import { prisma } from './config/database';

const startServer = async () => {
  try {
    // Initialize Firebase Admin SDK
    initFirebaseAdmin();

    const app = createApp();
    const server = http.createServer(app);

    // Initialize Real-time Socket.IO Server
    SocketServer.initialize(server);

    server.listen(env.PORT, () => {
      logger.info(`🚀 CampusHub Server running on http://localhost:${env.PORT} in ${env.NODE_ENV} mode`);
    });

    const shutdown = async () => {
      logger.info('Graceful shutdown initiated...');
      server.close(async () => {
        await prisma.$disconnect();
        logger.info('Database connection closed. Server terminated.');
        process.exit(0);
      });
    };

    process.on('SIGINT', shutdown);
    process.on('SIGTERM', shutdown);
  } catch (error) {
    logger.error(error, 'Fatal error starting server');
    process.exit(1);
  }
};

startServer();
