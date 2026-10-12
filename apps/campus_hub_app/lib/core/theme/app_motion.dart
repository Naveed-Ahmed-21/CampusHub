import 'package:flutter/material.dart';

/// Centralized Motion and Animation Constants for CampusHub
abstract class AppMotion {
  // Durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 300);

  // iOS-inspired Curves
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve spring = Curves.fastOutSlowIn;

  // Reduced motion check
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  // Get duration respecting reduced motion
  static Duration getDuration(BuildContext context, Duration standardDuration) {
    return shouldReduceMotion(context) ? Duration.zero : standardDuration;
  }
}
