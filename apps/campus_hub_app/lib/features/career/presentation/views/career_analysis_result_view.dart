import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/career_repository.dart';
import '../providers/career_provider.dart';
import 'career_roadmap_view.dart';

class CareerAnalysisResultView extends ConsumerStatefulWidget {
  final Map<String, dynamic> analysisData;

  const CareerAnalysisResultView({
    super.key,
    required this.analysisData,
  });

  static void open(BuildContext context, {required Map<String, dynamic> analysisData}) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CareerAnalysisResultView(analysisData: analysisData),
      ),
    );
  }

  @override
  ConsumerState<CareerAnalysisResultView> createState() => _CareerAnalysisResultViewState();
}

class _CareerAnalysisResultViewState extends ConsumerState<CareerAnalysisResultView> {
  bool _isGenerating = false;
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    final primary = widget.analysisData['primaryDirection'] as Map<String, dynamic>?;
    _selectedRole = primary?['title'] ?? 'Software Engineer';
  }

  Future<void> _generateRoadmap() async {
    if (_selectedRole == null) return;

    setState(() => _isGenerating = true);
    try {
      final repo = ref.read(careerRepositoryProvider);
      final roadmap = await repo.generatePersonalizedRoadmap(
        targetRole: _selectedRole!,
        timelineWeeks: 16,
        hoursPerWeek: 10,
        primaryGoal: 'Campus Placement & Real-world Capstone Portfolio',
      );

      ref.invalidate(activeUserRoadmapProvider);
      ref.invalidate(userRoadmapsProvider);

      if (mounted) {
        CareerRoadmapView.open(context, roadmapId: roadmap.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate roadmap: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.analysisData['primaryDirection'] as Map<String, dynamic>? ?? {};
    final primaryTitle = primary['title'] ?? 'Specialized Engineer';
    final fitPercent = primary['fitPercentage'] ?? 92;
    final primaryDesc = primary['description'] ?? 'Strong technical fit based on your responses.';

    final alternatives = (widget.analysisData['alternativePaths'] as List<dynamic>?) ?? [];
    final strengths = (widget.analysisData['keyStrengths'] as List<dynamic>?) ?? [];
    final areasToImprove = (widget.analysisData['areasToImprove'] as List<dynamic>?) ?? [];
    final nextAction = widget.analysisData['recommendedNextAction'] ??
        'Generate your personalized roadmap to begin learning.';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Career Analysis Result',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PRIMARY RECOMMENDATION CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 14),
                            SizedBox(width: 5),
                            Text('TOP MATCH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$fitPercent% Fit',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    primaryTitle,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    primaryDesc,
                    style: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ALTERNATIVE CAREER PATHS
            if (alternatives.isNotEmpty) ...[
              const Text(
                'Viable Alternative Directions',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 10),
              ...alternatives.map((alt) {
                final a = alt as Map<String, dynamic>;
                final aTitle = a['title'] ?? '';
                final aFit = a['fitPercentage'] ?? 75;
                final aDesc = a['description'] ?? '';
                final isChosen = _selectedRole == aTitle;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isChosen ? const Color(0xFF6366F1).withValues(alpha: 0.12) : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isChosen ? const Color(0xFF6366F1) : const Color(0xFF334155)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Radio<String>(
                        value: aTitle,
                        // ignore: deprecated_member_use
                        groupValue: _selectedRole,
                        activeColor: const Color(0xFF6366F1),
                        // ignore: deprecated_member_use
                        onChanged: (val) => setState(() => _selectedRole = val),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    aTitle,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('$aFit% Match', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF818CF8))),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(aDesc, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],

            // STRENGTHS BREAKDOWN
            const Text(
              'Your Key Career Strengths',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: strengths.map((s) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF065F46).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 14),
                      const SizedBox(width: 5),
                      Text(s.toString(), style: const TextStyle(fontSize: 12, color: Color(0xFFE2E8F0))),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // AREAS TO IMPROVE
            const Text(
              'Recommended Focus Areas',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: areasToImprove.map((a) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF78350F).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up_rounded, color: Color(0xFFF59E0B), size: 14),
                      const SizedBox(width: 5),
                      Text(a.toString(), style: const TextStyle(fontSize: 12, color: Color(0xFFE2E8F0))),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // NEXT ACTION CALLOUT
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF38BDF8), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pathfinder Insight', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF38BDF8))),
                        const SizedBox(height: 2),
                        Text(nextAction.toString(), style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // PRIMARY GENERATE BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generateRoadmap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                  shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.5),
                ),
                child: _isGenerating
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                          SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              'Generating Custom Curriculum Graph...',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.route_rounded, size: 20),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Generate Roadmap for $_selectedRole',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
