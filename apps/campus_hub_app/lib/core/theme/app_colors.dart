import 'package:flutter/material.dart';

/// Centralized CampusHub Color System.
/// Standardized for Government College of Engineering, Erode (GCEE).
abstract class AppColors {
  // Brand Core Colors (Pure Monochromatic X & Enterprise Grade)
  static const Color pureBlack = Color(0xFF000000);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  static const Color primaryNavy = pureBlack;
  static const Color primaryBlue = pureBlack; // Canonical monochrome primary
  static const Color accentCyan = pureWhite; // Canonical monochrome accent
  static const Color secondaryCyan = pureWhite; // Alias for backwards compatibility
  static const Color electricBlue = pureBlack;

  // Semantic Status Colors (Subtle, Restrained Enterprise-grade Semantics)
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF71767B);

  // Light Theme Surfaces & Text (Crisp stark white & charcoal black)
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSecondarySurface = Color(0xFFF7F9F9); // Light Gray surface (X light mode)
  static const Color border = Color(0xFFEFF3F4); // X-style light hairline divider
  static const Color primaryText = Color(0xFF0F1419); // X-style primary black
  static const Color secondaryText = Color(0xFF536471); // X-style muted gray
  static const Color lightGlassSurface = Color(0xF2FFFFFF); // 95% white frost
  static const Color lightGlassBorder = Color(0xFFEFF3F4);
  static const Color lightAppBarSurface = Color(0xF2FFFFFF);

  // Dark Theme Surfaces & Text (True "Lights Out" Pure Black & Crisp White)
  static const Color darkBackground = Color(0xFF000000); // True Lights-Out Black
  static const Color darkBase = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF000000); // True Black surface
  static const Color darkSecondary = Color(0xFF16181C); // Dark charcoal container
  static const Color darkElevatedSurface = Color(0xFF16181C); // Elevated card surface
  static const Color darkBorder = Color(0xFF2F3336); // X-style dark hairline divider
  static const Color darkText = Color(0xFFFFFFFF); // Crisp Pure White
  static const Color darkSecondaryText = Color(0xFF71767B); // X-style secondary gray
  static const Color darkGlassSurface = Color(0xF2000000); // 95% black frost
  static const Color darkGlassBorder = Color(0xFF2F3336);
  static const Color darkAppBarSurface = Color(0xE6000000);

  // Backward compatibility aliases
  static const Color primarySeed = black;
  static const Color lightPrimary = black;
  static const Color lightOnPrimary = white;
  static const Color lightOnSurface = primaryText;
  static const Color darkPrimary = white;
  static const Color darkOnPrimary = black;
  static const Color darkOnSurface = darkText;
}
