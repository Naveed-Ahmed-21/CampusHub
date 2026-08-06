import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/notifications_repository.dart';

final notificationsListProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(notificationsRepositoryProvider);
  return repo.getUserNotifications();
});

final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final asyncState = ref.watch(notificationsListProvider);
  return asyncState.valueOrNull?['unreadCount'] ?? 0;
});
