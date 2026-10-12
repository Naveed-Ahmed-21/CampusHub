import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'router_notifier.dart';
import '../features/auth/presentation/views/login_view.dart';
import '../features/auth/presentation/views/register_view.dart';
import '../features/auth/presentation/views/forgot_password_view.dart';
import '../features/auth/presentation/views/setup_password_view.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/onboarding/presentation/views/student_onboarding_view.dart';
import '../features/profile/presentation/views/profile_view.dart';

import '../features/feed/presentation/views/feed_view.dart';
import '../features/feed/presentation/views/post_detail_view.dart';
import '../features/feed/presentation/views/campus_collaboration_view.dart';
import '../features/clubs/presentation/views/clubs_list_view.dart';
import '../features/clubs/presentation/views/club_detail_view.dart';
import '../features/clubs/presentation/views/admin_verify_clubs_view.dart';
import '../features/chat/presentation/views/chat_inbox_view.dart';
import '../features/chat/presentation/views/chat_room_view.dart';
import '../features/chat/presentation/views/contact_select_view.dart';
import '../features/chat/presentation/views/create_group_view.dart';
import '../features/chat/presentation/views/group_info_view.dart';
import '../features/chat/presentation/views/chat_requests_view.dart';
import '../features/career/presentation/views/career_hub_view.dart';
import '../features/career/presentation/views/user_roadmaps_list_view.dart';
import '../features/events/presentation/views/events_list_view.dart';
import '../features/placement/presentation/views/placement_hub_view.dart';
import '../features/placement/presentation/views/opportunities_view.dart';
import '../features/placement/presentation/views/drive_detail_view.dart';
import '../features/placement/presentation/views/create_placement_drive_view.dart';
import '../features/placement/presentation/views/companies_view.dart';
import '../features/placement/presentation/views/company_profile_view.dart';
import '../features/placement/presentation/views/applications_view.dart';
import '../features/placement/presentation/views/application_detail_view.dart';
import '../features/placement/presentation/views/shortlist_results_view.dart';
import '../features/placement/presentation/views/interviews_view.dart';
import '../features/placement/presentation/views/preparation_hub_view.dart';
import '../features/placement/presentation/views/resource_detail_view.dart';
import '../features/placement/presentation/views/students_directory_view.dart';
import '../features/placement/presentation/views/student_profile_view.dart';
import '../features/placement/presentation/views/placement_analytics_view.dart';
import '../features/placement/presentation/views/reports_view.dart';
import '../features/placement/presentation/views/placement_profile_view.dart';
import '../features/notifications/presentation/views/notifications_view.dart';
import '../features/admin/presentation/views/admin_panel_view.dart';
import '../features/admin/presentation/views/admin_profile_view.dart';
import '../features/admin/presentation/views/account_activity_view.dart';
import '../features/search/presentation/views/global_search_view.dart';
import '../features/faculty/presentation/views/faculty_home_view.dart';
import '../features/faculty/presentation/views/faculty_teaching_view.dart';
import '../features/faculty/presentation/views/subject_detail_view.dart';
import '../features/faculty/presentation/views/faculty_campus_view.dart';
import '../features/faculty/presentation/views/faculty_profile_view.dart';
import '../features/portfolio/presentation/views/portfolio_view.dart';
import '../features/profile/presentation/views/user_profile_detail_view.dart';
import '../features/profile/presentation/views/user_follows_view.dart';
import '../features/settings/presentation/views/settings_view.dart';
import '../features/settings/presentation/views/help_support_view.dart';
import '../features/settings/presentation/views/about_view.dart';
import '../features/academics/presentation/views/student_subjects_view.dart';
import '../features/academics/presentation/views/student_subject_detail_view.dart';
import '../features/academics/presentation/views/faculty_directory_view.dart';
import '../features/academics/presentation/views/student_timetable_view.dart';
import '../features/dept_admin/presentation/views/dept_admin_home_view.dart';
import '../features/dept_admin/presentation/views/dept_students_view.dart';
import '../features/dept_admin/presentation/views/dept_student_profile_view.dart';
import '../features/dept_admin/presentation/views/dept_faculty_view.dart';
import '../features/dept_admin/presentation/views/dept_academics_view.dart';
import '../features/dept_admin/presentation/views/dept_timetable_view.dart';
import '../features/dept_admin/presentation/views/dept_attendance_view.dart';
import '../features/dept_admin/presentation/views/dept_low_attendance_view.dart';
import '../features/dept_admin/presentation/views/dept_assignments_view.dart';
import '../features/dept_admin/presentation/views/dept_assessments_view.dart';
import '../features/dept_admin/presentation/views/dept_resources_view.dart';
import '../features/dept_admin/presentation/views/dept_placement_view.dart';
import '../features/dept_admin/presentation/views/dept_feed_view.dart';
import '../features/dept_admin/presentation/views/dept_reports_view.dart';
import '../features/dept_admin/presentation/views/dept_admin_profile_view.dart';
import '../features/dept_admin/presentation/views/dept_admin_settings_view.dart';
import '../shared/responsive/main_scaffold.dart';
import '../core/branding/campushub_brand.dart';
import '../core/theme/app_colors.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
String? _pendingNotificationRoute;

void handleNotificationNavigation(String? path) {
  final target = (path == null || path.isEmpty) ? '/notifications' : path;
  debugPrint('🔔 [AppRouter] Deep linking to notification path: $target');
  final navContext = rootNavigatorKey.currentContext;
  if (navContext != null && navContext.mounted) {
    try {
      GoRouter.of(navContext).push(target);
    } catch (e) {
      debugPrint(
          '⚠️ [AppRouter] Failed to navigate to $target: $e. Falling back to /notifications');
      try {
        GoRouter.of(navContext).push('/notifications');
      } catch (_) {}
    }
  } else {
    _pendingNotificationRoute = target;
  }
}

String? consumePendingNotificationRoute() {
  final path = _pendingNotificationRoute;
  _pendingNotificationRoute = null;
  return path;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.read(routerNotifierProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: routerNotifier,
    redirect: (context, state) =>
        routerNotifier.redirect(context, state.uri.toString()),
    routes: [
      // Root splash / bootstrap route handled by RouterNotifier
      GoRoute(
        path: '/',
        name: 'root',
        builder: (context, state) => const _AppSplashScreen(),
      ),
      // 1. Auth & Public Entry Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordView(),
      ),
      GoRoute(
        path: '/setup-password',
        name: 'setup-password',
        builder: (context, state) => SetupPasswordView(
          initialEmail: state.uri.queryParameters['email'],
          token: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const StudentOnboardingView(),
      ),

      // 2. Sub-views pushed onto root navigator

      GoRoute(
        path: '/portfolio',
        name: 'my-portfolio',
        builder: (context, state) => const PortfolioView(),
      ),
      GoRoute(
        path: '/portfolio/:identifier',
        name: 'public-portfolio',
        builder: (context, state) => UserProfileDetailView(
          userId: state.pathParameters['identifier']!,
        ),
      ),
      GoRoute(
        path: '/posts/:postId',
        name: 'post-detail',
        builder: (context, state) => PostDetailView(
          postId: state.pathParameters['postId']!,
        ),
      ),
      GoRoute(
        path: '/profile/:userId',
        name: 'user-profile-direct',
        redirect: (context, state) {
          final targetId = state.pathParameters['userId'];
          final currentUserId = ref.read(authControllerProvider).asData?.value?.id;
          if (targetId != null && currentUserId != null && targetId.trim() == currentUserId.trim()) {
            return '/profile';
          }
          return null;
        },
        builder: (context, state) => UserProfileDetailView(
          userId: state.pathParameters['userId']!,
        ),
      ),
      GoRoute(
        path: '/profile/user/:userId',
        name: 'other-user-profile',
        redirect: (context, state) {
          final targetId = state.pathParameters['userId'];
          final currentUserId = ref.read(authControllerProvider).asData?.value?.id;
          if (targetId != null && currentUserId != null && targetId.trim() == currentUserId.trim()) {
            return '/profile';
          }
          return null;
        },
        builder: (context, state) => UserProfileDetailView(
          userId: state.pathParameters['userId']!,
        ),
      ),
      GoRoute(
        path: '/profile/:userId/connections',
        name: 'user-connections',
        builder: (context, state) => UserFollowsView(
          userId: state.pathParameters['userId']!,
          userName: (state.uri.queryParameters['name']) ?? 'Connections',
          initialIndex:
              int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0,
        ),
      ),
      GoRoute(
        path: '/events/:eventId',
        name: 'event-detail',
        builder: (context, state) => const EventsListView(),
      ),
      GoRoute(
        path: '/clubs/:clubId',
        name: 'club-detail',
        builder: (context, state) => ClubDetailView(
          clubId: state.pathParameters['clubId']!,
        ),
      ),
      GoRoute(
        path: '/chat/contacts',
        name: 'chat-contacts',
        builder: (context, state) => const ContactSelectView(),
      ),
      GoRoute(
        path: '/chat/create-group',
        name: 'chat-create-group',
        builder: (context, state) => const CreateGroupView(),
      ),
      GoRoute(
        path: '/chat/group-info/:roomId',
        name: 'chat-group-info',
        builder: (context, state) => GroupInfoView(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/chat/requests',
        name: 'chat-requests',
        builder: (context, state) {
          final tabStr = state.uri.queryParameters['tab'];
          final initialTab = int.tryParse(tabStr ?? '0') ?? 0;
          return ChatRequestsView(initialTabIndex: initialTab);
        },
      ),
      GoRoute(
        path: '/chat/requests/incoming',
        name: 'chat-requests-incoming',
        builder: (context, state) => const ChatRequestsView(initialTabIndex: 0),
      ),
      GoRoute(
        path: '/chat/requests/sent',
        name: 'chat-requests-sent',
        builder: (context, state) => const ChatRequestsView(initialTabIndex: 1),
      ),
      GoRoute(
        path: '/chat/room/:roomId',
        name: 'chat-room',
        builder: (context, state) => ChatRoomView(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/chat/:roomId',
        name: 'chat-room-direct',
        builder: (context, state) => ChatRoomView(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/collaborations',
        name: 'campus-collaborations',
        builder: (context, state) => const CampusCollaborationView(),
      ),
      GoRoute(
        path: '/teaching/subjects/:subjectId',
        name: 'subject-detail',
        builder: (context, state) => SubjectDetailView(
          subjectId: state.pathParameters['subjectId']!,
          initialTab: int.tryParse(state.uri.queryParameters['tab'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsView(),
      ),
      GoRoute(
        path: '/help',
        name: 'help-support',
        builder: (context, state) => const HelpSupportView(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutView(),
      ),
      GoRoute(
        path: '/academics',
        name: 'academic-subjects',
        builder: (context, state) => const StudentSubjectsView(),
      ),
      GoRoute(
        path: '/academics/subjects/:subjectId',
        name: 'academic-subject-detail',
        builder: (context, state) => StudentSubjectDetailView(
          subjectId: state.pathParameters['subjectId']!,
          initialTab: int.tryParse(state.uri.queryParameters['tab'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/academics/faculty',
        name: 'academic-faculty-directory',
        builder: (context, state) => const FacultyDirectoryView(),
      ),
      GoRoute(
        path: '/academics/timetable',
        name: 'academic-timetable',
        builder: (context, state) => const StudentTimetableView(),
      ),
      GoRoute(
        path: '/admin/profile',
        name: 'admin-profile',
        builder: (context, state) => const AdminProfileView(),
      ),
      GoRoute(
        path: '/admin/feed',
        name: 'admin-feed',
        redirect: (context, state) => '/feed',
      ),
      GoRoute(
        path: '/admin/activity',
        name: 'admin-activity',
        builder: (context, state) => const AccountActivityView(),
      ),
      GoRoute(
        path: '/clubs/pending',
        name: 'clubs-pending-legacy',
        redirect: (context, state) => '/admin/clubs/pending',
      ),
      GoRoute(
        path: '/career-hub',
        name: 'career-hub-standalone',
        builder: (context, state) => const CareerHubView(),
      ),
      GoRoute(
        path: '/career/roadmaps',
        name: 'career-roadmaps-standalone',
        builder: (context, state) => const UserRoadmapsListView(),
      ),

      // 2b. Placement Operations Routes (Sub-views)
      GoRoute(
        path: '/placement/drives/:id',
        name: 'placement-drive-detail',
        builder: (context, state) => DriveDetailView(
          driveId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/placement/create-drive',
        name: 'placement-create-drive',
        builder: (context, state) => const CreatePlacementDriveView(),
      ),
      GoRoute(
        path: '/placement/companies',
        name: 'placement-companies',
        builder: (context, state) => const CompaniesView(),
      ),
      GoRoute(
        path: '/placement/companies/:id',
        name: 'placement-company-profile',
        builder: (context, state) => CompanyProfileView(
          companyId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/placement/applications',
        name: 'placement-applications',
        builder: (context, state) => ApplicationsView(
          driveId: state.uri.queryParameters['drive_id'],
        ),
      ),
      GoRoute(
        path: '/placement/applications/:id',
        name: 'placement-application-detail',
        builder: (context, state) => ApplicationDetailView(
          applicationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/placement/shortlist',
        name: 'placement-shortlist',
        builder: (context, state) => ShortlistResultsView(
          driveId: state.uri.queryParameters['drive_id'],
        ),
      ),
      GoRoute(
        path: '/placement/interviews',
        name: 'placement-interviews',
        builder: (context, state) => const InterviewsView(),
      ),
      GoRoute(
        path: '/placement/preparation',
        name: 'placement-preparation',
        builder: (context, state) => const PreparationHubView(),
      ),
      GoRoute(
        path: '/placement/resources/:id',
        name: 'placement-resource-detail',
        builder: (context, state) => ResourceDetailView(
          resourceId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/placement/students/:id',
        name: 'placement-student-profile',
        builder: (context, state) => StudentProfileView(
          studentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/placement/reports',
        name: 'placement-reports',
        builder: (context, state) => const ReportsView(),
      ),

      // 2c. Department Administrator Routes
      GoRoute(
        path: '/dept-admin/students/:id',
        name: 'dept-admin-student-profile',
        builder: (context, state) => DeptStudentProfileView(
          studentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/dept-admin/faculty',
        name: 'dept-admin-faculty',
        builder: (context, state) => const DeptFacultyView(),
      ),
      GoRoute(
        path: '/dept-admin/timetable',
        name: 'dept-admin-timetable',
        builder: (context, state) => const DeptTimetableView(),
      ),
      GoRoute(
        path: '/dept-admin/attendance',
        name: 'dept-admin-attendance',
        builder: (context, state) => const DeptAttendanceView(),
      ),
      GoRoute(
        path: '/dept-admin/attendance/low',
        name: 'dept-admin-low-attendance',
        builder: (context, state) => const DeptLowAttendanceView(),
      ),
      GoRoute(
        path: '/dept-admin/assignments',
        name: 'dept-admin-assignments',
        builder: (context, state) => const DeptAssignmentsView(),
      ),
      GoRoute(
        path: '/dept-admin/assessments',
        name: 'dept-admin-assessments',
        builder: (context, state) => const DeptAssessmentsView(),
      ),
      GoRoute(
        path: '/dept-admin/resources',
        name: 'dept-admin-resources',
        builder: (context, state) => const DeptResourcesView(),
      ),
      GoRoute(
        path: '/dept-admin/feed',
        name: 'dept-admin-feed',
        builder: (context, state) => const DeptFeedView(),
      ),
      GoRoute(
        path: '/dept-admin/reports',
        name: 'dept-admin-reports',
        builder: (context, state) => const DeptReportsView(),
      ),
      GoRoute(
        path: '/dept-admin/settings',
        name: 'dept-admin-settings',
        builder: (context, state) => const DeptAdminSettingsView(),
      ),

      // 3. Main Persistent Tab Navigation Shell (Stateful IndexedStack)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainScaffold(
          navigationShell: navigationShell,
        ),
        branches: [
          // Branch 0: Feed / Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                name: 'feed',
                builder: (context, state) => const FeedView(),
              ),
            ],
          ),

          // Branch 1: Search / Explore
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                name: 'search',
                builder: (context, state) => const GlobalSearchView(),
              ),
            ],
          ),

          // Branch 2: Clubs & Communities
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/clubs',
                name: 'clubs',
                builder: (context, state) => const ClubsListView(),
              ),
            ],
          ),

          // Branch 3: Chat / Direct & Group Messages
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                name: 'chat',
                builder: (context, state) => const ChatInboxView(),
              ),
            ],
          ),

          // Branch 4: User Profile & Portfolio
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileView(),
              ),
            ],
          ),

          // Branch 5: Faculty Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/faculty',
                name: 'faculty-home',
                builder: (context, state) => const FacultyHomeView(),
              ),
            ],
          ),

          // Branch 6: Faculty Teaching & Subjects
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/teaching',
                name: 'faculty-teaching',
                builder: (context, state) => const FacultyTeachingView(),
              ),
            ],
          ),

          // Branch 7: Faculty Campus Ecosystem
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/faculty/campus',
                name: 'faculty-campus',
                builder: (context, state) => const FacultyCampusView(),
              ),
            ],
          ),

          // Branch 8: Faculty Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/faculty/profile',
                name: 'faculty-profile',
                builder: (context, state) => const FacultyProfileView(),
              ),
            ],
          ),

          // Branch 9: Placement Officer Hub
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/placement',
                name: 'placement',
                builder: (context, state) => const PlacementHubView(),
              ),
            ],
          ),

          // Branch 10: Admin Panel
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin',
                name: 'admin',
                builder: (context, state) => const AdminPanelView(),
              ),
            ],
          ),

          // Branch 11: Club Pending Approvals
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/clubs/pending',
                name: 'clubs-pending',
                builder: (context, state) => const AdminVerifyClubsView(),
              ),
            ],
          ),

          // Branch 12: Events List
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/events',
                name: 'events',
                builder: (context, state) => const EventsListView(),
              ),
            ],
          ),

          // Branch 13: Career Hub
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/career',
                name: 'career',
                builder: (context, state) => const CareerHubView(),
              ),
            ],
          ),

          // Branch 14: Notifications
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                name: 'notifications',
                builder: (context, state) => const NotificationsView(),
              ),
            ],
          ),

          // Branch 15: Department Admin Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dept-admin',
                name: 'dept-admin-home',
                builder: (context, state) => const DeptAdminHomeView(),
              ),
            ],
          ),

          // Branch 16: Department Admin Students
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dept-admin/students',
                name: 'dept-admin-students',
                builder: (context, state) => const DeptStudentsView(),
              ),
            ],
          ),

          // Branch 17: Department Admin Academics
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dept-admin/academics',
                name: 'dept-admin-academics',
                builder: (context, state) => const DeptAcademicsView(),
              ),
            ],
          ),

          // Branch 18: Department Admin Placement
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dept-admin/placement',
                name: 'dept-admin-placement',
                builder: (context, state) => const DeptPlacementView(),
              ),
            ],
          ),

          // Branch 19: Department Admin Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dept-admin/profile',
                name: 'dept-admin-profile',
                builder: (context, state) => const DeptAdminProfileView(),
              ),
            ],
          ),

          // Branch 20: Placement Opportunities / Drives
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/placement/opportunities',
                name: 'placement-opportunities',
                builder: (context, state) => const OpportunitiesView(),
              ),
            ],
          ),

          // Branch 21: Placement Students Directory
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/placement/students',
                name: 'placement-students',
                builder: (context, state) => const StudentsDirectoryView(),
              ),
            ],
          ),

          // Branch 22: Placement Analytics
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/placement/analytics',
                name: 'placement-analytics',
                builder: (context, state) => const PlacementAnalyticsView(),
              ),
            ],
          ),

          // Branch 23: Placement Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/placement/profile',
                name: 'placement-profile',
                builder: (context, state) => const PlacementProfileView(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _AppSplashScreen extends StatelessWidget {
  const _AppSplashScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBase : AppColors.lightBackground,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CampusHubBrand.login(),
            SizedBox(height: 32),
            CircularProgressIndicator(strokeWidth: 2.5),
          ],
        ),
      ),
    );
  }
}
