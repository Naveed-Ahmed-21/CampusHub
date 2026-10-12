import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_glass.dart';
import '../theme/app_spacing.dart';

/// iOS-inspired Glass Bottom Sheet for CampusHub
class CampusBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const CampusBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.padding = AppSpacing.p20,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    Widget? trailing,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => CampusBottomSheet(
        title: title,
        trailing: trailing,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkElevatedSurface
        : Colors.white;
    final borderColor = isDark
        ? AppColors.darkBorder
        : AppColors.border;
    const sheetRadius = BorderRadius.vertical(top: Radius.circular(20));

    return Container(
      decoration: const BoxDecoration(
        borderRadius: sheetRadius,
      ),
      child: ClipRRect(
        borderRadius: sheetRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppGlassTheme.blurHero,
            sigmaY: AppGlassTheme.blurHero,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: sheetRadius,
              border: Border(top: BorderSide(color: borderColor, width: 1.0)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // iOS Grab Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.darkSecondaryText : AppColors.secondaryText)
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  if (title != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20, vertical: AppSpacing.s10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkText : AppColors.primaryText,
                              ),
                            ),
                          ),
                          if (trailing != null) trailing!,
                        ],
                      ),
                    ),
                    Divider(color: borderColor, height: 1),
                  ],
                  Padding(
                    padding: padding,
                    child: child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
