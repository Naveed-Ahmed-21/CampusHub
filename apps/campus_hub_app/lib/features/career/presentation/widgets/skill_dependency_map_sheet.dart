import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/career_provider.dart';
import '../../domain/career_models.dart';

class SkillDependencyMapSheet extends ConsumerStatefulWidget {
  final String roadmapId;
  final String targetRole;

  const SkillDependencyMapSheet({
    super.key,
    required this.roadmapId,
    required this.targetRole,
  });

  @override
  ConsumerState<SkillDependencyMapSheet> createState() => _SkillDependencyMapSheetState();
}

class _SkillDependencyMapSheetState extends ConsumerState<SkillDependencyMapSheet> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skillMapAsync = ref.watch(skillMapProvider(widget.roadmapId));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_tree, color: Colors.indigo, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Skill Dependency Graph',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      widget.targetRole,
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'COMPLETED', 'IN_PROGRESS', 'NEEDS_WORK', 'LOCKED'].map((status) {
                final isSelected = _filter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      status == 'All' ? 'All Skills' : status.replaceAll('_', ' '),
                      style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                    ),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _filter = status),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Nodes list
          Expanded(
            child: skillMapAsync.when(
              data: (nodes) {
                final filtered = _filter == 'All'
                    ? nodes
                    : nodes.where((n) => n.status.toUpperCase() == _filter).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No skills match the selected filter.',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final node = filtered[idx];
                    return _buildNodeCard(node, theme);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text('Failed to load skill map: $err'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeCard(SkillMapNodeModel node, ThemeData theme) {
    Color statusColor;
    IconData statusIcon;

    switch (node.status.toUpperCase()) {
      case 'COMPLETED':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'IN_PROGRESS':
        statusColor = Colors.blue;
        statusIcon = Icons.timelapse;
        break;
      case 'NEEDS_WORK':
        statusColor = Colors.orange;
        statusIcon = Icons.warning_amber;
        break;
      case 'LOCKED':
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.lock_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  node.status.replaceAll('_', ' '),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (node.description != null && node.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              node.description!,
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  node.category,
                  style: TextStyle(fontSize: 10, color: theme.colorScheme.outline),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '~${node.estimatedHours} hrs',
                style: TextStyle(fontSize: 10, color: theme.colorScheme.outline),
              ),
              if (node.prerequisites.isNotEmpty) ...[
                const Spacer(),
                Text(
                  'Prerequisites: ${node.prerequisites.length}',
                  style: TextStyle(fontSize: 10, color: theme.colorScheme.outline),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
