import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/career_provider.dart';
import '../../domain/career_models.dart';
import 'career_pathfinder_view.dart';
import 'career_roadmap_view.dart';
import 'skill_graph_view.dart';
import 'learning_workspace_view.dart';
import 'adaptive_quiz_view.dart';
import 'projects_evidence_view.dart';
import 'job_readiness_view.dart';
import 'interview_prep_view.dart';
import 'document_reader_view.dart';

class CareerHubHomeView extends ConsumerStatefulWidget {
  const CareerHubHomeView({super.key});

  @override
  ConsumerState<CareerHubHomeView> createState() => _CareerHubHomeViewState();
}

class _CareerHubHomeViewState extends ConsumerState<CareerHubHomeView> {
  @override
  Widget build(BuildContext context) {
    final activeRoadmapAsync = ref.watch(activeUserRoadmapProvider);
    final readinessAsync = ref.watch(detailedJobReadinessProvider(null));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.rocket_launch_rounded, color: Color(0xFF818CF8), size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Career Hub',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'AI-Powered Career & Learning Workspace',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology_alt_rounded, color: Color(0xFF38BDF8)),
            tooltip: 'Launch AI Pathfinder',
            onPressed: () => CareerPathfinderView.open(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF94A3B8)),
            tooltip: 'Refresh Workspace',
            onPressed: () {
              ref.invalidate(activeUserRoadmapProvider);
              ref.invalidate(detailedJobReadinessProvider(null));
              ref.invalidate(projectEvidencesProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeUserRoadmapProvider);
          ref.invalidate(detailedJobReadinessProvider(null));
          ref.invalidate(projectEvidencesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. ACTIVE GOAL & SUMMARY SPOTLIGHT
              _buildSpotlightCard(activeRoadmapAsync, readinessAsync),
              const SizedBox(height: 20),

              // 2. NEXT BEST ACTION BANNER
              _buildNextBestActionBar(readinessAsync),
              const SizedBox(height: 24),

              // 3. FEATURE HUB GRID HEADER
              const Text(
                'Career Workspace',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 4),
              const Text(
                'Access your personalized tools, learning modules, and verification engines',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 14),

              // 4. CORE NAVIGATION TILES GRID
              _buildWorkspaceGrid(context, activeRoadmapAsync),
              const SizedBox(height: 24),

              // 5. DOCUMENTATION LIBRARY QUICK ACCESS
              _buildDocsLibraryBanner(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpotlightCard(
    AsyncValue<ActiveRoadmapState?> activeAsync,
    AsyncValue<Map<String, dynamic>> readinessAsync,
  ) {
    return activeAsync.when(
      data: (active) {
        final hasRoadmap = active != null;
        final targetRole = hasRoadmap ? active.targetRole : 'Engineering Student';
        final progress = hasRoadmap ? (active.progressPercent).clamp(0, 100) : 0;
        final roadmapId = active?.roadmapId ?? '';

        final readinessScore = readinessAsync.valueOrNull?['overallScore'] ?? 45;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4338CA).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF818CF8).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars_rounded, color: Color(0xFFFBBF24), size: 14),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              hasRoadmap ? 'Active Career Track' : 'Unassigned Direction',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => CareerPathfinderView.open(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tune_rounded, color: Color(0xFF38BDF8), size: 13),
                          SizedBox(width: 4),
                          Text('Pathfinder', style: TextStyle(fontSize: 11, color: Color(0xFF38BDF8), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                targetRole,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                hasRoadmap
                    ? 'Phase ${active.currentPhaseNumber}: ${active.currentPhaseTitle.isNotEmpty ? active.currentPhaseTitle : "Foundations"}'
                    : 'Take the dynamic 7-stage Pathfinder to generate your roadmap.',
                style: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 18),

              // Progress bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Curriculum Progress ($progress%)',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Readiness: $readinessScore%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF38BDF8)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress / 100.0,
                  minHeight: 8,
                  backgroundColor: const Color(0xFF0F172A),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (hasRoadmap) {
                          CareerRoadmapView.open(context, roadmapId: roadmapId);
                        } else {
                          CareerPathfinderView.open(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(hasRoadmap ? Icons.map_rounded : Icons.explore_rounded, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              hasRoadmap ? 'View Roadmap' : 'Discover Career',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => JobReadinessView.open(context, targetRole: targetRole),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF38BDF8),
                        side: const BorderSide(color: Color(0xFF38BDF8)),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.insights_rounded, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Readiness ($readinessScore%)',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 190,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('Unable to load career spotlight', style: TextStyle(color: Colors.white70)),
      ),
    );
  }

  Widget _buildNextBestActionBar(AsyncValue<Map<String, dynamic>> readinessAsync) {
    final nextAction = readinessAsync.valueOrNull?['nextBestAction'] as Map<String, dynamic>?;
    final title = nextAction?['title'] ?? 'Complete Phase 1 Checkpoint Quiz';
    final desc = nextAction?['description'] ?? 'Validate your foundational knowledge to increase technical readiness by +15%.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bolt_rounded, color: Color(0xFF38BDF8), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Next Best Action',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF38BDF8), letterSpacing: 0.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                      child: const Text('Recommended', style: TextStyle(fontSize: 9, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => AdaptiveQuizView.open(context, topic: 'Core Technical Concepts'),
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF38BDF8), size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceGrid(BuildContext context, AsyncValue<ActiveRoadmapState?> activeAsync) {
    final active = activeAsync.valueOrNull;
    final roadmapId = active?.roadmapId ?? '';
    final targetRole = active?.targetRole ?? 'Software Engineer';

    final items = [
      _WorkspaceItem(
        title: 'AI Pathfinder',
        subtitle: 'Dynamic 7-stage profiling',
        icon: Icons.psychology_rounded,
        gradient: const [Color(0xFF4F46E5), Color(0xFF6366F1)],
        onTap: () => CareerPathfinderView.open(context),
      ),
      _WorkspaceItem(
        title: 'Roadmap & Phases',
        subtitle: 'Chronological timeline',
        icon: Icons.alt_route_rounded,
        gradient: const [Color(0xFF0284C7), Color(0xFF0EA5E9)],
        onTap: () => CareerRoadmapView.open(context, roadmapId: roadmapId),
      ),
      _WorkspaceItem(
        title: 'Interactive Skill Graph',
        subtitle: '2D DAG dependencies',
        icon: Icons.hub_rounded,
        gradient: const [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
        onTap: () => SkillGraphView.open(context, roadmapId: roadmapId),
      ),
      _WorkspaceItem(
        title: 'Learning Workspace',
        subtitle: 'Videos, checklists & notes',
        icon: Icons.laptop_chromebook_rounded,
        gradient: const [Color(0xFF059669), Color(0xFF10B981)],
        onTap: () => LearningWorkspaceView.open(context, topic: 'State Management & Architecture'),
      ),
      _WorkspaceItem(
        title: 'Adaptive Quizzes',
        subtitle: 'Checkpoint skill tests',
        icon: Icons.quiz_rounded,
        gradient: const [Color(0xFFD97706), Color(0xFFF59E0B)],
        onTap: () => AdaptiveQuizView.open(context, topic: 'Core Concepts Checkpoint'),
      ),
      _WorkspaceItem(
        title: 'Projects & Evidence',
        subtitle: 'GitHub repos & live demos',
        icon: Icons.code_rounded,
        gradient: const [Color(0xFFDB2777), Color(0xFFEC4899)],
        onTap: () => ProjectsEvidenceView.open(context),
      ),
      _WorkspaceItem(
        title: 'Job Readiness',
        subtitle: '6 dimensions & radar score',
        icon: Icons.speed_rounded,
        gradient: const [Color(0xFF2563EB), Color(0xFF3B82F6)],
        onTap: () => JobReadinessView.open(context, targetRole: targetRole),
      ),
      _WorkspaceItem(
        title: 'EVA AI Interview',
        subtitle: '1-on-1 mock practice',
        icon: Icons.record_voice_over_rounded,
        gradient: const [Color(0xFF9333EA), Color(0xFFA855F7)],
        onTap: () => InterviewPrepView.open(context, targetRole: targetRole, roadmapId: roadmapId),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: item.gradient),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: Colors.white, size: 20),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocsLibraryBanner(BuildContext context) {
    final docsAsync = ref.watch(verifiedDocumentsProvider);

    return Container(
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
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.auto_stories_rounded, color: Color(0xFF38BDF8), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Verified Documentation Library',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF38BDF8).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: const Text('6 Curated Books', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF38BDF8))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Official reference handbooks across IoT, C++, Flutter, Python, Node.js & DSA.',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),
          docsAsync.when(
            data: (docs) {
              if (docs.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final doc = docs[idx];
                    return ActionChip(
                      backgroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFF475569)),
                      avatar: const Icon(Icons.book_rounded, size: 14, color: Color(0xFF818CF8)),
                      label: Text(doc.title, style: const TextStyle(fontSize: 11, color: Colors.white)),
                      onPressed: () => DocumentReaderView.open(context, document: doc),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(height: 30, child: LinearProgressIndicator(color: Color(0xFF6366F1))),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  _WorkspaceItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
}
