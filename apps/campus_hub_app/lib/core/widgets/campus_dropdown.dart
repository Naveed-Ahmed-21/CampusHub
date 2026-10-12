import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Unified Dropdown Field for CampusHub.
/// Consistent with [CampusTextField] styling, supporting both light and dark themes.
class CampusDropdown<T> extends StatelessWidget {
  final String? label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final IconData? prefixIcon;
  final bool isExpanded;
  final bool enabled;

  const CampusDropdown({
    super.key,
    this.label,
    this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.prefixIcon,
    this.isExpanded = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkText : AppColors.primaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;
    final surfaceColor = isDark
        ? AppColors.darkElevatedSurface
        : AppColors.lightSecondarySurface;
    final baseBorderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final focusBorderColor = isDark ? Colors.white : AppColors.primaryText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.captionMedium.copyWith(
              color: primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.s6),
        ],
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          isExpanded: isExpanded,
          style: AppTypography.body.copyWith(color: primaryText),
          dropdownColor: isDark ? AppColors.darkElevatedSurface : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: secondaryText,
            size: 20,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.body.copyWith(color: secondaryText.withValues(alpha: 0.8)),
            filled: true,
            fillColor: surfaceColor,
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    size: 20,
                    color: isDark ? Colors.white : AppColors.primaryText,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s14,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadius.br12,
              borderSide: BorderSide(color: baseBorderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.br12,
              borderSide: BorderSide(color: baseBorderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.br12,
              borderSide: BorderSide(color: focusBorderColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppRadius.br12,
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppRadius.br12,
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
