import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../providers/career_provider.dart';
import 'learning_workspace_view.dart';
import 'adaptive_quiz_view.dart';

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

class _SkillDetailViewState extends ConsumerState<SkillDetailView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              widget.skillName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            Text(
              'Phase ${widget.phaseNumber} Skill Module',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Learn'),
            Tab(text: 'Practice'),
            Tab(text: 'Quiz'),
            Tab(text: 'Resources'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLearnTab(),
          _buildPracticeTab(),
          _buildQuizTab(),
          _buildResourcesTab(),
        ],
      ),
    );
  }

  // TAB 1: LEARN
  Widget _buildLearnTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.menu_book_rounded, color: Color(0xFF818CF8), size: 18),
                    SizedBox(width: 8),
                    Text('Conceptual Overview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.description.isNotEmpty
                      ? widget.description
                      : 'Mastering ${widget.skillName} empowers you to architect robust, scalable, and high-performance solutions matching enterprise quality requirements.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('Key Theoretical Concepts', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 10),
          _buildConceptTile('1. Architectural Foundations', 'Core primitives, lifecycle semantics, and initialization sequence.'),
          _buildConceptTile('2. State & Memory Flow', 'Understanding variable mutability, scope, and clean separation of concerns.'),
          _buildConceptTile('3. Real-world Edge Cases', 'Handling concurrency, async failure scenarios, and latency bottlenecks.'),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                LearningWorkspaceView.open(
                  context,
                  topic: widget.skillName,
                  phaseNumber: widget.phaseNumber,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
              label: const Text('Open in Learning Workspace', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConceptTile(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF38BDF8), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: PRACTICE
  Widget _buildPracticeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Practical Engineering Exercises', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 12),

          _buildExerciseCard(
            title: 'Exercise 1: Minimal Working Prototype',
            difficulty: 'Beginner',
            description: 'Implement a minimal standalone script verifying ${widget.skillName} fundamentals and logging inputs.',
            timeMins: 30,
          ),
          _buildExerciseCard(
            title: 'Exercise 2: Robust Error & Edge-Case Handler',
            difficulty: 'Intermediate',
            description: 'Introduce graceful degradation and fallback states when communication or data fetching fails.',
            timeMins: 45,
          ),
          _buildExerciseCard(
            title: 'Exercise 3: Modular Integration Deliverable',
            difficulty: 'Advanced',
            description: 'Refactor into reusable services or components with unit tests and clear API contracts.',
            timeMins: 60,
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard({
    required String title,
    required String difficulty,
    required String description,
    required int timeMins,
  }) {
    Color diffColor = const Color(0xFF10B981);
    if (difficulty == 'Intermediate') diffColor = const Color(0xFFF59E0B);
    if (difficulty == 'Advanced') diffColor = const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: diffColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(difficulty, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: diffColor)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 13, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text('$timeMins mins estimated', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  LearningWorkspaceView.open(
                    context,
                    topic: widget.skillName,
                    phaseNumber: widget.phaseNumber,
                  );
                },
                icon: const Icon(Icons.terminal_rounded, size: 14, color: Color(0xFF38BDF8)),
                label: const Text('Start Exercise', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF38BDF8))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // TAB 3: QUIZ
  Widget _buildQuizTab() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.quiz_rounded, size: 48, color: Color(0xFF818CF8)),
          ),
          const SizedBox(height: 20),
          Text(
            'Checkpoint Test: ${widget.skillName}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Test your comprehension of foundational syntax, edge cases, and best practices. Passing this test records verified skill evidence on your profile.',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                AdaptiveQuizView.open(
                  context,
                  topic: widget.skillName,
                  phaseNumber: widget.phaseNumber,
                  roadmapId: widget.roadmapId,
                  skillName: widget.skillName,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Launch Checkpoint Quiz', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 4: RESOURCES (Live GitHub & Language-Aware YouTube)
  Widget _buildResourcesTab() {
    final githubAsync = ref.watch(gitHubResourcesProvider(widget.skillName));
    final youtubeAsync = ref.watch(
      youTubeResourcesProvider({'topic': widget.skillName, 'language': _selectedLanguage}),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Educational Videos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              DropdownButton<String>(
                value: _selectedLanguage,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600),
                underline: const SizedBox.shrink(),
                items: ['English', 'Tamil', 'Hindi'].map((lang) {
                  return DropdownMenuItem(value: lang, child: Text(lang));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedLanguage = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // YouTube list
          youtubeAsync.when(
            data: (videos) {
              if (videos.isEmpty) {
                return const Text('No videos found', style: TextStyle(color: Colors.white70));
              }
              return Column(
                children: videos.map((v) {
                  final title = v['title'] ?? '';
                  final channel = v['channel'] ?? '';
                  final duration = v['duration'] ?? '';
                  final views = v['views'] ?? '';
                  final url = v['url'] ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.smart_display_rounded, color: Color(0xFFEF4444), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 3),
                              Text('$channel • $duration • $views', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.open_in_new_rounded, color: Color(0xFF38BDF8), size: 18),
                          onPressed: () {
                            if (url.isNotEmpty) UrlLauncherService.openUrl(context, url);
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const LinearProgressIndicator(color: Color(0xFF6366F1)),
            error: (_, __) => const Text('Could not load videos', style: TextStyle(color: Colors.white70)),
          ),
          const SizedBox(height: 24),

          // GitHub Repositories
          const Text('Verified GitHub Repositories', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 10),

          githubAsync.when(
            data: (repos) {
              if (repos.isEmpty) {
                return const Text('No repositories found', style: TextStyle(color: Colors.white70));
              }
              return Column(
                children: repos.map((r) {
                  final name = r['name'] ?? '';
                  final fullName = r['fullName'] ?? name;
                  final desc = r['description'] ?? '';
                  final stars = r['stars'] ?? 0;
                  final forks = r['forks'] ?? 0;
                  final lang = r['language'] ?? 'Code';
                  final whyUseful = r['whyUseful'] ?? '';
                  final url = r['url'] ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
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
                                fullName,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF38BDF8)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 14),
                                const SizedBox(width: 3),
                                Text('$stars', style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                                const SizedBox(width: 8),
                                const Icon(Icons.fork_right_rounded, color: Color(0xFF94A3B8), size: 14),
                                const SizedBox(width: 3),
                                Text('$forks', style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
                        if (whyUseful.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Why Useful: $whyUseful',
                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF10B981)),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(4)),
                              child: Text(lang, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () {
                                if (url.isNotEmpty) UrlLauncherService.openUrl(context, url);
                              },
                              icon: const Icon(Icons.open_in_browser_rounded, size: 14, color: Color(0xFF818CF8)),
                              label: const Text('View Repo', style: TextStyle(fontSize: 11, color: Color(0xFF818CF8))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const LinearProgressIndicator(color: Color(0xFF6366F1)),
            error: (_, __) => const Text('Could not load repositories', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
