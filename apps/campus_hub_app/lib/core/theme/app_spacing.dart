import 'package:flutter/material.dart';

/// Centralized Spacing Tokens for CampusHub
abstract class AppSpacing {
  static const double s4 = 4.0;
  static const double s6 = 6.0;
  static const double s8 = 8.0;
  static const double s10 = 10.0;
  static const double s12 = 12.0;
  static const double s14 = 14.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s28 = 28.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s48 = 48.0;

  // Insets helpers
  static const EdgeInsets p4 = EdgeInsets.all(s4);
  static const EdgeInsets p8 = EdgeInsets.all(s8);
  static const EdgeInsets p12 = EdgeInsets.all(s12);
  static const EdgeInsets p16 = EdgeInsets.all(s16);
  static const EdgeInsets p20 = EdgeInsets.all(s20);
  static const EdgeInsets p24 = EdgeInsets.all(s24);
  static const EdgeInsets p32 = EdgeInsets.all(s32);

  // Horizontal helpers
  static const EdgeInsets h8 = EdgeInsets.symmetric(horizontal: s8);
  static const EdgeInsets h16 = EdgeInsets.symmetric(horizontal: s16);
  static const EdgeInsets h20 = EdgeInsets.symmetric(horizontal: s20);
  static const EdgeInsets h24 = EdgeInsets.symmetric(horizontal: s24);

  // Vertical helpers
  static const EdgeInsets v8 = EdgeInsets.symmetric(vertical: s8);
  static const EdgeInsets v12 = EdgeInsets.symmetric(vertical: s12);
  static const EdgeInsets v16 = EdgeInsets.symmetric(vertical: s16);
  static const EdgeInsets v24 = EdgeInsets.symmetric(vertical: s24);

  // Gaps (SizedBox)
  static const SizedBox gap4 = SizedBox(width: s4, height: s4);
  static const SizedBox gap8 = SizedBox(width: s8, height: s8);
  static const SizedBox gap12 = SizedBox(width: s12, height: s12);
  static const SizedBox gap16 = SizedBox(width: s16, height: s16);
  static const SizedBox gap20 = SizedBox(width: s20, height: s20);
  static const SizedBox gap24 = SizedBox(width: s24, height: s24);
  static const SizedBox gap32 = SizedBox(width: s32, height: s32);
  static const SizedBox gap40 = SizedBox(width: s40, height: s40);
  static const SizedBox gap48 = SizedBox(width: s48, height: s48);
}
