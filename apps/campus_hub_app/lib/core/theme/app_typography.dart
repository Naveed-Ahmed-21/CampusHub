import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized Typography System for CampusHub
abstract class AppTypography {
  static const TextStyle display = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0, // iOS tight headline (fontSize >= 28)
    height: 1.2,
  );

  static const TextStyle pageTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0, // iOS tight headline (fontSize >= 28)
    height: 1.25,
  );

  static const TextStyle section = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5, // iOS tight headline (fontSize >= 20)
    height: 1.3,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.35,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.45,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.45,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static const TextStyle captionMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static const TextStyle micro = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1.3,
  );

  static TextTheme createTextTheme({required bool isDark}) {
    final primary = isDark ? AppColors.darkText : AppColors.primaryText;
    final secondary = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;

    return TextTheme(
      displayLarge: display.copyWith(color: primary),
      headlineLarge: pageTitle.copyWith(color: primary),
      headlineMedium: section.copyWith(color: primary),
      titleLarge: section.copyWith(color: primary),
      titleMedium: cardTitle.copyWith(color: primary),
      titleSmall: cardTitle.copyWith(fontSize: 15, color: primary),
      bodyLarge: body.copyWith(fontSize: 16, color: primary),
      bodyMedium: body.copyWith(color: primary),
      bodySmall: caption.copyWith(color: secondary),
      labelLarge: bodyMedium.copyWith(fontSize: 14, color: primary),
      labelMedium: captionMedium.copyWith(color: secondary),
      labelSmall: micro.copyWith(color: secondary),
    );
  }
}
