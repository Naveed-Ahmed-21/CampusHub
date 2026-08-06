import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/notifications_provider.dart';
import '../../data/notifications_repository.dart';
import '../../domain/notification_models.dart';

class NotificationsView extends ConsumerStatefulWidget {
  const NotificationsView({super.key});

  @override
  ConsumerState<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends ConsumerState<NotificationsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    if (!notification.isRead) {
      final repo = ref.read(notificationsRepositoryProvider);
      await repo.markAsRead(notification.id);
      ref.invalidate(notificationsListProvider);
    }

    if (mounted && notification.deepLink != null && notification.deepLink!.isNotEmpty) {
      context.go(notification.deepLink!);
    }
  }

  Future<void> _markAllRead() async {
    try {
      final repo = ref.read(notificationsRepositoryProvider);
      await repo.markAllAsRead();
      ref.invalidate(notificationsListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark notifications read: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton.icon(
            onPressed: _markAllRead,
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Mark all read'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Placements'),
            Tab(text: 'Events'),
            Tab(text: 'Chat'),
            Tab(text: 'Announcements'),
          ],
        ),
      ),
      body: notificationsAsync.when(
        data: (data) {
          final List<NotificationModel> allNotifications = data['notifications'] ?? [];

          return TabBarView(
            controller: _tabController,
            children: [
              _buildNotificationList(allNotifications),
              _buildNotificationList(allNotifications.where((n) => n.type == 'PLACEMENT_UPDATE').toList()),
              _buildNotificationList(allNotifications.where((n) => n.type == 'EVENT_REMINDER').toList()),
              _buildNotificationList(allNotifications.where((n) => n.type == 'CHAT_MESSAGE').toList()),
              _buildNotificationList(allNotifications.where((n) => n.type == 'ANNOUNCEMENT').toList()),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, size: 48, color: Colors.orange),
                const SizedBox(height: 12),
                const Text('Could not load notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(notificationsListProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Connection'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationModel> notifications) {
    if (notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text('No notifications found.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notifications.length,
      separatorBuilder: (ctx, idx) => const Divider(height: 1),
      itemBuilder: (ctx, idx) {
        final item = notifications[idx];

        return ListTile(
          tileColor: item.isRead ? Colors.transparent : Colors.blue.shade50.withValues(alpha: 0.3),
          leading: CircleAvatar(
            backgroundColor: _getCategoryColor(item.type).withValues(alpha: 0.1),
            child: Icon(_getCategoryIcon(item.type), color: _getCategoryColor(item.type)),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
              ),
              if (!item.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(item.body),
              const SizedBox(height: 4),
              Text(
                '${item.createdAt.hour}:${item.createdAt.minute.toString().padLeft(2, '0')} • ${item.createdAt.day}/${item.createdAt.month}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          trailing: item.deepLink != null ? const Icon(Icons.chevron_right, size: 20, color: Colors.grey) : null,
          onTap: () => _handleNotificationTap(item),
        );
      },
    );
  }

  IconData _getCategoryIcon(String type) {
    switch (type) {
      case 'PLACEMENT_UPDATE':
        return Icons.business_center;
      case 'EVENT_REMINDER':
        return Icons.event;
      case 'CHAT_MESSAGE':
        return Icons.chat_bubble;
      case 'ANNOUNCEMENT':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  Color _getCategoryColor(String type) {
    switch (type) {
      case 'PLACEMENT_UPDATE':
        return Colors.indigo;
      case 'EVENT_REMINDER':
        return Colors.green;
      case 'CHAT_MESSAGE':
        return Colors.blue;
      case 'ANNOUNCEMENT':
        return Colors.orange;
      default:
        return Colors.teal;
    }
  }
}
