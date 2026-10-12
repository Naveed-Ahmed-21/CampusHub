import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/career_repository.dart';
import '../../domain/career_models.dart';
import '../providers/career_provider.dart';
import '../theme/career_theme.dart';
import '../widgets/career_shared_widgets.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
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
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF16181C) : Colors.white,
          title: Text(
            'Delete Roadmap?',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${_roadmap?.title ?? 'this roadmap'}"? All progress associated with this track will be removed.',
            style: TextStyle(
              color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
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
            backgroundColor: AppColors.success,
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
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: const CampusAppBar(
          title: 'Career Roadmap',
          leading: CampusBackButton(),
        ),
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: isDark ? Colors.white : AppColors.pureBlack,
          ),
        ),
      );
    }

    if (_errorMessage != null || _roadmap == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: const CampusAppBar(
          title: 'Career Roadmap',
          leading: CampusBackButton(),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Roadmap not found',
                  style: TextStyle(
                    color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
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

    final iconColor = isDark ? Colors.white : AppColors.primaryText;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CampusAppBar(
        title: roadmap.targetRole,
        subtitle: 'Roadmap & Milestones',
        leading: const CampusBackButton(),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isBookmarked
                  ? (isDark ? Colors.white : AppColors.pureBlack)
                  : (isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
            ),
            onPressed: () => setState(() => _isBookmarked = !_isBookmarked),
          ),
          IconButton(
            icon: Icon(Icons.hub_rounded, color: iconColor),
            tooltip: 'Skill Graph',
            onPressed: () => SkillGraphView.open(context, roadmapId: widget.roadmapId),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
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
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.primaryText,
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$estimatedWeeks Weeks • ${phases.isNotEmpty ? phases.length : 8} Milestones',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
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
                    progressColor: isDark ? Colors.white : AppColors.pureBlack,
                    backgroundColor: isDark ? AppColors.darkElevatedSurface : const Color(0xFFE2E8F0),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (phases.isEmpty && allNodes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No milestones available in this roadmap.',
            style: TextStyle(color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
          ),
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

    // Precalculate phase completion for sequential unlock progression
    final phaseCompletion = <int, bool>{};
    for (int i = 0; i < itemCount; i++) {
      int totalTasks = 1;
      int completedTasks = 0;
      if (phases.isNotEmpty) {
        final phase = phases[i];
        totalTasks = phase.tasks.isNotEmpty ? phase.tasks.length : 1;
        for (final t in phase.tasks) {
          if (_completedNodes.contains(t.id)) completedTasks++;
        }
      } else {
        final node = allNodes[i];
        if (_completedNodes.contains(node.id)) completedTasks = 1;
      }
      phaseCompletion[i] = completedTasks >= totalTasks && totalTasks > 0;
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

        // Sequential unlocking progression:
        // - Phase 0 is unlocked by default.
        // - Phase idx > 0 ONLY unlocks if phase idx - 1 is completed (or completed tasks > 0).
        final isCompleted = phaseCompletion[idx] ?? false;
        final prevPhaseCompleted = idx == 0 || (phaseCompletion[idx - 1] ?? false);
        final isInProgress = !isCompleted && prevPhaseCompleted;
        final isLocked = !isCompleted && !isInProgress;

        Color badgeColor;
        Widget badgeIcon = Text(
          '$phaseNumber',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isCompleted
                ? Colors.white
                : (isInProgress
                    ? (isDark ? Colors.black : Colors.white)
                    : (isDark ? AppColors.darkSecondaryText : AppColors.secondaryText)),
          ),
        );

        if (isCompleted) {
          badgeColor = AppColors.success;
        } else if (isInProgress) {
          badgeColor = isDark ? Colors.white : AppColors.pureBlack;
        } else {
          badgeColor = isDark ? AppColors.darkElevatedSurface : const Color(0xFFE2E8F0);
          badgeIcon = Icon(
            Icons.lock_rounded,
            size: 12,
            color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
          );
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
                      border: isLocked
                          ? Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0))
                          : null,
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
                            ? AppColors.success.withValues(alpha: 0.5)
                            : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
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
                                      ? AppColors.success
                                      : (isInProgress
                                          ? (isDark ? Colors.white : AppColors.primaryText)
                                          : (isDark ? AppColors.darkSecondaryText : AppColors.secondaryText)),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : AppColors.primaryText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (isCompleted) ...[
                                    const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
                                    const SizedBox(width: 4),
                                    Text(
                                      '✓ $totalPhaseTasks/$totalPhaseTasks completed',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success),
                                    ),
                                  ] else if (isInProgress) ...[
                                    const Text('⚡ ', style: TextStyle(fontSize: 11)),
                                    Text(
                                      'In progress • $completedPhaseTasks/$totalPhaseTasks',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : AppColors.primaryText,
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      '🔒 Locked',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                          size: 20,
                        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CareerGlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Curriculum Overview',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                roadmap.description.isNotEmpty
                    ? roadmap.description
                    : 'A comprehensive, industry-aligned learning path covering foundations, architecture, and real-world implementation.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('Estimated Time', '${roadmap.estimatedMonths} Months', isDark),
                  _buildStatItem('Target Level', roadmap.level, isDark),
                  _buildStatItem('Category', roadmap.category, isDark),
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
          child: Row(
            children: [
              Icon(Icons.hub_rounded, color: isDark ? Colors.white : AppColors.primaryText, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interactive Skill Dependency Graph',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Inspect prerequisites, parallel skills and DAG hierarchy',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: isDark ? Colors.white : AppColors.primaryText,
                size: 14,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.primaryText,
          ),
        ),
      ],
    );
  }
}
