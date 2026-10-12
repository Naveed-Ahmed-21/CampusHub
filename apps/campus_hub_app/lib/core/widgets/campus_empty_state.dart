import 'package:flutter/material.dart';
import 'campus_glass_card.dart';
import 'campus_button.dart';
import '../theme/app_colors.dart';
import '../theme/app_glass.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Elegant Glass Empty State Component for CampusHub.
/// Adheres to Section 58 (No Fake Data) by providing a clean, informative
/// state when data lists or metrics are currently empty.
class CampusEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double iconSize;

  const CampusEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.iconSize = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkText : AppColors.primaryText;
    final secondary = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: CampusGlassCard(
          intensity: GlassIntensity.subtle,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24, vertical: AppSpacing.s32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: iconSize + 28,
                height: iconSize + 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.darkElevatedSurface : AppColors.lightSecondarySurface,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: isDark ? Colors.white : AppColors.primaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.s20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.cardTitle.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: secondary,
                    height: 1.45,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.s24),
                CampusButton.primary(
                  label: actionLabel!,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
