import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../../../../core/widgets/campus_avatar.dart';
import '../../domain/chat_models.dart';
import '../providers/chat_provider.dart';
import '../utils/chat_date_formatter.dart';

class ChatRequestsView extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const ChatRequestsView({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<ChatRequestsView> createState() => _ChatRequestsViewState();
}

class _ChatRequestsViewState extends ConsumerState<ChatRequestsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleAccept(ChatRequestModel request) async {
    if (_processingIds.contains(request.id)) return;

    setState(() => _processingIds.add(request.id));

    try {
      final notifier = ref.read(incomingChatRequestsProvider.notifier);
      final result = await notifier.acceptRequest(request.id);
      final roomId = result['roomId'] as String? ?? result['conversationId'] as String?;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Accepted chat request from ${request.sender?.fullName ?? "User"}'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (roomId != null && roomId.isNotEmpty) {
          context.push('/chat/room/$roomId');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(request.id));
      }
    }
  }

  Future<void> _handleDecline(ChatRequestModel request) async {
    if (_processingIds.contains(request.id)) return;

    setState(() => _processingIds.add(request.id));

    try {
      final notifier = ref.read(incomingChatRequestsProvider.notifier);
      await notifier.declineRequest(request.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Declined chat request from ${request.sender?.fullName ?? "User"}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(request.id));
      }
    }
  }

  Future<void> _handleCancel(ChatRequestModel request) async {
    if (_processingIds.contains(request.id)) return;

    setState(() => _processingIds.add(request.id));

    try {
      final notifier = ref.read(sentChatRequestsProvider.notifier);
      await notifier.cancelRequest(request.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat request cancelled'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(request.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pendingCount = ref.watch(pendingRequestsCountProvider);

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const CampusAppBar(
          leading: CampusBackButton(),
          title: 'Message Requests',
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 42,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface.withValues(alpha: 0.6)
                    : AppColors.lightSurface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(11),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Incoming'),
                        if (pendingCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$pendingCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'Sent'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildIncomingTab(context),
                  _buildSentTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingTab(BuildContext context) {
    final theme = Theme.of(context);
    final requestsAsync = ref.watch(incomingChatRequestsProvider);

    return requestsAsync.when(
      data: (requests) {
        final pending = requests.where((r) => r.status == ChatRequestStatus.pending).toList();

        if (pending.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mark_email_read_outlined,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Incoming Requests',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'When students request to message you, they will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(incomingChatRequestsProvider.notifier).refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pending.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, idx) {
              final req = pending[idx];
              return _buildIncomingRequestCard(context, req);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Failed to load requests: $err'),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => ref.read(incomingChatRequestsProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingRequestCard(BuildContext context, ChatRequestModel request) {
    final theme = Theme.of(context);
    final sender = request.sender;
    final isProcessing = _processingIds.contains(request.id);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User row
            Row(
              children: [
                CampusAvatar(
                  imageUrl: sender?.avatarUrl,
                  name: sender?.fullName ?? 'Student',
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sender?.fullName ?? 'Student',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sender?.departmentName ?? 'Student',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                Text(
                  ChatDateFormatter.formatMessageTime(request.createdAt, context),
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Introductory Message Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.format_quote, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Introductory Message',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    request.introductoryMessage,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: theme.colorScheme.onSurface,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isProcessing ? null : () => _handleDecline(request),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: isProcessing ? null : () => _handleAccept(request),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentTab(BuildContext context) {
    final theme = Theme.of(context);
    final requestsAsync = ref.watch(sentChatRequestsProvider);

    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.outbox_outlined,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Sent Requests',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Requests you send to other students will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(sentChatRequestsProvider.notifier).refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, idx) {
              final req = requests[idx];
              return _buildSentRequestCard(context, req);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Failed to load sent requests: $err'),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => ref.read(sentChatRequestsProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentRequestCard(BuildContext context, ChatRequestModel request) {
    final theme = Theme.of(context);
    final recipient = request.recipient;
    final isProcessing = _processingIds.contains(request.id);
    final isPending = request.status == ChatRequestStatus.pending;

    Color statusColor;
    IconData statusIcon;
    switch (request.status) {
      case ChatRequestStatus.accepted:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case ChatRequestStatus.declined:
        statusColor = Colors.red;
        statusIcon = Icons.cancel_outlined;
        break;
      case ChatRequestStatus.cancelled:
        statusColor = Colors.grey;
        statusIcon = Icons.remove_circle_outline;
        break;
      case ChatRequestStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User row
            Row(
              children: [
                CampusAvatar(
                  imageUrl: recipient?.avatarUrl,
                  name: recipient?.fullName ?? 'Student',
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipient?.fullName ?? 'Student',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        recipient?.departmentName ?? 'Student',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                // Status Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        request.status.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Introductory Message Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                request.introductoryMessage,
                style: TextStyle(
                  fontSize: 13.5,
                  color: theme.colorScheme.onSurface,
                  height: 1.35,
                ),
              ),
            ),

            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ChatDateFormatter.formatMessageTime(request.createdAt, context),
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
                  ),
                  TextButton.icon(
                    onPressed: isProcessing ? null : () => _handleCancel(request),
                    icon: isProcessing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.close, size: 16),
                    label: const Text('Cancel Request'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  ChatDateFormatter.formatMessageTime(request.createdAt, context),
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
