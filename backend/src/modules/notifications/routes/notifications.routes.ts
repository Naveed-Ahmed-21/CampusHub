import { Router } from 'express';
import { NotificationsRepository } from '../notifications.repository';
import { NotificationsService } from '../notifications.service';
import { NotificationsController } from '../notifications.controller';
import { authenticate } from '../../../shared/middlewares/auth.middleware';
import { validateRequest } from '../../../shared/middlewares/validate.middleware';
import {
  registerFcmTokenSchema,
  sendNotificationSchema,
} from '../notifications.validation';

const notificationsRepository = new NotificationsRepository();
const notificationsService = new NotificationsService(notificationsRepository);
const notificationsController = new NotificationsController(notificationsService);

export const notificationsRouter = Router();

notificationsRouter.use(authenticate);

notificationsRouter.post('/fcm-token', validateRequest(registerFcmTokenSchema), notificationsController.registerFcmToken);
notificationsRouter.post('/send', validateRequest(sendNotificationSchema), notificationsController.sendNotification);
notificationsRouter.get('/', notificationsController.getUserNotifications);
notificationsRouter.patch('/:id/read', notificationsController.markAsRead);
notificationsRouter.patch('/read-all', notificationsController.markAllAsRead);

export default notificationsRouter;
