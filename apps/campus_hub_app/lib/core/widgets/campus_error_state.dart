import 'package:flutter/material.dart';
import 'campus_glass_card.dart';
import 'campus_button.dart';
import '../theme/app_colors.dart';
import '../theme/app_glass.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Clean Glass Error State Component for CampusHub
class CampusErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  const CampusErrorState({
    super.key,
    this.title = 'Unable to Load Information',
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try Again',
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
          variant: GlassCardVariant.danger,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24, vertical: AppSpacing.s28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withValues(alpha: isDark ? 0.2 : 0.1),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
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
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: secondary,
                    height: 1.4,
                  ),
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.s20),
                CampusButton.secondary(
                  label: retryLabel,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  onPressed: onRetry,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
