import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/career_provider.dart';
import '../theme/career_theme.dart';
import '../widgets/career_shared_widgets.dart';
import 'adaptive_quiz_view.dart';
import 'projects_evidence_view.dart';
import 'interview_prep_view.dart';

class JobReadinessView extends ConsumerWidget {
  final String? targetRole;

  const JobReadinessView({
    super.key,
    this.targetRole,
  });

  static void open(BuildContext context, {String? targetRole}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JobReadinessView(targetRole: targetRole),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readinessAsync = ref.watch(detailedJobReadinessProvider(targetRole));

    return Scaffold(
      backgroundColor: CareerTheme.background,
      appBar: AppBar(
        backgroundColor: CareerTheme.background,
        elevation: 0,
        leading: BackButton(
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job Readiness',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3),
            ),
            SizedBox(height: 2),
            Text(
              '6-Dimension Placement Analytics',
              style: TextStyle(fontSize: 11, color: CareerTheme.textMuted),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: CareerTheme.primaryCyan,
        backgroundColor: CareerTheme.surface,
        onRefresh: () async => ref.invalidate(detailedJobReadinessProvider(targetRole)),
        child: readinessAsync.when(
          data: (data) {
            final overallScore = (data['overallScore'] as num?)?.toInt() ?? 72;
            final readinessLevel = data['readinessLevel']?.toString() ?? 'Intermediate Builder';
            final role = data['targetRole']?.toString() ?? targetRole ?? 'Frontend Developer';
            final dimensions = (data['dimensions'] as List<dynamic>?) ?? _defaultDimensions;
            final nextAction = data['nextBestAction'] as Map<String, dynamic>? ?? {
              'title': 'Complete 2 more full-stack projects to reach 80% readiness',
              'description': 'Deliverable evidence in full-stack architecture is your highest-leverage growth area for campus hiring.',
              'actionType': 'PROJECT',
            };
            final strongAreas = (data['strongAreas'] as List<dynamic>?) ?? [
              'Modern UI Component Architecture & State Management',
              'Git Version Control & PR Reviews',
              'RESTful API Contract Design',
            ];
            final areasToImprove = (data['areasToImprove'] as List<dynamic>?) ?? [
              'Distributed Systems & Real-Time WebSockets',
              'Advanced Graph Algorithms & System Design',
            ];

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TOP CIRCULAR GAUGE HERO CARD (SCREEN 11)
                  _buildHeroGaugeCard(
                    score: overallScore,
                    level: readinessLevel,
                    role: role,
                  ),
                  const SizedBox(height: 20),

                  // 2. 6 DIMENSIONS GRID (SCREEN 11)
                  const CareerSectionHeader(
                    title: 'Evaluated Competencies',
                    subtitle: 'Multi-dimensional readiness breakdown for hiring rubrics',
                  ),
                  const SizedBox(height: 12),
                  _buildDimensionsGrid(dimensions),
                  const SizedBox(height: 20),

                  // 3. NEXT BEST ACTION BANNER (SCREEN 11)
                  _buildNextBestActionCard(context, nextAction),
                  const SizedBox(height: 24),

                  // 4. STRENGTHS & FOCUS AREAS
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildCompetencyListCard(
                          title: 'Strengths',
                          items: strongAreas,
                          color: CareerTheme.success,
                          icon: Icons.check_circle_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCompetencyListCard(
                          title: 'Focus Areas',
                          items: areasToImprove,
                          color: CareerTheme.warning,
                          icon: Icons.lightbulb_outline_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: CareerTheme.primaryCyan),
          ),
          error: (err, _) => Center(
            child: Text(
              'Error loading readiness: $err',
              style: const TextStyle(color: CareerTheme.textMuted),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TOP CIRCULAR HERO CARD (SCREEN 11)
  // ==========================================
  Widget _buildHeroGaugeCard({
    required int score,
    required String level,
    required String role,
  }) {
    return CareerGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      gradient: const LinearGradient(
        colors: [Color(0xFF131C31), Color(0xFF0F172A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        children: [
          // Circular Score Gauge with Gradient Glow
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: CareerTheme.primaryCyan.withValues(alpha: 0.18),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              CareerProgressRing(
                percentage: score.toDouble(),
                size: 110,
                strokeWidth: 9,
                progressColor: CareerTheme.primaryCyan,
                backgroundColor: CareerTheme.surfaceElevated,
                labelStyle: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Encouragement message matching reference
          const Text(
            "You're on the right track!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Based on FAANG & Tier-1 startup hiring rubrics',
            style: TextStyle(fontSize: 12, color: CareerTheme.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),

          // Role & Level Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: CareerTheme.accentIndigo.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(CareerTheme.radiusPill),
                  border: Border.all(color: CareerTheme.accentIndigo.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.psychology_rounded, size: 14, color: CareerTheme.accentIndigo),
                    const SizedBox(width: 5),
                    Text(
                      level,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFA5B4FC)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: CareerTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(CareerTheme.radiusPill),
                  border: Border.all(color: CareerTheme.glassBorder),
                ),
                child: Text(
                  role,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CareerTheme.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6 DIMENSIONS GRID (SCREEN 11)
  // ==========================================
  Widget _buildDimensionsGrid(List<dynamic> dimensions) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemCount: dimensions.length,
      itemBuilder: (context, idx) {
        final dim = dimensions[idx] as Map<String, dynamic>;
        final name = dim['name']?.toString() ?? 'Dimension';
        final score = (dim['score'] as num?)?.toInt() ?? 60;
        final icon = _getDimensionIcon(name);
        final color = _getDimensionColor(idx);

        return CareerGlassCard(
          padding: const EdgeInsets.all(12),
          borderRadius: CareerTheme.radiusMedium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                  Text(
                    '$score%',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (score / 100.0).clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: CareerTheme.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getDimensionIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('tech')) return Icons.code_rounded;
    if (lower.contains('project')) return Icons.folder_rounded;
    if (lower.contains('dsa') || lower.contains('algo')) return Icons.account_tree_rounded;
    if (lower.contains('resume')) return Icons.description_rounded;
    if (lower.contains('interview')) return Icons.record_voice_over_rounded;
    if (lower.contains('comm')) return Icons.chat_bubble_outline_rounded;
    return Icons.insights_rounded;
  }

  Color _getDimensionColor(int idx) {
    const palette = [
      Color(0xFF38BDF8), // Cyan
      Color(0xFF6366F1), // Indigo
      Color(0xFFA855F7), // Purple
      Color(0xFF10B981), // Emerald
      Color(0xFFF59E0B), // Amber
      Color(0xFFEC4899), // Pink
    ];
    return palette[idx % palette.length];
  }

  // ==========================================
  // NEXT BEST ACTION CARD (SCREEN 11)
  // ==========================================
  Widget _buildNextBestActionCard(BuildContext context, Map<String, dynamic> nextAction) {
    final title = nextAction['title']?.toString() ?? 'Complete 2 more full-stack projects to reach 80% readiness';
    final desc = nextAction['description']?.toString() ?? 'Strengthen your portfolio evidence with verified deliverables.';
    final actionType = nextAction['actionType']?.toString() ?? 'PROJECT';

    return CareerGlassCard(
      padding: const EdgeInsets.all(18),
      borderColor: CareerTheme.primaryCyan.withValues(alpha: 0.5),
      gradient: const LinearGradient(
        colors: [Color(0xFF101B30), Color(0xFF13233E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: CareerTheme.primaryCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.bolt_rounded, color: CareerTheme.primaryCyan, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'NEXT BEST ACTION',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: CareerTheme.primaryCyan,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, height: 1.3),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(fontSize: 12, color: CareerTheme.textMuted, height: 1.35),
          ),
          const SizedBox(height: 16),
          CareerPrimaryButton(
            label: 'Execute Recommended Action →',
            onPressed: () {
              if (actionType == 'QUIZ') {
                AdaptiveQuizView.open(context, topic: 'Competency Checkpoint');
              } else if (actionType == 'PROJECT') {
                ProjectsEvidenceView.open(context);
              } else if (actionType == 'INTERVIEW') {
                InterviewPrepView.open(context, targetRole: targetRole ?? 'Software Engineer');
              } else {
                ProjectsEvidenceView.open(context);
              }
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STRENGTHS & FOCUS AREAS CARD
  // ==========================================
  Widget _buildCompetencyListCard({
    required String title,
    required List<dynamic> items,
    required Color color,
    required IconData icon,
  }) {
    return CareerGlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: CareerTheme.radiusMedium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.take(3).map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      item.toString(),
                      style: const TextStyle(fontSize: 11, color: CareerTheme.textSecondary, height: 1.3),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static const List<Map<String, dynamic>> _defaultDimensions = [
    {'name': 'Technical Skills', 'score': 80},
    {'name': 'Projects', 'score': 70},
    {'name': 'DSA & Problem Solving', 'score': 60},
    {'name': 'Resume & ATS', 'score': 70},
    {'name': 'Interview Prep', 'score': 65},
    {'name': 'Communication', 'score': 76},
  ];
}
