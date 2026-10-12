import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_glass.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

class CampusBottomNavItem {
  final Widget icon;
  final Widget selectedIcon;
  final String label;

  const CampusBottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// iOS-inspired Floating Glass Bottom Navigation for CampusHub.
class CampusBottomNav extends StatelessWidget {
  static const double barHeight = 64.0;
  static const double bottomMargin = 12.0;
  static const double contentSpacing = 16.0;

  /// Returns the total vertical clearance needed for scrollable views to scroll completely above the bottom navigation bar.
  static double getBottomClearance(BuildContext context) {
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      return 0.0;
    }
    final deviceBottom = MediaQuery.paddingOf(context).bottom;
    return barHeight + bottomMargin + deviceBottom + contentSpacing;
  }

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<CampusBottomNavItem> items;

  const CampusBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;
    final activeColor = isDark ? Colors.white : AppColors.primaryText;

    final surfaceColor = isDark
        ? const Color(0xE6000000) // 90% lights-out pure black
        : const Color(0xF2FFFFFF); // 95% crisp white frost
    final borderColor = isDark
        ? const Color(0xFF2F3336) // X dark hairline border
        : const Color(0xFFEFF3F4); // X light hairline border

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            borderRadius: AppRadius.br28,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppRadius.br28,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: AppGlassTheme.blurHero,
                sigmaY: AppGlassTheme.blurHero,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: AppRadius.br28,
                  border: Border.all(color: borderColor, width: 1.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final isSelected = index == selectedIndex;

                    return Expanded(
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onItemSelected(index);
                        },
                        borderRadius: BorderRadius.circular(20),
                        splashColor: activeColor.withValues(alpha: 0.08),
                        highlightColor: Colors.transparent,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? const Color(0xFF16181C) : const Color(0xFFEFF3F4))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedScale(
                                scale: isSelected ? 1.08 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutBack,
                                child: IconTheme(
                                  data: IconThemeData(
                                    color: isSelected ? activeColor : secondary,
                                    size: 22,
                                  ),
                                  child: isSelected ? item.selectedIcon : item.icon,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.label,
                                style: AppTypography.micro.copyWith(
                                  color: isSelected ? activeColor : secondary,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 11,
                                  letterSpacing: -0.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Spacer widget that reserves sufficient height for the floating bottom navigation bar
class CampusBottomNavSpacer extends StatelessWidget {
  final double extra;
  const CampusBottomNavSpacer({super.key, this.extra = 0.0});

  @override
  Widget build(BuildContext context) {
    final clearance = CampusBottomNav.getBottomClearance(context) + extra;
    return SizedBox(height: clearance);
  }
}

/// Sliver spacer widget for CustomScrollView / NestedScrollView
class SliverCampusBottomNavSpacer extends StatelessWidget {
  final double extra;
  const SliverCampusBottomNavSpacer({super.key, this.extra = 0.0});

  @override
  Widget build(BuildContext context) {
    final clearance = CampusBottomNav.getBottomClearance(context) + extra;
    return SliverToBoxAdapter(
      child: SizedBox(height: clearance),
    );
  }
}

/// InheritedWidget that propagates bottom navigation clearance to descendant screens
class CampusBottomNavClearance extends InheritedWidget {
  final double bottomClearance;
  final bool hasBottomNav;

  const CampusBottomNavClearance({
    super.key,
    required this.bottomClearance,
    required this.hasBottomNav,
    required super.child,
  });

  static double of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<CampusBottomNavClearance>();
    return result?.bottomClearance ?? 0.0;
  }

  static bool hasNav(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<CampusBottomNavClearance>();
    return result?.hasBottomNav ?? false;
  }

  @override
  bool updateShouldNotify(CampusBottomNavClearance oldWidget) {
    return bottomClearance != oldWidget.bottomClearance ||
        hasBottomNav != oldWidget.hasBottomNav;
  }
}

/// Extension on BuildContext for quick clearance and scroll padding calculation
extension CampusNavPaddingContext on BuildContext {
  double get bottomNavClearance {
    final clearance = CampusBottomNavClearance.of(this);
    return clearance > 0 ? clearance : CampusBottomNav.getBottomClearance(this);
  }

  EdgeInsets scrollPaddingWithBottomNav({
    double horizontal = 16.0,
    double top = 16.0,
    double extraBottom = 0.0,
  }) {
    return EdgeInsets.fromLTRB(
      horizontal,
      top,
      horizontal,
      bottomNavClearance + extraBottom,
    );
  }
}
