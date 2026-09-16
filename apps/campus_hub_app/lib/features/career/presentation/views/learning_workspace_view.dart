import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../domain/career_models.dart';
import '../providers/career_provider.dart';
import '../theme/career_theme.dart';
import '../widgets/ask_ai_doubt_sheet.dart';
import '../widgets/career_shared_widgets.dart';
import 'adaptive_quiz_view.dart';
import 'projects_evidence_view.dart';

class LearningWorkspaceView extends ConsumerStatefulWidget {
  final String topic;
  final int phaseNumber;
  final String? roadmapId;
  final String? nodeId;

  const LearningWorkspaceView({
    super.key,
    required this.topic,
    this.phaseNumber = 1,
    this.roadmapId,
    this.nodeId,
  });

  static void open(
    BuildContext context, {
    required String topic,
    int phaseNumber = 1,
    String? roadmapId,
    String? nodeId,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LearningWorkspaceView(
          topic: topic,
          phaseNumber: phaseNumber,
          roadmapId: roadmapId,
          nodeId: nodeId,
        ),
      ),
    );
  }

  @override
  ConsumerState<LearningWorkspaceView> createState() => _LearningWorkspaceViewState();
}

class _LearningWorkspaceViewState extends ConsumerState<LearningWorkspaceView> {
  int _selectedTab = 0; // 0 = Learn, 1 = Practice, 2 = Quiz, 3 = Resources
  bool _showHints = false;
  bool _practiceCompleted = false;
  final Set<int> _checkedConcepts = {};

  List<String> _resolveKeyConcepts(String topic) {
    final t = topic.toLowerCase();
    if (t.contains('esp') || t.contains('iot') || t.contains('embedded') || t.contains('gpio')) {
      return [
        'Hardware Pinout, Voltage Limits & GPIO Multiplexing',
        'Hardware Interrupts (ISR) vs Polling Architecture',
        'FreeRTOS Task Scheduling & Queue Synchronization',
        'Deep Sleep Modes, RTC Power Domains & Wake Stubs',
      ];
    }
    if (t.contains('security') || t.contains('cyber') || t.contains('owasp') || t.contains('wireshark')) {
      return [
        'Threat Modeling & Perimeter Vulnerability Analysis',
        'Packet Inspection, Protocol Handshakes & Payloads',
        'OWASP Top 10 Mitigation & Input Sanitization',
        'Zero-Trust Identity, Token Lifecycle & RBAC',
      ];
    }
    if (t.contains('flutter') || t.contains('dart') || t.contains('mobile')) {
      return [
        'RenderObject Tree, Layout Constraints & Repaint Boundaries',
        'Reactive State Management with Riverpod Code-Gen',
        'Dart Event Loop, Futures, Streams & Background Isolates',
        'Offline Cache, SQLite Persistence & Network Synchronization',
      ];
    }
    if (t.contains('cloud') || t.contains('docker') || t.contains('kubernetes') || t.contains('devops')) {
      return [
        'OCI Container Image Layering & Multi-Stage Compilation',
        'Pod Lifecycle, Service Discovery & Ingress Routing',
        'CI/CD Workflows, Secret Vaults & Automated Rollbacks',
        'Observability, Prometheus Metrics & Distributed Tracing',
      ];
    }
    if (t.contains('node') || t.contains('express') || t.contains('backend')) {
      return [
        'Node.js Event Loop Phases, Microtasks & libuv Pool',
        'Express Middleware Pipelines & Centralized Error Handlers',
        'JWT Authentication, Cookie Security & Rate Limiting',
        'Asynchronous Streams, Backpressure & Memory Profiling',
      ];
    }
    return [
      'Core Theoretical Principles & Execution Model',
      'Architectural Patterns & Component Separation',
      'Error Handling, Edge Cases & Verification',
      'Production Profiling & Performance Tuning',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final activeRoadmapAsync = ref.watch(activeUserRoadmapProvider);
    final effectiveRoadmapId = widget.roadmapId ?? activeRoadmapAsync.value?.roadmapId;

    final nodeContextAsync = (effectiveRoadmapId != null && effectiveRoadmapId.isNotEmpty)
        ? ref.watch(roadmapNodeContextProvider(NodeContextQuery(roadmapId: effectiveRoadmapId, nodeId: widget.nodeId)))
        : null;

    final resourceQuery = ResourceQuery(topic: widget.topic, language: 'English');
    final youtubeAsync = ref.watch(youTubeResourcesProvider(resourceQuery));
    final playlistsAsync = ref.watch(youTubePlaylistsProvider(resourceQuery));
    final githubAsync = ref.watch(gitHubResourcesProvider(widget.topic));

    final nodeContext = nodeContextAsync?.value;
    final roleTitle = nodeContext?.roadmap['targetRole'] ??
        nodeContext?.careerGoal ??
        activeRoadmapAsync.value?.targetRole ??
        'Engineering Track';

    return Scaffold(
      backgroundColor: CareerTheme.background,
      appBar: AppBar(
        backgroundColor: CareerTheme.background,
        elevation: 0,
        leading: BackButton(
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.topic,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '$roleTitle • Phase ${widget.phaseNumber}',
              style: const TextStyle(fontSize: 11, color: CareerTheme.primaryCyan),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented Tabs: [Learn] [Practice] [Quiz] [Resources]
              Center(
                child: CareerSegmentedControl(
                  segments: const ['Learn', 'Practice', 'Quiz', 'Resources'],
                  selectedIndex: _selectedTab,
                  onSegmentSelected: (idx) => setState(() => _selectedTab = idx),
                ),
              ),
              const SizedBox(height: 20),

              // Active Node Learning Objective Header
              _buildObjectiveHeader(nodeContext),
              const SizedBox(height: 18),

              // Tab View Contents
              if (_selectedTab == 0)
                _buildLearnTab(context, nodeContext, youtubeAsync)
              else if (_selectedTab == 1)
                _buildPracticeTab(context, nodeContext, githubAsync)
              else if (_selectedTab == 2)
                _buildQuizTab(context, nodeContext, effectiveRoadmapId)
              else
                _buildResourcesTab(context, nodeContext, youtubeAsync, playlistsAsync, githubAsync),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildObjectiveHeader(RoadmapNodeContextModel? nodeContext) {
    final objective = nodeContext?.learningObjective ??
        'Master ${widget.topic} fundamentals, production semantics, and hands-on implementation patterns.';
    final prereqs = nodeContext?.prerequisites ?? [];

    return CareerGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: CareerTheme.radiusMedium,
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
                child: const Icon(Icons.track_changes_rounded, color: CareerTheme.primaryCyan, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Learning Objective',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CareerTheme.primaryCyan),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            objective,
            style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4),
          ),
          if (prereqs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                const Text('Prerequisites: ', style: TextStyle(fontSize: 11, color: CareerTheme.textMuted)),
                ...prereqs.map(
                  (p) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: CareerTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: CareerTheme.glassBorder),
                    ),
                    child: Text(p, style: const TextStyle(fontSize: 10, color: CareerTheme.primaryCyan)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: LEARN (VIDEO PREVIEW + CONCEPTS)
  // ==========================================
  Widget _buildLearnTab(
    BuildContext context,
    RoadmapNodeContextModel? nodeContext,
    AsyncValue<List<Map<String, dynamic>>> youtubeAsync,
  ) {
    // Resolve primary video
    Map<String, dynamic>? primaryVideo;
    List<Map<String, dynamic>> followUpVideos = [];

    if (nodeContext != null && nodeContext.videos.isNotEmpty) {
      primaryVideo = nodeContext.videos.first.toMap();
      followUpVideos = nodeContext.videos.skip(1).take(3).map((v) => v.toMap()).toList();
    } else if (youtubeAsync.value != null && youtubeAsync.value!.isNotEmpty) {
      primaryVideo = youtubeAsync.value!.first;
      followUpVideos = youtubeAsync.value!.skip(1).take(3).toList();
    }

    final keyConcepts = _resolveKeyConcepts(widget.topic);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Featured Masterclass & Walkthrough', style: CareerTheme.sectionHeader),
        const SizedBox(height: 12),

        // Primary Video Preview Player Card
        _buildVideoPlayerCard(context, primaryVideo, youtubeAsync.isLoading),
        const SizedBox(height: 20),

        // Follow-up Lessons if available
        if (followUpVideos.isNotEmpty) ...[
          const Text('Recommended Follow-Up Lessons', style: CareerTheme.sectionHeader),
          const SizedBox(height: 10),
          ...followUpVideos.map((v) => _buildMiniVideoTile(context, v)),
          const SizedBox(height: 20),
        ],

        // Key Concepts Checklist
        const Text('Technical Mastery Checklist', style: CareerTheme.sectionHeader),
        const SizedBox(height: 10),
        ...keyConcepts.asMap().entries.map((entry) {
          final idx = entry.key;
          final concept = entry.value;
          final isChecked = _checkedConcepts.contains(idx);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: CareerTheme.surface,
              borderRadius: BorderRadius.circular(CareerTheme.radiusMedium),
              border: Border.all(
                color: isChecked
                    ? CareerTheme.success.withValues(alpha: 0.35)
                    : CareerTheme.glassBorder,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(CareerTheme.radiusMedium),
              onTap: () {
                setState(() {
                  if (isChecked) {
                    _checkedConcepts.remove(idx);
                  } else {
                    _checkedConcepts.add(idx);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: isChecked ? CareerTheme.success : CareerTheme.lockedText,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        concept,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: isChecked ? Colors.white : CareerTheme.textSecondary,
                          decoration: isChecked ? TextDecoration.lineThrough : null,
                          decorationColor: CareerTheme.textSubtle,
                        ),
                      ),
                    ),
                    if (isChecked)
                      const Text(
                        'Mastered',
                        style: TextStyle(color: CareerTheme.success, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),

        // EVA AI Mentor Card
        CareerGlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: CareerTheme.radiusMedium,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: CareerTheme.primaryCyan.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology_rounded, color: CareerTheme.primaryCyan, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Stuck on this concept?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(
                      'Ask EVA AI for instant explanation, architecture diagrams, or code debugging.',
                      style: TextStyle(fontSize: 11, color: CareerTheme.textMuted, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: CareerTheme.primaryCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: () => AskAiDoubtSheet.show(
                  context,
                  roadmapId: widget.roadmapId,
                  targetRole: widget.topic,
                ),
                child: const Text('Ask EVA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlayerCard(
    BuildContext context,
    Map<String, dynamic>? video,
    bool isLoading,
  ) {
    final title = video?['title'] ?? '${widget.topic} Complete Technical Guide';
    final channel = video?['channel'] ?? 'Curated Engineering Expert';
    final duration = video?['duration'] ?? '25:00';
    final views = video?['views'] ?? 'Verified Video';
    final url = video?['url'] ??
        'https://www.youtube.com/results?search_query=${Uri.encodeComponent(widget.topic)}';
    final thumbnailUrl = video?['thumbnailUrl'] as String?;

    return CareerGlassCard(
      padding: EdgeInsets.zero,
      borderRadius: CareerTheme.radiusLarge,
      onTap: () => UrlLauncherService.openUrl(context, url),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video Thumbnail Banner with Play Button
          Container(
            height: 180,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(CareerTheme.radiusLarge)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
                  Positioned.fill(
                    child: Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF0F172A),
                        child: const Center(
                          child: Icon(Icons.video_library_rounded, color: CareerTheme.textSubtle, size: 48),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    color: const Color(0xFF0F172A),
                    child: const Center(
                      child: Icon(Icons.smart_display_rounded, color: CareerTheme.textSubtle, size: 54),
                    ),
                  ),

                // Dark overlay
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                ),

                // Red YouTube Play Icon
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.45),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                ),

                // Duration badge
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
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

          // Metadata Details & Launch Button
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
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.smart_display_rounded, size: 14, color: Color(0xFFEF4444)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$channel • $views',
                        style: const TextStyle(fontSize: 11, color: CareerTheme.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                    label: const Text(
                      'Watch on YouTube',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => UrlLauncherService.openUrl(context, url),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniVideoTile(BuildContext context, Map<String, dynamic> video) {
    final title = video['title'] ?? 'Technical Lecture';
    final channel = video['channel'] ?? 'Educational Partner';
    final duration = video['duration'] ?? '15:00';
    final url = video['url'] ?? '';

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
              child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text('$channel • $duration', style: const TextStyle(fontSize: 10.5, color: CareerTheme.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded, color: CareerTheme.primaryCyan, size: 14),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: PRACTICE (HANDS-ON TASK + REPOS)
  // ==========================================
  Widget _buildPracticeTab(
    BuildContext context,
    RoadmapNodeContextModel? nodeContext,
    AsyncValue<List<Map<String, dynamic>>> githubAsync,
  ) {
    final task = nodeContext?.practiceTask;
    final taskTitle = task?.title ?? '${widget.topic} Hands-on Implementation';
    final taskDifficulty = task?.difficulty ?? 'Intermediate';
    final taskDesc = task?.description ??
        'Build and test a functional component or script demonstrating ${widget.topic}. Verify error handling, edge cases, and asynchronous flows.';
    final expectedOutput = task?.expectedOutput ??
        'A verified executable module or script demonstrating ${widget.topic} with clean passing tests or logs.';
    final hints = task?.hints ?? [
      'Review the official documentation and starter repository before writing code.',
      'Set up minimal configuration parameters and test your entry function locally.',
      'Check error handling paths and boundary values.',
    ];
    final starterCode = task?.starterCode ??
        '// Starter template for ${widget.topic}\n// Implement your solution below\n\nfunction main() {\n  console.log("Ready to implement ${widget.topic}");\n}\nmain();\n';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hands-on Implementation Challenge Card
        const Text('Hands-on Implementation Challenge', style: CareerTheme.sectionHeader),
        const SizedBox(height: 12),

        CareerGlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: CareerTheme.radiusMedium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      taskTitle,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: CareerTheme.primaryCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      taskDifficulty,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: CareerTheme.primaryCyan),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                taskDesc,
                style: const TextStyle(fontSize: 12.5, color: CareerTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 14),

              // Expected Output Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CareerTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CareerTheme.glassBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Expected Output / Acceptance Criteria:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CareerTheme.textMuted)),
                    const SizedBox(height: 4),
                    Text(
                      expectedOutput,
                      style: const TextStyle(fontSize: 12, color: CareerTheme.primaryCyan, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Starter Code with Copy Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Starter Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70)),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 14, color: CareerTheme.primaryCyan),
                    label: const Text('Copy', style: TextStyle(fontSize: 11, color: CareerTheme.primaryCyan)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: starterCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Starter code copied to clipboard!'),
                          backgroundColor: CareerTheme.primaryCyan,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CareerTheme.glassBorder),
                ),
                child: Text(
                  starterCode,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Expandable Hints
              GestureDetector(
                onTap: () => setState(() => _showHints = !_showHints),
                child: Row(
                  children: [
                    Icon(
                      _showHints ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: CareerTheme.primaryCyan,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _showHints ? 'Hide Implementation Hints' : 'View Guided Hints (${hints.length})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CareerTheme.primaryCyan),
                    ),
                  ],
                ),
              ),
              if (_showHints) ...[
                const SizedBox(height: 10),
                ...hints.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${entry.key + 1}. ', style: const TextStyle(fontSize: 11.5, color: CareerTheme.primaryCyan)),
                        Expanded(
                          child: Text(entry.value, style: const TextStyle(fontSize: 11.5, color: CareerTheme.textMuted, height: 1.3)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 16),

              // Action Buttons: Complete Task & Submit Evidence
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _practiceCompleted ? CareerTheme.success : CareerTheme.primaryCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: Icon(_practiceCompleted ? Icons.check_circle_rounded : Icons.check_rounded, size: 16),
                      label: Text(
                        _practiceCompleted ? 'Completed' : 'Mark Completed',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () {
                        setState(() => _practiceCompleted = !_practiceCompleted);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_practiceCompleted
                                ? 'Practice challenge marked complete!'
                                : 'Practice task updated.'),
                            backgroundColor: CareerTheme.success,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CareerTheme.surfaceElevated,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: CareerTheme.glassBorder),
                      ),
                    ),
                    icon: const Icon(Icons.upload_file_rounded, size: 16, color: CareerTheme.primaryCyan),
                    label: const Text('Add Evidence', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    onPressed: () => ProjectsEvidenceView.open(context),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Open Source Starter Repositories
        const CareerSectionHeader(
          title: 'Open Source Starter Repositories',
          subtitle: 'Fork and build real code from curated GitHub repositories',
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
                final desc = repo['description']?.toString() ?? 'Curated GitHub Repository';
                final stars = repo['stars'] ?? 100;

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
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 14),
                            const SizedBox(width: 3),
                            Text('$stars', style: const TextStyle(fontSize: 11, color: CareerTheme.textMuted)),
                            const SizedBox(width: 8),
                            const Icon(Icons.open_in_new_rounded, color: CareerTheme.primaryCyan, size: 15),
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
      ],
    );
  }

  // ==========================================
  // TAB 3: QUIZ (10-QUESTION ADAPTIVE CHECKPOINT)
  // ==========================================
  Widget _buildQuizTab(
    BuildContext context,
    RoadmapNodeContextModel? nodeContext,
    String? effectiveRoadmapId,
  ) {
    final skillName = nodeContext?.skill ?? widget.topic;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Adaptive Knowledge Checkpoint', style: CareerTheme.sectionHeader),
        const SizedBox(height: 12),

        CareerGlassCard(
          padding: const EdgeInsets.all(18),
          borderRadius: CareerTheme.radiusLarge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: CareerTheme.primaryCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.quiz_rounded, color: CareerTheme.primaryCyan, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.topic} Checkpoint',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '10 Rigorous Adaptive Questions',
                          style: TextStyle(fontSize: 12, color: CareerTheme.primaryCyan, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'This AI-evaluated adaptive quiz verifies your mastery across code syntax, real-world debugging, system trade-offs, and edge cases.',
                style: TextStyle(fontSize: 12.5, color: CareerTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),

              // Highlights row
              Row(
                children: [
                  _buildStatBadge(Icons.format_list_numbered_rounded, '10 Questions'),
                  const SizedBox(width: 8),
                  _buildStatBadge(Icons.verified_rounded, '≥70% to Pass'),
                  const SizedBox(width: 8),
                  _buildStatBadge(Icons.auto_awesome_rounded, 'Skill Evidence'),
                ],
              ),
              const SizedBox(height: 16),

              // Checklist points
              _buildBulletPoint('Calibrated dynamically to your target engineering role.'),
              const SizedBox(height: 6),
              _buildBulletPoint('Covers scenario questions, edge cases, and code snippets.'),
              const SizedBox(height: 6),
              _buildBulletPoint('Automatically persists Skill Evidence to your Career Profile upon passing.'),
              const SizedBox(height: 20),

              // Launch Quiz CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CareerTheme.primaryCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                  label: const Text(
                    'Start 10-Question Adaptive Quiz',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  onPressed: () {
                    AdaptiveQuizView.open(
                      context,
                      topic: widget.topic,
                      phaseNumber: widget.phaseNumber,
                      roadmapId: effectiveRoadmapId,
                      skillName: skillName,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatBadge(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: CareerTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CareerTheme.glassBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: CareerTheme.primaryCyan),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('✓ ', style: TextStyle(color: CareerTheme.primaryCyan, fontWeight: FontWeight.w700, fontSize: 13)),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 11.5, color: CareerTheme.textMuted, height: 1.3)),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 4: RESOURCES (DOCS + PLAYLISTS + ARTICLES)
  // ==========================================
  Widget _buildResourcesTab(
    BuildContext context,
    RoadmapNodeContextModel? nodeContext,
    AsyncValue<List<Map<String, dynamic>>> youtubeAsync,
    AsyncValue<List<Map<String, dynamic>>> playlistsAsync,
    AsyncValue<List<Map<String, dynamic>>> githubAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Official Documentation Section
        const Text('Official Documentation', style: CareerTheme.sectionHeader),
        const SizedBox(height: 12),
        Builder(
          builder: (context) {
            final docs = CareerDocsResolver.resolve(widget.topic);
            return CareerGlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: CareerTheme.radiusMedium,
              onTap: () => UrlLauncherService.openUrl(context, docs.url),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Official Docs & API Specs (${docs.domain})',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(docs.domain, style: const TextStyle(fontSize: 11, color: CareerTheme.primaryCyan)),
                        const SizedBox(height: 4),
                        Text(
                          docs.description,
                          style: const TextStyle(fontSize: 11, color: CareerTheme.textMuted, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.open_in_new_rounded, color: CareerTheme.primaryCyan, size: 18),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),

        // 2. Related Playlists Section
        const Text('Related Playlists', style: CareerTheme.sectionHeader),
        const SizedBox(height: 12),

        playlistsAsync.when(
          data: (playlists) {
            final items = playlists.isNotEmpty
                ? playlists.take(3).toList()
                : (youtubeAsync.value?.skip(1).take(2).toList() ?? []);

            if (items.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              children: items.map((v) {
                final title = v['title'] ?? 'Comprehensive Engineering Playlist';
                final channel = v['channel'] ?? 'Curated Educational Partner';
                final url = v['url'] ?? '';
                final itemCount = v['itemCount'] ?? v['item_count'];

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
                          child: const Icon(Icons.playlist_play_rounded, color: Color(0xFFEF4444), size: 24),
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
                                itemCount != null
                                    ? '$channel • $itemCount videos'
                                    : '$channel • Curated Educational Series',
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
        const SizedBox(height: 24),

        // 3. Recommended Articles & Deep Dives
        const Text('Recommended Articles & Deep Dives', style: CareerTheme.sectionHeader),
        const SizedBox(height: 12),

        _buildArticleCard(
          icon: Icons.article_rounded,
          iconColor: const Color(0xFF10B981),
          title: '${widget.topic} In-Depth Guide & Real-World Examples',
          domain: 'medium.com',
          url: 'https://medium.com/tag/${Uri.encodeComponent(widget.topic)}',
        ),
        const SizedBox(height: 10),

        _buildArticleCard(
          icon: Icons.language_rounded,
          iconColor: const Color(0xFFF59E0B),
          title: 'Core Concepts & Specifications',
          domain: 'dev.to',
          url: 'https://dev.to/t/${Uri.encodeComponent(widget.topic)}',
        ),
      ],
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
