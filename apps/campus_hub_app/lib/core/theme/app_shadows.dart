import 'package:flutter/material.dart';

/// Centralized Shadow Tokens for CampusHub
abstract class AppShadows {
  // Soft diffuse shadows for light mode surfaces
  static const List<BoxShadow> lightSubtle = [
    BoxShadow(
      color: Color(0x08000000), // ~3% black
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> lightMedium = [
    BoxShadow(
      color: Color(0x0F000000), // ~6% black
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> lightStrong = [
    BoxShadow(
      color: Color(0x14000000), // ~8% black
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];

  // Dark mode soft deep shadows
  static const List<BoxShadow> darkSubtle = [
    BoxShadow(
      color: Color(0x66000000), // 40% black
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> darkMedium = [
    BoxShadow(
      color: Color(0x80000000), // 50% black
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> darkStrong = [
    BoxShadow(
      color: Color(0x99000000), // 60% black
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  // Button glow shadows (restrained, monochrome)
  static List<BoxShadow> primaryButtonGlow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // Subtle neutral glow
  static List<BoxShadow> cyanGlow = [
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> getGlassShadow({required bool isDark, bool isElevated = false}) {
    if (isDark) {
      return isElevated ? darkStrong : darkMedium;
    } else {
      return isElevated ? lightStrong : lightMedium;
    }
  }
}
