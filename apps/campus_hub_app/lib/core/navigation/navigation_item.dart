import 'package:flutter/material.dart';

enum NavigationCategory {
  overview,
  academic,
  people,
  operations,
  campus,
  career,
  insights,
  system,
}

class NavigationItem {
  final String id;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final int branchIndex;
  final NavigationCategory category;
  final String? requiredPermission;
  final String? scope;
  final int? badgeCount;

  const NavigationItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    required this.branchIndex,
    this.category = NavigationCategory.overview,
    this.requiredPermission,
    this.scope,
    this.badgeCount,
  });

  NavigationItem copyWith({
    String? id,
    String? label,
    IconData? icon,
    IconData? selectedIcon,
    String? route,
    int? branchIndex,
    NavigationCategory? category,
    String? requiredPermission,
    String? scope,
    int? badgeCount,
  }) {
    return NavigationItem(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      selectedIcon: selectedIcon ?? this.selectedIcon,
      route: route ?? this.route,
      branchIndex: branchIndex ?? this.branchIndex,
      category: category ?? this.category,
      requiredPermission: requiredPermission ?? this.requiredPermission,
      scope: scope ?? this.scope,
      badgeCount: badgeCount ?? this.badgeCount,
    );
  }
}
