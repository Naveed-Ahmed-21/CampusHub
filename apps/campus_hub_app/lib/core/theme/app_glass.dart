import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Glassmorphism Intensity Levels
enum GlassIntensity {
  subtle,
  medium,
  strong,
  hero,
}

/// Centralized Glass Theme & Properties for CampusHub
abstract class AppGlassTheme {
  // Blur Sigma Values (optimized for performance without losing iOS feel)
  static const double blurSubtle = 6.0;
  static const double blurMedium = 10.0;
  static const double blurStrong = 16.0;

  /// Maximum blur for hero/modal cards with enableBlur: true
  static const double blurHero = 24.0;

  /// Reserved for future full-screen bottom sheets
  static const double blurUltra = 32.0;

  static double getBlurSigma(GlassIntensity intensity) {
    switch (intensity) {
      case GlassIntensity.subtle:
        return blurSubtle;
      case GlassIntensity.medium:
        return blurMedium;
      case GlassIntensity.strong:
        return blurStrong;
      case GlassIntensity.hero:
        return blurHero;
    }
  }

  // Light Mode Glass Colors
  static Color getLightSurfaceColor(GlassIntensity intensity) {
    switch (intensity) {
      case GlassIntensity.subtle:
        return const Color(0xF7FFFFFF); // 97% pure white
      case GlassIntensity.medium:
        return const Color(0xF2FFFFFF); // 95% pure white
      case GlassIntensity.strong:
        return const Color(0xEBFFFFFF); // 92% pure white
      case GlassIntensity.hero:
        return const Color(0xE6FFFFFF); // 90% pure white
    }
  }

  // Dark Mode Glass Colors
  static Color getDarkSurfaceColor(GlassIntensity intensity) {
    switch (intensity) {
      case GlassIntensity.subtle:
        return const Color(0xF2000000); // 95% true black
      case GlassIntensity.medium:
        return const Color(0xE6121212); // ~90% dark charcoal
      case GlassIntensity.strong:
        return const Color(0xD916181C); // ~85% dark charcoal
      case GlassIntensity.hero:
        return const Color(0xCC000000); // ~80% black
    }
  }

  // Glass Border Colors
  static Color getBorderColor({required bool isDark, GlassIntensity intensity = GlassIntensity.medium}) {
    if (isDark) {
      return const Color(0xFF2F3336); // X-style dark hairline border
    } else {
      return const Color(0xFFEFF3F4); // X-style light hairline border
    }
  }

  // Gradient Border for top/left specular highlight
  static LinearGradient getHighlightBorderGradient({required bool isDark}) {
    if (isDark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x33FFFFFF), // 20% white highlight
          Color(0x1AFFFFFF), // 10% white
          Color(0x00000000),
        ],
        stops: [0.0, 0.5, 1.0],
      );
    } else {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFFF),
          Color(0x80FFFFFF),
          Color(0x40EFF3F4),
        ],
        stops: [0.0, 0.4, 1.0],
      );
    }
  }

  // Atmospheric Background (Monochromatic Pure Canvas)
  static BoxDecoration getAtmosphericBackground({required bool isDark}) {
    if (isDark) {
      return const BoxDecoration(
        color: AppColors.darkBackground,
      );
    } else {
      return const BoxDecoration(
        color: AppColors.lightBackground,
      );
    }
  }
}
