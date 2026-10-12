import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

enum CampusButtonType {
  primary,
  secondary,
  outline,
  danger,
  ghost,
}

/// Premium CampusHub Button Component.
/// Follows iOS touch target standards (>= 44px height), rounded corners,
/// subtle glass-accent glow for primary actions, and clean accessible text.
class CampusButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final CampusButtonType type;
  final bool isLoading;
  final Widget? icon;
  final Widget? trailingIcon;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const CampusButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = CampusButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.width,
    this.height = 48.0,
    this.borderRadius,
  });

  const CampusButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.width,
    this.height = 48.0,
    this.borderRadius,
  }) : type = CampusButtonType.primary;

  const CampusButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.width,
    this.height = 48.0,
    this.borderRadius,
  }) : type = CampusButtonType.secondary;

  const CampusButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.width,
    this.height = 48.0,
    this.borderRadius,
  }) : type = CampusButtonType.outline;

  const CampusButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.width,
    this.height = 48.0,
    this.borderRadius,
  }) : type = CampusButtonType.danger;

  const CampusButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.width,
    this.height = 48.0,
    this.borderRadius,
  }) : type = CampusButtonType.ghost;

  @override
  State<CampusButton> createState() => _CampusButtonState();
}

class _CampusButtonState extends State<CampusButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = widget.borderRadius ?? BorderRadius.circular(16);
    final isDisabled = widget.onPressed == null || widget.isLoading;

    // Resolve Colors & Background
    BoxDecoration decoration;
    Color textColor;

    switch (widget.type) {
      case CampusButtonType.primary:
        textColor = isDark ? Colors.black : Colors.white;
        decoration = BoxDecoration(
          borderRadius: r,
          color: isDisabled
              ? (isDark ? const Color(0xFF333333) : const Color(0xFFCFD9DE))
              : (isDark ? Colors.white : const Color(0xFF0F1419)),
          boxShadow: null,
        );
        break;

      case CampusButtonType.secondary:
        textColor = isDark ? Colors.white : const Color(0xFF0F1419);
        decoration = BoxDecoration(
          borderRadius: r,
          color: isDark ? const Color(0xFF16181C) : const Color(0xFFF7F9F9),
          border: Border.all(
            color: isDark ? const Color(0xFF2F3336) : const Color(0xFFEFF3F4),
            width: 1.0,
          ),
        );
        break;

      case CampusButtonType.outline:
        textColor = isDark ? Colors.white : const Color(0xFF0F1419);
        decoration = BoxDecoration(
          borderRadius: r,
          color: Colors.transparent,
          border: Border.all(
            color: isDark ? const Color(0xFF2F3336) : const Color(0xFFCFD9DE),
            width: 1.0,
          ),
        );
        break;

      case CampusButtonType.danger:
        textColor = Colors.white;
        decoration = BoxDecoration(
          borderRadius: r,
          color: isDisabled ? const Color(0xFF71767B) : AppColors.error,
          boxShadow: null,
        );
        break;

      case CampusButtonType.ghost:
        textColor = isDark ? Colors.white : const Color(0xFF0F1419);
        decoration = BoxDecoration(
          borderRadius: r,
          color: Colors.transparent,
        );
        break;
    }

    Widget content = Row(
      mainAxisSize: widget.width == null ? MainAxisSize.min : MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
        ] else if (widget.icon != null) ...[
          widget.icon!,
          const SizedBox(width: AppSpacing.s8),
        ],
        Flexible(
          child: Text(
            widget.label,
            style: AppTypography.cardTitle.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: -0.2, // iOS button typography
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!widget.isLoading && widget.trailingIcon != null) ...[
          const SizedBox(width: AppSpacing.s8),
          widget.trailingIcon!,
        ],
      ],
    );

    return AnimatedScale(
      scale: (_pressed && !isDisabled) ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    widget.onPressed!();
                  },
            onHighlightChanged: (highlighted) {
              if (_pressed != highlighted) {
                setState(() => _pressed = highlighted);
              }
            },
            borderRadius: r,
            splashColor: textColor.withValues(alpha: 0.12),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
