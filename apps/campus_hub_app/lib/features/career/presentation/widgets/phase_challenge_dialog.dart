import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/career_repository.dart';
import '../providers/career_provider.dart';

class PhaseProjectDialog extends ConsumerStatefulWidget {
  final String roadmapId;
  final String projectTitle;
  final String description;
  final List<String> techStack;
  final List<String> requirements;

  const PhaseProjectDialog({
    super.key,
    required this.roadmapId,
    required this.projectTitle,
    required this.description,
    required this.techStack,
    required this.requirements,
  });

  @override
  ConsumerState<PhaseProjectDialog> createState() => _PhaseProjectDialogState();
}

class _PhaseProjectDialogState extends ConsumerState<PhaseProjectDialog> {
  final TextEditingController _repoController = TextEditingController();
  final TextEditingController _demoController = TextEditingController();
  bool _isExporting = false;
  bool _showExportFields = false;

  @override
  void dispose() {
    _repoController.dispose();
    _demoController.dispose();
    super.dispose();
  }

  Future<void> _exportToPortfolio() async {
    setState(() => _isExporting = true);
    try {
      final repo = ref.read(careerRepositoryProvider);
      await repo.exportProjectToPortfolio(
        widget.roadmapId,
        widget.projectTitle,
        widget.techStack,
        description: widget.description,
        repoUrl: _repoController.text.trim().isNotEmpty ? _repoController.text.trim() : null,
        projectUrl: _demoController.text.trim().isNotEmpty ? _demoController.text.trim() : null,
      );

      ref.invalidate(activeUserRoadmapProvider);
      ref.invalidate(userCareerProgressProvider);
      ref.invalidate(userRoadmapsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${widget.projectTitle}" successfully added to your CampusHub Portfolio!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export to portfolio: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.rocket_launch, color: Colors.purple, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.projectTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.description,
              style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 12),
            const Text('Tech Stack:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: widget.techStack.map((tech) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Text(tech, style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                );
              }).toList(),
            ),
            if (widget.requirements.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('Key Deliverables & Acceptance Criteria:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              ...widget.requirements.map((req) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Expanded(child: Text(req, style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 16),
            if (!_showExportFields)
              OutlinedButton.icon(
                icon: const Icon(Icons.add_to_photos, size: 16),
                label: const Text('Add to CampusHub Portfolio', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(38),
                ),
                onPressed: () => setState(() => _showExportFields = true),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Export to Portfolio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _repoController,
                      decoration: const InputDecoration(
                        labelText: 'GitHub Repo URL (Optional)',
                        hintText: 'https://github.com/...',
                        prefixIcon: Icon(Icons.code, size: 18),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _demoController,
                      decoration: const InputDecoration(
                        labelText: 'Live Demo URL (Optional)',
                        hintText: 'https://...',
                        prefixIcon: Icon(Icons.link, size: 18),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      icon: _isExporting
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check, size: 16),
                      label: Text(_isExporting ? 'Exporting...' : 'Confirm & Add to Portfolio'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.purple,
                        minimumSize: const Size.fromHeight(38),
                      ),
                      onPressed: _isExporting ? null : _exportToPortfolio,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
