import 'dart:ui';
import 'package:flutter/material.dart';
import 'campus_back_button.dart';
import '../theme/app_colors.dart';
import '../theme/app_glass.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Floating Glass App Bar for CampusHub.
/// Renders an authentic Apple iOS translucent, blurred navigation bar
/// with clean typography, hairline border, and contextual actions.
class CampusAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final double height;
  final bool isFloating;
  final bool centerTitle;

  const CampusAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.height = 56.0,
    this.isFloating = false,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(height + (isFloating ? 12.0 : 0.0));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkText : AppColors.primaryText;
    final secondary = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;

    final surfaceColor = isDark
        ? const Color(0xE6000000) // 90% lights-out black
        : const Color(0xF2FFFFFF); // 95% pure white frost
    final borderColor = isDark
        ? const Color(0xFF2F3336) // X-style dark hairline border
        : const Color(0xFFEFF3F4); // X-style light hairline border

    Widget barContent = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: isFloating ? BorderRadius.circular(20) : null,
        border: isFloating
            ? Border.all(color: borderColor, width: 0.8)
            : Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.s12),
          ] else if (automaticallyImplyLeading && CampusBackButton.canPop(context)) ...[
            CampusBackButton(color: primary),
            const SizedBox(width: AppSpacing.s8),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.cardTitle.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    letterSpacing: -0.4, // iOS title tracking
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
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
          ),
          if (actions != null) ...[
            const SizedBox(width: AppSpacing.s8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!,
            ),
          ],
        ],
      ),
    );

    barContent = ClipRRect(
      borderRadius: isFloating ? BorderRadius.circular(20) : BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppGlassTheme.blurHero,
          sigmaY: AppGlassTheme.blurHero,
        ),
        child: barContent,
      ),
    );

    if (isFloating) {
      return SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: barContent,
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: barContent,
    );
  }
}
