import 'package:flutter/material.dart';

/// Centralized Corner Radius Tokens for CampusHub
abstract class AppRadius {
  static const double r8 = 8.0;
  static const double r12 = 12.0;
  static const double r14 = 14.0;
  static const double r16 = 16.0;
  static const double r20 = 20.0;
  static const double r24 = 24.0;
  static const double r28 = 28.0;

  static const Radius radius8 = Radius.circular(r8);
  static const Radius radius12 = Radius.circular(r12);
  static const Radius radius14 = Radius.circular(r14);
  static const Radius radius16 = Radius.circular(r16);
  static const Radius radius20 = Radius.circular(r20);
  static const Radius radius24 = Radius.circular(r24);
  static const Radius radius28 = Radius.circular(r28);

  static const BorderRadius br8 = BorderRadius.all(radius8);
  static const BorderRadius br12 = BorderRadius.all(radius12);
  static const BorderRadius br14 = BorderRadius.all(radius14);
  static const BorderRadius br16 = BorderRadius.all(radius16);
  static const BorderRadius br20 = BorderRadius.all(radius20);
  static const BorderRadius br24 = BorderRadius.all(radius24);
  static const BorderRadius br28 = BorderRadius.all(radius28);

  // Top rounded for bottom sheets & cards
  static const BorderRadius top16 = BorderRadius.vertical(top: radius16);
  static const BorderRadius top20 = BorderRadius.vertical(top: radius20);
  static const BorderRadius top24 = BorderRadius.vertical(top: radius24);
}
