import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/navigation/role_navigation.dart';
import 'admin_sidebar.dart';
import 'admin_top_bar.dart';

class AdminScaffold extends ConsumerStatefulWidget {
  final String selectedItemId;
  final ValueChanged<String> onItemSelected;
  final Widget body;

  const AdminScaffold({
    super.key,
    required this.selectedItemId,
    required this.onItemSelected,
    required this.body,
  });

  @override
  ConsumerState<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends ConsumerState<AdminScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1100;
    final isTablet = width >= 750 && width < 1100;
    final user = ref.watch(authControllerProvider).value;
    final items = RoleNavigation.getAdminHubItems(user);

    // Tablet Collapsed Navigation Rail
    Widget buildTabletRail() {
      final selectedIndex = items.indexWhere((i) => i.id == widget.selectedItemId);

      return NavigationRail(
        selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
        onDestinationSelected: (index) {
          if (index >= 0 && index < items.length) {
            widget.onItemSelected(items[index].id);
          }
        },
        labelType: NavigationRailLabelType.selected,
        leading: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Icon(Icons.admin_panel_settings, size: 28, color: Theme.of(context).primaryColor),
        ),
        destinations: items.map((item) {
          return NavigationRailDestination(
            icon: Icon(item.icon, size: 20),
            selectedIcon: Icon(item.selectedIcon, size: 20),
            label: Text(item.label, style: const TextStyle(fontSize: 10)),
          );
        }).toList(),
      );
    }

    if (isDesktop) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: const AdminTopBar(),
        body: Row(
          children: [
            AdminSidebar(
              selectedItemId: widget.selectedItemId,
              onItemSelected: widget.onItemSelected,
            ),
            Expanded(
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                child: widget.body,
              ),
            ),
          ],
        ),
      );
    }

    if (isTablet) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: const AdminTopBar(),
        body: Row(
          children: [
            buildTabletRail(),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                child: widget.body,
              ),
            ),
          ],
        ),
      );
    }

    // Mobile layout with Drawer
    return Scaffold(
      key: _scaffoldKey,
      appBar: AdminTopBar(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: AdminSidebar(
            selectedItemId: widget.selectedItemId,
            onItemSelected: (id) {
              Navigator.of(context).pop();
              widget.onItemSelected(id);
            },
          ),
        ),
      ),
      body: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: widget.body,
      ),
    );
  }
}
