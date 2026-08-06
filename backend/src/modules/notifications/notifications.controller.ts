import { Request, Response } from 'express';
import { NotificationsService } from './notifications.service';
import { asyncHandler } from '../../shared/utils/async-handler.util';
import { ResponseUtil } from '../../shared/utils/api-response.util';
import { NotificationType } from '@prisma/client';

export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  registerFcmToken = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const token = await this.notificationsService.registerFcmToken(user.userId, req.body);
    ResponseUtil.success(res, token, 'FCM token registered successfully');
  });

  sendNotification = asyncHandler(async (req: Request, res: Response) => {
    const result = await this.notificationsService.sendNotification(req.body);
    ResponseUtil.success(res, result, 'Notification sent successfully', 201);
  });

  getUserNotifications = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const query = {
      type: req.query.type as NotificationType,
      is_read: req.query.is_read !== undefined ? req.query.is_read === 'true' : undefined,
      page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 20,
    };

    const notifications = await this.notificationsService.getUserNotifications(user.userId, query);
    ResponseUtil.success(res, notifications, 'Notifications retrieved successfully');
  });

  markAsRead = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { id } = req.params;
    await this.notificationsService.markAsRead(user.userId, id);
    ResponseUtil.success(res, null, 'Notification marked as read');
  });

  markAllAsRead = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    await this.notificationsService.markAllAsRead(user.userId);
    ResponseUtil.success(res, null, 'All notifications marked as read');
  });
}
