import { NotificationType } from '@prisma/client';

export interface RegisterFcmTokenDto {
  fcm_token: string;
  device_type?: string;
}

export interface SendNotificationDto {
  user_id: string;
  title: string;
  body: string;
  type?: NotificationType;
  category?: string;
  deep_link?: string;
  metadata?: Record<string, unknown>;
}

export interface QueryNotificationDto {
  type?: NotificationType;
  is_read?: boolean;
  page?: number;
  limit?: number;
}
