import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import 'gcee_brand.dart';

enum GceeLogoSize {
  compact(28.0),
  header(36.0),
  sidebar(44.0),
  profile(56.0),
  login(88.0),
  splash(132.0);

  final double dimension;
  const GceeLogoSize(this.dimension);
}

/// Official GCEE Logo Component
/// Displays the authentic, transparent Government College of Engineering, Erode emblem
/// with aspect ratio preservation and zero alteration or distortion.
class GceeLogo extends StatelessWidget {
  final double? size;
  final GceeLogoSize? presetSize;
  final bool showSurface;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color? color;

  const GceeLogo({
    super.key,
    this.size,
    this.presetSize,
    this.showSurface = false,
    this.onTap,
    this.tooltip,
    this.color,
  });

  const GceeLogo.header({
    super.key,
    this.showSurface = false,
    this.onTap,
    this.tooltip,
    this.color,
  })  : size = null,
        presetSize = GceeLogoSize.header;

  const GceeLogo.sidebar({
    super.key,
    this.showSurface = false,
    this.onTap,
    this.tooltip,
    this.color,
  })  : size = null,
        presetSize = GceeLogoSize.sidebar;

  const GceeLogo.login({
    super.key,
    this.showSurface = false,
    this.onTap,
    this.tooltip,
    this.color,
  })  : size = null,
        presetSize = GceeLogoSize.login;

  const GceeLogo.splash({
    super.key,
    this.showSurface = false,
    this.onTap,
    this.tooltip,
    this.color,
  })  : size = null,
        presetSize = GceeLogoSize.splash;

  const GceeLogo.profile({
    super.key,
    this.showSurface = false,
    this.onTap,
    this.tooltip,
    this.color,
  })  : size = null,
        presetSize = GceeLogoSize.profile;

  const GceeLogo.compact({
    super.key,
    this.showSurface = false,
    this.onTap,
    this.tooltip,
    this.color,
  })  : size = null,
        presetSize = GceeLogoSize.compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dim = size ?? presetSize?.dimension ?? GceeLogoSize.header.dimension;
    final logoColor = color ?? (isDark ? null : Colors.black);
    final blendMode = logoColor != null ? BlendMode.srcIn : null;

    Widget imageWidget = Image.asset(
      GceeBrand.logoAsset,
      width: dim,
      height: dim,
      fit: BoxFit.contain,
      color: logoColor,
      colorBlendMode: blendMode,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          GceeBrand.logoFallbackAsset,
          width: dim,
          height: dim,
          fit: BoxFit.contain,
          color: logoColor,
          colorBlendMode: blendMode,
          errorBuilder: (_, __, ___) => Icon(
            Icons.school_rounded,
            size: dim * 0.7,
            color: isDark ? Colors.white : Colors.black,
          ),
        );
      },
    );

    Widget result;
    if (showSurface) {
      result = Container(
        width: dim + 14,
        height: dim + 14,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkElevatedSurface : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(child: imageWidget),
      );
    } else {
      result = imageWidget;
    }

    result = Semantics(
      label: GceeBrand.logoSemanticsLabel,
      image: true,
      child: result,
    );

    if (tooltip != null) {
      result = Tooltip(
        message: tooltip!,
        child: result,
      );
    }

    if (onTap != null) {
      result = InkWell(
        onTap: onTap,
        borderRadius: AppRadius.br8,
        child: result,
      );
    }

    return result;
  }
}
