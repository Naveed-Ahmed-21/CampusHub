import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/campus_glass_card.dart';

class AdminScopeCard extends StatelessWidget {
  final bool isDeptAdmin;
  final String? deptId;
  final String collegeName;

  const AdminScopeCard({
    super.key,
    required this.isDeptAdmin,
    required this.deptId,
    required this.collegeName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final accessLevel = isDeptAdmin
        ? 'Department Administrator'
        : 'Institution-wide Administrator';
    final scope = isDeptAdmin
        ? (deptId != null && deptId!.isNotEmpty ? deptId! : 'Assigned Academic Department')
        : collegeName;
    final departments = isDeptAdmin
        ? (deptId != null && deptId!.isNotEmpty ? deptId! : 'Scoped Department')
        : 'All Institutional Departments';

    return CampusGlassCard(
      intensity: GlassIntensity.medium,
      borderRadius: AppRadius.br20,
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.domain_verification_outlined, color: AppColors.secondaryCyan, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Administrative Scope',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: (isDeptAdmin ? AppColors.warning : AppColors.primaryBlue).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isDeptAdmin ? 'DEPARTMENT SCOPE' : 'INSTITUTION-WIDE',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isDeptAdmin ? AppColors.warning : AppColors.primaryBlue,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildScopeRow(
            theme,
            label: 'Access Level',
            value: accessLevel,
          ),
          const Divider(height: 16),
          _buildScopeRow(
            theme,
            label: 'Scope',
            value: scope,
          ),
          const Divider(height: 16),
          _buildScopeRow(
            theme,
            label: 'Departments',
            value: departments,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.3 : 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 15,
                  color: isDark ? AppColors.secondaryCyan : AppColors.primaryBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Administrative scope is governed by institutional policy and cannot be altered from this screen.',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeRow(
    ThemeData theme, {
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Tooltip(
          message: 'Protected institutional administrative policy',
          child: Icon(
            Icons.lock_outline_rounded,
            size: 15,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
