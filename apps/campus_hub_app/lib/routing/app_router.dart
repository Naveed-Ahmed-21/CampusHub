import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'router_notifier.dart';
import '../features/auth/presentation/views/login_view.dart';
import '../features/auth/presentation/views/register_view.dart';
import '../features/auth/presentation/views/forgot_password_view.dart';
import '../features/profile/presentation/views/profile_view.dart';
import '../features/feed/presentation/views/feed_view.dart';
import '../features/clubs/presentation/views/clubs_list_view.dart';
import '../features/clubs/presentation/views/club_detail_view.dart';
import '../features/clubs/presentation/views/admin_verify_clubs_view.dart';
import '../features/chat/presentation/views/chat_inbox_view.dart';
import '../features/chat/presentation/views/chat_room_view.dart';
import '../features/career/presentation/views/career_hub_view.dart';
import '../features/events/presentation/views/events_list_view.dart';
import '../features/placement/presentation/views/placement_hub_view.dart';
import '../features/notifications/presentation/views/notifications_view.dart';
import '../features/admin/presentation/views/admin_panel_view.dart';
import '../shared/responsive/main_scaffold.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final routerNotifier = ref.watch(routerNotifierProvider.notifier);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/feed',
    refreshListenable: routerNotifier,
    redirect: (context, state) => routerNotifier.redirect(context, state.uri.toString()),
    routes: [
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
        path: '/clubs/pending',
        name: 'clubs-pending',
        builder: (context, state) => const AdminVerifyClubsView(),
      ),
      GoRoute(
        path: '/clubs/:clubId',
        name: 'club-detail',
        builder: (context, state) => ClubDetailView(
          clubId: state.pathParameters['clubId']!,
        ),
      ),
      GoRoute(
        path: '/chat/room/:roomId',
        name: 'chat-room',
        builder: (context, state) => ChatRoomView(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/feed',
            name: 'feed',
            builder: (context, state) => const FeedView(),
          ),
          GoRoute(
            path: '/clubs',
            name: 'clubs',
            builder: (context, state) => const ClubsListView(),
          ),
          GoRoute(
            path: '/chat',
            name: 'chat',
            builder: (context, state) => const ChatInboxView(),
          ),
          GoRoute(
            path: '/career',
            name: 'career',
            builder: (context, state) => const CareerHubView(),
          ),
          GoRoute(
            path: '/events',
            name: 'events',
            builder: (context, state) => const EventsListView(),
          ),
          GoRoute(
            path: '/placement',
            name: 'placement',
            builder: (context, state) => const PlacementHubView(),
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationsView(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileView(),
          ),
          GoRoute(
            path: '/admin',
            name: 'admin',
            builder: (context, state) => const AdminPanelView(),
          ),
        ],
      ),
    ],
  );
}
