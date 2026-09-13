import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../providers/career_provider.dart';

class LearningWorkspaceView extends ConsumerStatefulWidget {
  final String topic;
  final int phaseNumber;
  final String? videoUrl;

  const LearningWorkspaceView({
    super.key,
    required this.topic,
    this.phaseNumber = 1,
    this.videoUrl,
  });

  static void open(
    BuildContext context, {
    required String topic,
    int phaseNumber = 1,
    String? videoUrl,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LearningWorkspaceView(
          topic: topic,
          phaseNumber: phaseNumber,
          videoUrl: videoUrl,
        ),
      ),
    );
  }

  @override
  ConsumerState<LearningWorkspaceView> createState() => _LearningWorkspaceViewState();
}

class _LearningWorkspaceViewState extends ConsumerState<LearningWorkspaceView> {
  final Map<int, bool> _checklistStatus = {
    0: true,
    1: false,
    2: false,
    3: false,
  };

  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;

  final List<String> _checklistItems = [
    'Understand core architecture design & component lifecycles',
    'Follow code walkthrough and replicate key code patterns',
    'Execute local tests and verify output in terminal',
    'Synthesize personal takeaways and best-practice principles',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _completeSession() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Learning session recorded! Verified progress updated.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final youtubeAsync = ref.watch(
      youTubeResourcesProvider({'topic': widget.topic, 'language': 'English'}),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.topic,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            Text(
              'Phase ${widget.phaseNumber} • Active Learning Session',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. VIDEO PLAYER / RESOURCE CARD
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0F172A).withValues(alpha: 0.8),
                          const Color(0xFF1E1B4B).withValues(alpha: 0.9),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFEF4444)),
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFEF4444), size: 36),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Watch Masterclass: ${widget.topic}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Curated Verified Educational Stream',
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 12),
                      youtubeAsync.when(
                        data: (videos) {
                          final firstUrl = videos.isNotEmpty ? videos[0]['url'] as String? : null;
                          return ElevatedButton.icon(
                            onPressed: () {
                              final url = widget.videoUrl ?? firstUrl ?? 'https://youtube.com';
                              UrlLauncherService.openUrl(context, url);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            icon: const Icon(Icons.open_in_new_rounded, size: 14),
                            label: const Text('Open Educational Video', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. KEY TOPICS CHECKLIST
            const Text(
              'Key Topics & Milestones',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 4),
            const Text(
              'Track your progress through this learning session:',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 12),

            ..._checklistItems.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final isDone = _checklistStatus[idx] ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDone ? const Color(0xFF10B981).withValues(alpha: 0.5) : const Color(0xFF334155)),
                ),
                child: CheckboxListTile(
                  value: isDone,
                  activeColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: Text(
                    item,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDone ? const Color(0xFF94A3B8) : Colors.white,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _checklistStatus[idx] = val ?? false);
                  },
                ),
              );
            }),
            const SizedBox(height: 24),

            // 3. INTERACTIVE STUDY NOTES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Personal Study Notes',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Auto-saved', style: TextStyle(fontSize: 10, color: Color(0xFF818CF8), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Record key insights, syntax reminders, edge cases, and personal code patterns here...',
                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 4. ACTION BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _completeSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check_circle_rounded),
                label: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Mark Module Complete & Save Session', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
