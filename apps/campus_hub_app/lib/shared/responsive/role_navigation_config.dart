import 'package:flutter/material.dart';
import '../../features/auth/domain/models/auth_user.dart';

class NavigationItemConfig {
  final String label;
  final Widget icon;
  final Widget selectedIcon;
  final String route;
  final int branchIndex;

  const NavigationItemConfig({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    required this.branchIndex,
  });
}

class RoleNavigationConfig {
  static const int feedBranchIndex = 0;
  static const int searchBranchIndex = 1;
  static const int clubsBranchIndex = 2;
  static const int chatBranchIndex = 3;
  static const int profileBranchIndex = 4;
  static const int facultyHomeBranchIndex = 5;
  static const int facultyTeachingBranchIndex = 6;
  static const int facultyCampusBranchIndex = 7;
  static const int facultyProfileBranchIndex = 8;
  static const int placementBranchIndex = 9;
  static const int adminBranchIndex = 10;
  static const int clubsPendingBranchIndex = 11;
  static const int eventsBranchIndex = 12;
  static const int careerBranchIndex = 13;
  static const int notificationsBranchIndex = 14;
  static const int deptAdminHomeBranchIndex = 15;
  static const int deptAdminStudentsBranchIndex = 16;
  static const int deptAdminAcademicsBranchIndex = 17;
  static const int deptAdminPlacementBranchIndex = 18;
  static const int deptAdminProfileBranchIndex = 19;
  static const int placementOpportunitiesBranchIndex = 20;
  static const int placementStudentsBranchIndex = 21;
  static const int placementAnalyticsBranchIndex = 22;
  static const int placementProfileBranchIndex = 23;

  static String getHomeRouteForUser(AuthUser? user) {
    if (user == null) {
      return '/feed';
    }
    if (user.isDeptAdmin) {
      return '/dept-admin';
    }
    if (user.isMainAdmin) {
      return '/admin';
    }
    if (user.isPlacementOfficer) {
      return '/placement';
    }
    if (user.isFaculty) {
      return '/faculty';
    }
    return '/feed';
  }

  static List<NavigationItemConfig> getNavigationItemsForUser(AuthUser? user) {
    if (user == null) {
      return _studentItems;
    }
    if (user.isDeptAdmin) {
      return _deptAdminItems;
    }
    if (user.isMainAdmin) {
      return _adminItems;
    }
    if (user.isPlacementOfficer) {
      return _placementItems;
    }
    if (user.isFaculty) {
      return _facultyItems;
    }
    return _studentItems;
  }

  static const List<NavigationItemConfig> _studentItems = [
    NavigationItemConfig(
      label: 'Home',
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      route: '/feed',
      branchIndex: feedBranchIndex,
    ),
    NavigationItemConfig(
      label: 'Search',
      icon: Icon(Icons.search_outlined),
      selectedIcon: Icon(Icons.search),
      route: '/search',
      branchIndex: searchBranchIndex,
    ),
    NavigationItemConfig(
      label: 'Clubs',
      icon: Icon(Icons.groups_outlined),
      selectedIcon: Icon(Icons.groups),
      route: '/clubs',
      branchIndex: clubsBranchIndex,
    ),
    NavigationItemConfig(
      label: 'Chats',
      icon: Icon(Icons.chat_bubble_outline),
      selectedIcon: Icon(Icons.chat_bubble),
      route: '/chat',
      branchIndex: chatBranchIndex,
    ),
    NavigationItemConfig(
      label: 'Profile',
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      route: '/profile',
      branchIndex: profileBranchIndex,
    ),
  ];

  static const List<NavigationItemConfig> _facultyItems = [
    NavigationItemConfig(
      label: 'Home',
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      route: '/faculty',
      branchIndex: facultyHomeBranchIndex,
    ),
    NavigationItemConfig(
      label: 'Teaching',
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book),
      route: '/teaching',
      branchIndex: facultyTeachingBranchIndex,
    ),
    NavigationItemConfig(
      label: 'Campus',
      icon: Icon(Icons.hub_outlined),
      selectedIcon: Icon(Icons.hub),
      route: '/faculty/campus',
      branchIndex: facultyCampusBranchIndex,
    ),
    NavigationItemConfig(
      label: 'Chats',
      icon: Icon(Icons.chat_bubble_outline),
      selectedIcon: Icon(Icons.chat_bubble),
      route: '/chat',
      branchIndex: chatBranchIndex,
    ),
    NavigationItemConfig(
      label: 'Profile',
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      route: '/faculty/profile',
      branchIndex: facultyProfileBranchIndex,
    ),
  ];

  static const List<NavigationItemConfig> _placementItems = [
    NavigationItemConfig(
      label: 'Hub',
      icon: Icon(Icons.work_outline),
      selectedIcon: Icon(Icons.work),
      route: '/placement',
      branchIndex: placementBranchIndex,
    ),
    NavigationItemConfig(
      label: 'Drives',
      icon: Icon(Icons.business_center_outlined),
      selectedIcon: Icon(Icons.business_center),
      route: '/placement/opportunities',
      branchIndex: placementOpportunitiesBranchIndex,
    ),
    NavigationItemConfig(
      label: 'Students',
      icon: Icon(Icons.people_alt_outlined),
      selectedIcon: Icon(Icons.people_alt),
      route: '/placement/students',
      branchIndex: placementStudentsBranchIndex,
    ),
    NavigationItemConfig(
      label: 'Chats',
      icon: Icon(Icons.chat_bubble_outline),
      selectedIcon: Icon(Icons.chat_bubble),
      route: '/chat',
      branchIndex: chatBranchIndex,
    ),
    NavigationItemConfig(
      label: 'Profile',
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      route: '/placement/profile',
      branchIndex: placementProfileBranchIndex,
    ),
  ];

  static const List<NavigationItemConfig> _adminItems = [
    NavigationItemConfig(
      label: 'Admin',
      icon: Icon(Icons.admin_panel_settings_outlined),
      selectedIcon: Icon(Icons.admin_panel_settings),
      route: '/admin',
      branchIndex: adminBranchIndex,
    ),
    NavigationItemConfig(
      label: 'Feed',
      icon: Icon(Icons.dynamic_feed_outlined),
      selectedIcon: Icon(Icons.dynamic_feed),
      route: '/feed',
      branchIndex: feedBranchIndex,
    ),
    NavigationItemConfig(
      label: 'Clubs',
      icon: Icon(Icons.groups_outlined),
      selectedIcon: Icon(Icons.groups),
      route: '/clubs',
      branchIndex: clubsBranchIndex,
    ),
    NavigationItemConfig(
      label: 'Chats',
      icon: Icon(Icons.chat_bubble_outline),
      selectedIcon: Icon(Icons.chat_bubble),
      route: '/chat',
      branchIndex: chatBranchIndex,
    ),
    NavigationItemConfig(
      label: 'Profile',
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      route: '/profile',
      branchIndex: profileBranchIndex,
    ),
  ];

  static const List<NavigationItemConfig> _deptAdminItems = [
    NavigationItemConfig(
      label: 'Home',
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      route: '/dept-admin',
      branchIndex: deptAdminHomeBranchIndex,
    ),
    NavigationItemConfig(
      label: 'Students',
      icon: Icon(Icons.people_alt_outlined),
      selectedIcon: Icon(Icons.people_alt),
      route: '/dept-admin/students',
      branchIndex: deptAdminStudentsBranchIndex,
    ),
    NavigationItemConfig(
      label: 'Academics',
      icon: Icon(Icons.school_outlined),
      selectedIcon: Icon(Icons.school),
      route: '/dept-admin/academics',
      branchIndex: deptAdminAcademicsBranchIndex,
    ),
    NavigationItemConfig(
      label: 'Placement',
      icon: Icon(Icons.work_outline),
      selectedIcon: Icon(Icons.work),
      route: '/dept-admin/placement',
      branchIndex: deptAdminPlacementBranchIndex,
    ),
    NavigationItemConfig(
      label: 'Profile',
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      route: '/dept-admin/profile',
      branchIndex: deptAdminProfileBranchIndex,
    ),
  ];
}
