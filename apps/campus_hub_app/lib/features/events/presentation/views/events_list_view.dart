import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/events_provider.dart';
import '../../data/events_repository.dart';
import '../../domain/event_models.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../../../../core/widgets/campus_top_notification.dart';
import '../../../../core/utils/app_date_formatter.dart';
import 'create_event_dialog.dart';
import 'qr_ticket_dialog.dart';

class EventsListView extends ConsumerStatefulWidget {
  final bool showAppBar;

  const EventsListView({super.key, this.showAppBar = true});

  @override
  ConsumerState<EventsListView> createState() => _EventsListViewState();
}

class _EventsListViewState extends ConsumerState<EventsListView>
    with SingleTickerProviderStateMixin {
  late TabController _scopeTabController;
  bool _isCalendarView = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _scopeTabController = TabController(length: 4, vsync: this);
    _scopeTabController.addListener(_onScopeTabChanged);
  }

  void _onScopeTabChanged() {
    if (_scopeTabController.indexIsChanging) return;
    String? scope;
    if (_scopeTabController.index == 1) scope = 'COLLEGE';
    if (_scopeTabController.index == 2) scope = 'DEPARTMENT';
    if (_scopeTabController.index == 3) scope = 'CLUB';
    if (mounted) {
      ref.read(selectedEventsScopeProvider.notifier).state = scope;
    }
  }

  @override
  void dispose() {
    _scopeTabController.dispose();
    super.dispose();
  }

  void _showCreateEventDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const CreateEventDialog(),
    );
  }

  Future<void> _registerUser(EventModel event) async {
    try {
      final repo = ref.read(eventsRepositoryProvider);
      final reg = await repo.registerForEvent(event.id);
      ref.invalidate(userEventRegistrationsProvider);
      ref.invalidate(eventsListProvider);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => QRTicketDialog(registration: reg),
        );
      }
    } catch (e) {
      if (mounted) {
        CampusTopNotification.showError(
          context,
          title: 'Registration Error',
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  Widget _buildScopeTabBar(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
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
        controller: _scopeTabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11.5),
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'College'),
          Tab(text: 'Department'),
          Tab(text: 'Clubs'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventsAsync = ref.watch(eventsListProvider);
    final myRegsAsync = ref.watch(userEventRegistrationsProvider);

    final registeredEventIds =
        myRegsAsync.valueOrNull?.map((r) => r.eventId).toSet() ?? {};
    final regMap = Map.fromEntries(
      (myRegsAsync.valueOrNull ?? []).map((r) => MapEntry(r.eventId, r)),
    );

    return Scaffold(
      appBar: widget.showAppBar
          ? CampusAppBar(
              title: 'Campus Events',
              leading: const CampusBackButton(),
              actions: [
                IconButton(
                  icon: Icon(
                      _isCalendarView ? Icons.view_list : Icons.calendar_month),
                  tooltip: _isCalendarView
                      ? 'Switch to List View'
                      : 'Switch to Calendar View',
                  onPressed: () =>
                      setState(() => _isCalendarView = !_isCalendarView),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ref.invalidate(eventsListProvider);
                    ref.invalidate(userEventRegistrationsProvider);
                  },
                ),
              ],
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _showCreateEventDialog,
        icon: const Icon(Icons.add),
        label: const Text('Create Event'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: widget.showAppBar
                ? _buildScopeTabBar(theme)
                : Row(
                    children: [
                      Expanded(
                        child: _buildScopeTabBar(theme),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: theme.brightness == Brightness.dark ? 0.2 : 0.4,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                _isCalendarView ? Icons.view_list : Icons.calendar_month,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              tooltip: _isCalendarView ? 'Switch to List' : 'Switch to Calendar',
                              onPressed: () => setState(() => _isCalendarView = !_isCalendarView),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.refresh, size: 18),
                              tooltip: 'Refresh Events',
                              onPressed: () {
                                ref.invalidate(eventsListProvider);
                                ref.invalidate(userEventRegistrationsProvider);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          Expanded(
            child: _isCalendarView
                ? _buildCalendarView(eventsAsync.valueOrNull ?? [])
                : eventsAsync.when(
                    data: (events) {
                      if (events.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy,
                                  size: 64, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('No events scheduled in this scope yet.',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: events.length,
                        itemBuilder: (ctx, idx) {
                          final event = events[idx];
                          final isRegistered =
                              registeredEventIds.contains(event.id);
                          final registration = regMap[event.id];

                          return _buildEventCard(
                              event, isRegistered, registration);
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.wifi_off,
                                size: 56, color: Colors.orange),
                            const SizedBox(height: 12),
                            const Text(
                              'Could not connect to CampusHub Backend.',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Please verify your internet connection or check backend server.',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                ref.invalidate(eventsListProvider);
                                ref.invalidate(userEventRegistrationsProvider);
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry Connection'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventModel event, bool isRegistered,
      EventRegistrationModel? registration) {
    Color scopeColor = Colors.blue;
    if (event.scope == 'DEPARTMENT') scopeColor = Colors.indigo;
    if (event.scope == 'CLUB') scopeColor = Colors.orange.shade800;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Banner / Gradient Header
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [scopeColor.withValues(alpha: 0.8), scopeColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    event.scope,
                    style: TextStyle(
                        color: scopeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${event.startTime.day}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                      Text(
                        _getMonthAbbr(event.startTime.month),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(event.venue ?? 'Campus Ground',
                        style: TextStyle(
                            color: Colors.grey.shade700, fontSize: 13)),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      AppDateFormatter.formatTime(event.startTime),
                      style:
                          TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ],
                ),
                if (event.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    event.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${event.registeredCount} Registered',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey),
                    ),
                    if (isRegistered && registration != null)
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) =>
                                QRTicketDialog(registration: registration),
                          );
                        },
                        icon: const Icon(Icons.qr_code, size: 18),
                        label: const Text('View Ticket'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed:
                            event.isFull ? null : () => _registerUser(event),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scopeColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(event.isFull ? 'Full' : 'Register Now'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView(List<EventModel> events) {
    return Column(
      children: [
        // Date Selector Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.indigo.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Events Calendar (${_getMonthAbbr(_selectedDate.month)} ${_selectedDate.year})',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.today),
                onPressed: () => setState(() => _selectedDate = DateTime.now()),
              ),
            ],
          ),
        ),

        Expanded(
          child: events.isEmpty
              ? const Center(
                  child: Text('No events found for this calendar month.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  itemBuilder: (ctx, idx) {
                    final event = events[idx];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo.shade100,
                        child: Text('${event.startTime.day}'),
                      ),
                      title: Text(event.title,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${event.venue ?? 'Campus'} • ${AppDateFormatter.formatTime(event.startTime)} • ${AppDateFormatter.formatDate(event.startTime)}'),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _getMonthAbbr(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[(month - 1) % 12];
  }
}
