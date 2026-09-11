import 'package:flutter/material.dart';
import 'adaptive_quiz_view.dart';
import 'career_roadmap_view.dart';

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
    final score = resultData['score'] ?? 0;
    final total = resultData['totalQuestions'] ?? 5;
    final percentage = (resultData['percentage'] as num?)?.toDouble() ?? (total > 0 ? (score / total) * 100 : 0);
    final passed = resultData['passed'] == true || percentage >= 70;

    final strongTopics = (resultData['strongTopics'] as List<dynamic>?) ?? [];
    final needPractice = (resultData['needPractice'] as List<dynamic>?) ?? [];
    final aiInsight = resultData['aiInsight'] ?? 'Good effort. Solid performance on foundational concepts.';
    final recommendedActions = (resultData['recommendedActions'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Quiz Result & Analysis',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SCORE SUMMARY CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: passed
                      ? [const Color(0xFF064E3B), const Color(0xFF065F46), const Color(0xFF0F172A)]
                      : [const Color(0xFF7F1D1D), const Color(0xFF991B1B), const Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: passed ? const Color(0xFF10B981).withOpacity(0.5) : const Color(0xFFEF4444).withOpacity(0.5),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0F172A).withOpacity(0.6),
                      border: Border.all(
                        color: passed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        width: 3,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${percentage.round()}%',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: passed ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFEF4444).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      passed ? 'CHECKPOINT PASSED' : 'NEEDS PRACTICE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: passed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$score of $total Questions Correct',
                    style: const TextStyle(fontSize: 14, color: Color(0xFFCBD5E1)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    topic,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // AI REMEDIATION & INSIGHT
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.psychology_rounded, color: Color(0xFF818CF8), size: 18),
                      SizedBox(width: 8),
                      Text('AI Evaluation & Diagnostic', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    aiInsight.toString(),
                    style: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // STRONG TOPICS
            if (strongTopics.isNotEmpty) ...[
              const Text(
                'Demonstrated Mastery',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: strongTopics.map((t) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF065F46).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                        const SizedBox(width: 6),
                        Text(t.toString(), style: const TextStyle(fontSize: 12, color: Color(0xFFE2E8F0))),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // NEED PRACTICE
            if (needPractice.isNotEmpty) ...[
              const Text(
                'Requires Review',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: needPractice.map((t) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF78350F).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 14),
                        const SizedBox(width: 6),
                        Text(t.toString(), style: const TextStyle(fontSize: 12, color: Color(0xFFE2E8F0))),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // RECOMMENDED NEXT ACTIONS
            if (recommendedActions.isNotEmpty) ...[
              const Text(
                'Next Steps to Solidify Mastery',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 8),
              ...recommendedActions.map((action) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_right_alt_rounded, color: Color(0xFF38BDF8), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(action.toString(), style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],

            // ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      AdaptiveQuizView.open(context, topic: topic, roadmapId: roadmapId);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFCBD5E1),
                      side: const BorderSide(color: Color(0xFF475569)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.replay_rounded, size: 16),
                    label: const Text('Retake Quiz'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (roadmapId != null && roadmapId!.isNotEmpty) {
                        CareerRoadmapView.open(context, roadmapId: roadmapId!);
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.map_rounded, size: 16),
                    label: const Text('Back to Roadmap'),
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
