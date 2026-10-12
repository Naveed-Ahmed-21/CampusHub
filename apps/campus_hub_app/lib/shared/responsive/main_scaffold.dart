import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/chat/data/socket_chat_service.dart';
import '../../features/notifications/presentation/providers/notifications_provider.dart';
import '../../core/services/local_notification_service.dart';
import '../../core/widgets/atmospheric_background.dart';
import '../../core/widgets/campus_sidebar.dart';
import '../../core/widgets/campus_bottom_nav.dart';
import '../../routing/app_router.dart';
import 'responsive_layout.dart';
import 'role_navigation_config.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    // Narrow watch using select to only rebuild when role/user identity changes
    final user = ref.watch(authControllerProvider.select((state) => state.asData?.value));

    // Ensure live real-time notification socket is connected whenever user is authenticated
    if (user != null) {
      ref.watch(socketChatServiceProvider);
      ref.watch(notificationsNotifierProvider);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (user != null) {
        LocalNotificationService.requestPermission();
      }
      final pendingRoute = consumePendingNotificationRoute();
      if (pendingRoute != null && context.mounted) {
        context.push(pendingRoute);
      }
    });

    final items = RoleNavigationConfig.getNavigationItemsForUser(user);

    // Calculate current selected index matching active branch index
    int selectedIndex = items
        .indexWhere((item) => item.branchIndex == widget.navigationShell.currentIndex);
    if (selectedIndex < 0) {
      selectedIndex = 0;
    }

    void onDestinationTapped(int index) {
      if (index >= 0 && index < items.length) {
        final targetItem = items[index];
        final isCurrent = targetItem.branchIndex == widget.navigationShell.currentIndex;
        widget.navigationShell.goBranch(
          targetItem.branchIndex,
          initialLocation: isCurrent,
        );
      }
    }

    // Role-specific workspace label
    String roleLabel = 'Student Portal';
    if (user != null) {
      if (user.isDeptAdmin) {
        roleLabel = 'Department Workspace';
      } else if (user.isMainAdmin) {
        roleLabel = 'Admin Command Center';
      } else if (user.isPlacementOfficer) {
        roleLabel = 'Placement Operations';
      } else if (user.isFaculty) {
        roleLabel = 'Faculty Workspace';
      }
    }

    // Desktop Sidebar items
    final sidebarItems = items.asMap().entries.map((entry) {
      final idx = entry.key;
      final navItem = entry.value;
      return SidebarItem(
        label: navItem.label,
        icon: navItem.icon,
        selectedIcon: navItem.selectedIcon,
        isSelected: idx == selectedIndex,
        onTap: () => onDestinationTapped(idx),
      );
    }).toList(growable: false);

    // Mobile Bottom Nav items (Up to 5 primary items)
    final mobileNavItems = items.take(5).map((navItem) {
      return CampusBottomNavItem(
        label: navItem.label,
        icon: navItem.icon,
        selectedIcon: navItem.selectedIcon,
      );
    }).toList(growable: false);

    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bottomClearance = isKeyboardOpen ? 0.0 : CampusBottomNav.getBottomClearance(context);

    return AtmosphericBackground(
      child: ResponsiveLayout(
        mobile: CampusBottomNavClearance(
          bottomClearance: bottomClearance,
          hasBottomNav: !isKeyboardOpen,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBody: false,
            resizeToAvoidBottomInset: true,
            body: widget.navigationShell,
            bottomNavigationBar: isKeyboardOpen
                ? const SizedBox.shrink()
                : CampusBottomNav(
                    selectedIndex: selectedIndex.clamp(0, mobileNavItems.length - 1),
                    onItemSelected: onDestinationTapped,
                    items: mobileNavItems,
                  ),
          ),
        ),
        desktop: Scaffold(
          backgroundColor: Colors.transparent,
          body: Row(
            children: [
              CampusSidebar(
                items: sidebarItems,
                isCollapsed: _isSidebarCollapsed,
                roleLabel: roleLabel,
                onToggleCollapse: () {
                  setState(() {
                    _isSidebarCollapsed = !_isSidebarCollapsed;
                  });
                },
              ),
              Expanded(
                child: widget.navigationShell,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
