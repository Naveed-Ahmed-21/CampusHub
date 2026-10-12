import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/navigation/navigation_item.dart';
import '../../../../core/navigation/role_navigation.dart';

class AdminSidebar extends ConsumerWidget {
  final String selectedItemId;
  final ValueChanged<String> onItemSelected;

  const AdminSidebar({
    super.key,
    required this.selectedItemId,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final theme = Theme.of(context);
    final items = RoleNavigation.getAdminHubItems(user);

    // Group items by category
    final Map<NavigationCategory, List<NavigationItem>> grouped = {};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    String categoryTitle(NavigationCategory cat) {
      switch (cat) {
        case NavigationCategory.overview:
          return 'OVERVIEW';
        case NavigationCategory.academic:
          return 'ACADEMIC STRUCTURE';
        case NavigationCategory.people:
          return 'PEOPLE & DIRECTORY';
        case NavigationCategory.operations:
          return 'OPERATIONS';
        case NavigationCategory.campus:
          return 'CAMPUS & COMMUNITY';
        case NavigationCategory.career:
          return 'CAREER & PLACEMENT';
        case NavigationCategory.insights:
          return 'INSIGHTS & AUDIT';
        case NavigationCategory.system:
          return 'SYSTEM & GOVERNANCE';
      }
    }

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(right: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.admin_panel_settings, color: theme.primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CAMPUSHUB OS',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                      ),
                      Text(
                        user?.isDeptAdmin == true ? 'Department Console' : 'College Console',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              children: grouped.entries.map((entry) {
                final cat = entry.key;
                final catItems = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
                      child: Text(
                        categoryTitle(cat),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    ...catItems.map((item) {
                      final isSelected = item.id == selectedItemId;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isSelected ? theme.primaryColor.withValues(alpha: 0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          dense: true,
                          visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          leading: Icon(
                            isSelected ? item.selectedIcon : item.icon,
                            size: 18,
                            color: isSelected ? theme.primaryColor : Colors.grey.shade700,
                          ),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? theme.primaryColor : Colors.black87,
                            ),
                          ),
                          onTap: () => onItemSelected(item.id),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
