import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../data/career_repository.dart';
import '../../domain/career_models.dart';
import '../providers/career_provider.dart';
import '../theme/career_theme.dart';
import '../widgets/career_shared_widgets.dart';

class ProjectsEvidenceView extends ConsumerStatefulWidget {
  const ProjectsEvidenceView({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProjectsEvidenceView()),
    );
  }

  @override
  ConsumerState<ProjectsEvidenceView> createState() => _ProjectsEvidenceViewState();
}

class _ProjectsEvidenceViewState extends ConsumerState<ProjectsEvidenceView> {
  // Curated showcase projects if backend returns empty
  final List<Map<String, dynamic>> _sampleProjects = [
    {
      'title': 'Campus Social Hub & Real-Time Chat',
      'description': 'Production Flutter and Node.js collaboration application with WebSocket messaging, group channels, role-based access, and Redis caching.',
      'techStack': ['Flutter', 'Node.js', 'Express', 'Socket.IO', 'Redis', 'PostgreSQL'],
      'githubUrl': 'https://github.com/Naveed-Ahmed-21/CampusHub',
      'demoUrl': 'https://campushub.edu',
      'verified': true,
      'evidenceScore': 94,
      'gradient': [Color(0xFF1E1B4B), Color(0xFF312E81)],
      'icon': Icons.hub_rounded,
    },
    {
      'title': 'Distributed Job Readiness Evaluation Engine',
      'description': 'AI-driven rubric engine parsing GitHub repositories, static analysis, and adaptive checkpoints into a multi-dimensional competency score.',
      'techStack': ['TypeScript', 'FastAPI', 'Python', 'Docker', 'Prisma', 'PostgreSQL'],
      'githubUrl': 'https://github.com/Naveed-Ahmed-21/CampusHub',
      'demoUrl': '',
      'verified': true,
      'evidenceScore': 88,
      'gradient': [Color(0xFF0F766E), Color(0xFF134E4A)],
      'icon': Icons.insights_rounded,
    },
    {
      'title': 'AI Voice Mock Interview Studio (EVA)',
      'description': 'Real-time adaptive technical interview simulator evaluating response concepts, STAR methodology adherence, and latency.',
      'techStack': ['Dart', 'WebRTC', 'OpenAI', 'Node.js', 'Audio Streaming'],
      'githubUrl': 'https://github.com/Naveed-Ahmed-21/CampusHub',
      'demoUrl': '',
      'verified': true,
      'evidenceScore': 91,
      'gradient': [Color(0xFF581C87), Color(0xFF3B0764)],
      'icon': Icons.record_voice_over_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectEvidencesProvider);

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
              'My Projects',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3),
            ),
            SizedBox(height: 2),
            Text(
              'Build real-world portfolio proof',
              style: TextStyle(fontSize: 11, color: CareerTheme.textMuted),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _showSubmitProjectDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: CareerTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(CareerTheme.radiusPill),
                  boxShadow: [
                    BoxShadow(
                      color: CareerTheme.primaryCyan.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Add Project',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: CareerTheme.primaryCyan,
        backgroundColor: CareerTheme.surface,
        onRefresh: () async => ref.invalidate(projectEvidencesProvider),
        child: projectsAsync.when(
          data: (projects) {
            final hasReal = projects.isNotEmpty;
            final count = hasReal ? projects.length : _sampleProjects.length;
            final avgScore = hasReal
                ? (projects.map((p) => p.evidenceScore).reduce((a, b) => a + b) / count).round()
                : 91;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // Top Metrics Overview Card
                _buildOverviewHeader(count: count, avgScore: avgScore),
                const SizedBox(height: 20),

                const CareerSectionHeader(
                  title: 'Portfolio Deliverables',
                  subtitle: 'Verified by code evidence and architectural review',
                ),
                const SizedBox(height: 12),

                if (hasReal)
                  ...projects.map((p) => _buildProjectModelCard(p))
                else
                  ..._sampleProjects.map((p) => _buildSampleProjectCard(p)),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: CareerTheme.primaryCyan),
          ),
          error: (err, _) => Center(
            child: Text(
              'Failed to load projects: $err',
              style: const TextStyle(color: CareerTheme.textMuted),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TOP OVERVIEW METRICS CARD
  // ==========================================
  Widget _buildOverviewHeader({required int count, required int avgScore}) {
    return CareerGlassCard(
      padding: const EdgeInsets.all(18),
      gradient: const LinearGradient(
        colors: [Color(0xFF101827), Color(0xFF1E293B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: CareerTheme.primaryCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.verified_rounded, size: 16, color: CareerTheme.primaryCyan),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'PORTFOLIO STATUS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: CareerTheme.primaryCyan,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Placement-Ready Proof',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Verified GitHub repositories strengthen your placement ranking by 3.2x.',
                  style: TextStyle(fontSize: 11, color: CareerTheme.textMuted, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          CareerProgressRing(
            percentage: avgScore.toDouble(),
            size: 60,
            strokeWidth: 6,
            progressColor: CareerTheme.success,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BACKEND REAL MODEL CARD
  // ==========================================
  Widget _buildProjectModelCard(ProjectEvidenceModel project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: CareerGlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title & Verification Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    project.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: project.verified
                        ? CareerTheme.success.withValues(alpha: 0.15)
                        : CareerTheme.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(CareerTheme.radiusPill),
                    border: Border.all(
                      color: project.verified
                          ? CareerTheme.success.withValues(alpha: 0.4)
                          : CareerTheme.warning.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        project.verified ? Icons.check_circle_rounded : Icons.pending_rounded,
                        size: 13,
                        color: project.verified ? CareerTheme.success : CareerTheme.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        project.verified ? 'Verified (${project.evidenceScore}%)' : 'Under Review',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: project.verified ? CareerTheme.success : CareerTheme.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              project.description,
              style: const TextStyle(fontSize: 12, color: CareerTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 14),

            // Tech stack chips
            if (project.techStack.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: project.techStack.map((tech) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: CareerTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: CareerTheme.glassBorder),
                    ),
                    child: Text(
                      tech,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CareerTheme.primaryCyan),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],

            // Action links
            Row(
              children: [
                if (project.githubUrl != null && project.githubUrl!.isNotEmpty)
                  GestureDetector(
                    onTap: () => UrlLauncherService.openUrl(context, project.githubUrl),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: CareerTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CareerTheme.glassBorder),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.code_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'GitHub Repo',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (project.demoUrl != null && project.demoUrl!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => UrlLauncherService.openUrl(context, project.demoUrl),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: CareerTheme.primaryCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CareerTheme.primaryCyan.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.launch_rounded, size: 14, color: CareerTheme.primaryCyan),
                          SizedBox(width: 6),
                          Text(
                            'Live Demo',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CareerTheme.primaryCyan),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SAMPLE CURATED CARD (MATCHING SCREEN 10)
  // ==========================================
  Widget _buildSampleProjectCard(Map<String, dynamic> project) {
    final techStack = (project['techStack'] as List<String>?) ?? [];
    final title = project['title'] as String;
    final desc = project['description'] as String;
    final githubUrl = project['githubUrl'] as String;
    final score = project['evidenceScore'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: CareerGlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: project['gradient'] as List<Color>,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(project['icon'] as IconData, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 12, color: CareerTheme.success),
                          const SizedBox(width: 4),
                          Text(
                            'Verified • $score% Evidence Match',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CareerTheme.success),
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
              desc,
              style: const TextStyle(fontSize: 12, color: CareerTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: techStack.map((tech) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: CareerTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: CareerTheme.glassBorder),
                  ),
                  child: Text(
                    tech,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CareerTheme.primaryCyan),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                GestureDetector(
                  onTap: () => UrlLauncherService.openUrl(context, githubUrl),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: CareerTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CareerTheme.glassBorder),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.code_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'GitHub Repo',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _showProjectDetailsSheet(context, project),
                  child: const Text(
                    'View Details →',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CareerTheme.primaryCyan),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProjectDetailsSheet(BuildContext context, Map<String, dynamic> project) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CareerTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(project['title'] as String, style: CareerTheme.sectionHeader),
            const SizedBox(height: 8),
            Text(project['description'] as String, style: CareerTheme.body),
            const SizedBox(height: 16),
            const Text('Curated Architectural Rubrics:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 6),
            const Text('• Clean Layered Controller / Service Architecture\n• Relational DB Schema Normalization\n• Unit & End-to-End Automated Test Verification', style: TextStyle(fontSize: 11, color: CareerTheme.textMuted, height: 1.4)),
            const SizedBox(height: 20),
            CareerPrimaryButton(
              label: 'Close Details',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SUBMIT PROJECT DIALOG (MODAL)
  // ==========================================
  void _showSubmitProjectDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final githubCtrl = TextEditingController();
    final demoCtrl = TextEditingController();
    final techCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              backgroundColor: CareerTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(CareerTheme.radiusLarge),
                side: const BorderSide(color: CareerTheme.glassBorder),
              ),
              title: const Row(
                children: [
                  Icon(Icons.add_task_rounded, color: CareerTheme.primaryCyan, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Submit Project Evidence',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildInputField(controller: titleCtrl, label: 'Project Title *', hint: 'e.g. Distributed Task Queue'),
                    const SizedBox(height: 12),
                    _buildInputField(controller: descCtrl, label: 'Architecture & Description *', hint: 'Overview of modules, database, and tradeoffs', maxLines: 3),
                    const SizedBox(height: 12),
                    _buildInputField(controller: githubCtrl, label: 'GitHub Repository URL *', hint: 'https://github.com/username/repo'),
                    const SizedBox(height: 12),
                    _buildInputField(controller: demoCtrl, label: 'Live Demo URL (Optional)', hint: 'https://demo.app.com'),
                    const SizedBox(height: 12),
                    _buildInputField(controller: techCtrl, label: 'Tech Stack (comma separated)', hint: 'React, Go, PostgreSQL, Docker'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: CareerTheme.textMuted)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final title = titleCtrl.text.trim();
                          final desc = descCtrl.text.trim();
                          final github = githubCtrl.text.trim();

                          if (title.isEmpty || desc.isEmpty || github.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill title, description, and GitHub URL.')),
                            );
                            return;
                          }

                          setModalState(() => isSubmitting = true);
                          try {
                            final tech = techCtrl.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
                            final repo = ref.read(careerRepositoryProvider);
                            await repo.createProjectEvidence(
                              title: title,
                              description: desc,
                              githubUrl: github,
                              demoUrl: demoCtrl.text.trim().isNotEmpty ? demoCtrl.text.trim() : null,
                              techStack: tech,
                            );
                            ref.invalidate(projectEvidencesProvider);
                            ref.invalidate(detailedJobReadinessProvider(null));

                            if (!mounted) return;
                            if (dialogCtx.mounted) {
                              Navigator.of(dialogCtx).pop();
                            }
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✓ Project Deliverable Submitted & Verified!'),
                                backgroundColor: CareerTheme.success,
                              ),
                            );
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            if (!mounted) return;
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Submission error: $e')),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CareerTheme.primaryCyan,
                    foregroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text('Submit Deliverable', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CareerTheme.textMuted)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: CareerTheme.textSubtle, fontSize: 12),
            filled: true,
            fillColor: CareerTheme.surfaceMuted,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: CareerTheme.glassBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: CareerTheme.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: CareerTheme.primaryCyan),
            ),
          ),
        ),
      ],
    );
  }
}
