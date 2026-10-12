import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_date_formatter.dart';
import '../../../../core/widgets/campus_glass_card.dart';

class AdminAccountInfoCard extends StatelessWidget {
  final String userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String status;

  const AdminAccountInfoCard({
    super.key,
    required this.userId,
    this.createdAt,
    this.updatedAt,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cleanId = userId.replaceAll('-', '');
    final adminId = cleanId.isNotEmpty
        ? 'ADM-${cleanId.substring(0, min(8, cleanId.length)).toUpperCase()}'
        : 'ADM-GCEE';

    final createdStr = createdAt != null
        ? AppDateFormatter.formatDate(createdAt!)
        : 'Institutional Provision';

    final updatedStr = updatedAt != null
        ? AppDateFormatter.formatDate(updatedAt!)
        : 'Recent Sync';

    final isActive = status.toUpperCase() == 'ACTIVE';

    return CampusGlassCard(
      intensity: GlassIntensity.medium,
      borderRadius: AppRadius.br20,
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.secondaryCyan, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Account Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow(
            theme,
            label: 'Admin ID',
            value: adminId,
            isLocked: true,
          ),
          const Divider(height: 16),
          _buildInfoRow(
            theme,
            label: 'Account created',
            value: createdStr,
          ),
          const Divider(height: 16),
          _buildInfoRow(
            theme,
            label: 'Last profile update',
            value: updatedStr,
          ),
          const Divider(height: 16),
          Row(
            children: [
              SizedBox(
                width: 105,
                child: Text(
                  'Account status',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (isActive ? AppColors.success : AppColors.warning).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isActive ? '● Active' : status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme, {
    required String label,
    required String value,
    bool isLocked = false,
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
        if (isLocked) ...[
          const SizedBox(width: 6),
          Tooltip(
            message: 'Immutable institutional identifier',
            child: Icon(
              Icons.lock_outline_rounded,
              size: 15,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }
}
