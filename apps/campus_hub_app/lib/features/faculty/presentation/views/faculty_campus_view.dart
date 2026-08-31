import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../events/presentation/views/events_list_view.dart';
import '../../../clubs/presentation/views/clubs_list_view.dart';
import '../../../feed/presentation/views/feed_view.dart';
import '../widgets/qr_attendance_scanner_dialog.dart';

class FacultyCampusView extends ConsumerStatefulWidget {
  const FacultyCampusView({super.key});

  @override
  ConsumerState<FacultyCampusView> createState() => _FacultyCampusViewState();
}

class _FacultyCampusViewState extends ConsumerState<FacultyCampusView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Campus Ecosystem',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.purple),
            tooltip: 'Scan Student QR Attendance',
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => const QrAttendanceScannerDialog(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Campus',
            onPressed: () => context.push('/search'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.feed_outlined, size: 20), text: 'Feeds'),
            Tab(icon: Icon(Icons.event, size: 20), text: 'Events'),
            Tab(icon: Icon(Icons.groups_outlined, size: 20), text: 'Clubs & Advisory'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          FeedView(),
          EventsListView(),
          ClubsListView(),
        ],
      ),
    );
  }
}
