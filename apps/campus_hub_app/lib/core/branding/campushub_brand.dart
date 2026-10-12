import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import 'gcee_brand.dart';
import 'gcee_logo.dart';

enum BrandLayout {
  vertical,
  horizontal,
  compact,
}

/// Composite Institutional + Product Branding Component
/// Adheres strictly to the hierarchy:
/// 1. GCEE Emblem (Institution)
/// 2. CampusHub (Product)
/// 3. Government College of Engineering, Erode (Context)
class CampusHubBrand extends StatelessWidget {
  final BrandLayout layout;
  final double? logoSize;
  final bool showCollegeName;
  final bool showShortCode;
  final CrossAxisAlignment crossAxisAlignment;
  final VoidCallback? onTap;

  const CampusHubBrand({
    super.key,
    this.layout = BrandLayout.horizontal,
    this.logoSize,
    this.showCollegeName = true,
    this.showShortCode = true,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.onTap,
  });

  const CampusHubBrand.login({
    super.key,
    this.onTap,
  })  : layout = BrandLayout.vertical,
        logoSize = 88.0,
        showCollegeName = true,
        showShortCode = true,
        crossAxisAlignment = CrossAxisAlignment.center;

  const CampusHubBrand.header({
    super.key,
    this.onTap,
  })  : layout = BrandLayout.horizontal,
        logoSize = 34.0,
        showCollegeName = false,
        showShortCode = true,
        crossAxisAlignment = CrossAxisAlignment.center;

  const CampusHubBrand.sidebar({
    super.key,
    this.onTap,
  })  : layout = BrandLayout.vertical,
        logoSize = 44.0,
        showCollegeName = false,
        showShortCode = true,
        crossAxisAlignment = CrossAxisAlignment.center;

  const CampusHubBrand.compact({
    super.key,
    this.onTap,
  })  : layout = BrandLayout.compact,
        logoSize = 32.0,
        showCollegeName = false,
        showShortCode = false,
        crossAxisAlignment = CrossAxisAlignment.center;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkText : AppColors.primaryText;
    final secondary = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;

    switch (layout) {
      case BrandLayout.vertical:
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: crossAxisAlignment,
            children: [
              GceeLogo(
                size: logoSize ?? 80.0,
                showSurface: false,
              ),
              const SizedBox(height: AppSpacing.s12),
              Text(
                GceeBrand.productName,
                style: AppTypography.pageTitle.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                  letterSpacing: -0.5,
                ),
              ),
              if (showCollegeName) ...[
                const SizedBox(height: AppSpacing.s4),
                Text(
                  GceeBrand.institutionName,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (showShortCode) ...[
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkElevatedSurface : AppColors.lightSecondarySurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                  child: Text(
                    GceeBrand.institutionShort,
                    style: AppTypography.micro.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );

      case BrandLayout.horizontal:
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GceeLogo(
                size: logoSize ?? 34.0,
                showSurface: false,
              ),
              const SizedBox(width: AppSpacing.s10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        GceeBrand.productName,
                        style: AppTypography.cardTitle.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      if (showShortCode) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkElevatedSurface : AppColors.lightSecondarySurface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.border,
                            ),
                          ),
                          child: Text(
                            GceeBrand.institutionShort,
                            style: AppTypography.micro.copyWith(
                              color: primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 9.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (showCollegeName) ...[
                    const SizedBox(height: 1),
                    Text(
                      GceeBrand.institutionName,
                      style: AppTypography.micro.copyWith(
                        color: secondary,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ],
          ),
        );

      case BrandLayout.compact:
        return GceeLogo(
          size: logoSize ?? 32.0,
          showSurface: false,
          tooltip: GceeBrand.institutionName,
          onTap: onTap,
        );
    }
  }
}
