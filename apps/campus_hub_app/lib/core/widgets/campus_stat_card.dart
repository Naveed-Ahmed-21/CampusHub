import 'package:flutter/material.dart';
import 'campus_glass_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_glass.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Premium Glass KPI Metric Card for Student, Faculty, Placement, and Admin Dashboards.
class CampusStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? accentColor;
  final VoidCallback? onTap;

  const CampusStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkText : AppColors.primaryText;
    final secondary = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;
    final color = accentColor ?? (isDark ? Colors.white : AppColors.primaryText);

    return CampusGlassCard(
      intensity: GlassIntensity.medium,
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF16181C) : const Color(0xFFF7F9F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2F3336) : const Color(0xFFEFF3F4),
                    width: 1.0,
                  ),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.captionMedium.copyWith(
                    color: secondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            value,
            style: AppTypography.pageTitle.copyWith(
              color: primary,
              fontWeight: FontWeight.w700,
              fontSize: 26,
              letterSpacing: -0.8, // Apple large title tight tracking
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: AppTypography.micro.copyWith(
                color: secondary,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
