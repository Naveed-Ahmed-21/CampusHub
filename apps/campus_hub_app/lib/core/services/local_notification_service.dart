import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../routing/app_router.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'campushub_alerts_channel';
  static const String _channelName = 'CampusHub Notifications';
  static const String _channelDesc =
      'High priority notifications for campus events, announcements, grades, attendance, and messages.';

  static bool _isInitialized = false;

  /// Initialize local notifications for Android, iOS, and desktop
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings darwinSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const LinuxInitializationSettings linuxSettings =
          LinuxInitializationSettings(defaultActionName: 'Open CampusHub');

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      );

      await _notificationsPlugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          debugPrint(
              '🔔 [LocalNotificationService] User tapped notification: payload=$payload');
          if (payload != null && payload.isNotEmpty) {
            handleNotificationNavigation(payload);
          }
        },
      );

      // Create Android Notification Channel for heads-up alerts
      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          const AndroidNotificationChannel channel = AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          );

          await androidPlugin.createNotificationChannel(channel);
          await androidPlugin.requestNotificationsPermission();
        }
      }

      // Check if app was launched from a notification
      final launchDetails =
          await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        final payload = launchDetails?.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          debugPrint(
              '🚀 [LocalNotificationService] App launched from notification: $payload');
          handleNotificationNavigation(payload);
        }
      }

      _isInitialized = true;
      debugPrint('✅ [LocalNotificationService] Successfully initialized');
    } catch (e, stack) {
      debugPrint(
          '⚠️ [LocalNotificationService] Initialization error: $e\n$stack');
    }
  }

  /// Show a device-level heads-up notification
  static Future<void> showNotification({
    int? id,
    required String title,
    required String body,
    String? payload,
    String? category,
  }) async {
    try {
      final notifId =
          id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        ticker: title,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
        visibility: NotificationVisibility.public,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: category ?? 'CampusHub',
        ),
      );

      const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      await _notificationsPlugin.show(
        id: notifId,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
      debugPrint(
          '🔔 [LocalNotificationService] Dispatched notification #$notifId: "$title"');
    } catch (e) {
      debugPrint(
          '⚠️ [LocalNotificationService] Failed to show notification: $e');
    }
  }

  /// Explicitly request notification permissions (e.g. for Android 13+)
  static Future<bool?> requestPermission() async {
    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        return await androidPlugin.requestNotificationsPermission();
      }
    }
    return true;
  }

  /// Cancel all active notifications
  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
