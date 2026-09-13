import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/career_provider.dart';
import '../theme/career_theme.dart';
import '../widgets/career_shared_widgets.dart';
import 'eva_interview_room_view.dart';

class InterviewPrepView extends ConsumerStatefulWidget {
  final String targetRole;
  final String? roadmapId;

  const InterviewPrepView({
    super.key,
    required this.targetRole,
    this.roadmapId,
  });

  static void open(BuildContext context, {required String targetRole, String? roadmapId}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InterviewPrepView(targetRole: targetRole, roadmapId: roadmapId),
      ),
    );
  }

  @override
  ConsumerState<InterviewPrepView> createState() => _InterviewPrepViewState();
}

class _InterviewPrepViewState extends ConsumerState<InterviewPrepView> {
  int _selectedTab = 0; // 0 = Practice, 1 = History
  int _currentQuestionIndex = 0;
  bool _isRecording = false;
  bool _isEvaluating = false;
  Map<String, dynamic>? _lastEvaluation;

  final TextEditingController _answerController = TextEditingController();
  Timer? _timer;
  int _timeRemainingSeconds = 120; // 2 minutes per question

  final List<Map<String, dynamic>> _fallbackQuestions = [
    {
      'question': 'Explain the Virtual DOM and how React uses reconciliation to optimize UI updates.',
      'category': 'React & Component Architecture',
      'keyConcepts': ['Diffing Algorithm', 'Component Re-rendering', 'Keys Optimization', 'Fiber Tree'],
      'idealAnswer': 'The Virtual DOM is a lightweight in-memory representation of the actual DOM. When state changes, React creates a new VDOM tree, runs the reconciliation diffing algorithm (O(n) heuristic), and computes the minimum set of mutations before applying them in batch via React Fiber.',
    },
    {
      'question': 'How do you structure a production system to handle unexpected latency and network drops?',
      'category': 'Resilient Architecture & API Contracts',
      'keyConcepts': ['Exponential Backoff', 'Circuit Breakers', 'Optimistic UI', 'Offline Storage'],
      'idealAnswer': 'Implement idempotent requests with exponential backoff retries and jitter, configure client-side circuit breakers, leverage optimistic UI mutations with local cache rollbacks, and queue offline mutations.',
    },
    {
      'question': 'What are the performance tradeoffs between SSR (Server-Side Rendering) and CSR (Client-Side Rendering)?',
      'category': 'Web Performance & Rendering Engines',
      'keyConcepts': ['Time to First Byte (TTFB)', 'First Contentful Paint (FCP)', 'Time to Interactive (TTI)', 'Hydration Cost'],
      'idealAnswer': 'SSR delivers fast FCP and better SEO at the expense of server load and hydration delay (TTI). CSR offloads rendering to clients for fast subsequent navigation but suffers from initial blank screen and higher TTFB/FCP.',
    },
    {
      'question': 'Explain how concurrency primitives like Mutexes and Channels differ in asynchronous workloads.',
      'category': 'Concurrency & Systems Programming',
      'keyConcepts': ['Shared Memory Lock', 'Message Passing', 'Deadlock Prevention', 'CSP Pattern'],
      'idealAnswer': 'Mutexes guard shared mutable state through mutual exclusion locks, risking deadlocks and contention. Channels follow CSP (Communicating Sequential Processes) principles, sharing memory by communicating rather than communicating by sharing memory.',
    },
    {
      'question': 'Describe a technical tradeoff you made in a recent project and how you validated the outcome.',
      'category': 'System Design & STAR Behavioral',
      'keyConcepts': ['STAR Framework', 'Bottleneck Identification', 'Quantifiable Metrics', 'Simplicity vs Optimization'],
      'idealAnswer': 'Use Situation, Task, Action, Result. Frame the tradeoff around concrete engineering metrics (e.g. choosing Postgres JSONB over a separate Mongo instance to reduce operational overhead while monitoring query latencies under 5ms).',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answerController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timeRemainingSeconds = 120);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeRemainingSeconds > 0) {
        if (mounted) setState(() => _timeRemainingSeconds--);
      } else {
        t.cancel();
      }
    });
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (_isRecording && _answerController.text.isEmpty) {
        _answerController.text = 'The Virtual DOM creates an in-memory replica of UI elements, diffing nodes via reconciliation algorithms to minimize expensive DOM reflows.';
      }
    });
  }

  Future<void> _submitAnswer(Map<String, dynamic> currentQ) async {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _isEvaluating = true;
    });

    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    final keyConcepts = (currentQ['keyConcepts'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final studentText = _answerController.text.toLowerCase();
    final detected = keyConcepts.where((c) => studentText.contains(c.toLowerCase())).toList();
    final missing = keyConcepts.where((c) => !studentText.contains(c.toLowerCase())).toList();
    final coverage = keyConcepts.isEmpty ? 0.75 : (detected.length / keyConcepts.length);
    final score = (coverage * 100).round().clamp(45, 96);
    final feedback = detected.isNotEmpty
        ? 'Solid articulation covering ${detected.join(', ')}. Keep reinforcing real-world tradeoffs to elevate depth.'
        : 'Ensure your response directly addresses key concepts such as ${keyConcepts.take(2).join(', ')}.';

    setState(() {
      _isEvaluating = false;
      _lastEvaluation = {
        'score': score,
        'detectedConcepts': detected.isNotEmpty ? detected : keyConcepts.take(2).toList(),
        'missingConcepts': missing,
        'feedback': feedback,
      };
    });
  }

  void _nextQuestion(int totalCount) {
    setState(() {
      if (totalCount > 0 && _currentQuestionIndex < totalCount - 1) {
        _currentQuestionIndex++;
      } else {
        _currentQuestionIndex = 0;
      }
      _lastEvaluation = null;
      _answerController.clear();
      _isRecording = false;
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'AI Interview Practice',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3),
            ),
            const SizedBox(height: 2),
            Text(
              widget.targetRole,
              style: const TextStyle(fontSize: 11, color: CareerTheme.textMuted),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () {
                EvaInterviewRoomView.open(
                  context,
                  targetRole: widget.targetRole,
                  roadmapId: widget.roadmapId,
                  initialMode: 'VOICE',
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: CareerTheme.accentLavender.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(CareerTheme.radiusPill),
                  border: Border.all(color: CareerTheme.accentLavender.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.video_camera_front_rounded, size: 14, color: Color(0xFFE9D5FF)),
                    SizedBox(width: 4),
                    Text(
                      'Live EVA Room',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFE9D5FF)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Segmented Control: [Practice] [History]
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: CareerSegmentedControl(
              segments: const ['Practice', 'History'],
              selectedIndex: _selectedTab,
              onSegmentSelected: (idx) => setState(() => _selectedTab = idx),
            ),
          ),

          Expanded(
            child: _selectedTab == 0 ? _buildPracticeTab() : _buildHistoryTab(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PRACTICE TAB (SCREEN 12)
  // ==========================================
  Widget _buildPracticeTab() {
    final questionsAsync = ref.watch(interviewPrepProvider(widget.roadmapId));
    final List<Map<String, dynamic>> questions = questionsAsync.when(
      data: (items) {
        if (items.isNotEmpty) {
          return items.map((q) => {
            'question': q.question,
            'category': q.category,
            'keyConcepts': q.keyPoints.isNotEmpty ? q.keyPoints : q.tips,
            'idealAnswer': q.idealAnswer,
          }).toList();
        }
        return _fallbackQuestions;
      },
      loading: () => _fallbackQuestions,
      error: (_, __) => _fallbackQuestions,
    );

    final safeIndex = (_currentQuestionIndex < questions.length) ? _currentQuestionIndex : 0;
    final currentQ = questions[safeIndex];
    final minutes = (_timeRemainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_timeRemainingSeconds % 60).toString().padLeft(2, '0');
    final keyConcepts = (currentQ['keyConcepts'] as List<dynamic>?) ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // Question Header: Progress Counter & Timer (⏱ 02:00)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: CareerTheme.surface,
                borderRadius: BorderRadius.circular(CareerTheme.radiusPill),
                border: Border.all(color: CareerTheme.glassBorder),
              ),
              child: Text(
                'Question ${safeIndex + 1} of ${questions.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: CareerTheme.primaryCyan,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _timeRemainingSeconds <= 20
                    ? CareerTheme.error.withValues(alpha: 0.2)
                    : CareerTheme.surface,
                borderRadius: BorderRadius.circular(CareerTheme.radiusPill),
                border: Border.all(
                  color: _timeRemainingSeconds <= 20
                      ? CareerTheme.error.withValues(alpha: 0.5)
                      : CareerTheme.glassBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: _timeRemainingSeconds <= 20 ? CareerTheme.error : CareerTheme.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '⏱ $minutes:$seconds',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _timeRemainingSeconds <= 20 ? CareerTheme.error : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Question Card
        CareerGlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: CareerTheme.accentIndigo.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  (currentQ['category'] ?? 'Technical').toString(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFA5B4FC)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                (currentQ['question'] ?? '').toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: keyConcepts.map((concept) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: CareerTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: CareerTheme.glassBorder),
                    ),
                    child: Text(
                      concept.toString(),
                      style: const TextStyle(fontSize: 10, color: CareerTheme.textMuted),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Ideal Answer / Key Concepts Accordion
        CareerGlassCard(
          padding: const EdgeInsets.all(14),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 8),
              leading: const Icon(Icons.tips_and_updates_outlined, color: CareerTheme.warning, size: 20),
              title: const Text(
                'Key Evaluation Rubric & Ideal Flow',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              children: [
                Text(
                  (currentQ['idealAnswer'] ?? '').toString(),
                  style: const TextStyle(fontSize: 12, color: CareerTheme.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Student Answer Box with Mic
        CareerGlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Response',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  IconButton(
                    icon: Icon(
                      _isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _isRecording ? CareerTheme.error : CareerTheme.primaryCyan,
                    ),
                    onPressed: _toggleRecording,
                    tooltip: 'Speak Answer (Simulated Voice)',
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _answerController,
                maxLines: 5,
                style: const TextStyle(fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type or speak your answer structure...',
                  hintStyle: const TextStyle(color: CareerTheme.textMuted, fontSize: 12),
                  filled: true,
                  fillColor: CareerTheme.surfaceMuted,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: CareerTheme.glassBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: CareerTheme.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: CareerTheme.primaryCyan),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Evaluation Feedback Card (Shown after submitting)
        if (_lastEvaluation != null) ...[
          _buildEvaluationCard(_lastEvaluation!),
          const SizedBox(height: 16),
        ],

        // Action Buttons
        if (_lastEvaluation == null)
          CareerPrimaryButton(
            label: 'Submit Answer',
            icon: Icons.send_rounded,
            isLoading: _isEvaluating,
            onPressed: () => _submitAnswer(currentQ),
          )
        else
          CareerPrimaryButton(
            label: safeIndex < questions.length - 1 ? 'Next Question →' : 'Complete Practice Round',
            onPressed: () => _nextQuestion(questions.length),
          ),
      ],
    );
  }

  // ==========================================
  // EVALUATION RESULT CARD
  // ==========================================
  Widget _buildEvaluationCard(Map<String, dynamic> eval) {
    final score = eval['score'] as int;
    final detected = (eval['detectedConcepts'] as List<dynamic>?) ?? [];
    final missing = (eval['missingConcepts'] as List<dynamic>?) ?? [];
    final feedback = eval['feedback'] as String;

    return CareerGlassCard(
      padding: const EdgeInsets.all(18),
      borderColor: CareerTheme.success.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: CareerTheme.primaryCyan, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'EVA AI Evaluation',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CareerTheme.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(CareerTheme.radiusPill),
                  border: Border.all(color: CareerTheme.success.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '$score / 100',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: CareerTheme.success),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            feedback,
            style: const TextStyle(fontSize: 12, color: CareerTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),

          if (detected.isNotEmpty) ...[
            const Text('Concepts Covered:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CareerTheme.success)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: detected.map((c) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: CareerTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: CareerTheme.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check, size: 11, color: CareerTheme.success),
                      const SizedBox(width: 4),
                      Text(c.toString(), style: const TextStyle(fontSize: 10, color: Colors.white)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],

          if (missing.isNotEmpty) ...[
            const Text('Recommended Reinforcements:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CareerTheme.warning)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: missing.map((m) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: CareerTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: CareerTheme.warning.withValues(alpha: 0.3)),
                  ),
                  child: Text(m.toString(), style: const TextStyle(fontSize: 10, color: Color(0xFFFDE68A))),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // HISTORY TAB (SCREEN 12)
  // ==========================================
  Widget _buildHistoryTab() {
    final historyAsync = ref.watch(interviewHistoryProvider);

    return historyAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: CareerTheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: CareerTheme.glassBorder),
                    ),
                    child: const Icon(Icons.history_edu_rounded, size: 36, color: CareerTheme.textMuted),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Interview Sessions Yet',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Take a 1-on-1 mock interview with EVA AI or practice questions to record your interview performance and readiness.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: CareerTheme.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  CareerPrimaryButton(
                    label: 'Start Live EVA Room',
                    icon: Icons.video_camera_front_rounded,
                    onPressed: () {
                      EvaInterviewRoomView.open(
                        context,
                        targetRole: widget.targetRole,
                        roadmapId: widget.roadmapId,
                        initialMode: 'VOICE',
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          itemCount: sessions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, idx) {
            final session = sessions[idx];
            final score = session.overallScore ?? session.technicalScore ?? 0;
            final created = session.createdAt != null
                ? '${session.createdAt!.day}/${session.createdAt!.month}/${session.createdAt!.year}'
                : 'Recent';

            return CareerGlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        created,
                        style: const TextStyle(fontSize: 11, color: CareerTheme.textMuted, fontWeight: FontWeight.w500),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: score >= 70 ? CareerTheme.success.withValues(alpha: 0.15) : CareerTheme.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(CareerTheme.radiusPill),
                          border: Border.all(
                            color: score >= 70 ? CareerTheme.success.withValues(alpha: 0.4) : CareerTheme.warning.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'Score: $score%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: score >= 70 ? CareerTheme.success : CareerTheme.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    session.targetRole,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  if (session.finalReport != null && session.finalReport!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      session.finalReport!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: CareerTheme.textSecondary, height: 1.35),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: CareerTheme.primaryCyan)),
      error: (err, _) => Center(
        child: Text(
          'Failed to load interview history: $err',
          style: const TextStyle(color: CareerTheme.textMuted),
        ),
      ),
    );
  }
}
