import 'package:flutter/material.dart';
import '../../features/auth/domain/models/auth_user.dart';
import 'navigation_config.dart';
import 'navigation_item.dart';

class RoleNavigation {
  /// Top-level shell navigation destinations for the persistent shell scaffold
  static List<NavigationItem> getShellNavigationForUser(AuthUser? user) {
    if (user == null) return _studentShellItems;

    if (user.isDeptAdmin) {
      return _deptAdminShellItems;
    }
    if (user.isMainAdmin || user.isAdmin) {
      return _adminShellItems;
    }
    if (user.isPlacementOfficer) {
      return _placementShellItems;
    }
    if (user.isFaculty) {
      return _facultyShellItems;
    }
    return _studentShellItems;
  }

  static const List<NavigationItem> _studentShellItems = [
    NavigationItem(
      id: 'feed',
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      route: NavigationConfig.feedRoute,
      branchIndex: NavigationConfig.feedBranchIndex,
    ),
    NavigationItem(
      id: 'search',
      label: 'Search',
      icon: Icons.search_outlined,
      selectedIcon: Icons.search,
      route: NavigationConfig.searchRoute,
      branchIndex: NavigationConfig.searchBranchIndex,
    ),
    NavigationItem(
      id: 'clubs',
      label: 'Clubs',
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
      route: NavigationConfig.clubsRoute,
      branchIndex: NavigationConfig.clubsBranchIndex,
    ),
    NavigationItem(
      id: 'chat',
      label: 'Chats',
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
      route: NavigationConfig.chatRoute,
      branchIndex: NavigationConfig.chatBranchIndex,
    ),
    NavigationItem(
      id: 'profile',
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      route: NavigationConfig.profileRoute,
      branchIndex: NavigationConfig.profileBranchIndex,
    ),
  ];

  static const List<NavigationItem> _facultyShellItems = [
    NavigationItem(
      id: 'faculty_home',
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      route: NavigationConfig.facultyHomeRoute,
      branchIndex: NavigationConfig.facultyHomeBranchIndex,
    ),
    NavigationItem(
      id: 'teaching',
      label: 'Teaching',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      route: NavigationConfig.facultyTeachingRoute,
      branchIndex: NavigationConfig.facultyTeachingBranchIndex,
    ),
    NavigationItem(
      id: 'campus',
      label: 'Campus',
      icon: Icons.hub_outlined,
      selectedIcon: Icons.hub,
      route: NavigationConfig.facultyCampusRoute,
      branchIndex: NavigationConfig.facultyCampusBranchIndex,
    ),
    NavigationItem(
      id: 'chat',
      label: 'Chats',
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
      route: NavigationConfig.chatRoute,
      branchIndex: NavigationConfig.chatBranchIndex,
    ),
    NavigationItem(
      id: 'profile',
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      route: NavigationConfig.facultyProfileRoute,
      branchIndex: NavigationConfig.facultyProfileBranchIndex,
    ),
  ];

  static const List<NavigationItem> _placementShellItems = [
    NavigationItem(
      id: 'placement',
      label: 'Hub',
      icon: Icons.work_outline,
      selectedIcon: Icons.work,
      route: NavigationConfig.placementRoute,
      branchIndex: NavigationConfig.placementBranchIndex,
    ),
    NavigationItem(
      id: 'drives',
      label: 'Drives',
      icon: Icons.business_center_outlined,
      selectedIcon: Icons.business_center,
      route: NavigationConfig.placementOpportunitiesRoute,
      branchIndex: NavigationConfig.placementOpportunitiesBranchIndex,
    ),
    NavigationItem(
      id: 'students',
      label: 'Students',
      icon: Icons.people_alt_outlined,
      selectedIcon: Icons.people_alt,
      route: NavigationConfig.placementStudentsRoute,
      branchIndex: NavigationConfig.placementStudentsBranchIndex,
    ),
    NavigationItem(
      id: 'chat',
      label: 'Chats',
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
      route: NavigationConfig.chatRoute,
      branchIndex: NavigationConfig.chatBranchIndex,
    ),
    NavigationItem(
      id: 'profile',
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      route: NavigationConfig.placementProfileRoute,
      branchIndex: NavigationConfig.placementProfileBranchIndex,
    ),
  ];

  static const List<NavigationItem> _deptAdminShellItems = [
    NavigationItem(
      id: 'dept_home',
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      route: NavigationConfig.deptAdminRoute,
      branchIndex: NavigationConfig.deptAdminHomeBranchIndex,
    ),
    NavigationItem(
      id: 'dept_students',
      label: 'Students',
      icon: Icons.people_alt_outlined,
      selectedIcon: Icons.people_alt,
      route: NavigationConfig.deptAdminStudentsRoute,
      branchIndex: NavigationConfig.deptAdminStudentsBranchIndex,
    ),
    NavigationItem(
      id: 'dept_academics',
      label: 'Academics',
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
      route: NavigationConfig.deptAdminAcademicsRoute,
      branchIndex: NavigationConfig.deptAdminAcademicsBranchIndex,
    ),
    NavigationItem(
      id: 'dept_placement',
      label: 'Placement',
      icon: Icons.work_outline,
      selectedIcon: Icons.work,
      route: NavigationConfig.deptAdminPlacementRoute,
      branchIndex: NavigationConfig.deptAdminPlacementBranchIndex,
    ),
    NavigationItem(
      id: 'dept_profile',
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      route: NavigationConfig.deptAdminProfileRoute,
      branchIndex: NavigationConfig.deptAdminProfileBranchIndex,
    ),
  ];

  static const List<NavigationItem> _adminShellItems = [
    NavigationItem(
      id: 'admin',
      label: 'Admin Hub',
      icon: Icons.admin_panel_settings_outlined,
      selectedIcon: Icons.admin_panel_settings,
      route: NavigationConfig.adminRoute,
      branchIndex: NavigationConfig.adminBranchIndex,
    ),
    NavigationItem(
      id: 'feed',
      label: 'Feed',
      icon: Icons.dynamic_feed_outlined,
      selectedIcon: Icons.dynamic_feed,
      route: NavigationConfig.feedRoute,
      branchIndex: NavigationConfig.feedBranchIndex,
    ),
    NavigationItem(
      id: 'clubs',
      label: 'Clubs',
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
      route: NavigationConfig.clubsRoute,
      branchIndex: NavigationConfig.clubsBranchIndex,
    ),
    NavigationItem(
      id: 'chat',
      label: 'Chats',
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
      route: NavigationConfig.chatRoute,
      branchIndex: NavigationConfig.chatBranchIndex,
    ),
    NavigationItem(
      id: 'profile',
      label: 'Profile',
      icon: Icons.account_circle_outlined,
      selectedIcon: Icons.account_circle,
      route: NavigationConfig.profileRoute,
      branchIndex: NavigationConfig.profileBranchIndex,
    ),
  ];

  /// Internal Admin Hub navigation tree organized by institutional operating system categories
  static List<NavigationItem> getAdminHubItems(AuthUser? user) {
    final isDeptAdmin = user?.isDeptAdmin == true;

    return [
      // OVERVIEW
      const NavigationItem(
        id: 'dashboard',
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
        route: '/admin/dashboard',
        branchIndex: NavigationConfig.adminBranchIndex,
        category: NavigationCategory.overview,
      ),

      // ACADEMIC (Scoped for DEPT_ADMIN vs COLLEGE_ADMIN)
      if (!isDeptAdmin) ...[
        const NavigationItem(
          id: 'academic_years',
          label: 'Academic Years',
          icon: Icons.calendar_today_outlined,
          selectedIcon: Icons.calendar_today,
          route: '/admin/academic-years',
          branchIndex: NavigationConfig.adminBranchIndex,
          category: NavigationCategory.academic,
        ),
        const NavigationItem(
          id: 'departments',
          label: 'Departments',
          icon: Icons.domain_outlined,
          selectedIcon: Icons.domain,
          route: '/admin/departments',
          branchIndex: NavigationConfig.adminBranchIndex,
          category: NavigationCategory.academic,
        ),
        const NavigationItem(
          id: 'programs',
          label: 'Programs & Batches',
          icon: Icons.school_outlined,
          selectedIcon: Icons.school,
          route: '/admin/programs',
          branchIndex: NavigationConfig.adminBranchIndex,
          category: NavigationCategory.academic,
        ),
      ],
      const NavigationItem(
        id: 'classes',
        label: 'Classes & Sections',
        icon: Icons.meeting_room_outlined,
        selectedIcon: Icons.meeting_room,
        route: '/admin/classes',
        branchIndex: NavigationConfig.adminBranchIndex,
        category: NavigationCategory.academic,
      ),
      const NavigationItem(
        id: 'subjects',
        label: 'Subjects & Catalog',
        icon: Icons.menu_book_outlined,
        selectedIcon: Icons.menu_book,
        route: '/admin/subjects',
        branchIndex: NavigationConfig.adminBranchIndex,
        category: NavigationCategory.academic,
      ),
      const NavigationItem(
        id: 'rooms',
        label: 'Rooms & Venues',
        icon: Icons.room_preferences_outlined,
        selectedIcon: Icons.room_preferences,
        route: '/admin/rooms',
        branchIndex: NavigationConfig.adminBranchIndex,
        category: NavigationCategory.academic,
      ),

      // PEOPLE
      const NavigationItem(
        id: 'users',
        label: 'User Directory',
        icon: Icons.people_outline,
        selectedIcon: Icons.people,
        route: '/admin/users',
        branchIndex: NavigationConfig.adminBranchIndex,
        category: NavigationCategory.people,
      ),
      const NavigationItem(
        id: 'change_requests',
        label: 'Profile Changes',
        icon: Icons.pending_actions_outlined,
        selectedIcon: Icons.pending_actions,
        route: '/admin/change-requests',
        branchIndex: NavigationConfig.adminBranchIndex,
        category: NavigationCategory.people,
      ),

      // OPERATIONS
      const NavigationItem(
        id: 'timetable',
        label: 'Timetable Scheduling',
        icon: Icons.schedule_outlined,
        selectedIcon: Icons.schedule,
        route: '/admin/timetable',
        branchIndex: NavigationConfig.adminBranchIndex,
        category: NavigationCategory.operations,
      ),
      const NavigationItem(
        id: 'monitoring',
        label: 'Attendance & Monitoring',
        icon: Icons.fact_check_outlined,
        selectedIcon: Icons.fact_check,
        route: '/admin/monitoring',
        branchIndex: NavigationConfig.adminBranchIndex,
        category: NavigationCategory.operations,
      ),

      // CAMPUS
      const NavigationItem(
        id: 'feed',
        label: 'Campus Feed',
        icon: Icons.dynamic_feed_outlined,
        selectedIcon: Icons.dynamic_feed,
        route: '/admin/feed',
        branchIndex: NavigationConfig.adminBranchIndex,
        category: NavigationCategory.campus,
      ),
      const NavigationItem(
        id: 'moderation',
        label: 'Moderation & Posts',
        icon: Icons.security_outlined,
        selectedIcon: Icons.security,
        route: '/admin/moderation',
        branchIndex: NavigationConfig.adminBranchIndex,
        category: NavigationCategory.campus,
      ),
      const NavigationItem(
        id: 'clubs',
        label: 'Clubs & Events',
        icon: Icons.groups_outlined,
        selectedIcon: Icons.groups,
        route: '/admin/clubs',
        branchIndex: NavigationConfig.adminBranchIndex,
        category: NavigationCategory.campus,
      ),

      // CAREER
      const NavigationItem(
        id: 'placement',
        label: 'Placement Drives',
        icon: Icons.work_outline,
        selectedIcon: Icons.work,
        route: '/admin/placement',
        branchIndex: NavigationConfig.adminBranchIndex,
        category: NavigationCategory.career,
      ),

      // INSIGHTS
      const NavigationItem(
        id: 'audit_logs',
        label: 'Audit Trail & CSV',
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
        route: '/admin/audit',
        branchIndex: NavigationConfig.adminBranchIndex,
        category: NavigationCategory.insights,
      ),

      // SYSTEM
      if (!isDeptAdmin)
        const NavigationItem(
          id: 'college_settings',
          label: 'Institutional Profile',
          icon: Icons.account_balance_outlined,
          selectedIcon: Icons.account_balance,
          route: '/admin/institution',
          branchIndex: NavigationConfig.adminBranchIndex,
          category: NavigationCategory.system,
        ),
      const NavigationItem(
        id: 'admin_profile',
        label: 'Staff Identity',
        icon: Icons.badge_outlined,
        selectedIcon: Icons.badge,
        route: '/admin/profile',
        branchIndex: NavigationConfig.adminBranchIndex,
        category: NavigationCategory.system,
      ),
    ];
  }
}
