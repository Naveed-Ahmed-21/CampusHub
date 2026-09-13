import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/career_repository.dart';
import '../../domain/career_models.dart';
import '../providers/career_provider.dart';
import '../theme/career_theme.dart';
import '../widgets/career_shared_widgets.dart';
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
  bool _hasAnsweredCurrent = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
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
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load adaptive quiz: $e';
      });
    }
  }

  Future<void> _submitQuiz() async {
    if (_quiz == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: CareerTheme.primaryCyan),
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
        timeSpentSeconds: 120,
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
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error evaluating quiz: $e'),
            backgroundColor: CareerTheme.error,
          ),
        );
      }
    }
  }

  void _onOptionSelected(int optionIndex) {
    if (_hasAnsweredCurrent) return; // Prevent changing after revealing explanation

    setState(() {
      _userAnswers[_currentIndex] = optionIndex;
      _hasAnsweredCurrent = true;
    });
  }

  void _onNextQuestion(int totalQuestions) {
    if (_currentIndex < totalQuestions - 1) {
      setState(() {
        _currentIndex++;
        _hasAnsweredCurrent = _userAnswers.containsKey(_currentIndex);
      });
    } else {
      _submitQuiz();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: CareerTheme.background,
        appBar: AppBar(
          backgroundColor: CareerTheme.background,
          elevation: 0,
          leading: BackButton(
            color: Colors.white,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CareerAIOrb(size: 80, showText: true),
              SizedBox(height: 20),
              Text(
                'Generating adaptive questions...',
                style: TextStyle(color: CareerTheme.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _quiz == null || _quiz!.questions.isEmpty) {
      return Scaffold(
        backgroundColor: CareerTheme.background,
        appBar: AppBar(
          backgroundColor: CareerTheme.background,
          leading: BackButton(
            color: Colors.white,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: CareerTheme.error, size: 48),
                const SizedBox(height: 16),
                Text(_errorMessage ?? 'Quiz unavailable', style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                CareerPrimaryButton(
                  label: 'Retry Quiz',
                  width: 140,
                  onPressed: _loadQuiz,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final questions = _quiz!.questions;
    final currentQ = questions[_currentIndex];
    final selectedOption = _userAnswers[_currentIndex];
    final progress = (_currentIndex + 1) / questions.length;
    final isCorrect = selectedOption == currentQ.correctIndex;

    final optionLetters = ['A', 'B', 'C', 'D'];

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
          'Quiz • ${widget.topic}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: CareerTheme.surfaceElevated,
            valueColor: const AlwaysStoppedAnimation<Color>(CareerTheme.primaryCyan),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question Counter Header (Screen 7)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_currentIndex + 1}/${questions.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: CareerTheme.primaryCyan,
                    ),
                  ),
                  Text(
                    '${_currentIndex + 1}/${questions.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CareerTheme.textSubtle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Question Text (Screen 7)
              Text(
                currentQ.question,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),

              // Answer Cards: A, B, C, D (Screen 7)
              ...currentQ.options.asMap().entries.map((entry) {
                final optIdx = entry.key;
                final optText = entry.value;
                final isSelected = selectedOption == optIdx;
                final letter = optIdx < optionLetters.length ? optionLetters[optIdx] : '${optIdx + 1}';

                Color cardBorderColor = CareerTheme.glassBorder;
                Color cardBgColor = CareerTheme.surface;

                if (isSelected) {
                  if (_hasAnsweredCurrent) {
                    cardBorderColor = isCorrect ? CareerTheme.success : CareerTheme.error;
                    cardBgColor = (isCorrect ? CareerTheme.success : CareerTheme.error).withValues(alpha: 0.15);
                  } else {
                    cardBorderColor = CareerTheme.primaryCyan;
                    cardBgColor = CareerTheme.primaryCyan.withValues(alpha: 0.15);
                  }
                } else if (_hasAnsweredCurrent && optIdx == currentQ.correctIndex) {
                  cardBorderColor = CareerTheme.success;
                  cardBgColor = CareerTheme.success.withValues(alpha: 0.1);
                }

                return GestureDetector(
                  onTap: () => _onOptionSelected(optIdx),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(CareerTheme.radiusLarge),
                      border: Border.all(color: cardBorderColor, width: isSelected ? 1.5 : 1.0),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? CareerTheme.primaryCyan
                                : CareerTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              letter,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? const Color(0xFF0F172A) : Colors.white70,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            optText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : CareerTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),

              // Answer Explanation Card (Revealed after selection)
              if (_hasAnsweredCurrent) ...[
                CareerGlassCard(
                  padding: const EdgeInsets.all(14),
                  borderRadius: CareerTheme.radiusMedium,
                  backgroundColor: (isCorrect ? CareerTheme.success : CareerTheme.warning).withValues(alpha: 0.12),
                  borderColor: (isCorrect ? CareerTheme.success : CareerTheme.warning).withValues(alpha: 0.3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                            color: isCorrect ? CareerTheme.success : CareerTheme.warning,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isCorrect ? 'Correct!' : 'Key Takeaway',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isCorrect ? CareerTheme.success : CareerTheme.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currentQ.explanation.isNotEmpty
                            ? currentQ.explanation
                            : 'This concept validates your core technical understanding of ${widget.topic}.',
                        style: const TextStyle(fontSize: 12, color: CareerTheme.textSecondary, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Next Question CTA
              if (_hasAnsweredCurrent)
                CareerPrimaryButton(
                  label: _currentIndex < questions.length - 1 ? 'Next Question →' : 'Submit & View Results →',
                  onPressed: () => _onNextQuestion(questions.length),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
