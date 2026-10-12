import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_stat_card.dart';
import '../../../../core/widgets/campus_loading_state.dart';
import '../../../../core/widgets/campus_error_state.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../providers/placement_provider.dart';


class PlacementAnalyticsView extends ConsumerStatefulWidget {
  const PlacementAnalyticsView({super.key});

  @override
  ConsumerState<PlacementAnalyticsView> createState() => _PlacementAnalyticsViewState();
}

class _PlacementAnalyticsViewState extends ConsumerState<PlacementAnalyticsView> {
  String _selectedYear = '2023 - 2024';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final officerStatsAsync = ref.watch(officerDashboardProvider);

    return Scaffold(
      body: AtmosphericBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Academic Year Dropdown (Image 17)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const CampusBackButton(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Placement Analytics',
                            style: AppTypography.pageTitle.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkText : AppColors.primaryText,
                            ),
                          ),
                          Text(
                            'Institutional recruitment metrics & trends',
                            style: AppTypography.micro.copyWith(
                              color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.3),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedYear,
                          isDense: true,
                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                          ),
                          items: const [
                            DropdownMenuItem(value: '2023 - 2024', child: Text('2023 - 2024')),
                            DropdownMenuItem(value: '2024 - 2025', child: Text('2024 - 2025')),
                            DropdownMenuItem(value: '2025 - 2026', child: Text('2025 - 2026')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedYear = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: officerStatsAsync.when(
                  loading: () => const CampusLoadingState(),
                  error: (err, _) => CampusErrorState(
                    message: 'Failed to load analytics',
                    onRetry: () => ref.refresh(officerDashboardProvider),
                  ),
                  data: (data) {
                    final offeredCount = data['offeredCount'] ?? data['acceptedOffers'] ?? 0;
                    final placementRate = data['placementRate'] ?? 0;
                    final highestCtc = data['highestCtc']?.toString() ?? 'N/A';
                    final averageCtc = data['averageCtc']?.toString() ?? 'N/A';
                    final deptStats = (data['departmentStats'] as List<dynamic>?) ?? [];

                    final barColors = [
                      const Color(0xFF2563EB),
                      const Color(0xFF38BDF8),
                      const Color(0xFF10B981),
                      const Color(0xFFF59E0B),
                      const Color(0xFF8B5CF6),
                      const Color(0xFFEC4899),
                      const Color(0xFF6366F1),
                      const Color(0xFF14B8A6),
                    ];

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // 4 KPI Stat Cards
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.35,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            CampusStatCard(
                              title: 'Total Offers',
                              value: '$offeredCount',
                              subtitle: 'Campus recruitment season',
                              icon: Icons.celebration_outlined,
                              accentColor: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                            ),
                            CampusStatCard(
                              title: 'Placement Rate',
                              value: '$placementRate%',
                              subtitle: 'Of eligible students',
                              icon: Icons.trending_up,
                              accentColor: const Color(0xFF10B981),
                            ),
                            CampusStatCard(
                              title: 'Highest CTC',
                              value: highestCtc,
                              subtitle: 'Top drive compensation',
                              icon: Icons.payments_outlined,
                              accentColor: const Color(0xFF8B5CF6),
                            ),
                            CampusStatCard(
                              title: 'Average CTC',
                              value: averageCtc,
                              subtitle: 'Campus cohort mean',
                              icon: Icons.analytics_outlined,
                              accentColor: const Color(0xFFF59E0B),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Placements by Department
                        Text(
                          'Placements by Department',
                          style: AppTypography.captionMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: isDark ? AppColors.darkText : AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 10),

                        CampusGlassCard(
                          intensity: GlassIntensity.medium,
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Placement Percentage per Branch',
                                style: AppTypography.micro.copyWith(
                                  color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (deptStats.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      'No department placement records available yet.',
                                      style: TextStyle(fontSize: 13, color: Colors.grey),
                                    ),
                                  ),
                                )
                              else ...[
                                SizedBox(
                                  height: 180,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        for (int i = 0; i < deptStats.length; i++) ...[
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            child: _buildVerticalBar(
                                              (deptStats[i]['code'] ?? deptStats[i]['name'] ?? 'DEPT').toString(),
                                              (deptStats[i]['placementRate'] as num?)?.toInt() ?? 0,
                                              barColors[i % barColors.length],
                                              isDark,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2563EB),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Live institutional placement performance',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Institutional Reports Link Card (Image 17 -> 18)
                        Text(
                          'Accreditation & Documentation',
                          style: AppTypography.captionMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: isDark ? AppColors.darkText : AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 10),

                        CampusGlassCard(
                          intensity: GlassIntensity.medium,
                          onTap: () => context.push('/placement/reports'),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.file_copy_outlined, color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'View Complete Institutional Reports',
                                      style: AppTypography.captionMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: isDark ? AppColors.darkText : AppColors.primaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Download Annual Placement Dossier, Salary Matrix & PDF Reports',
                                      style: AppTypography.micro.copyWith(
                                        color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalBar(String label, int percentage, Color color, bool isDark) {
    const maxHeight = 130.0;
    final barHeight = (percentage / 100.0) * maxHeight;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 38,
          height: barHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color,
                color.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}
