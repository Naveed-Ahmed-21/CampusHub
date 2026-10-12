import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../../../../core/widgets/campus_button.dart';

class ReportsView extends ConsumerWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final reports = [
      {
        'title': 'Annual Institutional Placement Report',
        'subtitle': 'Comprehensive 2023-2024 recruitment season documentation and accreditation audit',
        'format': 'PDF',
        'size': '4.2 MB',
        'color': const Color(0xFFEF4444),
      },
      {
        'title': 'Department-wise Placement Matrix',
        'subtitle': 'Branch-level analysis (CSE, ECE, EEE, MECH, CIVIL, IT) with placement percentages',
        'format': 'XLSX',
        'size': '1.8 MB',
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Company-wise Recruitment & Offers',
        'subtitle': 'List of participating recruiters, visiting dates, job titles, and students selected',
        'format': 'PDF',
        'size': '3.1 MB',
        'color': const Color(0xFFEF4444),
      },
      {
        'title': 'Salary Trends & CTC Distribution Analysis',
        'subtitle': 'Highest CTC (₹28.5 LPA), Average CTC (₹7.4 LPA), and tier-1/tier-2 package distributions',
        'format': 'PDF',
        'size': '2.6 MB',
        'color': const Color(0xFF8B5CF6),
      },
      {
        'title': 'Eligible & Non-Placed Students Directory',
        'subtitle': 'Students eligible for ongoing phase-2 drives and targeted career skilling modules',
        'format': 'CSV',
        'size': '950 KB',
        'color': const Color(0xFFF59E0B),
      },
    ];

    return Scaffold(
      body: AtmosphericBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
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
                            'Placement Reports',
                            style: AppTypography.pageTitle.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkText : AppColors.primaryText,
                            ),
                          ),
                          Text(
                            'Institutional accreditation & export dossiers',
                            style: AppTypography.micro.copyWith(
                              color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content List (Image 18)
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final rep = reports[index];
                    final color = rep['color'] as Color;

                    return CampusGlassCard(
                      intensity: GlassIntensity.medium,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              rep['format'] == 'XLSX' || rep['format'] == 'CSV'
                                  ? Icons.table_chart_outlined
                                  : Icons.picture_as_pdf_outlined,
                              color: color,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        rep['title'] as String,
                                        style: AppTypography.captionMedium.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: isDark ? AppColors.darkText : AppColors.primaryText,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        rep['format'] as String,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  rep['subtitle'] as String,
                                  style: AppTypography.micro.copyWith(
                                    color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Text(
                                      'File size: ${rep['size']}',
                                      style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
                                    ),
                                    const Spacer(),
                                    InkWell(
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Downloading ${rep['title']} (${rep['format']})...'),
                                            backgroundColor: AppColors.success,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: (isDark ? AppColors.secondaryCyan : AppColors.primaryBlue).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.download_rounded,
                                              size: 14,
                                              color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Export',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Full Dossier Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: CampusButton(
                  label: 'Generate Full Campus Dossier (ZIP)',
                  icon: const Icon(Icons.archive_outlined),
                  type: CampusButtonType.primary,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Packaging all 5 reports into full institutional dossier...'),
                        backgroundColor: AppColors.success,
                      ),
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
}
