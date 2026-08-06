import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';

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
    final isAuthenticated = authState.asData?.value != null;
    final isAuthScreen = currentPath == '/login' ||
        currentPath == '/register' ||
        currentPath == '/forgot-password';

    if (!isAuthenticated && !isAuthScreen) return '/login';
    if (isAuthenticated && isAuthScreen) return '/feed';

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
