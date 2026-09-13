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
            if (projects.isEmpty) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  _buildOverviewHeader(count: 0, avgScore: 0),
                  const SizedBox(height: 24),
                  CareerGlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: CareerTheme.primaryCyan.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.folder_open_rounded, size: 40, color: CareerTheme.primaryCyan),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Projects Submitted Yet',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Submit your capstone or milestone project with a public GitHub repository to verify skill evidence.',
                          style: TextStyle(fontSize: 12, color: CareerTheme.textMuted, height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        CareerPrimaryButton(
                          label: 'Submit First Project',
                          icon: Icons.add_rounded,
                          width: 220,
                          onPressed: () => _showSubmitProjectDialog(context),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final count = projects.length;
            final avgScore = (projects.map((p) => p.evidenceScore).reduce((a, b) => a + b) / count).round();

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

                ...projects.map((p) => _buildProjectModelCard(p)),
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
