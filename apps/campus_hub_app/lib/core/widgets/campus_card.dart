import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Unified Standard Surface Card for CampusHub.
/// Provides a clean, lightweight surface with consistent borders,
/// radius, padding, and subtle elevation across all 5 roles.
class CampusCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool isElevated;

  const CampusCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.p16,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
    this.isElevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = borderRadius ?? AppRadius.br12;
    final surface = backgroundColor ??
        (isDark
            ? (isElevated ? AppColors.darkElevatedSurface : AppColors.darkSurface)
            : AppColors.lightSurface);
    final border = borderColor ?? (isDark ? AppColors.darkBorder : AppColors.border);

    Widget cardContent = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: r,
        border: Border.all(color: border, width: 1),
        boxShadow: isElevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: r,
          child: cardContent,
        ),
      );
    }

    if (margin != null) {
      return Padding(
        padding: margin!,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
