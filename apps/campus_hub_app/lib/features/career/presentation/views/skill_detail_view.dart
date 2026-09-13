import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../providers/career_provider.dart';
import '../theme/career_theme.dart';
import '../widgets/career_shared_widgets.dart';
import 'adaptive_quiz_view.dart';
import 'projects_evidence_view.dart';

class SkillDetailView extends ConsumerStatefulWidget {
  final String skillName;
  final String roadmapId;
  final String description;
  final int phaseNumber;

  const SkillDetailView({
    super.key,
    required this.skillName,
    required this.roadmapId,
    this.description = '',
    this.phaseNumber = 1,
  });

  static void open(
    BuildContext context, {
    required String skillName,
    required String roadmapId,
    String description = '',
    int phaseNumber = 1,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SkillDetailView(
          skillName: skillName,
          roadmapId: roadmapId,
          description: description,
          phaseNumber: phaseNumber,
        ),
      ),
    );
  }

  @override
  ConsumerState<SkillDetailView> createState() => _SkillDetailViewState();
}

class _SkillDetailViewState extends ConsumerState<SkillDetailView> {
  int _selectedTabIndex = 0; // 0 = Learn, 1 = Practice, 2 = Resources
  bool _isBookmarked = false;
  late final Set<int> _completedTopicIndices;

  final List<String> _keyTopics = [
    'What is core architecture?',
    'Components & Lifecycles',
    'State, Props & Mutability',
    'Event Handling & Streams',
    'Edge Cases & Performance',
  ];

  @override
  void initState() {
    super.initState();
    // Default 2 completed for realistic demonstration
    _completedTopicIndices = {0, 1};
  }

  void _toggleTopic(int index) {
    setState(() {
      if (_completedTopicIndices.contains(index)) {
        _completedTopicIndices.remove(index);
      } else {
        _completedTopicIndices.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final youtubeAsync = ref.watch(
      youTubeResourcesProvider({'topic': widget.skillName, 'language': 'English'}),
    );
    final githubAsync = ref.watch(gitHubResourcesProvider(widget.skillName));

    final completedCount = _completedTopicIndices.length;
    final totalCount = _keyTopics.length;
    final progressVal = (completedCount / totalCount).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: CareerTheme.background,
      appBar: AppBar(
        backgroundColor: CareerTheme.background,
        elevation: 0,
        leading: BackButton(
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isBookmarked ? CareerTheme.primaryCyan : Colors.white70,
            ),
            onPressed: () => setState(() => _isBookmarked = !_isBookmarked),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TITLE & SUBTITLE
              Text(
                widget.skillName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Week ${widget.phaseNumber} • Milestone Module',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: CareerTheme.textMuted,
                ),
              ),
              const SizedBox(height: 14),

              // 2. STATUS ROW (SCREEN 5)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: CareerTheme.primaryCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CareerTheme.primaryCyan.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      completedCount == totalCount ? 'Completed' : 'In Progress',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: CareerTheme.primaryCyan,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$completedCount/$totalCount completed',
                    style: const TextStyle(fontSize: 12, color: CareerTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressVal,
                  minHeight: 5,
                  backgroundColor: CareerTheme.surfaceElevated,
                  valueColor: const AlwaysStoppedAnimation<Color>(CareerTheme.primaryCyan),
                ),
              ),
              const SizedBox(height: 20),

              // 3. SEGMENTED TABS: [Learn] [Practice] [Resources]
              Center(
                child: CareerSegmentedControl(
                  segments: const ['Learn', 'Practice', 'Resources'],
                  selectedIndex: _selectedTabIndex,
                  onSegmentSelected: (idx) => setState(() => _selectedTabIndex = idx),
                ),
              ),
              const SizedBox(height: 20),

              // 4. TAB CONTENTS
              if (_selectedTabIndex == 0)
                _buildLearnTab(youtubeAsync)
              else if (_selectedTabIndex == 1)
                _buildPracticeTab()
              else
                _buildResourcesTab(githubAsync, youtubeAsync),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: LEARN (SCREEN 5)
  // ==========================================
  Widget _buildLearnTab(AsyncValue<List<Map<String, dynamic>>> youtubeAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Video Preview Card (Matching Screen 5)
        youtubeAsync.when(
          data: (videos) {
            final video = videos.isNotEmpty ? videos.first : null;
            final title = video?['title'] ?? '${widget.skillName} Full Course for Beginners';
            final channel = video?['channel'] ?? 'Programming with Mosh';
            final views = video?['views'] ?? '4.2M views';
            final duration = video?['duration'] ?? '2:15:30';
            final url = video?['url'] ?? 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(widget.skillName)}';

            return CareerGlassCard(
              padding: EdgeInsets.zero,
              borderRadius: CareerTheme.radiusLarge,
              onTap: () => UrlLauncherService.openUrl(context, url),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video Thumbnail Banner with Play Button
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(CareerTheme.radiusLarge)),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Red YouTube Play Icon
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                        ),
                        // Duration Tag
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              duration,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Video Details
                  Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.smart_display_rounded, size: 14, color: Color(0xFFEF4444)),
                            const SizedBox(width: 6),
                            Text(
                              '$channel • $views',
                              style: const TextStyle(fontSize: 11, color: CareerTheme.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => Container(
            height: 180,
            decoration: BoxDecoration(
              color: CareerTheme.surface,
              borderRadius: BorderRadius.circular(CareerTheme.radiusLarge),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: CareerTheme.primaryCyan),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 24),

        // Key Topics Checklist (Matching Screen 5)
        const Text('Key Topics', style: CareerTheme.sectionHeader),
        const SizedBox(height: 10),

        ..._keyTopics.asMap().entries.map((entry) {
          final idx = entry.key;
          final topic = entry.value;
          final isCompleted = _completedTopicIndices.contains(idx);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: CareerTheme.surface,
              borderRadius: BorderRadius.circular(CareerTheme.radiusMedium),
              border: Border.all(
                color: isCompleted
                    ? CareerTheme.success.withValues(alpha: 0.3)
                    : CareerTheme.glassBorder,
              ),
            ),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              leading: GestureDetector(
                onTap: () => _toggleTopic(idx),
                child: Icon(
                  isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isCompleted ? CareerTheme.success : CareerTheme.lockedText,
                  size: 20,
                ),
              ),
              title: Text(
                topic,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isCompleted ? Colors.white : CareerTheme.textSecondary,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  decorationColor: CareerTheme.textSubtle,
                ),
              ),
              trailing: isCompleted
                  ? const Text('✓', style: TextStyle(color: CareerTheme.success, fontWeight: FontWeight.w700))
                  : null,
              onTap: () => _toggleTopic(idx),
            ),
          );
        }),
        const SizedBox(height: 24),

        // Bottom CTA: Mark as Completed / Quiz
        CareerPrimaryButton(
          label: '✓ Mark as Completed',
          onPressed: () {
            setState(() {
              _completedTopicIndices.addAll(List.generate(_keyTopics.length, (i) => i));
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Milestone Marked as Completed!'),
                backgroundColor: CareerTheme.success,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: () {
              AdaptiveQuizView.open(
                context,
                topic: widget.skillName,
                phaseNumber: widget.phaseNumber,
                roadmapId: widget.roadmapId,
                skillName: widget.skillName,
              );
            },
            icon: const Icon(Icons.quiz_rounded, color: CareerTheme.primaryCyan, size: 16),
            label: const Text(
              'Test Knowledge in Checkpoint Quiz →',
              style: TextStyle(color: CareerTheme.primaryCyan, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ==========================================
  // TAB 2: PRACTICE
  // ==========================================
  Widget _buildPracticeTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CareerGlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.terminal_rounded, color: CareerTheme.primaryCyan, size: 20),
                  SizedBox(width: 8),
                  Text('Hands-On Code Lab', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Build a working implementation utilizing ${widget.skillName}. Apply clean architecture patterns and handle async failure boundaries.',
                style: const TextStyle(fontSize: 13, color: CareerTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              CareerPrimaryButton(
                label: 'Submit Deliverable Evidence',
                onPressed: () => ProjectsEvidenceView.open(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        CareerGlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.quiz_rounded, color: CareerTheme.accentLavender, size: 20),
                  SizedBox(width: 8),
                  Text('Adaptive Skill Checkpoint', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'AI evaluates your technical reasoning, syntax knowledge, and edge cases to record skill mastery on your profile.',
                style: TextStyle(fontSize: 13, color: CareerTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  AdaptiveQuizView.open(
                    context,
                    topic: widget.skillName,
                    phaseNumber: widget.phaseNumber,
                    roadmapId: widget.roadmapId,
                    skillName: widget.skillName,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: CareerTheme.primaryCyan,
                  side: const BorderSide(color: CareerTheme.primaryCyan),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 46),
                ),
                child: const Text('Launch Adaptive Quiz', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 3: RESOURCES (SCREEN 6)
  // ==========================================
  Widget _buildResourcesTab(
    AsyncValue<List<Map<String, dynamic>>> githubAsync,
    AsyncValue<List<Map<String, dynamic>>> youtubeAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Official Documentation Section
        const Text('Official Documentation', style: CareerTheme.sectionHeader),
        const SizedBox(height: 10),
        CareerGlassCard(
          padding: const EdgeInsets.all(14),
          borderRadius: CareerTheme.radiusMedium,
          onTap: () => UrlLauncherService.openUrl(context, 'https://react.dev'),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: CareerTheme.primaryCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book_rounded, color: CareerTheme.primaryCyan, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Official Documentation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                    SizedBox(height: 2),
                    Text('react.dev • Guides, hooks & API reference', style: TextStyle(fontSize: 11, color: CareerTheme.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new_rounded, color: CareerTheme.primaryCyan, size: 16),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Recommended Articles (GitHub & Verified Dev Portals)
        const Text('Recommended Articles & Code', style: CareerTheme.sectionHeader),
        const SizedBox(height: 10),

        githubAsync.when(
          data: (repos) {
            final list = repos.take(3).toList();
            if (list.isEmpty) {
              return const Text('No repositories found', style: TextStyle(color: CareerTheme.textMuted));
            }
            return Column(
              children: list.map((r) {
                final name = r['name'] ?? widget.skillName;
                final stars = r['stars'] ?? 1200;
                final url = r['url'] ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: CareerGlassCard(
                    padding: const EdgeInsets.all(12),
                    borderRadius: CareerTheme.radiusMedium,
                    onTap: () => UrlLauncherService.openUrl(context, url),
                    child: Row(
                      children: [
                        const Icon(Icons.code_rounded, color: Colors.white70, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 13),
                            const SizedBox(width: 3),
                            Text('$stars', style: const TextStyle(fontSize: 11, color: CareerTheme.textMuted)),
                            const SizedBox(width: 8),
                            const Icon(Icons.open_in_new_rounded, color: CareerTheme.textSubtle, size: 14),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const LinearProgressIndicator(color: CareerTheme.primaryCyan),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 20),

        // 3. Related Playlists
        const Text('Related Playlists', style: CareerTheme.sectionHeader),
        const SizedBox(height: 10),

        youtubeAsync.when(
          data: (videos) {
            final playlists = videos.skip(1).take(2).toList();
            return Column(
              children: playlists.map((v) {
                final title = v['title'] ?? 'Full Course Playlist';
                final channel = v['channel'] ?? 'freeCodeCamp';
                final url = v['url'] ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: CareerGlassCard(
                    padding: const EdgeInsets.all(12),
                    borderRadius: CareerTheme.radiusMedium,
                    onTap: () => UrlLauncherService.openUrl(context, url),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.playlist_play_rounded, color: Color(0xFFEF4444), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text('$channel • Curated Educational Series', style: const TextStyle(fontSize: 11, color: CareerTheme.textMuted)),
                            ],
                          ),
                        ),
                        const Icon(Icons.open_in_new_rounded, color: CareerTheme.primaryCyan, size: 14),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
