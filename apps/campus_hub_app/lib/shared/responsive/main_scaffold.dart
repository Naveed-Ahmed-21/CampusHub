import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/domain/models/auth_user.dart';
import 'responsive_layout.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context, bool isAdmin) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/feed')) return 0;
    if (location.startsWith('/events')) return 1;
    if (location.startsWith('/clubs')) return 2;
    if (location.startsWith('/chat')) return 3;
    if (location.startsWith('/placement')) return 4;
    if (location.startsWith('/notifications')) return 5;
    if (location.startsWith('/career')) return 6;
    if (location.startsWith('/profile')) return 7;
    if (location.startsWith('/admin') && isAdmin) return 8;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/feed');
        break;
      case 1:
        context.go('/events');
        break;
      case 2:
        context.go('/clubs');
        break;
      case 3:
        context.go('/chat');
        break;
      case 4:
        context.go('/placement');
        break;
      case 5:
        context.go('/notifications');
        break;
      case 6:
        context.go('/career');
        break;
      case 7:
        context.go('/profile');
        break;
      case 8:
        context.go('/admin');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final isAdmin = user?.isAdmin ?? false;
    final selectedIndex = _calculateSelectedIndex(context, isAdmin);

    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.dynamic_feed_outlined),
        selectedIcon: Icon(Icons.dynamic_feed),
        label: 'Feed',
      ),
      const NavigationDestination(
        icon: Icon(Icons.event_outlined),
        selectedIcon: Icon(Icons.event),
        label: 'Events',
      ),
      const NavigationDestination(
        icon: Icon(Icons.groups_outlined),
        selectedIcon: Icon(Icons.groups),
        label: 'Clubs',
      ),
      const NavigationDestination(
        icon: Icon(Icons.chat_outlined),
        selectedIcon: Icon(Icons.chat),
        label: 'Messages',
      ),
      const NavigationDestination(
        icon: Icon(Icons.business_center_outlined),
        selectedIcon: Icon(Icons.business_center),
        label: 'Placement',
      ),
      const NavigationDestination(
        icon: Icon(Icons.notifications_outlined),
        selectedIcon: Icon(Icons.notifications),
        label: 'Alerts',
      ),
      const NavigationDestination(
        icon: Icon(Icons.work_outline),
        selectedIcon: Icon(Icons.work),
        label: 'Career',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profile',
      ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
    ];

    final railDestinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.dynamic_feed_outlined),
        selectedIcon: Icon(Icons.dynamic_feed),
        label: Text('Feed'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.event_outlined),
        selectedIcon: Icon(Icons.event),
        label: Text('Events'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.groups_outlined),
        selectedIcon: Icon(Icons.groups),
        label: Text('Clubs'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.chat_outlined),
        selectedIcon: Icon(Icons.chat),
        label: Text('Messages'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.business_center_outlined),
        selectedIcon: Icon(Icons.business_center),
        label: Text('Placement'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.notifications_outlined),
        selectedIcon: Icon(Icons.notifications),
        label: Text('Alerts'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.work_outline),
        selectedIcon: Icon(Icons.work),
        label: Text('Career'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: Text('Profile'),
      ),
      if (isAdmin)
        const NavigationRailDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: Text('Admin'),
        ),
    ];

    return ResponsiveLayout(
      mobile: Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (idx) => _onItemTapped(idx, context),
          destinations: destinations,
        ),
      ),
      desktop: Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (idx) => _onItemTapped(idx, context),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Icon(Icons.school, size: 36, color: Colors.blue),
              ),
              destinations: railDestinations,
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
