import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/notification_models.dart';

class NotificationsRepository {
  final Dio _dio;

  NotificationsRepository(this._dio);

  Future<void> registerFcmToken(String fcmToken, {String? deviceType}) async {
    try {
      await _dio.post(
        '/api/v1/notifications/device-token',
        data: {
          'fcm_token': fcmToken,
          'device_type': deviceType ?? 'mobile',
        },
      );
    } catch (_) {
      // Non-blocking fallback
    }
  }

  Future<Map<String, dynamic>> getUserNotifications({String? type, bool? isRead}) async {
    final query = <String, dynamic>{};
    if (type != null && type.isNotEmpty) query['type'] = type;
    if (isRead != null) query['is_read'] = isRead;

    final response = await _dio.get('/api/v1/notifications', queryParameters: query);
    final data = response.data['data'] as Map<String, dynamic>;
    final List raw = data['notifications'] ?? [];
    final notifications = raw.map((json) => NotificationModel.fromJson(json)).toList();

    return {
      'total': data['total'] ?? 0,
      'unreadCount': data['unreadCount'] ?? 0,
      'notifications': notifications,
    };
  }

  Future<void> markAsRead(String notificationId) async {
    await _dio.patch('/api/v1/notifications/$notificationId/read');
  }

  Future<void> markAllAsRead() async {
    await _dio.patch('/api/v1/notifications/read-all');
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return NotificationsRepository(dio);
});
