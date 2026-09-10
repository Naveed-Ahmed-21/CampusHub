import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/notifications_repository.dart';
import '../../domain/notification_models.dart';
import '../../../chat/data/socket_chat_service.dart';

class NotificationsState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final int total;
  final bool isLoading;
  final String? error;

  const NotificationsState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.total = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    int? total,
    bool? isLoading,
    String? error,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationsRepository _repository;
  final SocketChatService _socketChatService;
  StreamSubscription<NotificationModel>? _socketSubscription;

  NotificationsNotifier(this._repository, this._socketChatService)
      : super(const NotificationsState(isLoading: true)) {
    loadNotifications();
    _listenToSocket();
  }

  void _listenToSocket() {
    _socketSubscription = _socketChatService.onNewNotification.listen((NotificationModel newNotif) {
      final updatedList = <NotificationModel>[
        newNotif,
        ...state.notifications.where((n) => n.id != newNotif.id),
      ];
      state = state.copyWith(
        notifications: updatedList,
        unreadCount: state.unreadCount + (newNotif.isRead ? 0 : 1),
        total: state.total + 1,
      );
    });
  }

  Future<void> loadNotifications() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final data = await _repository.getUserNotifications();
      final List<NotificationModel> list =
          (data['notifications'] as List<dynamic>?)?.cast<NotificationModel>() ?? [];
      final unread = data['unreadCount'] as int? ?? 0;
      final total = data['total'] as int? ?? list.length;
      state = state.copyWith(
        notifications: list,
        unreadCount: unread,
        total: total,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAsRead(String id) async {
    final updatedList = state.notifications.map((n) {
      if (n.id == id && !n.isRead) {
        return NotificationModel(
          id: n.id,
          userId: n.userId,
          title: n.title,
          body: n.body,
          type: n.type,
          category: n.category,
          deepLink: n.deepLink,
          isRead: true,
          metadata: n.metadata,
          createdAt: n.createdAt,
        );
      }
      return n;
    }).toList();

    final prevUnread = state.unreadCount;
    state = state.copyWith(
      notifications: updatedList,
      unreadCount: prevUnread > 0 ? prevUnread - 1 : 0,
    );

    try {
      await _repository.markAsRead(id);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final updatedList = state.notifications.map((n) {
      return NotificationModel(
        id: n.id,
        userId: n.userId,
        title: n.title,
        body: n.body,
        type: n.type,
        category: n.category,
        deepLink: n.deepLink,
        isRead: true,
        metadata: n.metadata,
        createdAt: n.createdAt,
      );
    }).toList();

    state = state.copyWith(
      notifications: updatedList,
      unreadCount: 0,
    );

    try {
      await _repository.markAllAsRead();
    } catch (_) {}
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }
}

final notificationsNotifierProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final repo = ref.watch(notificationsRepositoryProvider);
  final socketService = ref.watch(socketChatServiceProvider);
  return NotificationsNotifier(repo, socketService);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsNotifierProvider).unreadCount;
});

final notificationsListProvider =
    Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final s = ref.watch(notificationsNotifierProvider);
  if (s.isLoading) return const AsyncValue.loading();
  if (s.error != null) return AsyncValue.error(s.error!, StackTrace.current);
  return AsyncValue.data({
    'notifications': s.notifications,
    'unreadCount': s.unreadCount,
    'total': s.total,
  });
});
