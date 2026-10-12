import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AdminProfileActions extends StatelessWidget {
  final VoidCallback onViewActivity;
  final VoidCallback onSignOut;

  const AdminProfileActions({
    super.key,
    required this.onViewActivity,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Account Activity Shortcut
        OutlinedButton.icon(
          onPressed: onViewActivity,
          icon: const Icon(Icons.history_rounded, size: 18),
          label: const Text('View Account Activity →'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // 2. Governance Protection Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0x2238BDF8) : const Color(0x112563EB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.primaryBlue, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Primary institutional administrator identities are protected under GCEE governance and cannot be deactivated or self-deleted.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Sign Out Button (Small & Simple)
        Center(
          child: OutlinedButton.icon(
            onPressed: onSignOut,
            icon: Icon(Icons.logout_rounded, size: 16, color: theme.colorScheme.error),
            label: Text(
              'Sign Out',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.error,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.35)),
              backgroundColor: theme.colorScheme.error.withValues(alpha: 0.06),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              minimumSize: const Size(0, 36),
              shape: const StadiumBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
