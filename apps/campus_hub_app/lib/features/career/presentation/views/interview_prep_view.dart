import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/career_provider.dart';
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
  String _difficulty = 'Intermediate';
  String _interviewMode = 'TEXT'; // TEXT, VOICE

  final List<Map<String, String>> _sampleQuestions = [
    {
      'question': 'How do you structure a production system to handle unexpected latency and network drops?',
      'concept': 'Graceful Degradation & Timeouts',
      'answer': 'Implement exponential backoff retries, circuit breakers, fallback caches, and asynchronous queue buffers.',
    },
    {
      'question': 'Explain the difference between mutexes, semaphores, and condition variables in concurrent tasks.',
      'concept': 'Concurrency Primitives',
      'answer': 'A mutex is a mutual exclusion lock for one thread. A semaphore maintains a counter for shared resource access. A condition variable blocks threads until notified.',
    },
    {
      'question': 'Describe a technical tradeoff you made in a recent project deliverable and how you validated it.',
      'concept': 'System Design Tradeoffs (STAR)',
      'answer': 'Use the STAR format: Situation, Task, Action taken, Result and metrics. Emphasize why you chose simplicity or throughput over premature optimization.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(interviewPrepProvider(widget.roadmapId));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Interview Preparation Hub',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            Text(
              widget.targetRole,
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. EVA AI BANNER & LAUNCHER
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B0764), Color(0xFF581C87), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFA855F7).withOpacity(0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA855F7).withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFA855F7)),
                        ),
                        child: const Icon(Icons.record_voice_over_rounded, color: Color(0xFFA855F7), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EVA AI Interviewer',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            Text(
                              '1-on-1 Adaptive Mock Interview & Feedback',
                              style: TextStyle(fontSize: 11, color: Color(0xFFE9D5FF)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Practice live technical design and behavioral questions. EVA analyzes your answers in real time, evaluates detected vs missing concepts, and suggests targeted roadmap reinforcements.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFE2E8F0), height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // Mode selector
                  Row(
                    children: [
                      _buildModeChip('TEXT', 'Text Q&A', Icons.chat_rounded),
                      const SizedBox(width: 10),
                      _buildModeChip('VOICE', 'Live Voice', Icons.mic_rounded),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        EvaInterviewRoomView.open(
                          context,
                          targetRole: widget.targetRole,
                          roadmapId: widget.roadmapId,
                          initialMode: _interviewMode,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA855F7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.meeting_room_rounded, size: 18),
                      label: const Text('Enter EVA Interview Room', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. DIFFICULTY FILTER CHIPS
            const Text(
              'Target Interview Level',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Row(
              children: ['Beginner', 'Intermediate', 'Advanced'].map((diff) {
                final isSelected = _difficulty == diff;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(diff),
                    selected: isSelected,
                    selectedColor: const Color(0xFF6366F1),
                    backgroundColor: const Color(0xFF1E293B),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _difficulty = diff);
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 3. COMMON INTERVIEW QUESTIONS
            const Text(
              'Curated Technical Interview Questions',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 4),
            const Text(
              'Review key questions commonly asked by placement interviewers:',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 12),

            questionsAsync.when(
              data: (questions) {
                final list = questions.isNotEmpty
                    ? questions.map((q) => {
                          'question': q.question,
                          'concept': q.category,
                          'answer': q.idealAnswer,
                        }).toList()
                    : _sampleQuestions;

                return Column(
                  children: list.map((item) => _buildQuestionCard(item)).toList(),
                );
              },
              loading: () => Column(
                children: _sampleQuestions.map((item) => _buildQuestionCard(item)).toList(),
              ),
              error: (_, __) => Column(
                children: _sampleQuestions.map((item) => _buildQuestionCard(item)).toList(),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildModeChip(String mode, String label, IconData icon) {
    final isSelected = _interviewMode == mode;
    return InkWell(
      onTap: () => setState(() => _interviewMode = mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFA855F7).withOpacity(0.3) : const Color(0xFF0F172A).withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFFA855F7) : const Color(0xFF475569)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? const Color(0xFFE9D5FF) : const Color(0xFF94A3B8)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, String> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          title: Text(
            item['question'] ?? '',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              item['concept'] ?? 'Core Competency',
              style: const TextStyle(fontSize: 11, color: Color(0xFF38BDF8)),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Color(0xFF334155)),
                  const SizedBox(height: 4),
                  const Text('Expected Answer & Concepts:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                  const SizedBox(height: 4),
                  Text(
                    item['answer'] ?? '',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1), height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
