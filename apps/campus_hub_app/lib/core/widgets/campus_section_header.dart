import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Unified Section Header widget for CampusHub.
/// Standardizes section titles and optional actions across dashboards and lists.
class CampusSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onActionTap;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const CampusSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onActionTap,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkText : AppColors.primaryNavy;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.cardTitle.copyWith(
                    color: primaryText,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTypography.caption.copyWith(
                      color: secondaryText,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (actionText != null && onActionTap != null)
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onActionTap!();
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionText!,
                      style: AppTypography.captionMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: isDark ? Colors.white : AppColors.primaryText,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
