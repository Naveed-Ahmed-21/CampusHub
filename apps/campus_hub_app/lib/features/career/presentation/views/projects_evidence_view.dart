import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../data/career_repository.dart';
import '../../domain/career_models.dart';
import '../providers/career_provider.dart';

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
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Projects & Evidence',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            Text(
              'Verified Deliverables & Capstones',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF38BDF8)),
            tooltip: 'Submit Project',
            onPressed: () => _showSubmitProjectDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(projectEvidencesProvider),
        child: projectsAsync.when(
          data: (projects) {
            if (projects.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.code_rounded, size: 48, color: Color(0xFF6366F1)),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'No Projects Submitted Yet',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Submit your Phase milestone capstone projects with public GitHub repositories to verify skill evidence.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showSubmitProjectDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Submit First Project Evidence'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return _buildProjectCard(project);
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF6366F1)),
          ),
          error: (err, _) => Center(
            child: Text('Failed to load projects: $err', style: const TextStyle(color: Colors.white70)),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubmitProjectDialog(context),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Submit Evidence', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildProjectCard(ProjectEvidenceModel project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
              Expanded(
                child: Text(
                  project.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: project.verified
                      ? const Color(0xFF10B981).withOpacity(0.15)
                      : const Color(0xFFF59E0B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: project.verified
                        ? const Color(0xFF10B981).withOpacity(0.4)
                        : const Color(0xFFF59E0B).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      project.verified ? Icons.check_circle_rounded : Icons.pending_rounded,
                      size: 12,
                      color: project.verified ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      project.verified ? 'Verified (${project.evidenceScore}%)' : 'Submitted',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: project.verified ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            project.description,
            style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1), height: 1.35),
          ),
          const SizedBox(height: 12),

          // Tech stack chips
          if (project.techStack.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: project.techStack.map((tech) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Text(tech, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Links row
          Row(
            children: [
              if (project.githubUrl != null && project.githubUrl!.isNotEmpty)
                TextButton.icon(
                  onPressed: () => UrlLauncherService.openUrl(context, project.githubUrl),
                  icon: const Icon(Icons.code_rounded, size: 14, color: Color(0xFF38BDF8)),
                  label: const Text('GitHub Repository', style: TextStyle(fontSize: 11, color: Color(0xFF38BDF8))),
                ),
              if (project.demoUrl != null && project.demoUrl!.isNotEmpty) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => UrlLauncherService.openUrl(context, project.demoUrl),
                  icon: const Icon(Icons.launch_rounded, size: 14, color: Color(0xFF10B981)),
                  label: const Text('Live Demo', style: TextStyle(fontSize: 11, color: Color(0xFF10B981))),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

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
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Submit Project Evidence', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Project Title *',
                        labelStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Description & Architecture *',
                        labelStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: githubCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'GitHub Repository URL *',
                        hintText: 'https://github.com/username/repo',
                        labelStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: demoCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Live Demo URL (Optional)',
                        labelStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: techCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Tech Stack (comma separated)',
                        hintText: 'C++, ESP32, MQTT, FreeRTOS',
                        labelStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Project Evidence Submitted & Verified!'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Submission error: $e')),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                  child: isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Deliverable'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
