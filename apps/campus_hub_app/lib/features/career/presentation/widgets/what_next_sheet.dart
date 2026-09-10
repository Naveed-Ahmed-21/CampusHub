import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/career_models.dart';
import '../../data/career_repository.dart';
import '../providers/career_provider.dart';
import 'eva_ai_avatar.dart';

class WhatNextSheet extends ConsumerWidget {
  final ActiveRoadmapState activeRoadmap;
  final List<Map<String, dynamic>> phases;
  final void Function(int phaseNumber) onTakeQuiz;
  final void Function(RoadmapPracticalChallengeModel challenge) onViewChallenge;
  final void Function(RoadmapProjectModel project) onViewProject;
  final VoidCallback onStartInterview;

  const WhatNextSheet({
    super.key,
    required this.activeRoadmap,
    required this.phases,
    required this.onTakeQuiz,
    required this.onViewChallenge,
    required this.onViewProject,
    required this.onStartInterview,
  });

  static Future<void> show(
    BuildContext context, {
    required ActiveRoadmapState activeRoadmap,
    required List<Map<String, dynamic>> phases,
    required void Function(int phaseNumber) onTakeQuiz,
    required void Function(RoadmapPracticalChallengeModel challenge) onViewChallenge,
    required void Function(RoadmapProjectModel project) onViewProject,
    required VoidCallback onStartInterview,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WhatNextSheet(
        activeRoadmap: activeRoadmap,
        phases: phases,
        onTakeQuiz: onTakeQuiz,
        onViewChallenge: onViewChallenge,
        onViewProject: onViewProject,
        onStartInterview: onStartInterview,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dailyAsync = ref.watch(dailyPlanProvider(activeRoadmap.roadmapId));

    // Find the next incomplete phase
    Map<String, dynamic>? nextIncompletePhase;
    int nextPhaseNum = 1;
    for (final ph in phases) {
      final pNum = ph['num'] as int;
      final scoreData = activeRoadmap.quizScores?['phase_$pNum'];
      final passed = scoreData != null && scoreData['passed'] == true;
      if (!passed) {
        nextIncompletePhase = ph;
        nextPhaseNum = pNum;
        break;
      }
    }

    final currentChallenge = nextIncompletePhase != null
        ? nextIncompletePhase['challenge'] as RoadmapPracticalChallengeModel?
        : (phases.isNotEmpty ? phases.first['challenge'] as RoadmapPracticalChallengeModel? : null);

    final currentProject = nextIncompletePhase != null
        ? nextIncompletePhase['project'] as RoadmapProjectModel?
        : (phases.isNotEmpty ? phases.first['project'] as RoadmapProjectModel? : null);

    final currentScoreData = activeRoadmap.quizScores?['phase_$nextPhaseNum'];
    final allQuizzesPassed = nextIncompletePhase == null;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const EvaAiAvatar(size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'What To Finish Next',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'EVA AI',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your real-time personalized milestone checklist',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              const Divider(height: 20),

              // Content Body
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  children: [
                    // Roadmap Summary Header Card
                    _buildSummaryCard(theme, nextPhaseNum, allQuizzesPassed),
                    const SizedBox(height: 18),

                    // SECTION 1: Daily Micro-Tasks
                    _buildDailyTasksSection(ctx, ref, theme, dailyAsync),
                    const SizedBox(height: 18),

                    // SECTION 2: Next Checkpoint Test / Quiz
                    _buildNextQuizSection(ctx, theme, nextPhaseNum, nextIncompletePhase, currentScoreData, allQuizzesPassed),
                    const SizedBox(height: 18),

                    // SECTION 3: Next Practical Coding Challenge
                    if (currentChallenge != null) ...[
                      _buildNextChallengeSection(ctx, theme, nextPhaseNum, currentChallenge),
                      const SizedBox(height: 18),
                    ],

                    // SECTION 4: Next Milestone Project
                    if (currentProject != null) ...[
                      _buildNextProjectSection(ctx, theme, nextPhaseNum, currentProject),
                      const SizedBox(height: 18),
                    ],

                    // SECTION 5: Next Assessment: Mock Interview
                    _buildMockInterviewSection(ctx, theme),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(ThemeData theme, int nextPhaseNum, bool allQuizzesPassed) {
    final percent = activeRoadmap.progressPercent.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  activeRoadmap.targetRole,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  allQuizzesPassed ? 'Mastery Level' : 'Phase $nextPhaseNum of ${phases.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(percent * 100).toStringAsFixed(0)}% Completed',
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              Text(
                '🔥 ${activeRoadmap.streakDays} Day Streak',
                style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTasksSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AsyncValue<DailyLearningPlanModel?> dailyAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.today, size: 16, color: Colors.green),
            const SizedBox(width: 8),
            const Text(
              "TODAY'S ACTION ITEMS",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        dailyAsync.when(
          data: (plan) {
            if (plan == null) {
              return Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'No micro-tasks assigned today. You are ready to tackle the phase checkpoint!',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              );
            }

            final pendingTasks = plan.tasks.where((t) => !t.isCompleted).toList();
            final completedTasks = plan.tasks.where((t) => t.isCompleted).toList();

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.microGoal.isNotEmpty ? plan.microGoal : 'Complete daily study session',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '~${plan.estimatedMinutes}m',
                          style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (plan.tasks.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    if (pendingTasks.isNotEmpty) ...[
                      const Text(
                        'Pending Tasks:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                      const SizedBox(height: 6),
                      ...pendingTasks.map((t) => _buildTaskItem(context, ref, theme, t, false)),
                    ],
                    if (completedTasks.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Completed Today:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const SizedBox(height: 4),
                      ...completedTasks.map((t) => _buildTaskItem(context, ref, theme, t, true)),
                    ],
                  ],
                ],
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildTaskItem(BuildContext context, WidgetRef ref, ThemeData theme, RoadmapTaskDetailModel task, bool isDone) {
    IconData catIcon;
    Color catColor;
    switch (task.type.toUpperCase()) {
      case 'PRACTICE':
        catIcon = Icons.code;
        catColor = Colors.green;
        break;
      case 'CHALLENGE':
        catIcon = Icons.bolt;
        catColor = Colors.purple;
        break;
      case 'LEARN':
      default:
        catIcon = Icons.menu_book;
        catColor = Colors.blue;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Checkbox(
            value: isDone,
            activeColor: Colors.green,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (val) async {
              final repo = ref.read(careerRepositoryProvider);
              await repo.toggleDailyTask(activeRoadmap.roadmapId, task.id, val ?? false);
              ref.invalidate(dailyPlanProvider(activeRoadmap.roadmapId));
              ref.invalidate(activeUserRoadmapProvider);
            },
          ),
          Icon(catIcon, size: 14, color: catColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                decoration: isDone ? TextDecoration.lineThrough : null,
                color: isDone ? theme.colorScheme.outline : theme.colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            '~${task.durationMins}m',
            style: TextStyle(fontSize: 10, color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildNextQuizSection(
    BuildContext context,
    ThemeData theme,
    int nextPhaseNum,
    Map<String, dynamic>? nextIncompletePhase,
    dynamic currentScoreData,
    bool allQuizzesPassed,
  ) {
    final phaseTitle = nextIncompletePhase != null
        ? (nextIncompletePhase['title'] as String? ?? 'Core Architecture')
        : 'Foundations & Architecture';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.quiz, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              "NEXT CHECKPOINT TEST",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (allQuizzesPassed) ...[
                const Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'All Checkpoint Quizzes Passed! 🎉',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'You have verified mastery of all 5 curriculum phases. Continue to practical capstone challenges!',
                  style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant),
                ),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.assignment, color: theme.colorScheme.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phase $nextPhaseNum Checkpoint Quiz',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            phaseTitle,
                            style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    if (currentScoreData != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${currentScoreData['score']}% Retake',
                          style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '3 questions • 70% to pass • Adaptive review',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: Text(
                      currentScoreData != null ? 'Retake Phase $nextPhaseNum Quiz' : 'Take Phase $nextPhaseNum Checkpoint Quiz',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onTakeQuiz(nextPhaseNum);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNextChallengeSection(
    BuildContext context,
    ThemeData theme,
    int nextPhaseNum,
    RoadmapPracticalChallengeModel challenge,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt, size: 16, color: Colors.purple),
            const SizedBox(width: 8),
            const Text(
              "NEXT PRACTICAL CODING CHALLENGE",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.code, color: Colors.purple, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Phase $nextPhaseNum Challenge • ${challenge.difficulty}',
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                challenge.description,
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.terminal, size: 15),
                  label: const Text('View Challenge Instructions', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple,
                    side: BorderSide(color: Colors.purple.withValues(alpha: 0.5)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onViewChallenge(challenge);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNextProjectSection(
    BuildContext context,
    ThemeData theme,
    int nextPhaseNum,
    RoadmapProjectModel project,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.rocket_launch, size: 16, color: Colors.indigo),
            const SizedBox(width: 8),
            const Text(
              "NEXT CAPSTONE / PORTFOLIO PROJECT",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.folder_special, color: Colors.indigo, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Phase $nextPhaseNum Portfolio Milestone',
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                project.description,
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (project.techStack.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: project.techStack.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                  )).toList(),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_outward, size: 15),
                  label: const Text('View Project & Submit to Portfolio', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.indigo,
                    side: BorderSide(color: Colors.indigo.withValues(alpha: 0.5)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onViewProject(project);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMockInterviewSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.record_voice_over, size: 16, color: Colors.teal),
            const SizedBox(width: 8),
            const Text(
              "NEXT PLACEMENT ASSESSMENT",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.psychology, color: Colors.teal, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EVA AI Mock Interview Session',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Simulate live placement screening for ${activeRoadmap.targetRole}',
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.mic, size: 16),
                  label: const Text('Launch Mock Interview Room', style: TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal.withValues(alpha: 0.18),
                    foregroundColor: Colors.teal,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onStartInterview();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
