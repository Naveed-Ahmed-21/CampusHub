import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/campus_glass_card.dart';

class AdminIdentityCard extends StatelessWidget {
  final String fullName;
  final String email;
  final String role;
  final bool isDeptAdmin;
  final String collegeName;
  final String? phone;

  const AdminIdentityCard({
    super.key,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isDeptAdmin,
    required this.collegeName,
    this.phone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CampusGlassCard(
      intensity: GlassIntensity.medium,
      borderRadius: AppRadius.br20,
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.badge_outlined, color: AppColors.primaryBlue, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Administrator Identity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildIdentityRow(
            theme,
            label: 'Full Name',
            value: fullName.isNotEmpty ? fullName : 'Administrator',
          ),
          const Divider(height: 16),
          _buildIdentityRow(
            theme,
            label: 'Email',
            value: email,
            isLocked: true,
          ),
          const Divider(height: 16),
          _buildIdentityRow(
            theme,
            label: 'Role',
            value: isDeptAdmin ? 'Department Administrator' : 'Principal & Institutional Administrator',
            isLocked: true,
          ),
          const Divider(height: 16),
          _buildIdentityRow(
            theme,
            label: 'Institution',
            value: collegeName,
            isLocked: true,
          ),
          if (phone != null && phone!.isNotEmpty) ...[
            const Divider(height: 16),
            _buildIdentityRow(
              theme,
              label: 'Phone',
              value: phone!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIdentityRow(
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
            message: 'Protected institutional account credential',
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
