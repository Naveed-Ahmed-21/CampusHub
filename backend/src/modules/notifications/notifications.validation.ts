import { z } from 'zod';
import { NotificationType } from '@prisma/client';

export const registerFcmTokenSchema = z.object({
  body: z.object({
    fcm_token: z.string().min(10, 'FCM token is required'),
    device_type: z.string().optional(),
  }),
});

export const sendNotificationSchema = z.object({
  body: z.object({
    user_id: z.string().uuid('Invalid user ID'),
    title: z.string().min(1, 'Title is required').max(255),
    body: z.string().min(1, 'Body is required'),
    type: z.nativeEnum(NotificationType).optional(),
    category: z.string().optional(),
    deep_link: z.string().optional(),
    metadata: z.record(z.unknown()).optional(),
  }),
});
