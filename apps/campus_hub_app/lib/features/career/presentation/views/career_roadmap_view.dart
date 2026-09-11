import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/career_repository.dart';
import '../../domain/career_models.dart';
import '../providers/career_provider.dart';
import 'skill_graph_view.dart';
import 'skill_detail_view.dart';
import 'adaptive_quiz_view.dart';

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

  Future<void> _toggleNode(String nodeId) async {
    final isCurrentlyCompleted = _completedNodes.contains(nodeId);
    setState(() {
      if (isCurrentlyCompleted) {
        _completedNodes.remove(nodeId);
      } else {
        _completedNodes.add(nodeId);
      }
    });

    try {
      final repo = ref.read(careerRepositoryProvider);
      await repo.toggleNodeProgress(nodeId, !isCurrentlyCompleted);
      ref.invalidate(activeUserRoadmapProvider);
      ref.invalidate(detailedJobReadinessProvider(null));
    } catch (e) {
      // Revert on failure
      setState(() {
        if (isCurrentlyCompleted) {
          _completedNodes.add(nodeId);
        } else {
          _completedNodes.remove(nodeId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          leading: const BackButton(color: Colors.white),
          title: const Text('Personalized Roadmap', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );
    }

    if (_errorMessage != null || _roadmap == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          leading: const BackButton(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'Roadmap not found', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadRoadmap,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final roadmap = _roadmap!;
    final phases = roadmap.phases;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              roadmap.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${roadmap.category} • ${roadmap.level}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.hub_rounded, color: Color(0xFF38BDF8)),
            tooltip: 'View Interactive Skill Graph',
            onPressed: () => SkillGraphView.open(context, roadmapId: widget.roadmapId),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF38BDF8)),
                          const SizedBox(width: 6),
                          Text(
                            'Estimated ${roadmap.estimatedMonths} Months',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF38BDF8)),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => SkillGraphView.open(context, roadmapId: widget.roadmapId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1).withOpacity(0.2),
                          foregroundColor: const Color(0xFF818CF8),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Color(0xFF6366F1)),
                          ),
                        ),
                        icon: const Icon(Icons.account_tree_rounded, size: 14),
                        label: const Text('Skill Graph', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    roadmap.description,
                    style: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Phases header
            const Text(
              'Chronological Phases',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 12),

            // Phase cards
            if (phases.isEmpty && roadmap.nodes.isNotEmpty)
              _buildFlatNodesList(roadmap.nodes)
            else
              ...phases.asMap().entries.map((entry) {
                final idx = entry.key;
                final phase = entry.value;
                return _buildPhaseCard(idx + 1, phase, roadmap.nodes);
              }),

            const SizedBox(height: 40),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => SkillGraphView.open(context, roadmapId: widget.roadmapId),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.hub_rounded),
        label: const Text('Interactive DAG Graph', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildPhaseCard(int phaseNumber, RoadmapPhaseDetailModel phase, List<RoadmapNodeModel> allNodes) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: phaseNumber == 1,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'P$phaseNumber',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF818CF8)),
            ),
          ),
          title: Text(
            phase.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          subtitle: Text(
            'Weeks ${phase.weeks} • ${phase.tasks.length} Modules',
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Color(0xFF334155)),
                  const SizedBox(height: 6),
                  Text(
                    phase.description,
                    style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1), height: 1.35),
                  ),
                  const SizedBox(height: 14),

                  // Practical Milestone Project Card
                  if (phase.project != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.code_rounded, size: 15, color: Color(0xFFEC4899)),
                              const SizedBox(width: 6),
                              const Text('Milestone Deliverable', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFEC4899))),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFEC4899).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                child: Text(phase.project!.difficulty, style: const TextStyle(fontSize: 9, color: Color(0xFFEC4899), fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(phase.project!.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text(phase.project!.description, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Checkpoint Quiz CTA Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Checkpoint Test:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          AdaptiveQuizView.open(
                            context,
                            topic: '${phase.title} Checkpoint',
                            phaseNumber: phaseNumber,
                            roadmapId: widget.roadmapId,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF59E0B),
                          side: const BorderSide(color: Color(0xFFF59E0B)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.quiz_rounded, size: 14),
                        label: const Text('Take Phase Quiz', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Phase Topics / Tasks List
                  ...phase.tasks.map((task) {
                    final matchingNode = allNodes.firstWhere(
                      (n) => n.title.toLowerCase() == task.title.toLowerCase() || n.title.contains(task.title),
                      orElse: () => RoadmapNodeModel(
                        id: task.id,
                        roadmapId: widget.roadmapId,
                        title: task.title,
                        description: task.description,
                        orderIndex: 1,
                      ),
                    );

                    final isDone = _completedNodes.contains(matchingNode.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Checkbox(
                          value: isDone,
                          activeColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (_) => _toggleNode(matchingNode.id),
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDone ? const Color(0xFF94A3B8) : Colors.white,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Text(
                          task.keyTopics.take(2).join(' • '),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF64748B)),
                        onTap: () {
                          SkillDetailView.open(
                            context,
                            skillName: task.title,
                            roadmapId: widget.roadmapId,
                            description: task.description,
                            phaseNumber: phaseNumber,
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlatNodesList(List<RoadmapNodeModel> nodes) {
    return Column(
      children: nodes.map((node) {
        final isDone = _completedNodes.contains(node.id);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: ListTile(
            leading: Checkbox(
              value: isDone,
              activeColor: const Color(0xFF10B981),
              onChanged: (_) => _toggleNode(node.id),
            ),
            title: Text(node.title, style: const TextStyle(color: Colors.white, fontSize: 13)),
            subtitle: Text(node.description ?? '', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF64748B)),
            onTap: () {
              SkillDetailView.open(
                context,
                skillName: node.title,
                roadmapId: widget.roadmapId,
                description: node.description ?? '',
              );
            },
          ),
        );
      }).toList(),
    );
  }
}
