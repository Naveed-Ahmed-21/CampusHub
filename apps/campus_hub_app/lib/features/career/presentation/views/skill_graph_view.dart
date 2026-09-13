import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/career_models.dart';
import '../providers/career_provider.dart';
import '../theme/career_theme.dart';
import '../widgets/career_shared_widgets.dart';
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
  int _selectedViewTab = 0; // 0 = Graph, 1 = List

  @override
  Widget build(BuildContext context) {
    final graphAsync = ref.watch(skillGraphProvider(widget.roadmapId));

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
          'Skill Graph',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CareerSegmentedControl(
              segments: const ['Graph', 'List'],
              selectedIndex: _selectedViewTab,
              onSegmentSelected: (idx) => setState(() => _selectedViewTab = idx),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: graphAsync.when(
          data: (graph) {
            if (_selectedViewTab == 0) {
              return _buildGraphCanvas(graph);
            } else {
              return _buildListView(graph);
            }
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: CareerTheme.primaryCyan),
          ),
          error: (_, __) => _buildFallbackGraph(),
        ),
      ),
      bottomNavigationBar: _buildLegendBar(),
    );
  }

  // ==========================================
  // GRAPH CANVAS (SCREEN 9)
  // ==========================================
  Widget _buildGraphCanvas(SkillGraphModel graph) {
    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(80),
      minScale: 0.6,
      maxScale: 2.2,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Root Node: Domain (e.g. Frontend Development)
              _buildNodeBadge(
                title: 'Frontend Development',
                status: 'current',
                isRoot: true,
              ),
              _buildVerticalConnector(),

              // Level 1: Core Primitives (HTML/CSS -> JavaScript -> React)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildNodeBadge(title: 'HTML/CSS', status: 'completed'),
                  _buildHorizontalConnector(),
                  _buildNodeBadge(title: 'JavaScript', status: 'completed'),
                  _buildHorizontalConnector(),
                  _buildNodeBadge(title: 'React', status: 'current'),
                ],
              ),
              _buildVerticalConnector(),

              // Central Hub: React
              _buildNodeBadge(title: 'React Core', status: 'current'),
              _buildVerticalConnector(),

              // Level 2: Advanced Branches (Next.js, State Mgmt, API Integration)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildNodeBadge(title: 'Next.js', status: 'locked'),
                  const SizedBox(width: 12),
                  _buildNodeBadge(title: 'State Mgmt', status: 'current'),
                  const SizedBox(width: 12),
                  _buildNodeBadge(title: 'API Integration', status: 'locked'),
                ],
              ),
              _buildVerticalConnector(),

              // Level 3: Capstone Deliverable (Full Stack Project)
              _buildNodeBadge(
                title: 'Full Stack Project',
                status: 'locked',
                isCapstone: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNodeBadge({
    required String title,
    required String status,
    bool isRoot = false,
    bool isCapstone = false,
  }) {
    Color borderColor = CareerTheme.glassBorder;
    Color bgColor = CareerTheme.surface;
    Color textColor = CareerTheme.textSecondary;

    if (status == 'completed') {
      borderColor = CareerTheme.success;
      bgColor = CareerTheme.success.withValues(alpha: 0.15);
      textColor = Colors.white;
    } else if (status == 'current') {
      borderColor = CareerTheme.primaryCyan;
      bgColor = CareerTheme.primaryCyan.withValues(alpha: 0.2);
      textColor = Colors.white;
    } else {
      borderColor = CareerTheme.locked.withValues(alpha: 0.4);
      bgColor = CareerTheme.surfaceElevated;
      textColor = CareerTheme.lockedText;
    }

    return GestureDetector(
      onTap: () {
        SkillDetailView.open(
          context,
          skillName: title,
          roadmapId: widget.roadmapId,
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isRoot || isCapstone ? 20 : 14,
          vertical: isRoot || isCapstone ? 12 : 9,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(CareerTheme.radiusPill),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: status == 'current'
              ? [
                  BoxShadow(
                    color: CareerTheme.primaryCyan.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == 'completed') ...[
              const Icon(Icons.check, size: 13, color: CareerTheme.success),
              const SizedBox(width: 5),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: isRoot || isCapstone ? 13 : 12,
                fontWeight: isRoot || isCapstone ? FontWeight.w800 : FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalConnector() {
    return Container(
      width: 2,
      height: 24,
      color: CareerTheme.primaryCyan.withValues(alpha: 0.5),
      margin: const EdgeInsets.symmetric(vertical: 2),
    );
  }

  Widget _buildHorizontalConnector() {
    return Container(
      width: 14,
      height: 2,
      color: CareerTheme.primaryCyan.withValues(alpha: 0.5),
      margin: const EdgeInsets.symmetric(horizontal: 2),
    );
  }

  // ==========================================
  // LIST VIEW (SCREEN 9 TOGGLE)
  // ==========================================
  Widget _buildListView(SkillGraphModel graph) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: graph.nodes.length,
      itemBuilder: (context, idx) {
        final node = graph.nodes[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: CareerGlassCard(
            padding: const EdgeInsets.all(14),
            borderRadius: CareerTheme.radiusMedium,
            onTap: () => SkillDetailView.open(context, skillName: node.title, roadmapId: widget.roadmapId),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: node.isCompleted
                        ? CareerTheme.success.withValues(alpha: 0.2)
                        : CareerTheme.primaryCyan.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    node.isCompleted ? Icons.check : Icons.circle_outlined,
                    size: 14,
                    color: node.isCompleted ? CareerTheme.success : CareerTheme.primaryCyan,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(node.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(node.description, style: const TextStyle(fontSize: 11, color: CareerTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: CareerTheme.textSubtle, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // BOTTOM LEGEND BAR (SCREEN 9)
  // ==========================================
  Widget _buildLegendBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: CareerTheme.surface,
        border: const Border(top: BorderSide(color: CareerTheme.glassBorder)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _LegendItem(color: CareerTheme.success, label: 'Completed'),
          _LegendItem(color: CareerTheme.primaryCyan, label: 'Current'),
          _LegendItem(color: CareerTheme.locked, label: 'Locked'),
        ],
      ),
    );
  }

  Widget _buildFallbackGraph() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hub_rounded, size: 48, color: CareerTheme.primaryCyan),
          const SizedBox(height: 12),
          const Text('Skill graph is active', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          CareerPrimaryButton(
            label: 'Reload Graph',
            width: 140,
            onPressed: () => ref.invalidate(skillGraphProvider(widget.roadmapId)),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CareerTheme.textMuted),
        ),
      ],
    );
  }
}
