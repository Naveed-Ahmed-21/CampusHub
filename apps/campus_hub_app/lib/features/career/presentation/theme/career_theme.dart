import 'package:flutter/material.dart';

/// Centralized Design System for CampusHub Career Hub v2.0
/// Inspired by the Apple-grade dark glassmorphism reference specification.
abstract class CareerTheme {
  // Background & Surface Palettes
  static const Color background = Color(0xFF070B14); // Deep Obsidian Navy
  static const Color surface = Color(0xFF101827); // Dark Glass Surface
  static const Color surfaceSecondary = Color(0xFF162033); // Elevated Glass Surface
  static const Color surfaceElevated = Color(0xFF1E293B); // High-contrast Container
  static const Color surfaceMuted = Color(0xFF0F172A); // Slate 900

  // Primary & Accent Brand Colors
  static const Color primaryCyan = Color(0xFF38BDF8); // Electric Sky / Cyan
  static const Color primaryBlue = Color(0xFF0284C7); // Vibrant Blue
  static const Color accentIndigo = Color(0xFF6366F1); // Radiant Indigo
  static const Color accentPurple = Color(0xFF8B5CF6); // Soft Lavender
  static const Color accentLavender = Color(0xFFA855F7); // High-voltage Violet
  static const Color accentPink = Color(0xFFEC4899); // Deliverable Magenta

  // Semantic Status Colors
  static const Color success = Color(0xFF10B981); // Emerald Mint (Completed / Mastered)
  static const Color inProgress = Color(0xFF38BDF8); // Electric Cyan (Active / In Progress)
  static const Color warning = Color(0xFFF59E0B); // Radiant Amber
  static const Color error = Color(0xFFEF4444); // YouTube Red / Danger
  static const Color locked = Color(0xFF475569); // Muted Slate (Locked State)
  static const Color lockedText = Color(0xFF64748B); // Slate 500

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFCBD5E1); // Slate 300
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  static const Color textSubtle = Color(0xFF64748B); // Slate 500

  // Border & Glow Accents
  static const Color glassBorder = Color(0x1FFFFFFF); // 12% White Border
  static const Color glassBorderHover = Color(0x3338BDF8); // 20% Cyan Glow Border
  static const Color accentGlow = Color(0x336366F1); // Subtle Indigo Glow

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF38BDF8), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroOrbGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF101827), Color(0xFF162033)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF162033)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Radii
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusPill = 999.0;

  // Typography Styles
  static const TextStyle heroTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle screenTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle sectionHeader = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textMuted,
  );

  static const TextStyle label = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: textMuted,
    letterSpacing: 0.5,
  );
}
