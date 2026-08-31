import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void toggleTheme(bool isDark) {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void setSystemTheme() {
    state = ThemeMode.system;
  }
}

final themeNotifierProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);
