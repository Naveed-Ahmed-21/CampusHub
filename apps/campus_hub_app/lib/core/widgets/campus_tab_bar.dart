import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Unified CampusTabBar for CampusHub.
/// Selected: Primary Blue
/// Unselected: Secondary text
/// Indicator: Primary Blue
/// Zero multicolor tabs.
class CampusTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController? controller;
  final List<Widget> tabs;
  final bool isScrollable;
  final ValueChanged<int>? onTap;
  final bool isPill;

  const CampusTabBar({
    super.key,
    this.controller,
    required this.tabs,
    this.isScrollable = false,
    this.onTap,
    this.isPill = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(44.0);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? Colors.white : AppColors.primaryText;
    final secondary = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;
    final pillSurface = isDark ? AppColors.darkSecondary : AppColors.lightSecondarySurface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    if (isPill) {
      return Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: pillSurface,
          borderRadius: AppRadius.br12,
          border: Border.all(color: border, width: 1),
        ),
        child: TabBar(
          controller: controller,
          tabs: tabs,
          isScrollable: isScrollable,
          onTap: onTap,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: isDark ? const Color(0xFF2F3336) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF536471) : const Color(0xFFEFF3F4),
              width: 1,
            ),
          ),
          labelColor: activeColor,
          unselectedLabelColor: secondary,
          labelStyle: AppTypography.cardTitle.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
          tabAlignment: isScrollable ? TabAlignment.start : TabAlignment.fill,
        ),
      );
    }

    return TabBar(
      controller: controller,
      tabs: tabs,
      isScrollable: isScrollable,
      onTap: onTap,
      dividerColor: border,
      indicatorColor: activeColor,
      indicatorWeight: 2.5,
      labelColor: activeColor,
      unselectedLabelColor: secondary,
      labelStyle: AppTypography.cardTitle.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
      unselectedLabelStyle: AppTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
      tabAlignment: isScrollable ? TabAlignment.start : TabAlignment.fill,
    );
  }
}
