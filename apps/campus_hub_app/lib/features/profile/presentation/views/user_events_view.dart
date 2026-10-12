import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../events/data/events_repository.dart';
import '../../../events/domain/event_models.dart';
import '../../../events/presentation/views/qr_ticket_dialog.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/widgets/campus_back_button.dart';

final myRegisteredEventsProvider = FutureProvider.autoDispose<List<EventRegistrationModel>>((ref) async {
  final repo = ref.watch(eventsRepositoryProvider);
  return repo.getUserRegistrations();
});

final allEventsListProvider = FutureProvider.autoDispose<List<EventModel>>((ref) async {
  final repo = ref.watch(eventsRepositoryProvider);
  return repo.getEvents();
});

class UserEventsView extends ConsumerStatefulWidget {
  const UserEventsView({super.key});

  @override
  ConsumerState<UserEventsView> createState() => _UserEventsViewState();
}

class _UserEventsViewState extends ConsumerState<UserEventsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myRegsAsync = ref.watch(myRegisteredEventsProvider);
    final allEventsAsync = ref.watch(allEventsListProvider);

    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CampusAppBar(
        leading: const CampusBackButton(),
        title: 'Your Events',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(myRegisteredEventsProvider);
              ref.invalidate(allEventsListProvider);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Container(
              height: 42,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.4),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.85),
                    ],
                  ),
                ),
                tabs: const [
                  Tab(text: 'Registered Events'),
                  Tab(text: 'All Campus Events'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
        children: [
          // Tab 1: Registered Events
          myRegsAsync.when(
            data: (registrations) {
              if (registrations.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_available, size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(
                          'No event registrations found.',
                          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Explore upcoming workshops, hackathons, and campus events to register!',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: registrations.length,
                itemBuilder: (context, index) {
                  final reg = registrations[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(Icons.qr_code_2, color: theme.colorScheme.onPrimaryContainer),
                      ),
                      title: Text(
                        reg.event?.title ?? 'Campus Event',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Ticket: ${reg.ticketCode}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('Status: ${reg.attendanceStatus}'),
                        ],
                      ),
                      trailing: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => QRTicketDialog(registration: reg),
                          );
                        },
                        icon: const Icon(Icons.confirmation_number_outlined, size: 16),
                        label: const Text('View Ticket'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, __) => Center(child: Text('Error loading registrations: $err')),
          ),

          // Tab 2: All Campus Events List
          allEventsAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return const Center(child: Text('No events available.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Chip(
                                label: Text(event.scope, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                backgroundColor: theme.colorScheme.secondaryContainer,
                              ),
                              Text(
                                '${event.startTime.day}/${event.startTime.month}/${event.startTime.year}',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          if (event.venue != null) ...[
                            const SizedBox(height: 4),
                            Text('Venue: ${event.venue}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, __) => Center(child: Text('Error loading events: $err')),
          ),
        ],
            ),
          ),
        ],
      ),
    );
  }
}
