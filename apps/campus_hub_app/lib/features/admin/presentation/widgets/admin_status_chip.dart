import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AdminStatusChip extends StatelessWidget {
  final String status;
  final String? customLabel;

  const AdminStatusChip({
    super.key,
    required this.status,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final upper = status.toUpperCase();
    Color baseColor;

    if (upper.contains('ACTIVE') ||
        upper.contains('APPROVED') ||
        upper.contains('CORE') ||
        upper.contains('OFFERED') ||
        upper.contains('VERIFIED') ||
        upper.contains('SUCCESS')) {
      baseColor = AppColors.success;
    } else if (upper.contains('PENDING') ||
        upper.contains('SHORTLIST') ||
        upper.contains('ELECTIVE') ||
        upper.contains('REVIEW') ||
        upper.contains('WARNING')) {
      baseColor = AppColors.warning;
    } else if (upper.contains('REJECT') ||
        upper.contains('INACTIVE') ||
        upper.contains('FAILED') ||
        upper.contains('BLOCKED') ||
        upper.contains('DELETE')) {
      baseColor = AppColors.error;
    } else if (upper.contains('INTERVIEW') ||
        upper.contains('COLLEGE') ||
        upper.contains('PRIMARY')) {
      baseColor = isDark ? AppColors.secondaryCyan : AppColors.primaryBlue;
    } else {
      baseColor = isDark ? AppColors.electricBlue : AppColors.primaryNavy;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: isDark ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: baseColor.withValues(alpha: isDark ? 0.35 : 0.25), width: 1),
      ),
      child: Text(
        customLabel ?? upper,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: baseColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

