import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_shadows.dart';

/// Semi-opaque glass panel designed for dense information, academic tables,
/// administrative lists, and form containers where high contrast and text clarity
/// are essential.
class CampusGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? header;
  final Widget? footer;

  const CampusGlassPanel({
    super.key,
    required this.child,
    this.padding = AppSpacing.p20,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.header,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = borderRadius ?? AppRadius.br12;

    final backgroundColor = isDark
        ? AppColors.darkElevatedSurface
        : Colors.white;

    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: r,
        border: Border.all(color: borderColor, width: 1),
        boxShadow: AppShadows.getGlassShadow(isDark: isDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s20,
                vertical: AppSpacing.s16,
              ),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                color: isDark ? AppColors.darkBackground : AppColors.lightSecondarySurface,
              ),
              child: header!,
            ),
          ],
          Padding(
            padding: padding,
            child: child,
          ),
          if (footer != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s20,
                vertical: AppSpacing.s12,
              ),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor, width: 1)),
                color: isDark ? AppColors.darkBackground : AppColors.lightSecondarySurface,
              ),
              child: footer!,
            ),
          ],
        ],
      ),
    );
  }
}
