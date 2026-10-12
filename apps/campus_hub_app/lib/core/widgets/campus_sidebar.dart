import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_glass.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../branding/gcee_logo.dart';
import '../branding/gcee_brand.dart';

class SidebarItem {
  final String label;
  final Widget icon;
  final Widget selectedIcon;
  final VoidCallback onTap;
  final bool isSelected;
  final int? badgeCount;

  const SidebarItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.onTap,
    required this.isSelected,
    this.badgeCount,
  });
}

/// Floating Glass Sidebar for Desktop / Large Screen CampusHub.
class CampusSidebar extends StatelessWidget {
  final List<SidebarItem> items;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;
  final Widget? footer;
  final String? roleLabel;

  const CampusSidebar({
    super.key,
    required this.items,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.footer,
    this.roleLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkText : AppColors.primaryText;
    final secondary = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;

    final surfaceColor = isDark
        ? const Color(0xE6000000) // 90% true black surface
        : const Color(0xF2FFFFFF); // 95% white surface
    final borderColor = isDark ? const Color(0xFF2F3336) : const Color(0xFFEFF3F4);

    final width = isCollapsed ? 80.0 : 260.0;

    return Container(
      width: width,
      margin: const EdgeInsets.fromLTRB(16, 16, 0, 16),
      decoration: BoxDecoration(
        borderRadius: AppRadius.br24,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.05),
            blurRadius: 18,
            offset: const Offset(2, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.br24,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppGlassTheme.blurMedium,
            sigmaY: AppGlassTheme.blurMedium,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: AppRadius.br24,
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: Branding
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCollapsed ? 12 : 20,
                    vertical: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                    children: [
                      GceeLogo(
                        size: 38,
                        tooltip: isCollapsed ? GceeBrand.institutionName : null,
                      ),
                      if (!isCollapsed) ...[
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'CampusHub',
                                    style: AppTypography.cardTitle.copyWith(
                                      color: primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF16181C) : const Color(0xFFEFF3F4),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'GCEE',
                                      style: AppTypography.micro.copyWith(
                                        color: isDark ? Colors.white : AppColors.primaryText,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                roleLabel ?? 'GCE Erode Portal',
                                style: AppTypography.micro.copyWith(
                                  color: secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Divider(color: borderColor, height: 1),

                // Navigation Items List
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCollapsed ? 10 : 14,
                      vertical: 16,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildNavItem(context, item, isDark, primary, secondary);
                    },
                  ),
                ),

                // Footer / Collapse Button
                Divider(color: borderColor, height: 1),
                Padding(
                  padding: EdgeInsets.all(isCollapsed ? 8 : 12),
                  child: Row(
                    mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                    children: [
                      if (footer != null && !isCollapsed) Expanded(child: footer!),
                      if (onToggleCollapse != null)
                        IconButton(
                          icon: Icon(
                            isCollapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                            color: secondary,
                          ),
                          onPressed: onToggleCollapse,
                          tooltip: isCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    SidebarItem item,
    bool isDark,
    Color primary,
    Color secondary,
  ) {
    final activeBg = isDark
        ? const Color(0xFF16181C)
        : const Color(0xFFEFF3F4);
    final activeBorder = isDark
        ? const Color(0xFF2F3336)
        : const Color(0xFFCFD9DE);
    final activeText = isDark ? Colors.white : AppColors.primaryText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: activeText.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: isCollapsed ? 12 : 14,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: item.isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item.isSelected ? activeBorder : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              IconTheme(
                data: IconThemeData(
                  color: item.isSelected ? activeText : secondary,
                  size: 20,
                ),
                child: item.isSelected ? item.selectedIcon : item.icon,
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Text(
                    item.label,
                    style: AppTypography.bodyMedium.copyWith(
                      color: item.isSelected ? activeText : primary,
                      fontWeight: item.isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.badgeCount != null && item.badgeCount! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : AppColors.primaryText,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${item.badgeCount}',
                      style: TextStyle(
                        color: isDark ? Colors.black : Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
