import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../shared/responsive/role_navigation_config.dart';

/// Clean iOS-style Back Pop Button for AppBars across all platforms and devices.
class CampusBackButton extends ConsumerWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  const CampusBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.size = 20.0,
  });

  /// Safely checks if the screen can pop either via Navigator or GoRouter.
  static bool canPop(BuildContext context) {
    if (Navigator.of(context).canPop()) return true;
    try {
      return context.canPop();
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(
        Icons.arrow_back_ios_new_rounded,
        size: size,
        color: color,
      ),
      tooltip: 'Back',
      onPressed: () {
        if (onPressed != null) {
          onPressed!();
        } else if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          try {
            if (context.canPop()) {
              context.pop();
            } else {
              final user = ref.read(authControllerProvider).asData?.value;
              final fallbackRoute = RoleNavigationConfig.getHomeRouteForUser(user);
              context.go(fallbackRoute);
            }
          } catch (_) {
            Navigator.of(context).maybePop();
          }
        }
      },
    );
  }
}
