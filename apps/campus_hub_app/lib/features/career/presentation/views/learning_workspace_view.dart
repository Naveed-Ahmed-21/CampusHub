import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../providers/career_provider.dart';
import '../theme/career_theme.dart';
import '../widgets/career_shared_widgets.dart';

class LearningWorkspaceView extends ConsumerStatefulWidget {
  final String topic;
  final int phaseNumber;

  const LearningWorkspaceView({
    super.key,
    required this.topic,
    this.phaseNumber = 1,
  });

  static void open(BuildContext context, {required String topic, int phaseNumber = 1}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LearningWorkspaceView(topic: topic, phaseNumber: phaseNumber),
      ),
    );
  }

  @override
  ConsumerState<LearningWorkspaceView> createState() => _LearningWorkspaceViewState();
}

class _LearningWorkspaceViewState extends ConsumerState<LearningWorkspaceView> {
  int _selectedTab = 2; // Default to Resources as shown in Screen 6

  @override
  Widget build(BuildContext context) {
    final githubAsync = ref.watch(gitHubResourcesProvider(widget.topic));
    final youtubeAsync = ref.watch(
      youTubeResourcesProvider({'topic': widget.topic, 'language': 'English'}),
    );

    return Scaffold(
      backgroundColor: CareerTheme.background,
      appBar: AppBar(
        backgroundColor: CareerTheme.background,
        elevation: 0,
        leading: BackButton(
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.topic,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented Tabs: [Learn] [Practice] [Resources]
              Center(
                child: CareerSegmentedControl(
                  segments: const ['Learn', 'Practice', 'Resources'],
                  selectedIndex: _selectedTab,
                  onSegmentSelected: (idx) => setState(() => _selectedTab = idx),
                ),
              ),
              const SizedBox(height: 24),

              if (_selectedTab == 2) ...[
                // ==========================================
                // SECTION 1: OFFICIAL DOCUMENTATION (SCREEN 6)
                // ==========================================
                const Text('Official Documentation', style: CareerTheme.sectionHeader),
                const SizedBox(height: 12),
                CareerGlassCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: CareerTheme.radiusMedium,
                  onTap: () => UrlLauncherService.openUrl(context, 'https://react.dev'),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: CareerTheme.primaryCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.code_rounded, color: CareerTheme.primaryCyan, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Official Docs & API Specs',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            SizedBox(height: 2),
                            Text('react.dev', style: TextStyle(fontSize: 11, color: CareerTheme.primaryCyan)),
                            SizedBox(height: 4),
                            Text(
                              'The official documentation with interactive code snippets and architectural guides.',
                              style: TextStyle(fontSize: 11, color: CareerTheme.textMuted, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.open_in_new_rounded, color: CareerTheme.primaryCyan, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ==========================================
                // SECTION 2: RECOMMENDED ARTICLES (SCREEN 6)
                // ==========================================
                const Text('Recommended Articles', style: CareerTheme.sectionHeader),
                const SizedBox(height: 12),

                // Card 1: Beginner Guide
                _buildArticleCard(
                  icon: Icons.article_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: '${widget.topic} In-Depth Guide',
                  domain: 'medium.com',
                  url: 'https://medium.com/tag/${Uri.encodeComponent(widget.topic)}',
                ),
                const SizedBox(height: 10),

                // Card 2: Deep Dive Concepts
                _buildArticleCard(
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Core Concepts & Specifications',
                  domain: 'javascript.info',
                  url: 'https://developer.mozilla.org',
                ),
                const SizedBox(height: 10),

                // Card 3: Advanced Architecture
                _buildArticleCard(
                  icon: Icons.rocket_launch_rounded,
                  iconColor: const Color(0xFFEC4899),
                  title: 'Production State & Performance',
                  domain: 'blog.logrocket.com',
                  url: 'https://blog.logrocket.com',
                ),
                const SizedBox(height: 24),

                // ==========================================
                // SECTION 3: RELATED PLAYLISTS (SCREEN 6)
                // ==========================================
                const Text('Related Playlists', style: CareerTheme.sectionHeader),
                const SizedBox(height: 12),

                youtubeAsync.when(
                  data: (videos) {
                    final list = videos.take(2).toList();
                    return Column(
                      children: list.map((v) {
                        final title = v['title'] ?? 'Full Bootcamp Playlist';
                        final channel = v['channel'] ?? 'freeCodeCamp';
                        final url = v['url'] ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: CareerGlassCard(
                            padding: const EdgeInsets.all(14),
                            borderRadius: CareerTheme.radiusMedium,
                            onTap: () => UrlLauncherService.openUrl(context, url),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.play_circle_filled_rounded, color: Color(0xFFEF4444), size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$channel • Curated Educational Series',
                                        style: const TextStyle(fontSize: 11, color: CareerTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.open_in_new_rounded, color: CareerTheme.primaryCyan, size: 16),
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
              ] else if (_selectedTab == 0) ...[
                // Learn Tab Summary
                CareerGlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Learning Foundations: ${widget.topic}', style: CareerTheme.cardTitle),
                      const SizedBox(height: 8),
                      const Text(
                        'Follow structured video courses and code walkthroughs to establish mental models for core semantics and real-world architectures.',
                        style: TextStyle(fontSize: 13, color: CareerTheme.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Practice Tab Summary
                CareerGlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hands-on Exercises: ${widget.topic}', style: CareerTheme.cardTitle),
                      const SizedBox(height: 8),
                      const Text(
                        'Verify your code logic by completing exercises and examining open-source reference implementations.',
                        style: TextStyle(fontSize: 13, color: CareerTheme.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const CareerSectionHeader(
                  title: 'Open Source Starter Repositories',
                  subtitle: 'Fork and build projects from curated GitHub repositories',
                ),
                const SizedBox(height: 12),
                githubAsync.when(
                  data: (repos) {
                    if (repos.isEmpty) {
                      return const CareerGlassCard(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No public repositories found for this topic.',
                          style: TextStyle(color: CareerTheme.textMuted, fontSize: 13),
                        ),
                      );
                    }
                    return Column(
                      children: repos.take(4).map((repo) {
                        final repoUrl = repo['repo_url']?.toString() ?? repo['url']?.toString() ?? '';
                        final title = repo['title']?.toString() ?? repo['name']?.toString() ?? 'Repository';
                        final desc = repo['description']?.toString() ?? 'GitHub Repository';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: CareerGlassCard(
                            onTap: repoUrl.isNotEmpty ? () => UrlLauncherService.openUrl(context, repoUrl) : null,
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: CareerTheme.surfaceElevated,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.code_rounded, color: CareerTheme.primaryCyan, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        desc,
                                        style: const TextStyle(fontSize: 11, color: CareerTheme.textMuted),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.open_in_new_rounded, color: CareerTheme.primaryCyan, size: 16),
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
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArticleCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String domain,
    required String url,
  }) {
    return CareerGlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: CareerTheme.radiusMedium,
      onTap: () => UrlLauncherService.openUrl(context, url),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(domain, style: const TextStyle(fontSize: 11, color: CareerTheme.primaryCyan)),
              ],
            ),
          ),
          const Icon(Icons.open_in_new_rounded, color: CareerTheme.textSubtle, size: 16),
        ],
      ),
    );
  }
}
