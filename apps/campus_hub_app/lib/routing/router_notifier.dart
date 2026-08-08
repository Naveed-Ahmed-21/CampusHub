import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/domain/models/auth_user.dart';

part 'router_notifier.g.dart';

@riverpod
class RouterNotifier extends _$RouterNotifier implements Listenable {
  VoidCallback? _routerListener;

  @override
  void build() {
    ref.listen(authControllerProvider, (_, __) {
      _routerListener?.call();
    });
  }

  String? redirect(BuildContext context, String currentPath) {
    final authState = ref.read(authControllerProvider);
    final user = authState.asData?.value;
    final isAuthenticated = user != null;
    final isAuthScreen = currentPath == '/login' ||
        currentPath == '/register' ||
        currentPath == '/forgot-password';

    if (!isAuthenticated && !isAuthScreen) return '/login';

    if (isAuthenticated && isAuthScreen) {
      if (user.isAdmin) return '/admin';
      if (user.isPlacementOfficer) return '/placement';
      return '/feed';
    }

    // Role-based navigation route guards (UX level)
    if (isAuthenticated) {
      if (currentPath.startsWith('/admin') && !user.isAdmin) {
        return '/feed';
      }
      if (currentPath.startsWith('/placement/drives/create') &&
          !user.isPlacementOfficer &&
          !user.isAdmin) {
        return '/placement';
      }
    }

    return null;
  }

  @override
  void addListener(VoidCallback listener) {
    _routerListener = listener;
  }

  @override
  void removeListener(VoidCallback listener) {
    _routerListener = null;
  }
}
