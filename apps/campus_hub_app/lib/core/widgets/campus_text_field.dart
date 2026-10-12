import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// iOS-inspired Glass Text Field for CampusHub.
/// Features a subtle translucent glass surface, thin border,
/// glowing electric-blue focus state, and accessible labels.
class CampusTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? helperText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool autofocus;
  final bool readOnly;
  final int maxLines;
  final FocusNode? focusNode;

  const CampusTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.focusNode,
  });

  @override
  State<CampusTextField> createState() => _CampusTextFieldState();
}

class _CampusTextFieldState extends State<CampusTextField> {
  late FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.removeListener(_handleFocusChange);
      _focusNode.dispose();
    }
    super.dispose();
  }

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
        Text(
          widget.label,
          style: AppTypography.captionMedium.copyWith(
            color: _hasFocus ? focusBorderColor : primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: AppRadius.br12,
            boxShadow: _hasFocus
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            inputFormatters: widget.inputFormatters,
            autofocus: widget.autofocus,
            readOnly: widget.readOnly,
            maxLines: widget.maxLines,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            validator: widget.validator,
            style: AppTypography.body.copyWith(color: primaryText),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTypography.body.copyWith(color: secondaryText.withValues(alpha: 0.8)),
              filled: true,
              fillColor: surfaceColor,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      size: 20,
                      color: _hasFocus ? focusBorderColor : secondaryText,
                    )
                  : null,
              suffixIcon: widget.suffixIcon,
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
                borderSide: BorderSide(color: focusBorderColor, width: 1.6),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: AppRadius.br12,
                borderSide: const BorderSide(color: AppColors.error, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: AppRadius.br12,
                borderSide: const BorderSide(color: AppColors.error, width: 1.6),
              ),
              helperText: widget.helperText,
              helperStyle: AppTypography.micro.copyWith(color: secondaryText),
            ),
          ),
        ),
      ],
    );
  }
}
