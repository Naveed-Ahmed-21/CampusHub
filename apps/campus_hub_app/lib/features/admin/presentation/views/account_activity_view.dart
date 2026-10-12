import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/widgets/campus_empty_state.dart';
import '../../../../core/widgets/campus_glass_card.dart';
import '../../../../core/utils/app_date_formatter.dart';
import '../providers/admin_provider.dart';

class AccountActivityView extends ConsumerStatefulWidget {
  const AccountActivityView({super.key});

  @override
  ConsumerState<AccountActivityView> createState() => _AccountActivityViewState();
}

class _AccountActivityViewState extends ConsumerState<AccountActivityView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'ALL';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getActionColor(String action) {
    final act = action.toUpperCase();
    if (act.contains('PASSWORD') || act.contains('SECURITY')) {
      return AppColors.success;
    } else if (act.contains('ROLE') || act.contains('STATUS') || act.contains('UPDATE')) {
      return AppColors.primaryBlue;
    } else if (act.contains('DELETE') || act.contains('DEACTIVATE')) {
      return AppColors.error;
    } else if (act.contains('CREATE') || act.contains('APPROVED')) {
      return AppColors.secondaryCyan;
    }
    return AppColors.primaryNavy;
  }

  IconData _getActionIcon(String action) {
    final act = action.toUpperCase();
    if (act.contains('PASSWORD')) {
      return Icons.lock_reset_rounded;
    } else if (act.contains('ROLE')) {
      return Icons.admin_panel_settings_rounded;
    } else if (act.contains('STATUS')) {
      return Icons.toggle_on_rounded;
    } else if (act.contains('DELETE')) {
      return Icons.delete_outline_rounded;
    } else if (act.contains('CREATE')) {
      return Icons.person_add_alt_1_rounded;
    } else if (act.contains('UPDATE')) {
      return Icons.edit_note_rounded;
    }
    return Icons.history_rounded;
  }

  String _formatTimestamp(dynamic rawTimestamp) {
    if (rawTimestamp == null) return 'Recent';
    try {
      final dt = DateTime.parse(rawTimestamp.toString()).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';

      return AppDateFormatter.formatDateTime(dt);
    } catch (_) {
      return rawTimestamp.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auditLogsAsync = ref.watch(adminAuditReportsProvider);

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CampusAppBar(
          title: 'Account & System Activity',
          leading: CampusBackButton.canPop(context) ? const CampusBackButton() : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh Activity Logs',
              onPressed: () => ref.invalidate(adminAuditReportsProvider),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              children: [
                // Search and Filters Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
                  child: CampusGlassCard(
                    intensity: GlassIntensity.subtle,
                    borderRadius: AppRadius.br16,
                    padding: const EdgeInsets.all(AppSpacing.s12),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                          decoration: InputDecoration(
                            hintText: 'Search activity by action, user, or details...',
                            hintStyle: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                            ),
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
                              ),
                            ),
                            filled: true,
                            fillColor: isDark
                                ? Colors.black.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('ALL', 'All Events'),
                              const SizedBox(width: 8),
                              _buildFilterChip('USER_MANAGEMENT', 'User Management'),
                              const SizedBox(width: 8),
                              _buildFilterChip('SECURITY', 'Security & Passwords'),
                              const SizedBox(width: 8),
                              _buildFilterChip('AUTHENTICATION', 'Authentication'),
                              const SizedBox(width: 8),
                              _buildFilterChip('SYSTEM', 'System Audit'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Activity Logs List
                Expanded(
                  child: auditLogsAsync.when(
                    data: (logs) {
                      final filtered = logs.where((item) {
                        final log = item is Map<String, dynamic> ? item : <String, dynamic>{};
                        final category = log['category']?.toString().toUpperCase() ?? '';
                        final action = log['action']?.toString().toLowerCase() ?? '';
                        final desc = (log['description'] ?? log['details'])?.toString().toLowerCase() ?? '';
                        final actor = log['actorName']?.toString().toLowerCase() ?? '';

                        final matchesCat = _selectedCategory == 'ALL' ||
                            category.contains(_selectedCategory) ||
                            action.contains(_selectedCategory);

                        final matchesSearch = _searchQuery.isEmpty ||
                            action.contains(_searchQuery) ||
                            desc.contains(_searchQuery) ||
                            actor.contains(_searchQuery);

                        return matchesCat && matchesSearch;
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: CampusEmptyState(
                            icon: Icons.manage_search_rounded,
                            title: 'No Activity Logs Found',
                            description: _searchQuery.isNotEmpty || _selectedCategory != 'ALL'
                                ? 'No security or administration events match your search criteria.'
                                : 'No account or system activity recorded yet in institutional audit logs.',
                            actionLabel: 'Reset Filters',
                            onAction: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedCategory = 'ALL';
                              });
                            },
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(adminAuditReportsProvider);
                          await ref.read(adminAuditReportsProvider.future);
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s16,
                            vertical: AppSpacing.s8,
                          ),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final raw = filtered[index];
                            final log = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
                            final action = log['action']?.toString() ?? 'SYSTEM_EVENT';
                            final desc = (log['description'] ?? log['details'])?.toString() ?? 'Action recorded';
                            final actorName = log['actorName']?.toString() ?? 'System Administrator';
                            final actorRole = log['actorRole']?.toString() ?? '';
                            final timestamp = log['timestamp'] ?? log['created_at'];
                            final actionColor = _getActionColor(action);
                            final actionIcon = _getActionIcon(action);

                            return CampusGlassCard(
                              intensity: GlassIntensity.medium,
                              borderRadius: AppRadius.br16,
                              padding: const EdgeInsets.all(AppSpacing.s16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Action Icon Badge
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: actionColor.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: actionColor.withValues(alpha: 0.25),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Icon(actionIcon, size: 20, color: actionColor),
                                  ),
                                  const SizedBox(width: 14),

                                  // Event Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _formatActionTitle(action),
                                                style: const TextStyle(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: -0.2,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              _formatTimestamp(timestamp),
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: isDark
                                                    ? AppColors.darkSecondaryText
                                                    : AppColors.secondaryText,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          desc,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark
                                                ? AppColors.darkText
                                                : AppColors.primaryText,
                                            height: 1.35,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.verified_user_outlined,
                                              size: 13,
                                              color: isDark
                                                  ? AppColors.darkSecondaryText
                                                  : AppColors.secondaryText,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              actorRole.isNotEmpty
                                                  ? '$actorName ($actorRole)'
                                                  : actorName,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? AppColors.darkSecondaryText
                                                    : AppColors.secondaryText,
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
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.s24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
                            const SizedBox(height: 12),
                            Text(
                              'Failed to Load Activity Logs',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$err',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => ref.invalidate(adminAuditReportsProvider),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedCategory == key;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedCategory = key),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected
            ? Colors.white
            : (isDark ? AppColors.darkText : AppColors.primaryText),
      ),
      selectedColor: AppColors.primaryBlue,
      backgroundColor: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.04),
      side: BorderSide(
        color: isSelected
            ? AppColors.primaryBlue
            : (isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder),
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  String _formatActionTitle(String action) {
    return action
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }
}
