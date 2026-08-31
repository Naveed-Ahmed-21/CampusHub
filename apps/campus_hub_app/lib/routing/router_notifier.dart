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
    final user = authState.asData?.value;
    if (currentPath == '/register') return '/login';

    final isAuthenticated = user != null;
    final isAuthScreen = currentPath == '/login' || currentPath == '/forgot-password';

    if (!isAuthenticated && !isAuthScreen) return '/login';

    if (isAuthenticated && (isAuthScreen || currentPath == '/' || (currentPath == '/feed' && !user.isStudent))) {
      if (user.isAdmin) return '/admin';
      if (user.isPlacementOfficer) return '/placement';
      if (user.isFaculty) return '/faculty';
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
