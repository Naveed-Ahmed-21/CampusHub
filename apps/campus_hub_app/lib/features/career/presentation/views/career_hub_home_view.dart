import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/career_provider.dart';
import '../../domain/career_models.dart';
import '../theme/career_theme.dart';
import '../widgets/career_shared_widgets.dart';
import 'create_roadmap_view.dart';
import 'career_pathfinder_view.dart';
import 'career_roadmap_view.dart';
import 'skill_graph_view.dart';
import 'projects_evidence_view.dart';
import 'job_readiness_view.dart';
import 'interview_prep_view.dart';

class CareerHubHomeView extends ConsumerStatefulWidget {
  const CareerHubHomeView({super.key});

  @override
  ConsumerState<CareerHubHomeView> createState() => _CareerHubHomeViewState();
}

class _CareerHubHomeViewState extends ConsumerState<CareerHubHomeView> {
  @override
  Widget build(BuildContext context) {
    final activeRoadmapAsync = ref.watch(activeUserRoadmapProvider);

    return Scaffold(
      backgroundColor: CareerTheme.background,
      appBar: AppBar(
        backgroundColor: CareerTheme.background,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: CareerTheme.accentIndigo.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CareerTheme.accentIndigo.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.school_rounded, color: CareerTheme.primaryCyan, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'CampusHub',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white70, size: 22),
            onPressed: () => CreateRoadmapView.open(context),
          ),
          IconButton(
            icon: const Icon(Icons.psychology_alt_rounded, color: CareerTheme.primaryCyan, size: 22),
            tooltip: 'AI Pathfinder',
            onPressed: () => CareerPathfinderView.open(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: CareerTheme.primaryCyan,
        backgroundColor: CareerTheme.surfaceSecondary,
        onRefresh: () async {
          ref.invalidate(activeUserRoadmapProvider);
          ref.invalidate(detailedJobReadinessProvider(null));
          ref.invalidate(projectEvidencesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. GREETING HEADER
              const Text(
                'Hi, Alex 👋',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                "Let's build your future.",
                style: TextStyle(fontSize: 13, color: CareerTheme.textMuted),
              ),
              const SizedBox(height: 20),

              // 2. HERO CARD — AI ROADMAP GENERATOR
              _buildHeroAiCard(context),
              const SizedBox(height: 24),

              // 3. ACTIVE ROADMAPS
              _buildActiveRoadmapsSection(context, activeRoadmapAsync),
              const SizedBox(height: 24),

              // 4. QUICK ACTIONS
              const Text(
                'Quick Actions',
                style: CareerTheme.sectionHeader,
              ),
              const SizedBox(height: 12),
              _buildQuickActionsGrid(context, activeRoadmapAsync),
              const SizedBox(height: 24),

              // 5. POPULAR CAMPUS TRACKS
              _buildPopularTracksSection(context),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HERO CARD (SCREEN 1)
  // ==========================================
  Widget _buildHeroAiCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E1B4B), // Deep Indigo
            Color(0xFF2E1065), // Rich Violet
            Color(0xFF0F172A), // Slate Dark
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: CareerTheme.accentLavender.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: CareerTheme.accentIndigo.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'AI Roadmap Generator',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Personalized, Practical. Powered by AI.',
                  style: TextStyle(
                    fontSize: 12,
                    color: CareerTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => CreateRoadmapView.open(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: CareerTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(CareerTheme.radiusPill),
                      boxShadow: [
                        BoxShadow(
                          color: CareerTheme.primaryCyan.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Create New Roadmap',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Right Glowing AI Orb
          const CareerAIOrb(
            size: 76,
            showText: true,
            text: 'AI',
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ACTIVE ROADMAPS SECTION (SCREEN 1)
  // ==========================================
  Widget _buildActiveRoadmapsSection(
    BuildContext context,
    AsyncValue<ActiveRoadmapState?> activeAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Active Roadmaps', style: CareerTheme.sectionHeader),
            GestureDetector(
              onTap: () {
                final active = activeAsync.valueOrNull;
                if (active != null) {
                  CareerRoadmapView.open(context, roadmapId: active.roadmapId);
                } else {
                  CreateRoadmapView.open(context);
                }
              },
              child: const Text(
                'See all',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CareerTheme.primaryCyan),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        activeAsync.when(
          data: (active) {
            if (active == null) {
              return CareerGlassCard(
                padding: const EdgeInsets.all(16),
                onTap: () => CreateRoadmapView.open(context),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: CareerTheme.primaryCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CareerTheme.primaryCyan.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.add_road_rounded, color: CareerTheme.primaryCyan, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No active roadmap yet',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Tap to generate your personalized learning roadmap',
                            style: TextStyle(fontSize: 11, color: CareerTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: CareerTheme.primaryCyan, size: 20),
                  ],
                ),
              );
            }

            final role = active.targetRole;
            final progress = (active.progressPercent).clamp(0, 100);
            final roadmapId = active.roadmapId;

            return CareerGlassCard(
              padding: const EdgeInsets.all(16),
              onTap: () => CareerRoadmapView.open(context, roadmapId: roadmapId),
              child: Row(
                children: [
                  // Role Icon Box
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: CareerTheme.accentIndigo.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CareerTheme.accentIndigo.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.code_rounded, color: CareerTheme.primaryCyan, size: 22),
                  ),
                  const SizedBox(width: 14),

                  // Role Details & Progress
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'In Progress • $progress%',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CareerTheme.primaryCyan),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress / 100.0,
                            minHeight: 5,
                            backgroundColor: CareerTheme.surfaceElevated,
                            valueColor: const AlwaysStoppedAnimation<Color>(CareerTheme.primaryCyan),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Trailing Chevron
                  const Icon(Icons.chevron_right_rounded, color: CareerTheme.textSubtle, size: 22),
                ],
              ),
            );
          },
          loading: () => Container(
            height: 76,
            decoration: BoxDecoration(
              color: CareerTheme.surface,
              borderRadius: BorderRadius.circular(CareerTheme.radiusLarge),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: CareerTheme.primaryCyan),
            ),
          ),
          error: (_, __) => CareerGlassCard(
            padding: const EdgeInsets.all(16),
            child: const Text('Connect to create your first roadmap.', style: TextStyle(color: CareerTheme.textMuted)),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // QUICK ACTIONS (SCREEN 1)
  // ==========================================
  Widget _buildQuickActionsGrid(
    BuildContext context,
    AsyncValue<ActiveRoadmapState?> activeAsync,
  ) {
    final roadmapId = activeAsync.valueOrNull?.roadmapId ?? '';
    final targetRole = activeAsync.valueOrNull?.targetRole ?? 'Software Engineer';

    final actions = [
      _QuickActionItem(
        label: 'Explore\nTracks',
        icon: Icons.explore_rounded,
        color: const Color(0xFF8B5CF6), // Purple
        onTap: () => CareerPathfinderView.open(context),
      ),
      _QuickActionItem(
        label: 'Skills',
        icon: Icons.bolt_rounded,
        color: const Color(0xFF10B981), // Mint
        onTap: () => SkillGraphView.open(context, roadmapId: roadmapId),
      ),
      _QuickActionItem(
        label: 'Projects',
        icon: Icons.folder_rounded,
        color: const Color(0xFF0EA5E9), // Cyan
        onTap: () => ProjectsEvidenceView.open(context),
      ),
      _QuickActionItem(
        label: 'Interview\nPrep',
        icon: Icons.mic_rounded,
        color: const Color(0xFFF59E0B), // Orange
        onTap: () => InterviewPrepView.open(context, targetRole: targetRole, roadmapId: roadmapId),
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GestureDetector(
              onTap: item.onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: CareerTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CareerTheme.glassBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: item.color, size: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==========================================
  // POPULAR CAMPUS TRACKS (SCREEN 1)
  // ==========================================
  Widget _buildPopularTracksSection(BuildContext context) {
    final tracks = [
      _TrackCardData(
        title: 'Campus\nPlacement',
        icon: Icons.school_rounded,
        gradient: const [Color(0xFF4338CA), Color(0xFF312E81)],
        initialTrack: 'Campus Placement & Core Engineering',
      ),
      _TrackCardData(
        title: 'Higher\nStudies',
        icon: Icons.history_edu_rounded,
        gradient: const [Color(0xFF0F766E), Color(0xFF134E4A)],
        initialTrack: 'Higher Studies, GATE & Research',
      ),
      _TrackCardData(
        title: 'Research &\nInnovation',
        icon: Icons.auto_awesome_rounded,
        gradient: const [Color(0xFF0369A1), Color(0xFF0C4A6E)],
        initialTrack: 'Research, Patents & Deep Tech Innovation',
      ),
      _TrackCardData(
        title: 'FAANG &\nProduct',
        icon: Icons.terminal_rounded,
        gradient: const [Color(0xFF7E22CE), Color(0xFF581C87)],
        initialTrack: 'FAANG Software Engineering & System Design',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Popular Campus Tracks', style: CareerTheme.sectionHeader),
            GestureDetector(
              onTap: () => CreateRoadmapView.open(context),
              child: const Text(
                'See all',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CareerTheme.primaryCyan),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tracks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, idx) {
              final track = tracks[idx];
              return GestureDetector(
                onTap: () {
                  if (idx == 0) {
                    JobReadinessView.open(context);
                  } else {
                    CreateRoadmapView.open(context, initialTrack: track.initialTrack);
                  }
                },
                child: Container(
                  width: 118,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: track.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(track.icon, color: Colors.white, size: 24),
                      Text(
                        track.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuickActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _QuickActionItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _TrackCardData {
  final String title;
  final IconData icon;
  final List<Color> gradient;
  final String initialTrack;

  _TrackCardData({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.initialTrack,
  });
}
