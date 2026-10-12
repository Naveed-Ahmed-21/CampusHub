import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Unified Filter Chip for CampusHub.
/// Selected: Primary Blue subtle background
/// Unselected: Clean theme surface with subtle border
class CampusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? icon;
  final Widget? trailing;

  const CampusChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;

    final bg = isSelected
        ? (isDark ? const Color(0xFF2F3336) : const Color(0xFF0F1419))
        : (isDark ? const Color(0xFF16181C) : const Color(0xFFF7F9F9));
    final borderColor = isSelected
        ? (isDark ? const Color(0xFF536471) : const Color(0xFF0F1419))
        : (isDark ? const Color(0xFF2F3336) : const Color(0xFFEFF3F4));
    final textColor = isSelected
        ? Colors.white
        : secondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                IconTheme(
                  data: IconThemeData(size: 14, color: textColor),
                  child: icon!,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTypography.micro.copyWith(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
