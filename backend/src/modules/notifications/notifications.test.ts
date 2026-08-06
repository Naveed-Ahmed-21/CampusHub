import { NotificationsService } from './notifications.service';
import { NotificationsRepository } from './notifications.repository';

describe('NotificationsService', () => {
  let notificationsRepository: jest.Mocked<NotificationsRepository>;
  let notificationsService: NotificationsService;

  const mockUserId = 'user-123';

  beforeEach(() => {
    notificationsRepository = {
      registerFcmToken: jest.fn(),
      getUserFcmTokens: jest.fn(),
      createNotification: jest.fn(),
      findUserNotifications: jest.fn(),
      markAsRead: jest.fn(),
      markAllAsRead: jest.fn(),
    } as unknown as jest.Mocked<NotificationsRepository>;

    notificationsService = new NotificationsService(notificationsRepository);
  });

  describe('sendNotification', () => {
    it('should create notification in DB and check FCM tokens', async () => {
      notificationsRepository.createNotification.mockResolvedValue({
        id: 'notif-1',
        title: 'New Placement Drive',
        body: 'Google software engineering drive updated',
      } as never);

      notificationsRepository.getUserFcmTokens.mockResolvedValue([
        { id: 'tok-1', fcm_token: 'fcm-device-token-123' },
      ] as never);

      const result = await notificationsService.sendNotification({
        user_id: mockUserId,
        title: 'New Placement Drive',
        body: 'Google software engineering drive updated',
        type: 'PLACEMENT_UPDATE',
        deep_link: '/placement',
      });

      expect(result.notification.id).toBe('notif-1');
      expect(result.fcmDispatchedCount).toBe(1);
    });
  });

  describe('markAllAsRead', () => {
    it('should call repository to mark all notifications as read', async () => {
      notificationsRepository.markAllAsRead.mockResolvedValue({ count: 5 } as never);

      await notificationsService.markAllAsRead(mockUserId);
      expect(notificationsRepository.markAllAsRead).toHaveBeenCalledWith(mockUserId);
    });
  });
});
