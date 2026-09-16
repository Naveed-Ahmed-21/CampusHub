import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/career_repository.dart';
import '../../domain/career_models.dart';
import '../providers/career_provider.dart';
import '../theme/career_theme.dart';
import '../widgets/career_shared_widgets.dart';
import 'career_roadmap_view.dart';
import 'create_roadmap_view.dart';
import 'skill_graph_view.dart';

/// Screen displaying all active and saved learning roadmaps for the user.
/// Allows viewing progress, switching the active track, navigating into full curricula,
/// opening skill dependency graphs, and managing/deleting tracks.
class UserRoadmapsListView extends ConsumerStatefulWidget {
  const UserRoadmapsListView({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const UserRoadmapsListView(),
      ),
    );
  }

  @override
  ConsumerState<UserRoadmapsListView> createState() => _UserRoadmapsListViewState();
}

class _UserRoadmapsListViewState extends ConsumerState<UserRoadmapsListView> {
  String? _activatingRoadmapId;
  String? _deletingRoadmapId;

  Future<void> _activateRoadmap(String roadmapId, String roleTitle) async {
    setState(() => _activatingRoadmapId = roadmapId);
    try {
      final repo = ref.read(careerRepositoryProvider);
      await repo.setActiveRoadmap(roadmapId);

      ref.invalidate(activeUserRoadmapProvider);
      ref.invalidate(userRoadmapsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '"$roleTitle" is now your active track!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: CareerTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set active track: $e'),
            backgroundColor: CareerTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _activatingRoadmapId = null);
      }
    }
  }

  Future<void> _confirmDeleteRoadmap(String roadmapId, String roleTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CareerTheme.surfaceSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: CareerTheme.glassBorder),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CareerTheme.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: CareerTheme.error, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Delete Roadmap?',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete your "$roleTitle" track? All completed milestones and study progress for this curriculum will be permanently removed.',
          style: const TextStyle(color: CareerTheme.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: CareerTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: CareerTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete Track'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingRoadmapId = roadmapId);
    try {
      final repo = ref.read(careerRepositoryProvider);
      await repo.deleteRoadmap(roadmapId);

      ref.invalidate(activeUserRoadmapProvider);
      ref.invalidate(userRoadmapsProvider);
      ref.invalidate(careerRoadmapsProvider);
      ref.invalidate(userCareerProgressProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Roadmap "$roleTitle" deleted successfully.'),
            backgroundColor: CareerTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete roadmap: $e'),
            backgroundColor: CareerTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _deletingRoadmapId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roadmapsAsync = ref.watch(userRoadmapsProvider);
    final activeRoadmapAsync = ref.watch(activeUserRoadmapProvider);

    return Scaffold(
      backgroundColor: CareerTheme.background,
      appBar: AppBar(
        backgroundColor: CareerTheme.background,
        elevation: 0,
        leading: BackButton(
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Learning Roadmaps',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_road_rounded, color: CareerTheme.primaryCyan),
            tooltip: 'Create New Roadmap',
            onPressed: () => CreateRoadmapView.open(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: CareerTheme.primaryCyan,
        backgroundColor: CareerTheme.surfaceSecondary,
        onRefresh: () async {
          ref.invalidate(userRoadmapsProvider);
          ref.invalidate(activeUserRoadmapProvider);
        },
        child: roadmapsAsync.when(
          data: (roadmaps) {
            if (roadmaps.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildRoadmapsList(context, roadmaps, activeRoadmapAsync.valueOrNull);
          },
          loading: () => _buildLoadingShimmer(),
          error: (err, _) => _buildErrorState(err),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        CareerGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: CareerTheme.primaryCyan.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: CareerTheme.primaryCyan.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.alt_route_rounded, color: CareerTheme.primaryCyan, size: 36),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Roadmaps Created Yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Generate an AI-powered personalized curriculum customized with weekly milestones, verified videos, hands-on projects, and skill graphs.',
                style: TextStyle(fontSize: 13, color: CareerTheme.textSecondary, height: 1.45),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => CreateRoadmapView.open(context),
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Generate First Roadmap'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CareerTheme.primaryCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoadmapsList(
    BuildContext context,
    List<UserRoadmapItemModel> roadmaps,
    ActiveRoadmapState? activeState,
  ) {
    final activeId = activeState?.roadmapId ?? '';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // Summary Header Card
        _buildHeaderOverview(roadmaps, activeId),
        const SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tracks (${roadmaps.length})',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            InkWell(
              onTap: () => CreateRoadmapView.open(context),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: CareerTheme.primaryCyan),
                    SizedBox(width: 4),
                    Text(
                      'New Track',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CareerTheme.primaryCyan),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...roadmaps.map((roadmap) {
          final isCurrentlyActive = roadmap.isActive || (activeId.isNotEmpty && roadmap.id == activeId);
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildRoadmapCard(context, roadmap, isCurrentlyActive),
          );
        }),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildHeaderOverview(List<UserRoadmapItemModel> roadmaps, String activeId) {
    final activeRoadmap = roadmaps.firstWhere(
      (r) => r.isActive || (activeId.isNotEmpty && r.id == activeId),
      orElse: () => roadmaps.first,
    );
    final hasActive = roadmaps.any((r) => r.isActive || (activeId.isNotEmpty && r.id == activeId));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CareerTheme.accentIndigo.withValues(alpha: 0.15),
            CareerTheme.primaryCyan.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CareerTheme.primaryCyan.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CareerTheme.primaryCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_rounded, color: CareerTheme.primaryCyan, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasActive ? 'Current Focus Track' : 'Selected Curriculum',
                      style: const TextStyle(fontSize: 11, color: CareerTheme.textMuted, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activeRoadmap.targetRole,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CareerTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CareerTheme.glassBorder),
                ),
                child: Text(
                  '${roadmaps.length} Total',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CareerTheme.primaryCyan),
                ),
              ),
            ],
          ),
          if (hasActive) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (activeRoadmap.progressPercent / 100.0).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: CareerTheme.surfaceSecondary,
                valueColor: const AlwaysStoppedAnimation<Color>(CareerTheme.primaryCyan),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Focus: ${activeRoadmap.currentFocus.isNotEmpty ? activeRoadmap.currentFocus : 'Phase 1: Foundations'}',
                    style: const TextStyle(fontSize: 11, color: CareerTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${activeRoadmap.progressPercent.round()}% complete',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CareerTheme.primaryCyan),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoadmapCard(
    BuildContext context,
    UserRoadmapItemModel roadmap,
    bool isActive,
  ) {
    final isActivating = _activatingRoadmapId == roadmap.id;
    final isDeleting = _deletingRoadmapId == roadmap.id;
    final progress = roadmap.progressPercent.clamp(0.0, 100.0);
    final weeks = roadmap.estimatedMonths * 4;

    return CareerGlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: isActive ? CareerTheme.primaryCyan.withValues(alpha: 0.55) : CareerTheme.glassBorder,
      backgroundColor: isActive
          ? CareerTheme.surface.withValues(alpha: 0.9)
          : CareerTheme.surface.withValues(alpha: 0.7),
      onTap: () => CareerRoadmapView.open(context, roadmapId: roadmap.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Role, Active Badge / Switch, Popup Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isActive
                      ? CareerTheme.primaryCyan.withValues(alpha: 0.18)
                      : CareerTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? CareerTheme.primaryCyan.withValues(alpha: 0.4)
                        : CareerTheme.glassBorder,
                  ),
                ),
                child: Icon(
                  Icons.terminal_rounded,
                  color: isActive ? CareerTheme.primaryCyan : CareerTheme.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roadmap.targetRole,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${roadmap.category} • ${roadmap.level} • v${roadmap.version}',
                      style: const TextStyle(fontSize: 11, color: CareerTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Active Badge OR "Set Active" Action
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: CareerTheme.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: CareerTheme.success.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 12, color: CareerTheme.success),
                      SizedBox(width: 4),
                      Text(
                        'ACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: CareerTheme.success,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                )
              else
                InkWell(
                  onTap: isActivating ? null : () => _activateRoadmap(roadmap.id, roadmap.targetRole),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: CareerTheme.primaryCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: CareerTheme.primaryCyan.withValues(alpha: 0.3)),
                    ),
                    child: isActivating
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: CareerTheme.primaryCyan),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow_rounded, size: 14, color: CareerTheme.primaryCyan),
                              SizedBox(width: 3),
                              Text(
                                'Set Active',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: CareerTheme.primaryCyan,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

              // Overflow Menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20, color: CareerTheme.textMuted),
                color: CareerTheme.surfaceSecondary,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: CareerTheme.glassBorder),
                ),
                onSelected: (value) {
                  if (value == 'open') {
                    CareerRoadmapView.open(context, roadmapId: roadmap.id);
                  } else if (value == 'graph') {
                    SkillGraphView.open(context, roadmapId: roadmap.id);
                  } else if (value == 'activate') {
                    _activateRoadmap(roadmap.id, roadmap.targetRole);
                  } else if (value == 'delete') {
                    _confirmDeleteRoadmap(roadmap.id, roadmap.targetRole);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'open',
                    child: Row(
                      children: [
                        Icon(Icons.auto_stories_rounded, size: 16, color: CareerTheme.primaryCyan),
                        SizedBox(width: 8),
                        Text('Open Curriculum', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'graph',
                    child: Row(
                      children: [
                        Icon(Icons.account_tree_rounded, size: 16, color: CareerTheme.accentIndigo),
                        SizedBox(width: 8),
                        Text('Skill Map Graph', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                  if (!isActive)
                    const PopupMenuItem(
                      value: 'activate',
                      child: Row(
                        children: [
                          Icon(Icons.flag_circle_rounded, size: 16, color: CareerTheme.success),
                          SizedBox(width: 8),
                          Text('Set as Active Track', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 16, color: CareerTheme.error),
                        SizedBox(width: 8),
                        Text('Delete Track', style: TextStyle(color: CareerTheme.error, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Metadata Tags
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildTag(Icons.calendar_today_rounded, '$weeks Weeks Duration'),
              if (roadmap.phases.isNotEmpty)
                _buildTag(Icons.layers_rounded, '${roadmap.phases.length} Phases')
              else if (roadmap.nodes.isNotEmpty)
                _buildTag(Icons.insights_rounded, '${roadmap.nodes.length} Milestones'),
              if (roadmap.streakDays > 0)
                _buildTag(Icons.local_fire_department_rounded, '${roadmap.streakDays}d Streak',
                    color: const Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  roadmap.currentFocus.isNotEmpty ? 'Focus: ${roadmap.currentFocus}' : 'Curriculum Progress',
                  style: const TextStyle(fontSize: 11, color: CareerTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${progress.round()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: progress >= 100 ? CareerTheme.success : CareerTheme.primaryCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress / 100.0,
              minHeight: 6,
              backgroundColor: CareerTheme.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 100 ? CareerTheme.success : CareerTheme.primaryCyan,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Actions Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => CareerRoadmapView.open(context, roadmapId: roadmap.id),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                  label: const Text('View Roadmap'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: isActive ? CareerTheme.primaryCyan.withValues(alpha: 0.5) : CareerTheme.glassBorder,
                    ),
                    backgroundColor: isActive
                        ? CareerTheme.primaryCyan.withValues(alpha: 0.1)
                        : Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => SkillGraphView.open(context, roadmapId: roadmap.id),
                icon: const Icon(Icons.account_tree_rounded, size: 14),
                label: const Text('Graph'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CareerTheme.textSecondary,
                  side: const BorderSide(color: CareerTheme.glassBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: isDeleting
                    ? null
                    : () => _confirmDeleteRoadmap(roadmap.id, roadmap.targetRole),
                icon: isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: CareerTheme.error),
                      )
                    : const Icon(Icons.delete_outline_rounded, size: 20, color: CareerTheme.textMuted),
                tooltip: 'Delete Roadmap',
                style: IconButton.styleFrom(
                  backgroundColor: CareerTheme.surfaceElevated.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: CareerTheme.glassBorder),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String label, {Color? color}) {
    final effectiveColor = color ?? CareerTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CareerTheme.surfaceElevated.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CareerTheme.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: effectiveColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: effectiveColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: 3,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            color: CareerTheme.surfaceElevated.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CareerTheme.glassBorder),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: CareerTheme.error, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Failed to load roadmaps',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              '$error',
              style: const TextStyle(fontSize: 12, color: CareerTheme.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.refresh(userRoadmapsProvider),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CareerTheme.primaryCyan,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
