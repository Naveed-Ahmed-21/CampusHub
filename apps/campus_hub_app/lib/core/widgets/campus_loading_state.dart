import 'package:flutter/material.dart';
import 'campus_glass_card.dart';
import '../theme/app_glass.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Smooth Glass Loading State / Skeleton Placeholder for CampusHub
class CampusLoadingState extends StatefulWidget {
  final int itemCount;
  final double itemHeight;

  const CampusLoadingState({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 90.0,
  });

  @override
  State<CampusLoadingState> createState() => _CampusLoadingStateState();
}

class _CampusLoadingStateState extends State<CampusLoadingState>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final shimmerColor = isDark
            ? Color.fromRGBO(47, 51, 54, _animation.value)
            : Color.fromRGBO(239, 243, 244, _animation.value);

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.s16),
          itemCount: widget.itemCount,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s12),
          itemBuilder: (_, __) => CampusGlassCard(
            intensity: GlassIntensity.subtle,
            height: widget.itemHeight,
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: AppRadius.br12,
                  ),
                ),
                const SizedBox(width: AppSpacing.s16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: AppRadius.br8,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s10),
                      Container(
                        height: 11,
                        width: 140,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: AppRadius.br8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
