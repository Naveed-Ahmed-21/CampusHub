import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../events/presentation/views/events_list_view.dart';
import '../../../clubs/presentation/views/clubs_list_view.dart';
import '../../../feed/presentation/views/feed_view.dart';
import '../widgets/faculty_drawer_widget.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/widgets/campus_segmented_control.dart';

class FacultyCampusView extends ConsumerStatefulWidget {
  const FacultyCampusView({super.key});

  @override
  ConsumerState<FacultyCampusView> createState() => _FacultyCampusViewState();
}

class _FacultyCampusViewState extends ConsumerState<FacultyCampusView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging &&
          _selectedTabIndex != _tabController.index) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const FacultyDrawerWidget(),
      appBar: CampusAppBar(
        title: 'Campus',
        subtitle: 'College Ecosystem',
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Open Drawer',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.search, size: 20),
            tooltip: 'Search Campus',
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.notifications_outlined, size: 20),
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: CampusSegmentedControl(
              height: 38,
              selectedIndex: _selectedTabIndex,
              items: const [
                CampusSegmentItem(label: 'Feed'),
                CampusSegmentItem(label: 'Events'),
                CampusSegmentItem(label: 'Clubs'),
              ],
              onValueChanged: (index) {
                setState(() {
                  _selectedTabIndex = index;
                });
                _tabController.animateTo(index);
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                FeedView(showAppBar: false),
                EventsListView(showAppBar: false),
                ClubsListView(showAppBar: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

