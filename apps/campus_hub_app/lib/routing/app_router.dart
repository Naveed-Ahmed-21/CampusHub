import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'router_notifier.dart';
import '../features/auth/presentation/views/login_view.dart';
import '../features/auth/presentation/views/register_view.dart';
import '../features/auth/presentation/views/forgot_password_view.dart';
import '../features/profile/presentation/views/profile_view.dart';
import '../features/feed/presentation/views/feed_view.dart';
import '../features/feed/presentation/views/campus_collaboration_view.dart';
import '../features/clubs/presentation/views/clubs_list_view.dart';
import '../features/clubs/presentation/views/club_detail_view.dart';
import '../features/clubs/presentation/views/admin_verify_clubs_view.dart';
import '../features/chat/presentation/views/chat_inbox_view.dart';
import '../features/chat/presentation/views/chat_room_view.dart';
import '../features/chat/presentation/views/contact_select_view.dart';
import '../features/chat/presentation/views/create_group_view.dart';
import '../features/chat/presentation/views/group_info_view.dart';
import '../features/career/presentation/views/career_hub_view.dart';
import '../features/events/presentation/views/events_list_view.dart';
import '../features/placement/presentation/views/placement_hub_view.dart';
import '../features/notifications/presentation/views/notifications_view.dart';
import '../features/admin/presentation/views/admin_panel_view.dart';
import '../features/search/presentation/views/global_search_view.dart';
import '../features/faculty/presentation/views/faculty_home_view.dart';
import '../features/faculty/presentation/views/faculty_teaching_view.dart';
import '../features/faculty/presentation/views/subject_detail_view.dart';
import '../features/faculty/presentation/views/faculty_campus_view.dart';
import '../features/faculty/presentation/views/faculty_profile_view.dart';
import '../features/portfolio/presentation/views/portfolio_view.dart';
import '../features/profile/presentation/views/user_profile_detail_view.dart';
import '../features/profile/presentation/views/user_follows_view.dart';
import '../shared/responsive/main_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/feed',
    refreshListenable: routerNotifier,
    redirect: (context, state) => routerNotifier.redirect(context, state.uri.toString()),
    routes: [
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
        path: '/profile/:userId',
        name: 'user-profile-direct',
        builder: (context, state) => UserProfileDetailView(
          userId: state.pathParameters['userId']!,
        ),
      ),
      GoRoute(
        path: '/profile/user/:userId',
        name: 'other-user-profile',
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
          initialIndex: int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0,
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
        path: '/chat/room/:roomId',
        name: 'chat-room',
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
        ),
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
        ],
      ),
    ],
  );
});
