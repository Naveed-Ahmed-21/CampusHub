import 'package:flutter/material.dart';
import '../theme/career_theme.dart';
import '../widgets/career_shared_widgets.dart';

class QuizResultView extends StatelessWidget {
  final String topic;
  final Map<String, dynamic> resultData;
  final String? roadmapId;

  const QuizResultView({
    super.key,
    required this.topic,
    required this.resultData,
    this.roadmapId,
  });

  static void open(
    BuildContext context, {
    required String topic,
    required Map<String, dynamic> resultData,
    String? roadmapId,
  }) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QuizResultView(
          topic: topic,
          resultData: resultData,
          roadmapId: roadmapId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = resultData['score'] ?? 8;
    final totalQuestions = resultData['totalQuestions'] ?? 10;
    final percentage = resultData['percentage'] ?? ((score / totalQuestions) * 100).round();
    final correctCount = score;
    final incorrectCount = (totalQuestions - score).clamp(0, totalQuestions);

    final strengths = (resultData['strengths'] as List<dynamic>?) ??
        [
          'Good understanding of components',
          'Strong on foundational principles and state flow',
        ];

    final areasToImprove = (resultData['areasToImprove'] as List<dynamic>?) ??
        [
          'Review async failure handling & streams',
          'Practice lifecycle optimization methods',
        ];

    return Scaffold(
      backgroundColor: CareerTheme.background,
      appBar: AppBar(
        backgroundColor: CareerTheme.background,
        elevation: 0,
        leading: BackButton(
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Quiz Result',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Circular Score Gauge (Screen 8)
              CareerProgressRing(
                percentage: percentage.toDouble(),
                size: 110,
                strokeWidth: 8,
                centerLabel: '$score/$totalQuestions',
                labelStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
                progressColor: percentage >= 70 ? CareerTheme.success : CareerTheme.warning,
              ),
              const SizedBox(height: 16),

              Text(
                percentage >= 70 ? 'Great Work!' : 'Keep Practicing!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "You've completed the quiz.",
                style: TextStyle(fontSize: 13, color: CareerTheme.textMuted),
              ),
              const SizedBox(height: 24),

              // 3 Stat Boxes: Correct, Incorrect, Score (Screen 8)
              Row(
                children: [
                  Expanded(
                    child: _buildStatBox(
                      value: '$correctCount',
                      label: 'Correct',
                      color: CareerTheme.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatBox(
                      value: '$incorrectCount',
                      label: 'Incorrect',
                      color: CareerTheme.error,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatBox(
                      value: '$percentage%',
                      label: 'Score',
                      color: CareerTheme.primaryCyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Strengths Section (Screen 8)
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Strengths', style: CareerTheme.sectionHeader),
              ),
              const SizedBox(height: 10),
              ...strengths.map((s) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: CareerTheme.surface,
                    borderRadius: BorderRadius.circular(CareerTheme.radiusMedium),
                    border: Border.all(color: CareerTheme.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: CareerTheme.success, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.toString(),
                          style: const TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),

              // Areas to Improve Section (Screen 8)
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Areas to Improve', style: CareerTheme.sectionHeader),
              ),
              const SizedBox(height: 10),
              ...areasToImprove.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: CareerTheme.surface,
                    borderRadius: BorderRadius.circular(CareerTheme.radiusMedium),
                    border: Border.all(color: CareerTheme.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.priority_high_rounded, color: CareerTheme.warning, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.toString(),
                          style: const TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 28),

              // Dual Action Buttons (Screen 8)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: CareerTheme.glassBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Review Answers', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CareerPrimaryButton(
                      label: 'Continue Learning',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: CareerTheme.surface,
        borderRadius: BorderRadius.circular(CareerTheme.radiusMedium),
        border: Border.all(color: CareerTheme.glassBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: CareerTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
