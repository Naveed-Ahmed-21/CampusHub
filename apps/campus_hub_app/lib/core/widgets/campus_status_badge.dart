import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

enum StatusBadgeType {
  info,
  success,
  warning,
  danger,
  neutral,
}

/// Translucent Status Badge with subtle glass tinting for
/// session states, assignment submissions, verification badges, and role pills.
class CampusStatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeType type;
  final IconData? icon;
  final bool showDot;

  const CampusStatusBadge({
    super.key,
    required this.label,
    this.type = StatusBadgeType.info,
    this.icon,
    this.showDot = false,
  });

  const CampusStatusBadge.success({
    super.key,
    required this.label,
    this.icon,
    this.showDot = false,
  }) : type = StatusBadgeType.success;

  const CampusStatusBadge.warning({
    super.key,
    required this.label,
    this.icon,
    this.showDot = false,
  }) : type = StatusBadgeType.warning;

  const CampusStatusBadge.danger({
    super.key,
    required this.label,
    this.icon,
    this.showDot = false,
  }) : type = StatusBadgeType.danger;

  const CampusStatusBadge.info({
    super.key,
    required this.label,
    this.icon,
    this.showDot = false,
  }) : type = StatusBadgeType.info;

  const CampusStatusBadge.neutral({
    super.key,
    required this.label,
    this.icon,
    this.showDot = false,
  }) : type = StatusBadgeType.neutral;

  Color _getColor(bool isDark) {
    switch (type) {
      case StatusBadgeType.info:
        return isDark ? Colors.white : AppColors.primaryText;
      case StatusBadgeType.success:
        return isDark ? const Color(0xFF4ADE80) : AppColors.success;
      case StatusBadgeType.warning:
        return isDark ? const Color(0xFFFBBF24) : AppColors.warning;
      case StatusBadgeType.danger:
        return isDark ? const Color(0xFFF87171) : AppColors.error;
      case StatusBadgeType.neutral:
        return isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getColor(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: AppRadius.br20,
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.s6),
          ] else if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.micro.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
