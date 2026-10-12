import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_glass.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_shadows.dart';

enum GlassCardVariant {
  standard,
  primary,
  success,
  warning,
  danger,
}

/// Premium Glass Card for CampusHub.
/// Implements Layer 2 (Glass Surface) with subtle blur, white/cyan edge highlight,
/// and semantic accent tinting when requested.
class CampusGlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final GlassIntensity intensity;
  final GlassCardVariant variant;
  final VoidCallback? onTap;
  final bool enableBlur;
  final Color? customBackgroundColor;
  final Border? customBorder;

  const CampusGlassCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.p16,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.intensity = GlassIntensity.medium,
    this.variant = GlassCardVariant.standard,
    this.onTap,
    this.enableBlur = false,
    this.customBackgroundColor,
    this.customBorder,
  });

  const CampusGlassCard.primary({
    super.key,
    required this.child,
    this.padding = AppSpacing.p16,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.intensity = GlassIntensity.medium,
    this.onTap,
    this.enableBlur = false,
    this.customBackgroundColor,
    this.customBorder,
  }) : variant = GlassCardVariant.primary;

  const CampusGlassCard.success({
    super.key,
    required this.child,
    this.padding = AppSpacing.p16,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.intensity = GlassIntensity.medium,
    this.onTap,
    this.enableBlur = false,
    this.customBackgroundColor,
    this.customBorder,
  }) : variant = GlassCardVariant.success;

  const CampusGlassCard.warning({
    super.key,
    required this.child,
    this.padding = AppSpacing.p16,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.intensity = GlassIntensity.medium,
    this.onTap,
    this.enableBlur = false,
    this.customBackgroundColor,
    this.customBorder,
  }) : variant = GlassCardVariant.warning;

  const CampusGlassCard.danger({
    super.key,
    required this.child,
    this.padding = AppSpacing.p16,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.intensity = GlassIntensity.medium,
    this.onTap,
    this.enableBlur = false,
    this.customBackgroundColor,
    this.customBorder,
  }) : variant = GlassCardVariant.danger;

  @override
  State<CampusGlassCard> createState() => _CampusGlassCardState();
}

class _CampusGlassCardState extends State<CampusGlassCard> {
  bool _pressed = false;

  Color _getVariantAccentColor(bool isDark) {
    switch (widget.variant) {
      case GlassCardVariant.standard:
        return Colors.transparent;
      case GlassCardVariant.primary:
        return isDark ? Colors.white : AppColors.primaryText;
      case GlassCardVariant.success:
        return AppColors.success;
      case GlassCardVariant.warning:
        return AppColors.warning;
      case GlassCardVariant.danger:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = widget.borderRadius ?? AppRadius.br16;
    final sigma = widget.enableBlur ? AppGlassTheme.getBlurSigma(widget.intensity) : 0.0;

    final baseSurfaceColor = widget.customBackgroundColor ??
        (isDark
            ? AppGlassTheme.getDarkSurfaceColor(widget.intensity)
            : AppGlassTheme.getLightSurfaceColor(widget.intensity));

    final accent = _getVariantAccentColor(isDark);
    final surfaceColor = widget.variant == GlassCardVariant.standard
        ? baseSurfaceColor
        : Color.alphaBlend(accent.withValues(alpha: isDark ? 0.12 : 0.06), baseSurfaceColor);

    final borderColor = widget.customBorder != null
        ? null
        : (widget.variant == GlassCardVariant.standard
            ? AppGlassTheme.getBorderColor(isDark: isDark, intensity: widget.intensity)
            : accent.withValues(alpha: isDark ? 0.35 : 0.25));

    final border = widget.customBorder ?? Border.all(color: borderColor!, width: 1);

    Widget cardBody = Container(
      width: widget.width,
      height: widget.height,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: r,
        border: border,
      ),
      child: widget.child,
    );

    if (widget.enableBlur && sigma > 0) {
      cardBody = ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: cardBody,
        ),
      );
    } else {
      cardBody = ClipRRect(
        borderRadius: r,
        child: cardBody,
      );
    }

    final cardWithShadow = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: AppShadows.getGlassShadow(isDark: isDark, isElevated: widget.intensity == GlassIntensity.strong),
      ),
      child: cardBody,
    );

    if (widget.onTap != null) {
      return AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onTap!();
            },
            onHighlightChanged: (highlighted) {
              if (_pressed != highlighted) {
                setState(() => _pressed = highlighted);
              }
            },
            borderRadius: r,
            splashColor: accent == Colors.transparent
                ? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05))
                : accent.withValues(alpha: 0.10),
            highlightColor: Colors.transparent,
            child: cardWithShadow,
          ),
        ),
      );
    }

    return cardWithShadow;
  }
}
