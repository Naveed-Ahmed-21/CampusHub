import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/career_repository.dart';
import '../../domain/career_models.dart';
import '../providers/career_provider.dart';
import 'quiz_result_view.dart';

class AdaptiveQuizView extends ConsumerStatefulWidget {
  final String topic;
  final int phaseNumber;
  final String? roadmapId;
  final String? skillName;

  const AdaptiveQuizView({
    super.key,
    required this.topic,
    this.phaseNumber = 1,
    this.roadmapId,
    this.skillName,
  });

  static void open(
    BuildContext context, {
    required String topic,
    int phaseNumber = 1,
    String? roadmapId,
    String? skillName,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdaptiveQuizView(
          topic: topic,
          phaseNumber: phaseNumber,
          roadmapId: roadmapId,
          skillName: skillName,
        ),
      ),
    );
  }

  @override
  ConsumerState<AdaptiveQuizView> createState() => _AdaptiveQuizViewState();
}

class _AdaptiveQuizViewState extends ConsumerState<AdaptiveQuizView> {
  AdaptiveQuizModel? _quiz;
  bool _isLoading = true;
  String? _errorMessage;

  int _currentIndex = 0;
  final Map<int, int> _userAnswers = {}; // questionIndex -> selectedOptionIndex
  int _secondsRemaining = 300; // 5 minutes
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        _submitQuiz();
      }
    });
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(careerRepositoryProvider);
      final quiz = await repo.generateAdaptiveQuizV2(
        topic: widget.topic,
        phaseNumber: widget.phaseNumber,
        roadmapId: widget.roadmapId,
        skillName: widget.skillName,
      );

      setState(() {
        _quiz = quiz;
        _isLoading = false;
      });
      _startTimer();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load adaptive quiz: $e';
      });
    }
  }

  Future<void> _submitQuiz() async {
    _timer?.cancel();
    if (_quiz == null) return;

    // Show submitting overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      ),
    );

    try {
      final repo = ref.read(careerRepositoryProvider);
      final questionsPayload = _quiz!.questions
          .map((q) => {
                'id': q.id,
                'question': q.question,
                'options': q.options,
                'correctIndex': q.correctIndex,
                'explanation': q.explanation,
                'concept': q.concept,
                'difficulty': q.difficulty,
              })
          .toList();

      final stringKeyAnswers = <String, dynamic>{};
      _userAnswers.forEach((k, v) {
        stringKeyAnswers[k.toString()] = v;
      });

      final result = await repo.submitAdaptiveQuizV2(
        roadmapId: widget.roadmapId,
        phaseNumber: widget.phaseNumber,
        topic: widget.topic,
        skillName: widget.skillName,
        answers: stringKeyAnswers,
        questions: questionsPayload,
        timeSpentSeconds: 300 - _secondsRemaining,
      );

      ref.invalidate(activeUserRoadmapProvider);
      ref.invalidate(detailedJobReadinessProvider(null));

      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading dialog
        QuizResultView.open(
          context,
          topic: widget.topic,
          resultData: result,
          roadmapId: widget.roadmapId,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error evaluating quiz: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          leading: const BackButton(color: Colors.white),
          title: const Text('Adaptive Checkpoint Quiz', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF6366F1)),
              SizedBox(height: 16),
              Text('Generating adaptive checkpoint questions...', style: TextStyle(color: Color(0xFF94A3B8))),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _quiz == null || _quiz!.questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          leading: const BackButton(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'Quiz unavailable', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadQuiz,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final questions = _quiz!.questions;
    final currentQ = questions[_currentIndex];
    final selectedOption = _userAnswers[_currentIndex];
    final progress = (_currentIndex + 1) / questions.length;

    final mins = _secondsRemaining ~/ 60;
    final secs = _secondsRemaining % 60;
    final timeFormatted = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          widget.topic,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _secondsRemaining < 60 ? const Color(0xFFEF4444) : const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_rounded,
                  size: 14,
                  color: _secondsRemaining < 60 ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
                ),
                const SizedBox(width: 4),
                Text(
                  timeFormatted,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _secondsRemaining < 60 ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF1E293B),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question index & concept badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentIndex + 1} of ${questions.length}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    currentQ.concept,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF818CF8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Question Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          currentQ.difficulty,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF38BDF8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currentQ.question,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Options
            ...currentQ.options.asMap().entries.map((entry) {
              final optIdx = entry.key;
              final optText = entry.value;
              final isChosen = selectedOption == optIdx;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isChosen ? const Color(0xFF6366F1).withValues(alpha: 0.15) : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isChosen ? const Color(0xFF6366F1) : const Color(0xFF334155),
                    width: isChosen ? 1.5 : 1.0,
                  ),
                ),
                child: ListTile(
                  onTap: () {
                    setState(() => _userAnswers[_currentIndex] = optIdx);
                  },
                  leading: Radio<int>(
                    value: optIdx,
                    groupValue: selectedOption,
                    activeColor: const Color(0xFF6366F1),
                    onChanged: (val) {
                      if (val != null) setState(() => _userAnswers[_currentIndex] = val);
                    },
                  ),
                  title: Text(
                    optText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isChosen ? FontWeight.w600 : FontWeight.w400,
                      color: isChosen ? Colors.white : const Color(0xFFCBD5E1),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 28),

            // Navigation Buttons
            Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentIndex--),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF94A3B8),
                        side: const BorderSide(color: Color(0xFF334155)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentIndex > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentIndex < questions.length - 1) {
                        setState(() => _currentIndex++);
                      } else {
                        _submitQuiz();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _currentIndex < questions.length - 1 ? 'Next Question' : 'Submit & Analyze',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
