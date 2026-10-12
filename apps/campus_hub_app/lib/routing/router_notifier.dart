import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authControllerProvider, (_, __) {
      notifyListeners();
    });
  }

  String? redirect(BuildContext context, String currentPath) {
    final authState = _ref.read(authControllerProvider);

    // If auth state is still loading (cold start autoLogin in flight),
    // stay on root splash and do not bounce to /login
    if (authState.isLoading) {
      return null;
    }

    final user = authState.asData?.value;
    if (currentPath == '/register') return '/login';

    final isAuthenticated = user != null;
    final isAuthScreen = currentPath == '/login' ||
        currentPath == '/forgot-password' ||
        currentPath.startsWith('/setup-password');

    if (!isAuthenticated && !isAuthScreen) return '/login';

    // If authenticated student hasn't completed onboarding, direct them to /onboarding
    if (isAuthenticated && user.isStudent && !user.isProfileCompleted) {
      if (currentPath != '/onboarding') {
        return '/onboarding';
      }
      return null;
    }

    // If already completed onboarding but visits /onboarding, redirect to home
    if (isAuthenticated && currentPath == '/onboarding' && user.isProfileCompleted) {
      return '/feed';
    }

    if (isAuthenticated && (isAuthScreen || currentPath == '/')) {
      if (user.isDeptAdmin) return '/dept-admin';
      if (user.isMainAdmin) return '/admin';
      if (user.isPlacementOfficer) return '/placement';
      if (user.isFaculty) return '/faculty';
      return '/feed';
    }

    // Role-based navigation route guards (UX level)
    if (isAuthenticated) {
      if (currentPath == '/feed' && user.isDeptAdmin) {
        return '/dept-admin';
      }
      if (currentPath == '/feed' && user.isFaculty) {
        return '/faculty';
      }
      if (currentPath.startsWith('/dept-admin') && !user.isDeptAdmin && !user.isMainAdmin) {
        return '/feed';
      }
      if (currentPath.startsWith('/admin') && !user.isMainAdmin) {
        return '/feed';
      }
      if (currentPath.startsWith('/placement/drives/create') &&
          !user.isPlacementOfficer &&
          !user.isAdmin) {
        return '/placement';
      }
      if ((currentPath.startsWith('/teaching') || currentPath.startsWith('/faculty')) &&
          !user.isFaculty &&
          !user.isAdmin) {
        return '/feed';
      }
    }

    return null;

  }
}

final routerNotifierProvider = ChangeNotifierProvider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});
