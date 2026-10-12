import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Standardized Search Field for CampusHub.
/// Consistent across Students, Faculty, Companies, Placement Drives, Resources, and Feed.
class CampusSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilterTap;
  final VoidCallback? onClear;
  final bool hasActiveFilter;
  final bool autofocus;

  const CampusSearchField({
    super.key,
    this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onFilterTap,
    this.onClear,
    this.hasActiveFilter = false,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? const Color(0xFF16181C) // X dark search surface
        : const Color(0xFFEFF3F4); // X light search surface
    final border = isDark
        ? const Color(0xFF2F3336) // X dark border
        : const Color(0xFFEFF3F4); // X light border
    final primary = isDark ? AppColors.darkText : AppColors.primaryText;
    final secondary = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;
    final activeColor = isDark ? Colors.white : AppColors.primaryText;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search, size: 20, color: secondary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              style: AppTypography.body.copyWith(color: primary, fontSize: 14),
              cursorColor: activeColor,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTypography.body.copyWith(color: secondary, fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (controller != null && controller!.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close, size: 16, color: secondary),
              splashRadius: 16,
              onPressed: () {
                controller!.clear();
                if (onClear != null) onClear!();
                if (onChanged != null) onChanged!('');
              },
            ),
          if (onFilterTap != null) ...[
            Container(
              height: 24,
              width: 1,
              color: border,
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),
            IconButton(
              icon: Icon(
                Icons.tune,
                size: 18,
                color: hasActiveFilter ? activeColor : secondary,
              ),
              splashRadius: 18,
              tooltip: 'Filter',
              onPressed: onFilterTap,
            ),
          ],
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
