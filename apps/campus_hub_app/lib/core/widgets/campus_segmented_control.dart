import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class CampusSegmentItem {
  final String label;
  final Widget? icon;
  final int? badgeCount;

  const CampusSegmentItem({
    required this.label,
    this.icon,
    this.badgeCount,
  });
}

/// Authentic Apple iOS-styled Segmented Control with smooth sliding pill,
/// frosted translucent track, and haptic selection feedback.
class CampusSegmentedControl extends StatelessWidget {
  final List<CampusSegmentItem> items;
  final int selectedIndex;
  final ValueChanged<int> onValueChanged;
  final double height;
  final EdgeInsetsGeometry padding;

  const CampusSegmentedControl({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onValueChanged,
    this.height = 36.0,
    this.padding = const EdgeInsets.all(2.5),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark
        ? const Color(0xFF16181C) // X dark track
        : const Color(0xFFEFF3F4); // X light track
    final pillColor = isDark
        ? const Color(0xFF2F3336) // X elevated dark pill
        : Colors.white; // Pure white pill
    final activeTextColor = isDark ? Colors.white : AppColors.primaryText;
    final inactiveTextColor = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;

    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth) / items.length;

          return Stack(
            children: [
              // Sliding Animated Pill
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                left: selectedIndex * itemWidth,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: pillColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              // Segment Items Row
              Row(
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = index == selectedIndex;

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (!isSelected) {
                          HapticFeedback.selectionClick();
                          onValueChanged(index);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (item.icon != null) ...[
                              IconTheme(
                                data: IconThemeData(
                                  size: 15,
                                  color: isSelected ? activeTextColor : inactiveTextColor,
                                ),
                                child: item.icon!,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Flexible(
                              child: Text(
                                item.label,
                                style: AppTypography.cardTitle.copyWith(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? activeTextColor : inactiveTextColor,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item.badgeCount != null && item.badgeCount! > 0) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark ? Colors.white : AppColors.primaryText)
                                      : (isDark ? AppColors.darkBorder : AppColors.border),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${item.badgeCount}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? (isDark ? Colors.black : Colors.white)
                                        : (isDark ? Colors.white70 : AppColors.secondaryText),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
