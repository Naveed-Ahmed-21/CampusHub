import { prisma } from '../../config/database';
import {
  RegisterFcmTokenDto,
  SendNotificationDto,
  QueryNotificationDto,
} from './notifications.types';

export class NotificationsRepository {
  async registerFcmToken(userId: string, dto: RegisterFcmTokenDto) {
    return prisma.notificationToken.upsert({
      where: { fcm_token: dto.fcm_token },
      update: {
        user_id: userId,
        device_type: dto.device_type,
      },
      create: {
        user_id: userId,
        fcm_token: dto.fcm_token,
        device_type: dto.device_type,
      },
    });
  }

  async getUserFcmTokens(userId: string) {
    return prisma.notificationToken.findMany({
      where: { user_id: userId },
    });
  }

  async createNotification(dto: SendNotificationDto) {
    return prisma.notification.create({
      data: {
        user_id: dto.user_id,
        title: dto.title,
        body: dto.body,
        type: dto.type || 'SYSTEM',
        category: dto.category || 'General',
        deep_link: dto.deep_link,
        metadata: dto.metadata ? JSON.parse(JSON.stringify(dto.metadata)) : undefined,
      },
    });
  }

  async findUserNotifications(userId: string, query: QueryNotificationDto) {
    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const where: Record<string, unknown> = { user_id: userId };
    if (query.type) where.type = query.type;
    if (typeof query.is_read === 'boolean') where.is_read = query.is_read;

    const [total, unreadCount, notifications] = await Promise.all([
      prisma.notification.count({ where: where as never }),
      prisma.notification.count({ where: { user_id: userId, is_read: false } }),
      prisma.notification.findMany({
        where: where as never,
        skip,
        take: limit,
        orderBy: { created_at: 'desc' },
      }),
    ]);

    return { total, unreadCount, page, limit, notifications };
  }

  async markAsRead(userId: string, notificationId: string) {
    return prisma.notification.updateMany({
      where: { id: notificationId, user_id: userId },
      data: { is_read: true },
    });
  }

  async markAllAsRead(userId: string) {
    return prisma.notification.updateMany({
      where: { user_id: userId, is_read: false },
      data: { is_read: true },
    });
  }
}
