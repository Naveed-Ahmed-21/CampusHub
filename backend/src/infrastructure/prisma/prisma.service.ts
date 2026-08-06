import { PrismaClient } from '@prisma/client';
import { logger } from '../logger/logger.service.js';

class PrismaService extends PrismaClient {
  constructor() {
    super({
      log: [
        { emit: 'event', level: 'query' },
        { emit: 'stdout', level: 'error' },
        { emit: 'stdout', level: 'warn' },
      ],
    });
  }

  async connect() {
    try {
      await this.$connect();
      logger.info('✅ Database connected successfully via Prisma ORM');
    } catch (error) {
      logger.error({ error }, '❌ Failed to connect to database via Prisma ORM');
      process.exit(1);
    }
  }

  async disconnect() {
    await this.$disconnect();
    logger.info('Database disconnected');
  }
}

export const prisma = new PrismaService();
