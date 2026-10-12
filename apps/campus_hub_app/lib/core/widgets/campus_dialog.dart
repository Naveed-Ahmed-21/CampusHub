import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_glass.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Notification-inspired Premium Glass Modal Dialog for CampusHub
class CampusDialog extends StatelessWidget {
  final Widget? icon;
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final double maxWidth;
  final String? badgeText;
  final Color? accentColor;

  const CampusDialog({
    super.key,
    this.icon,
    required this.title,
    required this.content,
    this.actions,
    this.maxWidth = 440.0,
    this.badgeText,
    this.accentColor,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    Widget? icon,
    required String title,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
    String? badgeText,
    Color? accentColor,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Dismiss Dialog',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 240),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.90, end: 1.0).animate(curved),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, _, __) {
        return CampusDialog(
          icon: icon,
          title: title,
          content: content,
          actions: actions,
          badgeText: badgeText,
          accentColor: accentColor,
        );
      },
    );
  }

  /// Convenience helper to show a notification-styled informational dialog
  static Future<void> showNotice(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'Understood',
    IconData icon = Icons.notifications_active_outlined,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : AppColors.primaryText;
    return show<void>(
      context: context,
      badgeText: 'NOTIFICATION',
      icon: Icon(icon, color: iconColor, size: 24),
      title: title,
      content: Text(message),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(buttonText),
        ),
      ],
    );
  }

  /// Convenience helper to show an error notification dialog
  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'Dismiss',
  }) {
    return show<void>(
      context: context,
      badgeText: 'ALERT',
      accentColor: AppColors.error,
      icon: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 24),
      title: title,
      content: Text(message),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(buttonText),
        ),
      ],
    );
  }

  /// Convenience helper to show an action confirmation dialog
  static Future<bool> showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
    IconData icon = Icons.help_outline_rounded,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.white : AppColors.primaryText;
    final result = await show<bool>(
      context: context,
      badgeText: isDestructive ? 'ACTION REQUIRED' : 'CONFIRMATION',
      accentColor: isDestructive ? AppColors.error : primaryColor,
      icon: Icon(
        icon,
        color: isDestructive ? AppColors.error : primaryColor,
        size: 24,
      ),
      title: title,
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          style: isDestructive
              ? ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmText),
        ),
      ],
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkText : AppColors.primaryText;
    final effectiveAccent = accentColor ?? (isDark ? Colors.white : AppColors.primaryText);

    final surfaceColor = isDark
        ? AppColors.darkElevatedSurface
        : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s20, vertical: AppSpacing.s28),
          decoration: BoxDecoration(
            borderRadius: AppRadius.br16,
            boxShadow: AppShadows.getGlassShadow(isDark: isDark, isElevated: true),
          ),
          child: ClipRRect(
            borderRadius: AppRadius.br16,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: AppGlassTheme.blurStrong,
                sigmaY: AppGlassTheme.blurStrong,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: AppRadius.br16,
                  border: Border.all(color: borderColor, width: 1.4),
                ),
                padding: const EdgeInsets.all(22),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Badge + Icon
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (icon != null) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: effectiveAccent.withValues(alpha: isDark ? 0.2 : 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: effectiveAccent.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: icon,
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: effectiveAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    badgeText ?? 'CAMPUSHUB NOTIFICATION',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: effectiveAccent,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  title,
                                  style: AppTypography.cardTitle.copyWith(
                                    color: primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      DefaultTextStyle(
                        style: AppTypography.body.copyWith(
                          color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                          height: 1.4,
                        ),
                        child: content,
                      ),
                      if (actions != null && actions!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: actions!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
