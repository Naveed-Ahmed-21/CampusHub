import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import 'responsive_layout.dart';
import 'role_navigation_config.dart';

class MainScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Narrow watch using select to only rebuild when role/user identity changes
    final user = ref.watch(authControllerProvider.select((state) => state.asData?.value));
    final items = RoleNavigationConfig.getNavigationItemsForUser(user);

    // Calculate current selected index matching active branch index
    int selectedIndex = items.indexWhere((item) => item.branchIndex == navigationShell.currentIndex);
    if (selectedIndex < 0) {
      selectedIndex = 0;
    }

    void onDestinationTapped(int index) {
      if (index >= 0 && index < items.length) {
        final targetItem = items[index];
        final isCurrent = targetItem.branchIndex == navigationShell.currentIndex;
        navigationShell.goBranch(
          targetItem.branchIndex,
          initialLocation: isCurrent,
        );
      }
    }

    final destinations = items
        .map(
          (item) => NavigationDestination(
            icon: item.icon,
            selectedIcon: item.selectedIcon,
            label: item.label,
          ),
        )
        .toList(growable: false);

    final railDestinations = items
        .map(
          (item) => NavigationRailDestination(
            icon: item.icon,
            selectedIcon: item.selectedIcon,
            label: Text(item.label),
          ),
        )
        .toList(growable: false);

    return ResponsiveLayout(
      mobile: Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationTapped,
          destinations: destinations,
        ),
      ),
      desktop: Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationTapped,
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Icon(Icons.school, size: 36, color: Colors.blue),
              ),
              destinations: railDestinations,
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      ),
    );
  }
}
