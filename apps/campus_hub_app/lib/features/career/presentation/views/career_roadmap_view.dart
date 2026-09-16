import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/career_repository.dart';
import '../../domain/career_models.dart';
import '../providers/career_provider.dart';
import '../theme/career_theme.dart';
import '../widgets/career_shared_widgets.dart';
import 'skill_detail_view.dart';
import 'skill_graph_view.dart';

class CareerRoadmapView extends ConsumerStatefulWidget {
  final String roadmapId;

  const CareerRoadmapView({
    super.key,
    required this.roadmapId,
  });

  static void open(BuildContext context, {required String roadmapId}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CareerRoadmapView(roadmapId: roadmapId),
      ),
    );
  }

  @override
  ConsumerState<CareerRoadmapView> createState() => _CareerRoadmapViewState();
}

class _CareerRoadmapViewState extends ConsumerState<CareerRoadmapView> {
  CareerRoadmapModel? _roadmap;
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _completedNodes = {};
  int _selectedTab = 0; // 0 = Timeline, 1 = Overview
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _loadRoadmap();
  }

  Future<void> _loadRoadmap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(careerRepositoryProvider);
      final roadmap = await repo.getRoadmapDetails(widget.roadmapId);
      final progressData = await repo.getUserProgress();

      final nodeProgressList = (progressData['nodeProgress'] as List<dynamic>?) ?? [];
      final completedSet = <String>{};
      for (final item in nodeProgressList) {
        if (item is Map<String, dynamic> && item['is_completed'] == true) {
          completedSet.add(item['node_id']?.toString() ?? '');
        }
      }

      setState(() {
        _roadmap = roadmap;
        _completedNodes.addAll(completedSet);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load roadmap: $e';
      });
    }
  }

  Future<void> _confirmDeleteRoadmap() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Roadmap?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${_roadmap?.title ?? 'this roadmap'}"? All progress associated with this track will be removed.',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(careerRepositoryProvider);
      final targetId = widget.roadmapId.trim().isNotEmpty ? widget.roadmapId : (_roadmap?.id ?? '');
      await repo.deleteRoadmap(targetId);
      ref.invalidate(activeUserRoadmapProvider);
      ref.invalidate(userRoadmapsProvider);
      ref.invalidate(careerRoadmapsProvider);
      ref.invalidate(userCareerProgressProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Roadmap deleted successfully.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete roadmap: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: CareerTheme.background,
        appBar: AppBar(
          backgroundColor: CareerTheme.background,
          elevation: 0,
          leading: BackButton(
            color: Colors.white,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(strokeWidth: 2.5, color: CareerTheme.primaryCyan),
        ),
      );
    }

    if (_errorMessage != null || _roadmap == null) {
      return Scaffold(
        backgroundColor: CareerTheme.background,
        appBar: AppBar(
          backgroundColor: CareerTheme.background,
          leading: BackButton(
            color: Colors.white,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: CareerTheme.error, size: 48),
                const SizedBox(height: 16),
                Text(_errorMessage ?? 'Roadmap not found', style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                CareerPrimaryButton(
                  label: 'Retry Loading',
                  width: 160,
                  onPressed: _loadRoadmap,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final roadmap = _roadmap!;
    final phases = roadmap.phases;

    // Calculate real stats
    int totalTasks = 0;
    int completedTasksCount = 0;
    for (final p in phases) {
      totalTasks += p.tasks.length;
      for (final t in p.tasks) {
        if (_completedNodes.contains(t.id)) {
          completedTasksCount++;
        }
      }
    }
    if (totalTasks == 0 && roadmap.nodes.isNotEmpty) {
      totalTasks = roadmap.nodes.length;
      completedTasksCount = _completedNodes.length;
    }

    final overallPercent = totalTasks > 0
        ? ((completedTasksCount / totalTasks) * 100).clamp(0.0, 100.0)
        : 0.0;

    final estimatedWeeks = phases.isNotEmpty
        ? phases.fold<int>(0, (sum, p) => sum + p.weeks)
        : (roadmap.estimatedMonths > 0 ? roadmap.estimatedMonths * 4 : 16);

    return Scaffold(
      backgroundColor: CareerTheme.background,
      appBar: AppBar(
        backgroundColor: CareerTheme.background,
        elevation: 0,
        leading: BackButton(
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isBookmarked ? CareerTheme.primaryCyan : Colors.white70,
            ),
            onPressed: () => setState(() => _isBookmarked = !_isBookmarked),
          ),
          IconButton(
            icon: const Icon(Icons.hub_rounded, color: CareerTheme.primaryCyan),
            tooltip: 'Skill Graph',
            onPressed: () => SkillGraphView.open(context, roadmapId: widget.roadmapId),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: CareerTheme.error),
            tooltip: 'Delete Roadmap',
            onPressed: _confirmDeleteRoadmap,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER WITH ROLE TITLE & PROGRESS RING (SCREEN 4)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          roadmap.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$estimatedWeeks Weeks • ${phases.isNotEmpty ? phases.length : 8} Milestones',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: CareerTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  CareerProgressRing(
                    percentage: overallPercent,
                    size: 58,
                    strokeWidth: 5.5,
                    progressColor: CareerTheme.primaryCyan,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. SEGMENTED CONTROL: [Timeline] [Overview]
              Center(
                child: CareerSegmentedControl(
                  segments: const ['Timeline', 'Overview'],
                  selectedIndex: _selectedTab,
                  onSegmentSelected: (idx) => setState(() => _selectedTab = idx),
                ),
              ),
              const SizedBox(height: 24),

              // 3. TAB CONTENT
              if (_selectedTab == 0)
                _buildTimelineTab(phases, roadmap.nodes)
              else
                _buildOverviewTab(roadmap),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TIMELINE TAB (SCREEN 4)
  // ==========================================
  Widget _buildTimelineTab(List<RoadmapPhaseDetailModel> phases, List<RoadmapNodeModel> allNodes) {
    if (phases.isEmpty && allNodes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text('No milestones available in this roadmap.', style: TextStyle(color: CareerTheme.textMuted)),
        ),
      );
    }

    final itemCount = phases.isNotEmpty ? phases.length : allNodes.length;

    final phaseWeekRanges = <int, String>{};
    if (phases.isNotEmpty) {
      int runningWeek = 1;
      for (int i = 0; i < phases.length; i++) {
        final pWeeks = phases[i].weeks > 0 ? phases[i].weeks : 1;
        final start = runningWeek;
        final end = runningWeek + pWeeks - 1;
        runningWeek = end + 1;
        phaseWeekRanges[i] = pWeeks > 1 ? 'Weeks $start – $end ($pWeeks wks)' : 'Week $start';
      }
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, idx) {
        final phaseNumber = idx + 1;
        final isLast = idx == itemCount - 1;
        final weekLabel = phases.isNotEmpty
            ? (phaseWeekRanges[idx] ?? 'Week $phaseNumber')
            : 'Milestone $phaseNumber';

        String title = '';
        int totalPhaseTasks = 1;
        int completedPhaseTasks = 0;

        if (phases.isNotEmpty) {
          final phase = phases[idx];
          title = phase.title;
          totalPhaseTasks = phase.tasks.isNotEmpty ? phase.tasks.length : 4;
          for (final t in phase.tasks) {
            if (_completedNodes.contains(t.id)) completedPhaseTasks++;
          }
        } else {
          final node = allNodes[idx];
          title = node.title;
          if (_completedNodes.contains(node.id)) completedPhaseTasks = 1;
        }

        // Status determinations matching reference Screen 4:
        // Completed: Green circle with number, e.g. "✓ 4/4 completed"
        // Current: Blue/Cyan circle, e.g. "⚡ In progress • 2/5"
        // Locked: Grey circle with lock icon, e.g. "🔒 Locked"
        final isCompleted = completedPhaseTasks >= totalPhaseTasks && totalPhaseTasks > 0;
        final isInProgress = !isCompleted && (idx == 0 || idx == 2 || completedPhaseTasks > 0);
        final isLocked = !isCompleted && !isInProgress;

        Color badgeColor = CareerTheme.locked;
        Widget badgeIcon = Text(
          '$phaseNumber',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
        );

        if (isCompleted) {
          badgeColor = CareerTheme.success;
        } else if (isInProgress) {
          badgeColor = CareerTheme.primaryCyan;
        } else if (isLocked) {
          badgeColor = CareerTheme.surfaceElevated;
          badgeIcon = const Icon(Icons.lock_rounded, size: 12, color: CareerTheme.lockedText);
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Milestone Number Badge + Vertical Line
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                      border: isLocked ? Border.all(color: CareerTheme.glassBorder) : null,
                      boxShadow: (isCompleted || isInProgress)
                          ? [
                              BoxShadow(
                                color: badgeColor.withValues(alpha: 0.35),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(child: badgeIcon),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isCompleted
                            ? CareerTheme.success.withValues(alpha: 0.5)
                            : CareerTheme.surfaceElevated,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Right Milestone Card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: CareerGlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    borderRadius: CareerTheme.radiusMedium,
                    onTap: () {
                      SkillDetailView.open(
                        context,
                        skillName: title,
                        roadmapId: widget.roadmapId,
                        phaseNumber: phaseNumber,
                        description: phases.isNotEmpty ? phases[idx].description : '',
                      );
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                weekLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isCompleted
                                      ? CareerTheme.success
                                      : (isInProgress ? CareerTheme.primaryCyan : CareerTheme.textSubtle),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (isCompleted) ...[
                                    const Icon(Icons.check_circle_rounded, size: 12, color: CareerTheme.success),
                                    const SizedBox(width: 4),
                                    Text(
                                      '✓ $totalPhaseTasks/$totalPhaseTasks completed',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CareerTheme.success),
                                    ),
                                  ] else if (isInProgress) ...[
                                    const Text('⚡ ', style: TextStyle(fontSize: 11)),
                                    Text(
                                      'In progress • $completedPhaseTasks/$totalPhaseTasks',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CareerTheme.primaryCyan),
                                    ),
                                  ] else ...[
                                    const Text(
                                      '🔒 Locked',
                                      style: TextStyle(fontSize: 11, color: CareerTheme.lockedText),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: CareerTheme.textSubtle, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // OVERVIEW TAB (SCREEN 4)
  // ==========================================
  Widget _buildOverviewTab(CareerRoadmapModel roadmap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CareerGlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Curriculum Overview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                roadmap.description.isNotEmpty
                    ? roadmap.description
                    : 'A comprehensive, industry-aligned learning path covering foundations, architecture, and real-world implementation.',
                style: const TextStyle(fontSize: 13, color: CareerTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('Estimated Time', '${roadmap.estimatedMonths} Months'),
                  _buildStatItem('Target Level', roadmap.level),
                  _buildStatItem('Category', roadmap.category),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Interactive Skill Graph Link
        CareerGlassCard(
          padding: const EdgeInsets.all(16),
          onTap: () => SkillGraphView.open(context, roadmapId: widget.roadmapId),
          child: const Row(
            children: [
              Icon(Icons.hub_rounded, color: CareerTheme.primaryCyan, size: 24),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Interactive Skill Dependency Graph', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                    SizedBox(height: 2),
                    Text('Inspect prerequisites, parallel skills and DAG hierarchy', style: TextStyle(fontSize: 11, color: CareerTheme.textMuted)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: CareerTheme.primaryCyan, size: 14),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: CareerTheme.textSubtle)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: CareerTheme.primaryCyan)),
      ],
    );
  }
}
