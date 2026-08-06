import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreenPlaceholder(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreenPlaceholder(),
      ),
      GoRoute(
        path: '/feed',
        name: 'feed',
        builder: (context, state) => const FeedScreenPlaceholder(),
      ),
      GoRoute(
        path: '/clubs',
        name: 'clubs',
        builder: (context, state) => const ClubsScreenPlaceholder(),
      ),
      GoRoute(
        path: '/events',
        name: 'events',
        builder: (context, state) => const EventsScreenPlaceholder(),
      ),
      GoRoute(
        path: '/placements',
        name: 'placements',
        builder: (context, state) => const PlacementsScreenPlaceholder(),
      ),
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) => const ChatScreenPlaceholder(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error?.message}'),
      ),
    ),
  );
});

// Structural Placeholders for Router Navigation
class HomeScreenPlaceholder extends StatelessWidget {
  const HomeScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CampusHub Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 64, color: Colors.indigo),
            const SizedBox(height: 16),
            const Text(
              'Welcome to CampusHub Ecosystem',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreenPlaceholder extends StatelessWidget {
  const LoginScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: const Center(child: Text('Login Screen (Authentication Module)')),
    );
  }
}

class FeedScreenPlaceholder extends StatelessWidget {
  const FeedScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Feed')),
      body: const Center(child: Text('Feed Module Placeholder')),
    );
  }
}

class ClubsScreenPlaceholder extends StatelessWidget {
  const ClubsScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Clubs')),
      body: const Center(child: Text('Clubs Module Placeholder')),
    );
  }
}

class EventsScreenPlaceholder extends StatelessWidget {
  const EventsScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Events')),
      body: const Center(child: Text('Events Module Placeholder')),
    );
  }
}

class PlacementsScreenPlaceholder extends StatelessWidget {
  const PlacementsScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Placement Hub')),
      body: const Center(child: Text('Placements Module Placeholder')),
    );
  }
}

class ChatScreenPlaceholder extends StatelessWidget {
  const ChatScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Chat')),
      body: const Center(child: Text('Chat Module Placeholder')),
    );
  }
}
