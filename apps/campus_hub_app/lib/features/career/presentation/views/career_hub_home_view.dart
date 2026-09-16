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
import 'user_roadmaps_list_view.dart';

class CareerHubHomeView extends ConsumerStatefulWidget {
  const CareerHubHomeView({super.key});

  @override
  ConsumerState<CareerHubHomeView> createState() => _CareerHubHomeViewState();
}

class _CareerHubHomeViewState extends ConsumerState<CareerHubHomeView> {
  @override
  Widget build(BuildContext context) {
    final activeRoadmapAsync = ref.watch(activeUserRoadmapProvider);
    final userRoadmapsAsync = ref.watch(userRoadmapsProvider);

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
          ref.invalidate(userRoadmapsProvider);
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
              _buildActiveRoadmapsSection(context, activeRoadmapAsync, userRoadmapsAsync),
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
    AsyncValue<List<UserRoadmapItemModel>> roadmapsAsync,
  ) {
    final roadmaps = roadmapsAsync.valueOrNull ?? [];
    final roadmapsCount = roadmaps.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Active Roadmaps', style: CareerTheme.sectionHeader),
            GestureDetector(
              onTap: () {
                UserRoadmapsListView.open(context);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'See all',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CareerTheme.primaryCyan),
                  ),
                  if (roadmapsCount > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: CareerTheme.primaryCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$roadmapsCount',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: CareerTheme.primaryCyan),
                      ),
                    ),
                  ],
                  const SizedBox(width: 3),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: CareerTheme.primaryCyan),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        activeAsync.when(
          data: (active) {
            if (active == null) {
              final hasSavedRoadmaps = roadmaps.isNotEmpty;
              return CareerGlassCard(
                padding: const EdgeInsets.all(16),
                onTap: () {
                  if (hasSavedRoadmaps) {
                    UserRoadmapsListView.open(context);
                  } else {
                    CreateRoadmapView.open(context);
                  }
                },
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
                      child: Icon(
                        hasSavedRoadmaps ? Icons.alt_route_rounded : Icons.add_road_rounded,
                        color: CareerTheme.primaryCyan,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasSavedRoadmaps ? 'Saved Roadmaps Available' : 'No active roadmap yet',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            hasSavedRoadmaps
                                ? 'Tap to view all roadmaps and select your active focus track'
                                : 'Tap to generate your personalized learning roadmap',
                            style: const TextStyle(fontSize: 11, color: CareerTheme.textMuted),
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
              onTap: () => _showPopularTracksExplorer(context),
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

  void _showPopularTracksExplorer(BuildContext context) {
    final allTracks = [
      {
        'title': 'FAANG Software Engineering',
        'subtitle': 'System design, advanced data structures, dynamic programming & high-frequency interview questions.',
        'duration': '24 Weeks',
        'level': 'Advanced',
        'skills': ['System Design', 'DSA', 'Concurrency', 'Low-Level Design'],
        'icon': Icons.apartment_rounded,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'title': 'Modern Full-Stack & Cloud Engineer',
        'subtitle': 'Production-ready web engineering from responsive frontend to scalable microservices.',
        'duration': '20 Weeks',
        'level': 'Intermediate',
        'skills': ['React/Next.js', 'Node.js', 'PostgreSQL', 'Docker', 'AWS'],
        'icon': Icons.layers_rounded,
        'color': const Color(0xFF0284C7),
      },
      {
        'title': 'Mobile Engineering (Flutter & Cross-Platform)',
        'subtitle': 'Production Flutter apps, reactive state architectures, offline sync & native platform channels.',
        'duration': '16 Weeks',
        'level': 'Intermediate',
        'skills': ['Flutter', 'Dart', 'Riverpod', 'REST/GraphQL', 'CI/CD'],
        'icon': Icons.phone_android_rounded,
        'color': const Color(0xFF0EA5E9),
      },
      {
        'title': 'Backend & Cloud Infrastructure Architect',
        'subtitle': 'Distributed consensus, message queues, container orchestration, caching & high throughput APIs.',
        'duration': '22 Weeks',
        'level': 'Advanced',
        'skills': ['Go / Node.js', 'Kubernetes', 'Redis', 'Kafka', 'PostgreSQL'],
        'icon': Icons.dns_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'AI, Machine Learning & MLOps',
        'subtitle': 'Deep learning pipelines, transformers, LLM integrations, embeddings and model deployment.',
        'duration': '24 Weeks',
        'level': 'Advanced',
        'skills': ['PyTorch', 'Transformers', 'LangChain', 'Vector DBs', 'FastAPI'],
        'icon': Icons.psychology_rounded,
        'color': const Color(0xFFEC4899),
      },
      {
        'title': 'Data Engineering & Analytics Pipelines',
        'subtitle': 'Large-scale ETL architectures, stream processing, distributed databases and data modeling.',
        'duration': '20 Weeks',
        'level': 'Intermediate',
        'skills': ['Apache Spark', 'SQL', 'Kafka', 'dbt', 'Snowflake'],
        'icon': Icons.query_stats_rounded,
        'color': const Color(0xFFF59E0B),
      },
      {
        'title': 'Cyber Security & DevSecOps',
        'subtitle': 'Defensive security, penetration testing, zero-trust infrastructure, and automated vulnerability scanning.',
        'duration': '18 Weeks',
        'level': 'Intermediate',
        'skills': ['Network Security', 'OWASP Top 10', 'Pen Testing', 'Cloud IAM'],
        'icon': Icons.shield_rounded,
        'color': const Color(0xFFEF4444),
      },
      {
        'title': 'Embedded Systems & IoT Engineering',
        'subtitle': 'Hardware-software integration, RTOS task management, sensor fusion and low-power communication.',
        'duration': '18 Weeks',
        'level': 'Intermediate',
        'skills': ['C/C++', 'ESP32/Arduino', 'FreeRTOS', 'MQTT', 'I2C/SPI'],
        'icon': Icons.memory_rounded,
        'color': const Color(0xFF14B8A6),
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CareerTheme.primaryCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.explore_rounded, color: CareerTheme.primaryCyan, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Campus Career Tracks Catalog',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Explore structured industry paths designed for placement success',
                              style: TextStyle(fontSize: 11, color: CareerTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.white10),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: allTracks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final item = allTracks[idx];
                      final color = item['color'] as Color;
                      final skills = item['skills'] as List<String>;

                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(item['icon'] as IconData, color: color, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'] as String,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Text(
                                            item['duration'] as String,
                                            style: const TextStyle(fontSize: 11, color: CareerTheme.textMuted),
                                          ),
                                          const Text(' • ', style: TextStyle(color: CareerTheme.textMuted)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: color.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item['level'] as String,
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item['subtitle'] as String,
                              style: const TextStyle(fontSize: 12, color: CareerTheme.textSecondary, height: 1.35),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: skills.map((skill) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Text(
                                    skill,
                                    style: const TextStyle(fontSize: 10.5, color: Colors.white70),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: color,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  CreateRoadmapView.open(context, initialTrack: item['title'] as String);
                                },
                                icon: const Icon(Icons.route_rounded, size: 16),
                                label: const Text(
                                  'Generate Track Roadmap',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
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
