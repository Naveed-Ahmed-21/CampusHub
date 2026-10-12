import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_glass.dart';

/// Layer 1: CampusHub Atmospheric Background.
/// Provides a calm, subtle ambient glow (cyan + electric blue)
/// that enhances glassmorphism without interfering with content or contrast.
class AtmosphericBackground extends StatelessWidget {
  final Widget child;
  final bool hasGlow;

  const AtmosphericBackground({
    super.key,
    required this.child,
    this.hasGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!hasGlow) {
      return Container(
        color: isDark ? AppColors.darkBase : AppColors.lightBackground,
        child: child,
      );
    }

    return Container(
      decoration: AppGlassTheme.getAtmosphericBackground(isDark: isDark),
      child: child,
    );
  }
}
