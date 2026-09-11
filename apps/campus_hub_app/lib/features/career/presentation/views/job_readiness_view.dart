import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/career_provider.dart';
import 'adaptive_quiz_view.dart';
import 'projects_evidence_view.dart';
import 'interview_prep_view.dart';

class JobReadinessView extends ConsumerWidget {
  final String? targetRole;

  const JobReadinessView({
    super.key,
    this.targetRole,
  });

  static void open(BuildContext context, {String? targetRole}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JobReadinessView(targetRole: targetRole),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readinessAsync = ref.watch(detailedJobReadinessProvider(targetRole));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job Readiness Radar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            Text(
              '6-Dimension Placement Analytics',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(detailedJobReadinessProvider(targetRole)),
        child: readinessAsync.when(
          data: (data) {
            final overallScore = data['overallScore'] ?? 72;
            final readinessLevel = data['readinessLevel'] ?? 'Intermediate Builder';
            final role = data['targetRole'] ?? targetRole ?? 'Software Engineer';
            final dimensions = (data['dimensions'] as List<dynamic>?) ?? [];
            final nextAction = data['nextBestAction'] as Map<String, dynamic>?;
            final strongAreas = (data['strongAreas'] as List<dynamic>?) ?? [];
            final areasToImprove = (data['areasToImprove'] as List<dynamic>?) ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. OVERALL CIRCLE GAUGE CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0F172A),
                            border: Border.all(color: const Color(0xFF38BDF8), width: 4),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$overallScore%',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                              const Text('READINESS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF38BDF8), letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF818CF8).withOpacity(0.4)),
                          ),
                          child: Text(
                            readinessLevel,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF818CF8)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Target: $role',
                          style: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. NEXT BEST ACTION BANNER
                  if (nextAction != null) ...[
                    _buildNextBestActionCard(context, nextAction),
                    const SizedBox(height: 24),
                  ],

                  // 3. 6 DIMENSIONS BREAKDOWN
                  const Text(
                    'Evaluated Competency Dimensions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 12),

                  ...dimensions.map((d) {
                    final dim = d as Map<String, dynamic>;
                    final name = dim['name'] ?? '';
                    final score = dim['score'] ?? 50;
                    final status = dim['status'] ?? 'GROWING';
                    final evidence = dim['evidence'] ?? '';

                    Color barColor = const Color(0xFF38BDF8);
                    if (status == 'STRONG') barColor = const Color(0xFF10B981);
                    if (status == 'NEEDS_WORK') barColor = const Color(0xFFF59E0B);

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
                              Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                              Row(
                                children: [
                                  Text('$score%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: barColor)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: barColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: barColor)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (score / 100.0).clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: const Color(0xFF0F172A),
                              valueColor: AlwaysStoppedAnimation<Color>(barColor),
                            ),
                          ),
                          if (evidence.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(evidence, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          ],
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),

                  // 4. STRENGTHS & IMPROVEMENTS
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildListCard('Strengths', strongAreas, const Color(0xFF10B981)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildListCard('Focus Areas', areasToImprove, const Color(0xFFF59E0B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF6366F1)),
          ),
          error: (err, _) => Center(
            child: Text('Error loading readiness: $err', style: const TextStyle(color: Colors.white70)),
          ),
        ),
      ),
    );
  }

  Widget _buildNextBestActionCard(BuildContext context, Map<String, dynamic> nextAction) {
    final title = nextAction['title'] ?? 'Take Practice Quiz';
    final desc = nextAction['description'] ?? 'Strengthen your weak competencies.';
    final actionType = nextAction['actionType'] ?? 'QUIZ';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Color(0xFF38BDF8), size: 18),
              const SizedBox(width: 6),
              const Text('NEXT BEST ACTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF38BDF8), letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1), height: 1.35)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () {
                if (actionType == 'QUIZ') {
                  AdaptiveQuizView.open(context, topic: 'Competency Checkpoint');
                } else if (actionType == 'PROJECT') {
                  ProjectsEvidenceView.open(context);
                } else if (actionType == 'INTERVIEW') {
                  InterviewPrepView.open(context, targetRole: targetRole ?? 'Software Engineer');
                } else {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Execute Recommended Action', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(String title, List<dynamic> items, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accentColor)),
          const SizedBox(height: 8),
          ...items.take(3).map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(item.toString(), style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
