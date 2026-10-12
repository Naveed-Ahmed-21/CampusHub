import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_radius.dart';
import 'app_spacing.dart';

class AppTheme {
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF0F1419), // Stark X Black
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFE7E7E8),
      onPrimaryContainer: Color(0xFF0F1419),
      secondary: Color(0xFF536471), // X Muted Gray
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFEFF3F4),
      onSecondaryContainer: Color(0xFF0F1419),
      tertiary: Color(0xFF0F1419),
      onTertiary: Color(0xFFFFFFFF),
      error: AppColors.error,
      onError: Color(0xFFFFFFFF),
      surface: AppColors.lightSurface, // 0xFFFFFFFF
      onSurface: AppColors.primaryText, // 0xFF0F1419
      onSurfaceVariant: AppColors.secondaryText, // 0xFF536471
      surfaceContainerHighest: AppColors.lightSecondarySurface, // 0xFFF7F9F9
      outline: AppColors.border, // 0xFFEFF3F4
      outlineVariant: Color(0xFFCFD9DE),
    );

    final textTheme = AppTypography.createTextTheme(isDark: false);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      textTheme: textTheme,
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
        titleTextStyle: AppTypography.cardTitle.copyWith(color: AppColors.primaryText),
      ),
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (BuildContext context) => const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: AppColors.primaryText,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.br12,
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSecondarySurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s16),
        border: OutlineInputBorder(
          borderRadius: AppRadius.br12,
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.br12,
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.br12,
          borderSide: BorderSide(color: Color(0xFF0F1419), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.br12,
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.br12,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: AppTypography.body.copyWith(color: AppColors.secondaryText),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.secondaryText),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.br16,
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.top20),
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFFFFFFF), // Crisp Pure White
      onPrimary: Color(0xFF000000), // Pure Black
      primaryContainer: Color(0xFF16181C), // Dark Charcoal
      onPrimaryContainer: Color(0xFFFFFFFF),
      secondary: Color(0xFF71767B), // X Muted Gray
      onSecondary: Color(0xFF000000),
      secondaryContainer: Color(0xFF202327),
      onSecondaryContainer: Color(0xFFFFFFFF),
      tertiary: Color(0xFFFFFFFF),
      onTertiary: Color(0xFF000000),
      error: AppColors.error,
      onError: Color(0xFF000000),
      surface: AppColors.darkSurface, // 0xFF000000 True Lights-Out Black
      onSurface: AppColors.darkText, // 0xFFFFFFFF
      onSurfaceVariant: AppColors.darkSecondaryText, // 0xFF71767B
      surfaceContainerHighest: AppColors.darkElevatedSurface, // 0xFF16181C
      outline: AppColors.darkBorder, // 0xFF2F3336
      outlineVariant: Color(0xFF2F3336),
    );

    final textTheme = AppTypography.createTextTheme(isDark: true);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground, // 0xFF000000 True Black
      textTheme: textTheme,
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.darkText),
        titleTextStyle: AppTypography.cardTitle.copyWith(color: AppColors.darkText),
      ),
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (BuildContext context) => const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: AppColors.darkText,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.br12,
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s16),
        border: OutlineInputBorder(
          borderRadius: AppRadius.br12,
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.br12,
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.br12,
          borderSide: BorderSide(color: Color(0xFFFFFFFF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.br12,
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.br12,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: AppTypography.body.copyWith(color: AppColors.darkSecondaryText),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkSecondaryText),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSecondary,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.br16,
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSecondary,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.top20),
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
