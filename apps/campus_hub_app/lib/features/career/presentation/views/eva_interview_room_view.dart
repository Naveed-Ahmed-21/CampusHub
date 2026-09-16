import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/career_repository.dart';
import '../../domain/career_models.dart';
import '../providers/career_provider.dart';
import '../widgets/eva_ai_avatar.dart';

enum InterviewRoomState {
  connecting,
  evaSpeaking,
  studentAnswering,
  evaluating,
  turnFeedback,
  finalReport,
  error,
}

class EvaInterviewRoomView extends ConsumerStatefulWidget {
  final String? roadmapId;
  final String targetRole;
  final String initialMode; // TEXT, VOICE, VIDEO

  const EvaInterviewRoomView({
    super.key,
    this.roadmapId,
    required this.targetRole,
    this.initialMode = 'VOICE',
  });

  static void open(
    BuildContext context, {
    String? roadmapId,
    required String targetRole,
    String initialMode = 'VOICE',
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EvaInterviewRoomView(
          roadmapId: roadmapId,
          targetRole: targetRole,
          initialMode: initialMode,
        ),
      ),
    );
  }

  @override
  ConsumerState<EvaInterviewRoomView> createState() => _EvaInterviewRoomViewState();
}

class _EvaInterviewRoomViewState extends ConsumerState<EvaInterviewRoomView>
    with TickerProviderStateMixin {
  late InterviewRoomState _roomState;
  late String _mode;
  InterviewSessionModel? _session;
  InterviewTurnModel? _currentTurn;
  Map<String, dynamic>? _lastTurnEvaluation;
  String? _errorMessage;

  final TextEditingController _answerController = TextEditingController();
  Timer? _timer;
  int _timeRemainingSeconds = 120;
  bool _isMicActive = false;
  bool _isReinforcingRoadmap = false;

  late AnimationController _waveformController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _roomState = InterviewRoomState.connecting;
    _mode = widget.initialMode;

    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _waveAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _waveformController, curve: Curves.easeInOut),
    );

    _startSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answerController.dispose();
    _waveformController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timeRemainingSeconds = 120;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeRemainingSeconds > 0) {
        setState(() {
          _timeRemainingSeconds--;
        });
      } else {
        t.cancel();
        _submitCurrentAnswer();
      }
    });
  }

  Future<void> _startSession() async {
    setState(() {
      _roomState = InterviewRoomState.connecting;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(careerRepositoryProvider);
      final session = await repo.startInterviewSession(
        roadmapId: widget.roadmapId,
        targetRole: widget.targetRole,
        mode: _mode,
      );

      setState(() {
        _session = session;
        _currentTurn = session.nextTurn ?? (session.turns.isNotEmpty ? session.turns.first : null);
        _roomState = InterviewRoomState.evaSpeaking;
      });

      // Give 2 seconds for EVA to speak the question, then let student answer
      Future.delayed(const Duration(milliseconds: 2200), () {
        if (mounted && _roomState == InterviewRoomState.evaSpeaking) {
          setState(() {
            _roomState = InterviewRoomState.studentAnswering;
            if (_mode == 'VOICE' || _mode == 'VIDEO') {
              _isMicActive = true;
            }
          });
          _startTimer();
        }
      });
    } catch (e) {
      setState(() {
        _roomState = InterviewRoomState.error;
        _errorMessage = 'Failed to connect to EVA AI Interview Server: $e';
      });
    }
  }

  Future<void> _submitCurrentAnswer() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter or speak your answer before submitting.'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }

    _timer?.cancel();
    setState(() {
      _roomState = InterviewRoomState.evaluating;
      _isMicActive = false;
    });

    try {
      final repo = ref.read(careerRepositoryProvider);
      final evalResult = await repo.submitInterviewTurn(
        sessionId: _session!.id,
        studentAnswer: answer,
      );

      setState(() {
        _lastTurnEvaluation = evalResult;
        _roomState = InterviewRoomState.turnFeedback;
        _answerController.clear();
      });
    } catch (e) {
      setState(() {
        _roomState = InterviewRoomState.error;
        _errorMessage = 'Error evaluating answer: $e';
      });
    }
  }

  Future<void> _proceedToNextQuestionOrFinish() async {
    final nextTurnJson = _lastTurnEvaluation?['next_turn'] as Map<String, dynamic>?;
    final isComplete = _lastTurnEvaluation?['is_complete'] as bool? ?? false;

    if (isComplete || nextTurnJson == null) {
      // Fetch Final Report
      setState(() {
        _roomState = InterviewRoomState.evaluating;
      });
      try {
        final repo = ref.read(careerRepositoryProvider);
        final finalReport = await repo.finishInterviewSession(sessionId: _session!.id);
        setState(() {
          _session = finalReport;
          _roomState = InterviewRoomState.finalReport;
        });
        // Invalidate job readiness so new interview score reflects immediately
        ref.invalidate(jobReadinessProvider);
      } catch (e) {
        setState(() {
          _roomState = InterviewRoomState.error;
          _errorMessage = 'Failed to generate final report: $e';
        });
      }
    } else {
      setState(() {
        _currentTurn = InterviewTurnModel.fromJson(nextTurnJson);
        _roomState = InterviewRoomState.evaSpeaking;
      });

      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted && _roomState == InterviewRoomState.evaSpeaking) {
          setState(() {
            _roomState = InterviewRoomState.studentAnswering;
            if (_mode == 'VOICE' || _mode == 'VIDEO') {
              _isMicActive = true;
            }
          });
          _startTimer();
        }
      });
    }
  }

  Future<void> _applyRoadmapReinforcement() async {
    if (_session == null || _isReinforcingRoadmap) return;

    setState(() {
      _isReinforcingRoadmap = true;
    });

    try {
      final repo = ref.read(careerRepositoryProvider);
      await repo.applyInterviewRoadmapUpdate(sessionId: _session!.id);

      ref.invalidate(activeUserRoadmapProvider);
      ref.invalidate(jobReadinessProvider);
      ref.invalidate(roadmapChangesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎯 Your Career Roadmap has been reinforced based on interview findings!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isReinforcingRoadmap = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update roadmap: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D), // Dark interview room studio background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => _confirmExit(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.targetRole} Mock Interview',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Flexible(
                  child: Text(
                    'EVA AI Studio • Branching Evaluator',
                    style: TextStyle(fontSize: 11, color: Colors.white60),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Mode Pill Switcher
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeBtn('TEXT', Icons.keyboard),
                _buildModeBtn('VOICE', Icons.mic),
                _buildModeBtn('VIDEO', Icons.videocam),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildRoomBody(),
      ),
    );
  }

  Widget _buildModeBtn(String modeVal, IconData icon) {
    final isSelected = _mode == modeVal;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          _mode = modeVal;
          if (modeVal == 'VOICE' || modeVal == 'VIDEO') {
            _isMicActive = true;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          size: 15,
          color: isSelected ? Colors.white : Colors.white60,
        ),
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Leave Interview?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to end this interview session? Your progress so far will be recorded.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('End Interview'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomBody() {
    switch (_roomState) {
      case InterviewRoomState.connecting:
        return _buildConnectingView();
      case InterviewRoomState.evaSpeaking:
      case InterviewRoomState.studentAnswering:
        return _buildActiveTurnView();
      case InterviewRoomState.evaluating:
        return _buildEvaluatingView();
      case InterviewRoomState.turnFeedback:
        return _buildTurnFeedbackView();
      case InterviewRoomState.finalReport:
        return _buildFinalReportView();
      case InterviewRoomState.error:
        return _buildErrorView();
    }
  }

  Widget _buildConnectingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const EvaAiAvatar(size: 72),
          const SizedBox(height: 24),
          const CircularProgressIndicator(color: Color(0xFF38BDF8)),
          const SizedBox(height: 18),
          const Text(
            'Initializing 1-on-1 Interview Session...',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Calibrating technical questions for ${widget.targetRole}',
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTurnView() {
    final turnNum = _currentTurn?.turnNumber ?? 1;
    final totalTurns = _session?.totalTurns ?? 5;
    final question = _currentTurn?.question ?? 'Describe your experience with software architecture.';

    return Column(
      children: [
        // Top Progress & Timer Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Question $turnNum of $totalTurns',
                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    '${(_timeRemainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_timeRemainingSeconds % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: _timeRemainingSeconds <= 20 ? Colors.redAccent : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Upper Section: EVA Avatar + Video Camera Preview
        Expanded(
          flex: 5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background ambient glow
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      Colors.indigo.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Center Avatar + Pulse
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _waveAnimation,
                    builder: (context, child) {
                      final scale = _roomState == InterviewRoomState.evaSpeaking
                          ? _waveAnimation.value
                          : 1.0;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _roomState == InterviewRoomState.evaSpeaking
                                  ? const Color(0xFF38BDF8)
                                  : Colors.indigo.withValues(alpha: 0.5),
                              width: 3,
                            ),
                          ),
                          child: const EvaAiAvatar(size: 80),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _roomState == InterviewRoomState.evaSpeaking
                          ? const Color(0xFF0369A1)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _roomState == InterviewRoomState.evaSpeaking
                          ? 'EVA Speaking...'
                          : 'Your Turn to Answer',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // In Video Mode: Picture-in-picture student camera tile
              if (_mode == 'VIDEO')
                Positioned(
                  top: 10,
                  right: 16,
                  child: Container(
                    width: 95,
                    height: 125,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.person, color: Colors.white38, size: 48),
                        Positioned(
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Camera Active', style: TextStyle(color: Colors.white, fontSize: 8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Middle Section: Question Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.format_quote, color: Color(0xFF38BDF8), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Interviewer Question:',
                    style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                question,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),

        // Bottom Section: Student Response Controls
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: TextField(
                    controller: _answerController,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      hintText: _isMicActive
                          ? 'Listening to your speech... (or type your technical answer here)'
                          : 'Type your technical answer here...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Mic toggle
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: _isMicActive ? Colors.redAccent : const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                      ),
                      onPressed: () {
                        setState(() {
                          _isMicActive = !_isMicActive;
                        });
                      },
                      icon: Icon(_isMicActive ? Icons.mic : Icons.mic_off),
                    ),
                    const SizedBox(width: 12),
                    // Submit answer button
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF38BDF8),
                          foregroundColor: const Color(0xFF0A0F1D),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _roomState == InterviewRoomState.studentAnswering
                            ? _submitCurrentAnswer
                            : null,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text(
                          'Submit Answer',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEvaluatingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const EvaAiAvatar(size: 64),
          const SizedBox(height: 24),
          const CircularProgressIndicator(color: Color(0xFF38BDF8)),
          const SizedBox(height: 18),
          const Text(
            'Analyzing Technical Depth...',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Extracting expected architecture concepts, clarity of thought, and practical trade-offs.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnFeedbackView() {
    final eval = _lastTurnEvaluation ?? {};
    final score = eval['score'] as int? ?? 75;
    final detected = (eval['detected_concepts'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final missing = (eval['missing_concepts'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final feedback = eval['feedback'] as String? ?? 'Good explanation of foundational concepts.';
    final followUp = eval['follow_up_question'] as String?;
    final isComplete = eval['is_complete'] as bool? ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Turn Evaluation & Feedback',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: score >= 70 ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: score >= 70 ? Colors.green : Colors.orange),
                ),
                child: Text(
                  '$score / 100',
                  style: TextStyle(
                    color: score >= 70 ? Colors.greenAccent : Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Feedback Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    EvaAiAvatar(size: 24),
                    SizedBox(width: 8),
                    Text(
                      'EVA AI Analysis',
                      style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  feedback,
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Detected Concepts
          if (detected.isNotEmpty) ...[
            const Text(
              'Concepts You Explained Well:',
              style: TextStyle(color: Colors.greenAccent, fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: detected.map((concept) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check, size: 12, color: Colors.greenAccent),
                      const SizedBox(width: 4),
                      Text(concept, style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Missing Concepts
          if (missing.isNotEmpty) ...[
            const Text(
              'Missing or Incomplete Concepts:',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: missing.map((concept) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.priority_high, size: 12, color: Colors.orangeAccent),
                      const SizedBox(width: 4),
                      Text(concept, style: const TextStyle(color: Colors.orangeAccent, fontSize: 11)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Follow-up question preview
          if (followUp != null && followUp.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Branching Follow-Up from EVA:',
                    style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    followUp,
                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Action Button: Next Question or View Report
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: const Color(0xFF0A0F1D),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _proceedToNextQuestionOrFinish,
              icon: Icon(isComplete ? Icons.assessment : Icons.arrow_forward),
              label: Text(
                isComplete ? 'View Comprehensive Scorecard' : 'Continue to Next Question',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalReportView() {
    final report = _session!;
    final overall = report.overallScore ?? 78;
    final tech = report.technicalScore ?? 75;
    final comm = report.communicationScore ?? 80;
    final clarity = report.clarityScore ?? 80;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                const EvaAiAvatar(size: 60),
                const SizedBox(height: 14),
                const Text(
                  'Interview Performance Scorecard',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  'Target Role: ${widget.targetRole}',
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Score Breakdown Grid
          Row(
            children: [
              _buildScoreTile('Overall', '$overall%', Colors.cyanAccent),
              const SizedBox(width: 8),
              _buildScoreTile('Technical', '$tech%', Colors.indigoAccent),
              const SizedBox(width: 8),
              _buildScoreTile('Clarity', '$clarity%', Colors.greenAccent),
              const SizedBox(width: 8),
              _buildScoreTile('Comm', '$comm%', Colors.purpleAccent),
            ],
          ),
          const SizedBox(height: 20),

          // Summary Feedback
          if (report.summaryFeedback != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Executive Summary:',
                    style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report.summaryFeedback!,
                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Key Strengths
          if (report.strengths.isNotEmpty) ...[
            const Text(
              'Verified Strengths:',
              style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...report.strengths.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✓ ', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
          ],

          // Areas for Improvement
          if (report.improvements.isNotEmpty) ...[
            const Text(
              'Recommended Focus Areas:',
              style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...report.improvements.map((imp) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('! ', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(imp, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 20),
          ],

          // 1-Tap Roadmap Reinforcement Action
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade900, const Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.indigoAccent),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFF38BDF8), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Adaptive Learning Loop',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'EVA can automatically update your Career Roadmap to target the gaps identified in this interview.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      foregroundColor: const Color(0xFF0A0F1D),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isReinforcingRoadmap ? null : _applyRoadmapReinforcement,
                    icon: _isReinforcingRoadmap
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.sync_alt, size: 18),
                    label: Text(
                      _isReinforcingRoadmap ? 'Updating Roadmap...' : 'Reinforce Roadmap With Findings',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Finish & Exit button
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Career Hub', style: TextStyle(color: Colors.white60)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Interview Encountered an Issue',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Connection lost.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _startSession,
              child: const Text('Retry Connection'),
            ),
          ],
        ),
      ),
    );
  }
}
