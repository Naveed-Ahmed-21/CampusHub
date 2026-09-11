import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/career_provider.dart';
import '../../domain/career_models.dart';
import 'skill_detail_view.dart';

class SkillGraphView extends ConsumerStatefulWidget {
  final String roadmapId;

  const SkillGraphView({
    super.key,
    required this.roadmapId,
  });

  static void open(BuildContext context, {required String roadmapId}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SkillGraphView(roadmapId: roadmapId),
      ),
    );
  }

  @override
  ConsumerState<SkillGraphView> createState() => _SkillGraphViewState();
}

class _SkillGraphViewState extends ConsumerState<SkillGraphView> {
  String? _selectedSkill;

  @override
  Widget build(BuildContext context) {
    final graphAsync = ref.watch(skillGraphProvider(widget.roadmapId));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interactive Skill Graph',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            Text(
              '2D Prerequisite & Dependency DAG',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
      body: graphAsync.when(
        data: (graph) {
          if (graph.nodes.isEmpty) {
            return const Center(
              child: Text('No skill graph nodes found', style: TextStyle(color: Colors.white70)),
            );
          }

          return Column(
            children: [
              // Legend
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: const Color(0xFF1E293B),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem('Foundations', const Color(0xFF6366F1)),
                    _buildLegendItem('Core Protocols', const Color(0xFF38BDF8)),
                    _buildLegendItem('Advanced Capstone', const Color(0xFF10B981)),
                  ],
                ),
              ),

              // Interactive DAG Graph Canvas
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Render nodes as a directed vertical flow with prerequisite connector lines
                      ...graph.nodes.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final node = entry.value;
                        final isLast = idx == graph.nodes.length - 1;

                        // Find matching incoming or outgoing dependency
                        final outgoing = graph.edges.where((e) => e.sourceSkill == node.title).toList();

                        return Column(
                          children: [
                            _buildGraphNodeCard(node, outgoing),
                            if (!isLast) _buildConnectorArrow(outgoing),
                          ],
                        );
                      }),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
        error: (err, _) => Center(
          child: Text('Error loading skill graph: $err', style: const TextStyle(color: Colors.white70)),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1), fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildGraphNodeCard(SkillGraphNode node, List<SkillGraphEdge> outgoing) {
    final isHighlighted = _selectedSkill == node.title;

    Color badgeColor = const Color(0xFF6366F1);
    if (node.orderIndex > 4) {
      badgeColor = const Color(0xFF10B981);
    } else if (node.orderIndex > 2) {
      badgeColor = const Color(0xFF38BDF8);
    }

    return InkWell(
      onTap: () {
        setState(() => _selectedSkill = node.title);
        _showNodeDetailsSheet(node);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted ? const Color(0xFF38BDF8) : const Color(0xFF334155),
            width: isHighlighted ? 2 : 1,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: badgeColor.withOpacity(0.4)),
              ),
              child: Text(
                '${node.orderIndex}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: badgeColor),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    node.description.isNotEmpty ? node.description : 'Prerequisite skill for advanced concepts',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${node.estimatedHours}h',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFCBD5E1)),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectorArrow(List<SkillGraphEdge> outgoing) {
    return SizedBox(
      height: 38,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 2,
            height: 18,
            color: const Color(0xFF6366F1).withOpacity(0.6),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: Color(0xFF818CF8),
          ),
        ],
      ),
    );
  }

  void _showNodeDetailsSheet(SkillGraphNode node) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      node.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                node.description.isNotEmpty ? node.description : 'Prerequisite skill component in active curriculum graph.',
                style: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1), height: 1.4),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 6),
                  Text('Estimated Mastery Time: ${node.estimatedHours} Hours', style: const TextStyle(fontSize: 12, color: Color(0xFF38BDF8))),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    SkillDetailView.open(
                      context,
                      skillName: node.title,
                      roadmapId: widget.roadmapId,
                      description: node.description,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Open Skill Detail & Resources', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
