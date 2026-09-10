import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../providers/career_provider.dart';
import '../../data/career_repository.dart';
import '../../domain/career_models.dart';
import '../widgets/eva_ai_avatar.dart';
import '../widgets/skill_dependency_map_sheet.dart';
import '../widgets/interview_prep_sheet.dart';
import '../widgets/phase_challenge_dialog.dart';
import '../widgets/journey_map_widget.dart';
import '../widgets/roadmap_changes_dialog.dart';
import '../widgets/career_pathfinder_sheet.dart';
import '../widgets/ask_ai_doubt_sheet.dart';
import '../widgets/what_next_sheet.dart';
import 'eva_interview_room_view.dart';
import 'document_reader_view.dart';

class CareerHubView extends ConsumerStatefulWidget {
  const CareerHubView({super.key});

  @override
  ConsumerState<CareerHubView> createState() => _CareerHubViewState();
}

class _CareerHubViewState extends ConsumerState<CareerHubView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<String> _goalCategories = [
    'All',
    'DSA',
    'Development',
    'Projects',
    'Interview Preparation',
    'Aptitude',
    'Communication',
    'Certifications',
    'Custom',
  ];

  int _assessmentStep = 0;
  bool _isEvaluatingAssessment = false;
  List<CareerRecommendationModel>? _recommendations;
  final Map<String, dynamic> _assessmentAnswers = {};
  bool _todayGoalDone = false;
  bool _isActivatingRoadmap = false;

  // Adaptive Quiz State
  AdaptiveQuizModel? _activeAdaptiveQuiz;
  int _adaptiveQuizQuestionIdx = 0;
  int? _selectedAdaptiveOption;
  bool _isAdaptiveQuestionAnswered = false;
  final Map<int, int> _adaptiveUserAnswers = {};
  PhaseQuizResult? _adaptiveQuizResult;
  bool _isSubmittingAdaptiveQuiz = false;
  bool _isLoadingAdaptiveQuiz = false;

  // Learn Workspace Focus Timer State
  bool _isStudySessionActive = false;
  int _studySessionRemainingSeconds = 25 * 60;
  Timer? _studyTimer;
  String _selectedInterviewCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this);
  }

  @override
  void dispose() {
    _studyTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _toggleStudyTimer() {
    if (_isStudySessionActive) {
      _studyTimer?.cancel();
      setState(() {
        _isStudySessionActive = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Focus timer paused.')),
        );
      }
    } else {
      setState(() {
        _isStudySessionActive = true;
      });
      _studyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_studySessionRemainingSeconds > 0) {
          setState(() {
            _studySessionRemainingSeconds--;
          });
        } else {
          timer.cancel();
          setState(() {
            _isStudySessionActive = false;
            _studySessionRemainingSeconds = 25 * 60;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Focus session completed! Take a 5-minute break.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('25-minute focus session started! Stay in the zone.')),
        );
      }
    }
  }

  void _showAddGoalDialog() {
    final titleController = TextEditingController();
    String selectedCategory = 'DSA';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.add_task, color: Colors.blue),
              SizedBox(width: 8),
              Text('Add Weekly Goal'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _goalCategories
                      .where((c) => c != 'All')
                      .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedCategory = val);
                  },
                ),
                const SizedBox(height: 14),
                const Text(
                  'Goal Title',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'e.g. Complete 5 LeetCode Medium problems',
                    hintStyle: const TextStyle(fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final text = titleController.text.trim();
                      if (text.isEmpty) return;

                      setDialogState(() => isSubmitting = true);
                      try {
                        final repo = ref.read(careerRepositoryProvider);
                        await repo.createWeeklyGoal(text, category: selectedCategory);
                        ref.invalidate(weeklyGoalsProvider);
                        if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        String errMsg = 'Failed to create goal';
                        if (e is DioException) {
                          errMsg = e.response?.data?['message']?.toString() ?? e.message ?? errMsg;
                        }
                        if (dialogCtx.mounted) {
                          ScaffoldMessenger.of(dialogCtx).showSnackBar(
                            SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Add Goal'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGoalDialog(WeeklyGoalModel goal) {
    final titleController = TextEditingController(text: goal.title);
    String selectedCategory = _goalCategories.contains(goal.category) ? goal.category : 'DSA';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.edit_note, color: Colors.blue),
              SizedBox(width: 8),
              Text('Edit Goal'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _goalCategories
                      .where((c) => c != 'All')
                      .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedCategory = val);
                  },
                ),
                const SizedBox(height: 14),
                const Text('Goal Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final text = titleController.text.trim();
                      if (text.isEmpty) return;

                      setDialogState(() => isSubmitting = true);
                      try {
                        final repo = ref.read(careerRepositoryProvider);
                        await repo.updateWeeklyGoal(goal.id, title: text, category: selectedCategory);
                        ref.invalidate(weeklyGoalsProvider);
                        if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        String errMsg = 'Failed to update goal';
                        if (e is DioException) {
                          errMsg = e.response?.data?['message']?.toString() ?? e.message ?? errMsg;
                        }
                        if (dialogCtx.mounted) {
                          ScaffoldMessenger.of(dialogCtx).showSnackBar(
                            SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteGoalDialog(WeeklyGoalModel goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Goal?'),
        content: Text('Are you sure you want to delete "${goal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final repo = ref.read(careerRepositoryProvider);
                await repo.deleteWeeklyGoal(goal.id);
                ref.invalidate(weeklyGoalsProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Goal deleted successfully')),
                  );
                }
              } catch (_) {}
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSubmitProjectDialog(MiniProjectModel project) {
    final repoController = TextEditingController();
    final demoController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Submit Solution: ${project.title}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: repoController,
                decoration: const InputDecoration(
                  labelText: 'GitHub Repository URL',
                  hintText: 'https://github.com/...',
                  prefixIcon: Icon(Icons.code),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: demoController,
                decoration: const InputDecoration(
                  labelText: 'Optional Live Demo URL',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (repoController.text.trim().isEmpty) return;
                      setDialogState(() => isSubmitting = true);
                      try {
                        final repo = ref.read(careerRepositoryProvider);
                        await repo.submitMiniProject(
                          project.id,
                          repoController.text.trim(),
                          liveDemoUrl: demoController.text.trim().isEmpty ? null : demoController.text.trim(),
                        );
                        ref.invalidate(miniProjectsProvider);
                        if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (dialogCtx.mounted) {
                          ScaffoldMessenger.of(dialogCtx).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit Solution'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Career Hub',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Build your path. Learn with purpose.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist_rtl_rounded),
            tooltip: 'What to Finish Next',
            onPressed: () {
              final active = ref.read(activeUserRoadmapProvider).valueOrNull;
              if (active != null && active.roadmapId.isNotEmpty) {
                _showWhatNextSheet(active);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Activate or create a roadmap to view your next action items!')),
                );
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Options',
            onSelected: (val) {
              if (val == 'reset') {
                _confirmResetCareerData();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restart_alt, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Reset Career Hub', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
            Tab(icon: Icon(Icons.explore_outlined), text: 'AI Pathfinder'),
            Tab(icon: Icon(Icons.alt_route_outlined), text: 'My Roadmap'),
            Tab(icon: Icon(Icons.auto_stories_outlined), text: 'Learn'),
            Tab(icon: Icon(Icons.hub_outlined), text: 'Skills'),
            Tab(icon: Icon(Icons.verified_outlined), text: 'Resources'),
            Tab(icon: Icon(Icons.quiz_outlined), text: 'Assessments'),
            Tab(icon: Icon(Icons.rocket_launch_outlined), text: 'Projects'),
            Tab(icon: Icon(Icons.record_voice_over_outlined), text: 'Interview Prep'),
            Tab(icon: Icon(Icons.speed_outlined), text: 'Job Readiness'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildAiPathfinderTab(),
          _buildRoadmapPhasesTab(),
          _buildLearnWorkspaceTab(),
          _buildSkillsTab(),
          _buildLearningResourcesTab(),
          _buildAssessmentsTab(),
          _buildMiniProjectsTab(),
          _buildInterviewPrepTab(),
          _buildJobReadinessTab(),
        ],
      ),
    );
  }

  static const List<Map<String, dynamic>> _assessmentQuestions = [
    {
      'key': 'year',
      'title': 'What is your current college year?',
      'subtitle': 'Helps calibrate timeline and semester milestones before placement drives.',
      'options': [
        {'label': '1st Year / Fresher', 'value': '1st Year'},
        {'label': '2nd Year / Sophomore', 'value': '2nd Year'},
        {'label': '3rd Year / Pre-Final Year', 'value': '3rd Year'},
        {'label': 'Final Year / Graduating', 'value': 'Final Year'},
      ],
    },
    {
      'key': 'primary_interest',
      'title': 'Which engineering domain excites you the most?',
      'subtitle': 'Choose the technology stack you want to build projects in.',
      'options': [
        {'label': 'Full-Stack Web Development (React & Node.js)', 'value': 'Full Stack'},
        {'label': 'Cross-Platform Mobile Apps (Flutter & Dart)', 'value': 'Mobile Development'},
        {'label': 'Backend, Cloud APIs & High Scale Systems', 'value': 'Backend'},
        {'label': 'Applied AI, Machine Learning & LLM Agents', 'value': 'AI / Machine Learning'},
        {'label': 'Cloud DevOps, Kubernetes & Infrastructure', 'value': 'Cloud & DevOps'},
      ],
    },
    {
      'key': 'math_theory_comfort',
      'title': 'How comfortable are you with math and algorithmic theory?',
      'subtitle': 'Calibrates the balance between practical building and theoretical rigor.',
      'options': [
        {'label': 'Practical first (I love building apps & learning syntax hands-on)', 'value': 'Low'},
        {'label': 'Balanced (Comfortable with logic, complexity & algorithms)', 'value': 'Medium'},
        {'label': 'High (Enjoy rigorous math, linear algebra & optimization)', 'value': 'High'},
      ],
    },
    {
      'key': 'coding_experience',
      'title': 'What is your current hands-on coding experience level?',
      'subtitle': 'Determines your adaptive starting milestone.',
      'options': [
        {'label': 'Beginner / Zero previous experience', 'value': 'Beginner / Zero'},
        {'label': 'Know basic syntax (loops, functions, arrays)', 'value': 'Basic syntax'},
        {'label': 'Have built 1-2 small projects independently', 'value': 'Built small projects'},
        {'label': 'Internship or production-grade project experience', 'value': 'Internship / Production'},
      ],
    },
    {
      'key': 'learning_style',
      'title': 'How do you absorb technical concepts best?',
      'subtitle': 'We customize the recommended resources to your learning preferences.',
      'options': [
        {'label': 'Building projects hands-on with immediate visual feedback', 'value': 'Hands-on projects'},
        {'label': 'Following structured video walkthroughs and courses', 'value': 'Video courses'},
        {'label': 'Reading official documentation, specifications & books', 'value': 'Documentation & books'},
      ],
    },
    {
      'key': 'weekly_hours',
      'title': 'How many hours per week can you realistically commit?',
      'subtitle': 'Consistency is more important than intense sporadic cramming.',
      'options': [
        {'label': '5 – 8 hours / week (~1 hour per day)', 'value': 7},
        {'label': '10 – 14 hours / week (~2 hours per day)', 'value': 12},
        {'label': '15 – 20 hours / week (Intensive student pace)', 'value': 18},
        {'label': '20+ hours / week (Full-time placement preparation)', 'value': 25},
      ],
    },
    {
      'key': 'target_outcome',
      'title': 'What is your primary career target after graduation?',
      'subtitle': 'Shapes the focus on DSA vs system architecture vs open source.',
      'options': [
        {'label': 'Top Product Tech Giant (FAANG / Tier-1 MNC)', 'value': 'Product Company / FAANG'},
        {'label': 'High-Growth Tech Startup (High ownership & speed)', 'value': 'Tech Startup'},
        {'label': 'Established IT Consultancy / Global Enterprise', 'value': 'IT Services'},
        {'label': 'Higher Studies, MS abroad, or Research Lab', 'value': 'Higher Studies / Research'},
      ],
    },
    {
      'key': 'known_languages',
      'title': 'Which programming language are you most comfortable with?',
      'subtitle': 'We leverage your existing syntax comfort to accelerate learning.',
      'options': [
        {'label': 'JavaScript / TypeScript', 'value': 'JavaScript'},
        {'label': 'Python', 'value': 'Python'},
        {'label': 'Java / Kotlin', 'value': 'Java'},
        {'label': 'C++ / C', 'value': 'C++'},
        {'label': 'Dart / Flutter', 'value': 'Dart'},
      ],
    },
    {
      'key': 'preferred_ecosystem',
      'title': 'Which platform ecosystem do you prefer shipping to?',
      'subtitle': 'Choose where you want your portfolio to shine.',
      'options': [
        {'label': 'Web browsers (SaaS, responsive web applications)', 'value': 'Web'},
        {'label': 'Mobile app stores (Android & iOS native apps)', 'value': 'Mobile'},
        {'label': 'Distributed Linux cloud servers & APIs', 'value': 'Cloud'},
        {'label': 'AI models, Jupyter notebooks & data pipelines', 'value': 'Data/AI'},
      ],
    },
    {
      'key': 'struggle_area',
      'title': 'What is your single biggest blocker or struggle right now?',
      'subtitle': 'We will focus your today-goals and roadmap milestones to break this.',
      'options': [
        {'label': 'Information overload / Not knowing what to learn first', 'value': 'Where to start'},
        {'label': 'Tutorial hell (watching tutorials without writing real code)', 'value': 'Tutorial hell'},
        {'label': 'DSA & LeetCode problem solving confidence', 'value': 'DSA confidence'},
        {'label': 'Resume building, projects & technical interview readiness', 'value': 'Interview prep'},
      ],
    },
  ];

  Widget _buildAiPathfinderTab() {
    final theme = Theme.of(context);

    if (_isEvaluatingAssessment) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Evaluating your engineering profile...',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Analyzing college year, stack affinity, and goal trajectory to generate optimal paths.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_recommendations != null && _recommendations!.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your Personalized Career Match',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retake'),
                        onPressed: () {
                          setState(() {
                            _recommendations = null;
                            _assessmentStep = 0;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Based on your inputs, we calculated match scores for your engineering specialization:',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._recommendations!.map((rec) {
            final matchColor = rec.matchPercentage >= 85
                ? Colors.green
                : (rec.matchPercentage >= 70 ? Colors.orange : Colors.blue);

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rec.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${rec.category} • ${rec.difficulty} • ${rec.weeklyCommitment}',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: matchColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: matchColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '${rec.matchPercentage}% Match',
                            style: TextStyle(
                              color: matchColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.psychology, size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Why this path matches you:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  rec.reasoning,
                                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface, height: 1.35),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (rec.keySkills.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Key Foundational Skills:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: rec.keySkills
                            .map((skill) => Chip(
                                  label: Text(skill, style: const TextStyle(fontSize: 11)),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ))
                            .toList(),
                      ),
                    ],
                    if (rec.suggestedProjects.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Target Milestone Projects:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      ...rec.suggestedProjects.map((proj) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                                const SizedBox(width: 6),
                                Expanded(child: Text(proj, style: const TextStyle(fontSize: 12))),
                              ],
                            ),
                          )),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: _isActivatingRoadmap
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.rocket_launch, size: 18),
                        label: Text(_isActivatingRoadmap ? 'Activating...' : 'Activate This Roadmap'),
                        onPressed: _isActivatingRoadmap
                            ? null
                            : () async {
                                setState(() => _isActivatingRoadmap = true);
                                try {
                                  final repo = ref.read(careerRepositoryProvider);
                                  final hours = int.tryParse(rec.weeklyCommitment.split(' ').first) ?? 10;
                                  await repo.generateOrActivateRoadmap(
                                    role: rec.title,
                                    level: rec.difficulty,
                                    weeklyHours: hours,
                                    assessmentData: _assessmentAnswers,
                                  );
                                  ref.invalidate(activeUserRoadmapProvider);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Activated ${rec.title} as your roadmap!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    _tabController.animateTo(1);
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Activation failed: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) setState(() => _isActivatingRoadmap = false);
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      );
    }

    // Step-by-step 10 questions assessment
    final q = _assessmentQuestions[_assessmentStep];
    final selectedValue = _assessmentAnswers[q['key']];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AI PATHFINDER ASSESSMENT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      '${_assessmentStep + 1} / ${_assessmentQuestions.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_assessmentStep + 1) / _assessmentQuestions.length,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Calibrating your engineering career journey',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.help_outline, size: 14),
                      label: const Text('Confused?', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      onPressed: _showDecisionHelperDialog,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q['title'],
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                const SizedBox(height: 6),
                Text(
                  q['subtitle'],
                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                ...(q['options'] as List<Map<String, dynamic>>).map((opt) {
                  final isSelected = selectedValue == opt['value'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _assessmentAnswers[q['key']] = opt['value'];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                            width: isSelected ? 1.8 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                opt['label'],
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_assessmentStep > 0)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Previous'),
                        onPressed: () => setState(() => _assessmentStep--),
                      )
                    else
                      const SizedBox.shrink(),
                    if (_assessmentStep < _assessmentQuestions.length - 1)
                      FilledButton.icon(
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('Next'),
                        onPressed: selectedValue != null
                            ? () => setState(() => _assessmentStep++)
                            : null,
                      )
                    else
                      FilledButton.icon(
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text('Get My Recommendations'),
                        onPressed: selectedValue != null
                            ? () async {
                                setState(() => _isEvaluatingAssessment = true);
                                try {
                                  final repo = ref.read(careerRepositoryProvider);
                                  final recs = await repo.submitAssessment({'answers': _assessmentAnswers});
                                  if (mounted) {
                                    setState(() {
                                      _recommendations = recs;
                                      _isEvaluatingAssessment = false;
                                    });
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    setState(() => _isEvaluatingAssessment = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Evaluation failed: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            : null,
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

  void _showDecisionHelperDialog() {
    String visualVsLogic = 'VISUAL';
    String fastVsDeep = 'FAST_FEEDBACK';
    String startupVsEnterprise = 'AGILE_STARTUP';
    final notesController = TextEditingController();
    bool isEvaluating = false;
    CareerDecisionResult? decisionResult;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bContext) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final theme = Theme.of(ctx);

          Widget buildChoiceTile({
            required String title,
            required String subtitle,
            required bool isSelected,
            required VoidCallback onTap,
          }) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                      width: isSelected ? 1.6 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollCtrl) => SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.compare_arrows, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "I'm Confused. Help Me Decide",
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Answer 3 trade-off questions and describe your dilemma for personalized EVA guidance.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  if (decisionResult == null) ...[
                    const Text('1. Visual UI vs Deep Logic', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 6),
                    buildChoiceTile(
                      title: 'Visual UI & Tactile Experience',
                      subtitle: 'I enjoy seeing components render, fluid animations, and user interactions.',
                      isSelected: visualVsLogic == 'VISUAL',
                      onTap: () => setModalState(() => visualVsLogic = 'VISUAL'),
                    ),
                    buildChoiceTile(
                      title: 'Deep Logic & Data Architecture',
                      subtitle: 'I prefer backend systems, databases, high throughput APIs, and business rules.',
                      isSelected: visualVsLogic == 'LOGIC',
                      onTap: () => setModalState(() => visualVsLogic = 'LOGIC'),
                    ),
                    const Divider(height: 24),

                    const Text('2. Pace of Feedback vs Depth of Theory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 6),
                    buildChoiceTile(
                      title: 'Fast Feedback & Rapid Prototyping',
                      subtitle: 'I want to build MVPs quickly and see working features end-to-end.',
                      isSelected: fastVsDeep == 'FAST_FEEDBACK',
                      onTap: () => setModalState(() => fastVsDeep = 'FAST_FEEDBACK'),
                    ),
                    buildChoiceTile(
                      title: 'System Depth & Rigorous Engineering',
                      subtitle: 'I prefer diving deep into algorithms, concurrency, data structures, and scale.',
                      isSelected: fastVsDeep == 'DEEP_THEORY',
                      onTap: () => setModalState(() => fastVsDeep = 'DEEP_THEORY'),
                    ),
                    const Divider(height: 24),

                    const Text('3. Target Company / Ecosystem Style', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 6),
                    buildChoiceTile(
                      title: 'Agile High-Growth Startups',
                      subtitle: 'Wearing multiple hats, quick releases, and direct product ownership.',
                      isSelected: startupVsEnterprise == 'AGILE_STARTUP',
                      onTap: () => setModalState(() => startupVsEnterprise = 'AGILE_STARTUP'),
                    ),
                    buildChoiceTile(
                      title: 'Established Tech Enterprises / MNCs',
                      subtitle: 'Structured workflows, specialized roles, high scale, and formalized roadmaps.',
                      isSelected: startupVsEnterprise == 'ENTERPRISE',
                      onTap: () => setModalState(() => startupVsEnterprise = 'ENTERPRISE'),
                    ),
                    const Divider(height: 24),

                    const Text('4. What is Causing Your Dilemma? (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      'Tell EVA about your specific doubts, worries, or college placement considerations.',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. I love building mobile apps, but I want to make sure I am well-prepared for backend placements...',
                        hintStyle: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: isEvaluating
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.psychology),
                        label: Text(isEvaluating ? 'Analyzing...' : 'Get Decision Verdict'),
                        onPressed: isEvaluating
                            ? null
                            : () async {
                                setModalState(() => isEvaluating = true);
                                try {
                                  final repo = ref.read(careerRepositoryProvider);
                                  final result = await repo.helpMeDecide(
                                    visualVsLogic: visualVsLogic,
                                    fastVsDeep: fastVsDeep,
                                    startupVsEnterprise: startupVsEnterprise,
                                    confusionNotes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                                  );
                                  setModalState(() {
                                    decisionResult = result;
                                    isEvaluating = false;
                                  });
                                } catch (e) {
                                  setModalState(() => isEvaluating = false);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.stars, color: Colors.amber, size: 24),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  decisionResult!.verdict,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(decisionResult!.summary, style: const TextStyle(fontSize: 13, height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Why this direction works for you:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    ...decisionResult!.pros.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(p, style: const TextStyle(fontSize: 13))),
                            ],
                          ),
                        )),
                    if (decisionResult!.cons.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Considerations & Trade-offs:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      ...decisionResult!.cons.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(c, style: const TextStyle(fontSize: 13))),
                              ],
                            ),
                          )),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            child: const Text('Try Again'),
                            onPressed: () => setModalState(() => decisionResult = null),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            child: const Text('Apply to Quiz'),
                            onPressed: () {
                              Navigator.pop(ctx);
                              setState(() {
                                if (decisionResult!.verdict.contains('Mobile')) {
                                  _assessmentAnswers['primary_interest'] = 'Mobile Development';
                                } else if (decisionResult!.verdict.contains('Backend') || decisionResult!.verdict.contains('Distributed')) {
                                  _assessmentAnswers['primary_interest'] = 'Backend';
                                } else if (decisionResult!.verdict.contains('DevOps') || decisionResult!.verdict.contains('Cloud')) {
                                  _assessmentAnswers['primary_interest'] = 'Cloud & DevOps';
                                } else if (decisionResult!.verdict.contains('AI') || decisionResult!.verdict.contains('Machine Learning')) {
                                  _assessmentAnswers['primary_interest'] = 'AI / Machine Learning';
                                } else {
                                  _assessmentAnswers['primary_interest'] = 'Full Stack';
                                }
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Applied "${decisionResult!.verdict}" as your primary preference.'),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text('Create Roadmap with AI Pathfinder', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          CareerPathfinderSheet.show(context);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showOnboardingSheet() {
    CareerPathfinderSheet.show(context);
  }

  List<Map<String, dynamic>> _getRoadmapPhases(ActiveRoadmapState activeRoadmap) {
    return [
      {
        'num': 1,
        'title': 'Foundations & Core Architecture',
        'weeks': 'Weeks 1-3',
        'objectives': [
          'Understand syntax, variables, data structures & memory model',
          'Write clean modular functions and handle async execution',
          'Implement basic unit tests',
        ],
        'skills': ['Syntax', 'Async/Await', 'Data Structures', 'Git Flow'],
        'challenge': RoadmapPracticalChallengeModel(
          id: 'c1',
          title: 'Algorithmic Cache-Aside Simulator',
          description: 'Implement an in-memory LRU cache with expiration and eviction algorithms.',
          tasks: ['Define LRU eviction strategy', 'Implement get/put in O(1) time', 'Write unit test asserting capacity limit'],
          hints: ['Use doubly linked list + hash map'],
        ),
        'project': RoadmapProjectModel(
          id: 'p1',
          title: 'Developer Portfolio & API Explorer',
          description: 'Build a production-ready personal developer portfolio that pulls live stats and repos from GitHub API.',
          techStack: ['TypeScript', 'React/Flutter', 'REST APIs'],
          requirements: ['Responsive UI', 'Live API integration', 'Deployable to Vercel/Netlify'],
        ),
      },
      {
        'num': 2,
        'title': 'Core Engineering & Data Storage',
        'weeks': 'Weeks 4-7',
        'objectives': [
          'Model relational databases and write optimal queries',
          'Build REST and WebSocket APIs with authentication',
          'Understand B-tree indexes and normalization',
        ],
        'skills': ['PostgreSQL', 'Prisma', 'REST APIs', 'JWT Auth'],
        'challenge': RoadmapPracticalChallengeModel(
          id: 'c2',
          title: 'SQL Query Optimizer Challenge',
          description: 'Analyze an unindexed 1-million-row table query and add composite indexes to reduce lookup time from 400ms to 2ms.',
          tasks: ['Run EXPLAIN ANALYZE', 'Add composite index', 'Verify index scan'],
          hints: ['Target columns in WHERE and ORDER BY clauses'],
        ),
        'project': RoadmapProjectModel(
          id: 'p2',
          title: 'Campus Marketplace & Chat Backend',
          description: 'Full-stack campus buy/sell marketplace with realtime Socket.IO chat and image uploads.',
          techStack: ['Node.js', 'PostgreSQL', 'Socket.IO', 'Docker'],
          requirements: ['User auth & sessions', 'Real-time messaging', 'Database migrations'],
        ),
      },
      {
        'num': 3,
        'title': 'Advanced Systems & Scalability',
        'weeks': 'Weeks 8-11',
        'objectives': [
          'Design microservices and asynchronous message queues',
          'Implement distributed Redis caching',
          'Handle high concurrency with rate limiters',
        ],
        'skills': ['Redis', 'Message Queues', 'Docker', 'Rate Limiting'],
        'challenge': RoadmapPracticalChallengeModel(
          id: 'c3',
          title: 'Token Bucket Rate Limiter',
          description: 'Build a distributed Redis-backed rate limiter that throttles requests based on IP and user ID.',
          tasks: ['Atomic Redis transaction', 'Sliding window calculation', 'Return HTTP 429'],
        ),
        'project': RoadmapProjectModel(
          id: 'p3',
          title: 'Distributed Notification Engine',
          description: 'High-throughput notification service that fans out push, email, and in-app alerts via queues.',
          techStack: ['Node.js', 'Redis', 'RabbitMQ/BullMQ', 'PostgreSQL'],
          requirements: ['Retry queue mechanism', 'Deduplication', 'Worker clustering'],
        ),
      },
      {
        'num': 4,
        'title': 'Production Readiness & Cloud DevOps',
        'weeks': 'Weeks 12-14',
        'objectives': [
          'Containerize services with multi-stage Docker builds',
          'Setup automated CI/CD workflows with GitHub Actions',
          'Deploy on cloud with SSL and monitoring',
        ],
        'skills': ['CI/CD', 'GitHub Actions', 'AWS/GCP', 'Kubernetes Basics'],
        'challenge': RoadmapPracticalChallengeModel(
          id: 'c4',
          title: 'Multi-Stage Dockerfile Optimization',
          description: 'Reduce a 1.2 GB development image down to a hardened 95 MB production image using alpine & distroless.',
          tasks: ['Separate build and runtime stages', 'Strip build tools and source maps', 'Test healthcheck'],
        ),
        'project': RoadmapProjectModel(
          id: 'p4',
          title: 'Cloud DevOps CI/CD Pipeline',
          description: 'Automated deployment pipeline that tests, builds Docker containers, and deploys to cloud upon merge.',
          techStack: ['GitHub Actions', 'Docker', 'AWS ECS/DigitalOcean'],
          requirements: ['Automated test run', 'Zero-downtime rollouts', 'Production logs'],
        ),
      },
      {
        'num': 5,
        'title': 'Placement & System Design Mastery',
        'weeks': 'Weeks 15-16',
        'objectives': [
          'Master High-Level and Low-Level System Design',
          'Solve real-world campus placement interview problems',
          'Complete mock technical interviews with EVA AI',
        ],
        'skills': ['System Design', 'Scalability', 'Mock Interviews', 'Behavioral'],
        'challenge': RoadmapPracticalChallengeModel(
          id: 'c5',
          title: 'Design URL Shortener at Scale',
          description: 'Architect a Bitly-like URL shortener handling 100M daily writes and 1B reads with high availability.',
          tasks: ['Base62 encoding algorithm', 'Database sharding schema', 'Caching layer design'],
        ),
        'project': RoadmapProjectModel(
          id: 'p5',
          title: 'Enterprise Capstone Project',
          description: 'End-to-end full-stack SaaS platform with payment gateway, subscription tiers, and production analytics.',
          techStack: ['Full Stack', 'PostgreSQL', 'Redis', 'Stripe/Razorpay'],
          requirements: ['Production deployment', 'Telemetry monitoring', 'Live documentation'],
        ),
      },
    ];
  }

  void _confirmResetCareerData() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Reset Career Hub?'),
          ],
        ),
        content: const Text(
          'This will clear all your active career roadmaps, milestones, daily plans, and AI discovery chats so you can start completely fresh as a new user.\n\nThis action cannot be undone.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              try {
                final repo = ref.read(careerRepositoryProvider);
                await repo.resetCareerData();
                ref.invalidate(activeUserRoadmapProvider);
                ref.invalidate(userRoadmapsProvider);
                ref.invalidate(userCareerProgressProvider);
                ref.invalidate(weeklyGoalsProvider);
                ref.invalidate(dailyPlanProvider);
                ref.invalidate(skillGapProvider);
                ref.invalidate(jobReadinessProvider);
                ref.invalidate(careerRoadmapsProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Career Hub reset successfully. You can now build your path fresh!'),
                      backgroundColor: Colors.teal,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to reset career data: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }

  void _showWhatNextSheet(ActiveRoadmapState activeRoadmap) {
    final phases = _getRoadmapPhases(activeRoadmap);
    WhatNextSheet.show(
      context,
      activeRoadmap: activeRoadmap,
      phases: phases,
      onTakeQuiz: (phaseNum) => _showPhaseQuizDialog(phaseNum, activeRoadmap.targetRole, activeRoadmap.roadmapId),
      onViewChallenge: (challenge) => _showPracticalChallengeDialog(challenge),
      onViewProject: (project) => _showPhaseProjectDialog(activeRoadmap.roadmapId, project),
      onStartInterview: () => EvaInterviewRoomView.open(
        context,
        roadmapId: activeRoadmap.roadmapId,
        targetRole: activeRoadmap.targetRole,
      ),
    );
  }

  void _showUpdateStatusDialog(String roadmapId, String currentStatus) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);

        Widget buildStatusOption(String statusKey, String title, String subtitle, Color color, IconData icon) {
          final isSelected = currentStatus.toUpperCase() == statusKey;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final repo = ref.read(careerRepositoryProvider);
                  await repo.updateRoadmap(roadmapId, status: statusKey);
                  ref.invalidate(activeUserRoadmapProvider);
                  ref.invalidate(userRoadmapsProvider);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Roadmap status set to $title'),
                        backgroundColor: color,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.12) : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    width: isSelected ? 1.8 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: color, size: 20),
                  ],
                ),
              ),
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Update Roadmap Status',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Change your roadmap pacing, pause during exam periods, or mark as completed.',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                buildStatusOption(
                  'ACTIVE',
                  'Active',
                  'Currently learning and tracking daily streaks & micro-goals.',
                  Colors.green,
                  Icons.play_arrow,
                ),
                buildStatusOption(
                  'PAUSED',
                  'Paused',
                  'Put learning on hold during exams or busy periods.',
                  Colors.orange,
                  Icons.pause,
                ),
                buildStatusOption(
                  'COMPLETED',
                  'Completed',
                  'Curriculum and capstone projects finished with mastery.',
                  Colors.blue,
                  Icons.check_circle,
                ),
                buildStatusOption(
                  'ARCHIVED',
                  'Archived',
                  'Archive roadmap from your active workspace list.',
                  Colors.grey,
                  Icons.archive,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAskAiSheet(String roadmapId, String targetRole, int currentPhase) {
    AskAiDoubtSheet.show(
      context,
      roadmapId: roadmapId,
      targetRole: targetRole,
    );
  }

  void _showSkillMapSheet(String roadmapId, String targetRole) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SkillDependencyMapSheet(
        roadmapId: roadmapId,
        targetRole: targetRole,
      ),
    );
  }

  void _showInterviewPrepSheet(String roadmapId, String targetRole) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InterviewPrepSheet(
        roadmapId: roadmapId,
        targetRole: targetRole,
      ),
    );
  }

  void _showAskMentorDialog(String roadmapId, String role) {
    final msgController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.supervisor_account, color: Colors.indigo),
              SizedBox(width: 8),
              Text('Ask Faculty Mentor', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share your "$role" roadmap milestone and ask a question to your assigned faculty mentor.',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: msgController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ask about milestones, code reviews, or career advice...',
                  hintStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSending ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSending
                  ? null
                  : () async {
                      final text = msgController.text.trim();
                      if (text.isEmpty) return;
                      setDialogState(() => isSending = true);
                      try {
                        final repo = ref.read(careerRepositoryProvider);
                        await repo.askFacultyMentor(roadmapId, text);
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Question sent to your faculty mentor!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSending = false);
                        if (dialogCtx.mounted) {
                          ScaffoldMessenger.of(dialogCtx).showSnackBar(
                            SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: isSending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Send Message'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _adaptRoadmap(String roadmapId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('EVA AI is analyzing your quiz and task progress...')),
    );
    try {
      final repo = ref.read(careerRepositoryProvider);
      final res = await repo.adaptRoadmap(roadmapId);
      ref.invalidate(activeUserRoadmapProvider);
      ref.invalidate(skillGapProvider);
      ref.invalidate(dailyPlanProvider);
      ref.invalidate(userRoadmapsProvider);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.indigo),
                SizedBox(width: 8),
                Text('Roadmap Adapted by EVA AI', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: Text(
              res['adaptation_summary']?.toString() ??
                  'EVA AI updated your milestone priorities and detected new skill gaps based on your recent activity.',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Got it'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Adaptation failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showRenameRoadmapDialog(UserRoadmapItemModel roadmap) {
    final titleController = TextEditingController(text: roadmap.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rename Roadmap', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: titleController,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final newTitle = titleController.text.trim();
              if (newTitle.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final repo = ref.read(careerRepositoryProvider);
                await repo.updateRoadmap(roadmap.id, title: newTitle);
                ref.invalidate(userRoadmapsProvider);
                ref.invalidate(activeUserRoadmapProvider);
              } catch (_) {}
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteRoadmapDialog(UserRoadmapItemModel roadmap) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Roadmap?'),
        content: Text('Are you sure you want to delete "${roadmap.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = ref.read(careerRepositoryProvider);
                await repo.deleteRoadmap(roadmap.id);
                ref.invalidate(userRoadmapsProvider);
                ref.invalidate(activeUserRoadmapProvider);
              } catch (_) {}
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showPracticalChallengeDialog(RoadmapPracticalChallengeModel challenge) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(challenge.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(challenge.description, style: const TextStyle(fontSize: 13, height: 1.4)),
              if (challenge.tasks.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Challenge Tasks:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                ...challenge.tasks.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Expanded(child: Text(t, style: const TextStyle(fontSize: 12))),
                        ],
                      ),
                    )),
              ],
              if (challenge.hints != null && challenge.hints!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hint: ${challenge.hints!.join(', ')}',
                          style: const TextStyle(fontSize: 11, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showPhaseProjectDialog(String roadmapId, RoadmapProjectModel project) {
    showDialog(
      context: context,
      builder: (ctx) => PhaseProjectDialog(
        roadmapId: roadmapId,
        projectTitle: project.title,
        description: project.description,
        techStack: project.techStack,
        requirements: project.requirements,
      ),
    );
  }

  Widget _buildOverviewTab() {
    final theme = Theme.of(context);
    final activeAsync = ref.watch(activeUserRoadmapProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(activeUserRoadmapProvider);
        ref.invalidate(userRoadmapsProvider);
        ref.invalidate(userCareerProgressProvider);
        ref.invalidate(dailyPlanProvider);
        ref.invalidate(skillGapProvider);
        ref.invalidate(jobReadinessProvider);
        ref.invalidate(verifiedDocumentsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeroSection(theme),
          const SizedBox(height: 18),
          _buildContinueReadingShelf(theme),
          const SizedBox(height: 18),
          activeAsync.when(
            data: (activeRoadmap) {
              if (activeRoadmap == null || activeRoadmap.roadmapId.isEmpty) {
                return _buildEmptyRoadmapCard(theme);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContinueLearningCard(activeRoadmap, theme),
                  const SizedBox(height: 18),
                  _buildTodaysLearningSection(activeRoadmap.roadmapId, theme),
                  const SizedBox(height: 18),
                  _buildOverviewQuickJumpGrid(theme),
                ],
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
            error: (err, _) => Center(child: Text('Error loading overview: $err')),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueReadingShelf(ThemeData theme) {
    final docsAsync = ref.watch(verifiedDocumentsProvider);

    return docsAsync.when(
      data: (docs) {
        if (docs.isEmpty) return const SizedBox.shrink();

        return Card(
          elevation: 0,
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.auto_stories, color: Colors.amber, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Technical Books & Docs',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              'Offline-ready in-app reader & notes',
                              style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => _tabController.animateTo(5),
                      child: const Text('View All', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 148,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (ctx, idx) {
                      final doc = docs[idx];
                      Color badgeColor = Colors.blue;
                      IconData badgeIcon = Icons.book;
                      if (doc.domain == 'C++') {
                        badgeColor = Colors.indigo;
                        badgeIcon = Icons.memory;
                      } else if (doc.domain == 'Python') {
                        badgeColor = Colors.amber.shade800;
                        badgeIcon = Icons.terminal;
                      } else if (doc.domain == 'Flutter') {
                        badgeColor = Colors.cyan.shade700;
                        badgeIcon = Icons.phone_android;
                      } else if (doc.domain == 'Backend') {
                        badgeColor = Colors.teal;
                        badgeIcon = Icons.dns;
                      } else if (doc.domain == 'DSA') {
                        badgeColor = Colors.purple;
                        badgeIcon = Icons.account_tree;
                      } else if (doc.domain == 'System Design') {
                        badgeColor = Colors.deepOrange;
                        badgeIcon = Icons.cloud;
                      }

                      return InkWell(
                        onTap: () => DocumentReaderView.open(context, document: doc),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 220,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(badgeIcon, size: 12, color: badgeColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          doc.domain,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: badgeColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${doc.chapters.length} Ch.',
                                    style: TextStyle(fontSize: 10.5, color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                doc.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.menu_book, size: 13, color: theme.colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Read Book',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_forward, size: 12),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildOverviewQuickJumpGrid(ThemeData theme) {
    final shortcuts = [
      {'title': 'Curriculum Roadmap', 'icon': Icons.alt_route, 'color': Colors.blue, 'tab': 2},
      {'title': 'Learn Workspace', 'icon': Icons.auto_stories, 'color': Colors.green, 'tab': 3},
      {'title': 'Skill Mastery Map', 'icon': Icons.hub, 'color': Colors.orange, 'tab': 4},
      {'title': 'Verified Resources', 'icon': Icons.verified, 'color': Colors.indigo, 'tab': 5},
      {'title': 'Adaptive Quizzes', 'icon': Icons.quiz, 'color': Colors.purple, 'tab': 6},
      {'title': 'Practical Projects', 'icon': Icons.rocket_launch, 'color': Colors.teal, 'tab': 7},
      {'title': 'EVA Mock Interview', 'icon': Icons.record_voice_over, 'color': Colors.pink, 'tab': 8},
      {'title': 'Job Readiness Score', 'icon': Icons.speed, 'color': Colors.deepOrange, 'tab': 9},
    ];

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Career Workspace Modules',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Jump directly to specialized active learning modules.',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.2,
              ),
              itemCount: shortcuts.length,
              itemBuilder: (ctx, idx) {
                final item = shortcuts[idx];
                final color = item['color'] as Color;
                final tabIdx = item['tab'] as int;

                return InkWell(
                  onTap: () => _tabController.animateTo(tabIdx),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: color.withValues(alpha: 0.2),
                          child: Icon(item['icon'] as IconData, size: 18, color: color),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoadmapPhasesTab() {
    final theme = Theme.of(context);
    final activeAsync = ref.watch(activeUserRoadmapProvider);
    final userRoadmapsAsync = ref.watch(userRoadmapsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(activeUserRoadmapProvider);
        ref.invalidate(userRoadmapsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          activeAsync.when(
            data: (activeRoadmap) {
              if (activeRoadmap == null || activeRoadmap.roadmapId.isEmpty) {
                return _buildEmptyRoadmapCard(theme);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRoadmapPhasesSection(activeRoadmap, theme),
                  const SizedBox(height: 18),
                ],
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
          _buildUserRoadmapsSection(userRoadmapsAsync, theme),
        ],
      ),
    );
  }

  Widget _buildLearnWorkspaceTab() {
    final theme = Theme.of(context);
    final activeAsync = ref.watch(activeUserRoadmapProvider);

    return activeAsync.when(
      data: (activeRoadmap) {
        if (activeRoadmap == null || activeRoadmap.roadmapId.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildEmptyRoadmapCard(theme),
            ),
          );
        }

        final currentPhase = activeRoadmap.phases.firstWhere(
          (p) => p.phaseNumber == activeRoadmap.currentPhaseNumber,
          orElse: () => activeRoadmap.phases.isNotEmpty
              ? activeRoadmap.phases.first
              : RoadmapPhaseDetailModel(phaseNumber: 1, title: 'Phase 1', weeks: 3, description: 'Core Fundamentals'),
        );

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dailyPlanProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 0,
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ACTIVE PHASE ${currentPhase.phaseNumber}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              currentPhase.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      if (currentPhase.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(currentPhase.description, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.help_outline, size: 16),
                            label: const Text('Ask EVA About Phase', style: TextStyle(fontSize: 12)),
                            onPressed: () => _showAskAiSheet(activeRoadmap.roadmapId, activeRoadmap.targetRole, currentPhase.phaseNumber),
                          ),
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.quiz, size: 16),
                            label: const Text('Adaptive Quiz', style: TextStyle(fontSize: 12)),
                            onPressed: () => _tabController.animateTo(6),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _buildStudyTimerCard(theme),
              const SizedBox(height: 18),
              _buildTodaysLearningSection(activeRoadmap.roadmapId, theme),
              const SizedBox(height: 18),
              _buildWeeklyGoalsSection(theme),
            ],
          ),
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildStudyTimerCard(ThemeData theme) {
    final minutes = _studySessionRemainingSeconds ~/ 60;
    final seconds = _studySessionRemainingSeconds % 60;
    final timeFormatted = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.teal.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.teal.withValues(alpha: 0.15),
              child: Icon(_isStudySessionActive ? Icons.timer : Icons.timer_outlined, color: Colors.teal, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Focus Study Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    _isStudySessionActive ? 'In session ($timeFormatted remaining)' : '25-minute Deep Work Timer',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: _toggleStudyTimer,
              child: Text(_isStudySessionActive ? 'Pause' : 'Start (25m)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsTab() {
    final theme = Theme.of(context);
    final activeAsync = ref.watch(activeUserRoadmapProvider);

    return activeAsync.when(
      data: (activeRoadmap) {
        if (activeRoadmap == null || activeRoadmap.roadmapId.isEmpty) {
          return Center(child: Padding(padding: const EdgeInsets.all(24), child: _buildEmptyRoadmapCard(theme)));
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(skillGapProvider);
            ref.invalidate(skillMapProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 0,
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.account_tree, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Skill Dependency Graph', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 2),
                            Text('Visual tree of prerequisite concepts and node statuses.', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('View Graph'),
                        onPressed: () => _showSkillMapSheet(activeRoadmap.roadmapId, activeRoadmap.targetRole),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _buildSkillsImprovementSection(activeRoadmap.roadmapId, theme),
            ],
          ),
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildAssessmentsTab() {
    final theme = Theme.of(context);
    final activeAsync = ref.watch(activeUserRoadmapProvider);

    return activeAsync.when(
      data: (activeRoadmap) {
        if (activeRoadmap == null || activeRoadmap.roadmapId.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildEmptyRoadmapCard(theme),
            ),
          );
        }

        if (_activeAdaptiveQuiz != null) {
          if (_adaptiveQuizResult != null) {
            return _buildAdaptiveQuizSummary(theme, activeRoadmap);
          }
          return _buildAdaptiveQuizRunner(theme, activeRoadmap);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              color: Colors.purple.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.purple.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.quiz, color: Colors.purple, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Phase ${activeRoadmap.currentPhaseNumber} Checkpoint Assessment',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Adaptive 8-pillar quiz evaluating your active conceptual & debugging skills.',
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: const [
                        Chip(label: Text('MCQ', style: TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact),
                        Chip(label: Text('Scenario', style: TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact),
                        Chip(label: Text('Debugging', style: TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact),
                        Chip(label: Text('Code Prediction', style: TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact),
                        Chip(label: Text('Edge Cases', style: TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: Colors.purple),
                      icon: _isLoadingAdaptiveQuiz
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.play_arrow, size: 18),
                      label: Text(_isLoadingAdaptiveQuiz ? 'Generating Questions...' : 'Start Checkpoint Quiz'),
                      onPressed: _isLoadingAdaptiveQuiz
                          ? null
                          : () async {
                              setState(() => _isLoadingAdaptiveQuiz = true);
                              try {
                                final repo = ref.read(careerRepositoryProvider);
                                final quiz = await repo.generateAdaptiveQuiz(
                                  roadmapId: activeRoadmap.roadmapId,
                                  phaseNumber: activeRoadmap.currentPhaseNumber,
                                  role: activeRoadmap.targetRole,
                                  numQuestions: 5,
                                );
                                setState(() {
                                  _activeAdaptiveQuiz = quiz;
                                  _adaptiveQuizQuestionIdx = 0;
                                  _selectedAdaptiveOption = null;
                                  _isAdaptiveQuestionAnswered = false;
                                  _adaptiveUserAnswers.clear();
                                  _adaptiveQuizResult = null;
                                  _isLoadingAdaptiveQuiz = false;
                                });
                              } catch (e) {
                                setState(() => _isLoadingAdaptiveQuiz = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to generate quiz: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildAdaptiveQuizRunner(ThemeData theme, ActiveRoadmapState activeRoadmap) {
    final quiz = _activeAdaptiveQuiz!;
    final q = quiz.questions[_adaptiveQuizQuestionIdx];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${_adaptiveQuizQuestionIdx + 1} of ${quiz.totalQuestions}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                q.type,
                style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_adaptiveQuizQuestionIdx + 1) / quiz.totalQuestions,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          color: Colors.purple,
        ),
        const SizedBox(height: 16),

        if (q.scenario != null && q.scenario!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    q.scenario!,
                    style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        Text(
          q.question,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 14),

        if (q.codeSnippet != null && q.codeSnippet!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                q.codeSnippet!,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFFCDD6F4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        ...List.generate(q.options.length, (optIdx) {
          final isSelected = _selectedAdaptiveOption == optIdx;
          Color borderColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.5);
          Color bgColor = theme.colorScheme.surface;

          if (_isAdaptiveQuestionAnswered) {
            if (optIdx == q.correctIndex) {
              borderColor = Colors.green;
              bgColor = Colors.green.withValues(alpha: 0.1);
            } else if (isSelected && optIdx != q.correctIndex) {
              borderColor = Colors.red;
              bgColor = Colors.red.withValues(alpha: 0.1);
            }
          } else if (isSelected) {
            borderColor = Colors.purple;
            bgColor = Colors.purple.withValues(alpha: 0.08);
          }

          return InkWell(
            onTap: _isAdaptiveQuestionAnswered
                ? null
                : () {
                    setState(() => _selectedAdaptiveOption = optIdx);
                  },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isSelected ? Colors.purple : theme.colorScheme.surfaceContainerHighest,
                    child: Text(
                      String.fromCharCode(65 + optIdx),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      q.options[optIdx],
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        if (_isAdaptiveQuestionAnswered) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    SizedBox(width: 6),
                    Text('Pedagogical Explanation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(q.explanation, style: const TextStyle(fontSize: 12.5, height: 1.35)),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
        if (!_isAdaptiveQuestionAnswered)
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.purple, padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: _selectedAdaptiveOption == null
                ? null
                : () {
                    setState(() {
                      _isAdaptiveQuestionAnswered = true;
                      _adaptiveUserAnswers[_adaptiveQuizQuestionIdx] = _selectedAdaptiveOption!;
                    });
                  },
            child: const Text('Check Answer'),
          )
        else
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.purple, padding: const EdgeInsets.symmetric(vertical: 14)),
            icon: _isSubmittingAdaptiveQuiz
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.arrow_forward, size: 18),
            label: Text(
              _isSubmittingAdaptiveQuiz
                  ? 'Grading Assessment...'
                  : (_adaptiveQuizQuestionIdx < quiz.totalQuestions - 1 ? 'Next Question' : 'Finish & Submit Assessment'),
            ),
            onPressed: _isSubmittingAdaptiveQuiz
                ? null
                : () async {
                    if (_adaptiveQuizQuestionIdx < quiz.totalQuestions - 1) {
                      setState(() {
                        _adaptiveQuizQuestionIdx++;
                        _selectedAdaptiveOption = null;
                        _isAdaptiveQuestionAnswered = false;
                      });
                    } else {
                      // Submit to backend
                      setState(() => _isSubmittingAdaptiveQuiz = true);
                      try {
                        final repo = ref.read(careerRepositoryProvider);
                        final result = await repo.submitPhaseQuiz(
                          phaseNumber: quiz.phaseNumber,
                          role: quiz.role,
                          answers: _adaptiveUserAnswers,
                          roadmapId: activeRoadmap.roadmapId,
                        );
                        ref.invalidate(jobReadinessProvider);
                        ref.invalidate(skillGapProvider);
                        ref.invalidate(activeUserRoadmapProvider);
                        setState(() {
                          _adaptiveQuizResult = result;
                          _isSubmittingAdaptiveQuiz = false;
                        });
                      } catch (e) {
                        setState(() => _isSubmittingAdaptiveQuiz = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to submit quiz: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    }
                  },
          ),
      ],
    );
  }

  Widget _buildAdaptiveQuizSummary(ThemeData theme, ActiveRoadmapState activeRoadmap) {
    final result = _adaptiveQuizResult!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: result.passed ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: result.passed ? Colors.green.withValues(alpha: 0.4) : Colors.orange.withValues(alpha: 0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  result.passed ? Icons.check_circle : Icons.warning_amber,
                  size: 48,
                  color: result.passed ? Colors.green : Colors.orange,
                ),
                const SizedBox(height: 12),
                Text(
                  result.passed ? 'Phase Checkpoint Cleared!' : 'Checkpoint Completed — Review Gaps',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  'Score: ${result.score} / ${result.totalQuestions} (${result.percentage}%)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    result.passed
                        ? '🎉 Mastery Verified: Confidence increased +15% in ${activeRoadmap.targetRole} Architecture. Verified Skill Evidence recorded.'
                        : '💡 EVA AI Adaptation: Identified concept gaps. Practice checkpoints have been dynamically inserted into your curriculum roadmap.',
                    style: const TextStyle(fontSize: 12.5),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _activeAdaptiveQuiz = null;
                      _adaptiveQuizResult = null;
                    });
                  },
                  child: const Text('Back to Assessments'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterviewPrepTab() {
    final theme = Theme.of(context);
    final activeAsync = ref.watch(activeUserRoadmapProvider);
    final activeRoadmap = activeAsync.valueOrNull;
    final roadmapId = activeRoadmap?.roadmapId;
    final role = (activeRoadmap?.targetRole != null && activeRoadmap!.targetRole.isNotEmpty)
        ? activeRoadmap.targetRole
        : 'Modern Software Engineer';

    final questionsAsync = ref.watch(interviewPrepProvider(roadmapId));
    final fetchedQuestions = questionsAsync.valueOrNull ?? [];
    final allQuestions = fetchedQuestions.isNotEmpty
        ? fetchedQuestions
        : _getCuratedQuestionsForRole(role);

    final filteredQuestions = _selectedInterviewCategory == 'All'
        ? allQuestions
        : allQuestions.where((q) {
            final cat = q.category.toLowerCase();
            final selected = _selectedInterviewCategory.toLowerCase();
            return cat.contains(selected) || selected.contains(cat);
          }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        if (roadmapId != null && roadmapId.isNotEmpty) {
          ref.invalidate(interviewPrepProvider(roadmapId));
        }
        ref.invalidate(activeUserRoadmapProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInterviewHeroBanner(theme, roadmapId, role),
          const SizedBox(height: 18),
          _buildInterviewToolkitsCard(theme),
          const SizedBox(height: 18),
          _buildInterviewFilterSection(theme, role, allQuestions.length),
          const SizedBox(height: 12),
          if (filteredQuestions.isEmpty)
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.quiz_outlined, size: 36, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 8),
                      Text(
                        'No questions found in this category.',
                        style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() => _selectedInterviewCategory = 'All'),
                        child: const Text('Reset Category Filter'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredQuestions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final q = filteredQuestions[idx];
                return _buildInterviewQuestionCard(q, idx + 1, theme, roadmapId, role);
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInterviewHeroBanner(ThemeData theme, String? roadmapId, String role) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E1B4B),
            const Color(0xFF312E81),
            const Color(0xFF1E1B4B).withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4338CA).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const EvaAiAvatar(size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text(
                            'EVA AI Interview Room',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.verified, color: Color(0xFF38BDF8), size: 16),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          role,
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Real-time conversational mock technical interview. EVA evaluates your mental models, code quality, edge-case analysis, and STAR communication.',
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildSmallPill(Icons.mic, 'Live Voice & Speech', const Color(0xFF38BDF8)),
                _buildSmallPill(Icons.analytics_outlined, 'STAR Rubric Scored', const Color(0xFFFBBF24)),
                _buildSmallPill(Icons.psychology_outlined, 'Adaptive Follow-Ups', const Color(0xFF34D399)),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.record_voice_over, size: 18),
                  label: const Text('Enter Live Interview Room', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    EvaInterviewRoomView.open(
                      context,
                      roadmapId: roadmapId,
                      targetRole: role,
                      initialMode: 'VOICE',
                    );
                  },
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.flash_on, size: 16, color: Color(0xFFFBBF24)),
                  label: const Text('Quick 5-Min Drill'),
                  onPressed: () {
                    EvaInterviewRoomView.open(
                      context,
                      roadmapId: roadmapId,
                      targetRole: role,
                      initialMode: 'TEXT',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterviewToolkitsCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Placement & Career Preparation Modules',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Colors.teal,
                child: Icon(Icons.description, color: Colors.white, size: 20),
              ),
              title: const Text('ATS Resume Optimization Tips', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Action verbs, metrics, and ATS-friendly templates', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showResumeTipsSheet,
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Colors.deepPurple,
                child: Icon(Icons.school, color: Colors.white, size: 20),
              ),
              title: const Text('Placement Core Preparation Modules', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('DSA patterns, OS, DBMS, Networks & Aptitude', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showPlacementPrepSheet,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterviewFilterSection(ThemeData theme, String role, int count) {
    const categories = ['All', 'Technical', 'System Design', 'Behavioral', 'Data Structures'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '🎯 High-Yield Interview Bank ($count)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            Text(
              'Tier-1 Calibrated',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Target questions for $role campus placement drives and FAANG technical rounds.',
          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((cat) {
              final isSelected = _selectedInterviewCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedInterviewCategory = cat),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInterviewQuestionCard(
    InterviewQuestionModel q,
    int index,
    ThemeData theme,
    String? roadmapId,
    String role,
  ) {
    Color diffColor = q.difficulty == 'Hard'
        ? Colors.red
        : (q.difficulty == 'Intermediate' || q.difficulty == 'Medium' ? Colors.orange : Colors.green);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            child: Text(
              '$index',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
          ),
          title: Text(
            q.question,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: diffColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    q.difficulty,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: diffColor),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    q.category,
                    style: TextStyle(fontSize: 10, color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (q.context != null && q.context!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.psychology, size: 14, color: Colors.blue),
                        SizedBox(width: 6),
                        Text(
                          'Interviewer Evaluation Intent & Approach',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(q.context!, style: const TextStyle(fontSize: 12, height: 1.35)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (q.keyPoints.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '🔑 Key Concepts to Mention',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: q.keyPoints.map((point) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('• $point', style: const TextStyle(fontSize: 11)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],
            if (q.sampleAnswer.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📝 Answer Blueprint',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(q.sampleAnswer, style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant, height: 1.35)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.record_voice_over, size: 16),
                label: const Text('Practice this Question with EVA AI', style: TextStyle(fontSize: 12.5)),
                onPressed: () {
                  EvaInterviewRoomView.open(
                    context,
                    roadmapId: roadmapId,
                    targetRole: role,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<InterviewQuestionModel> _getCuratedQuestionsForRole(String role) {
    final lower = role.toLowerCase();

    if (lower.contains('c++') || lower.contains('cpp') || lower.contains('systems')) {
      return [
        InterviewQuestionModel(
          id: 'q-cpp-1',
          type: 'TECHNICAL',
          question: 'How does RAII prevent resource leaks in C++, and how do unique_ptr vs shared_ptr manage ownership and control block overhead?',
          difficulty: 'Hard',
          category: 'Technical',
          context: 'Assesses mastery of modern C++ resource management, exception safety guarantees, and the internal implementation of smart pointers.',
          keyPoints: ['RAII lifetime semantics', 'Stack unwinding exception safety', 'unique_ptr zero-overhead abstraction', 'shared_ptr atomic reference counting & control block', 'make_shared single allocation'],
          sampleAnswer: 'RAII binds resource lifecycle to object lifetime. When an object leaves scope, its destructor is invoked deterministically during stack unwinding. std::unique_ptr has exclusive ownership with zero runtime overhead (same size as raw pointer). std::shared_ptr maintains a reference-counted control block allocating strong and weak reference counts. Using std::make_shared combines the object and control block into a single cache-friendly heap allocation.',
          tips: ['Mention make_unique and make_shared exception safety advantages.', 'Explain how weak_ptr prevents circular reference leaks.'],
        ),
        InterviewQuestionModel(
          id: 'q-cpp-2',
          type: 'TECHNICAL',
          question: 'Explain the C++ Memory Model, atomic operations, and how acquire-release semantics enable lock-free concurrency.',
          difficulty: 'Hard',
          category: 'Technical',
          context: 'Tests deep knowledge of multithreading, CPU cache coherence, instruction reordering, and low-latency systems programming.',
          keyPoints: ['std::memory_order_relaxed', 'Acquire-release synchronization', 'Sequential consistency (seq_cst)', 'Lock-free ring buffer (SPSC)', 'Hardware memory barriers'],
          sampleAnswer: 'By default, C++ atomics use memory_order_seq_cst which guarantees a globally consistent execution order across all threads but incurs hardware memory fences. With acquire-release semantics, memory_order_release prevents writes from being reordered after it, and memory_order_acquire prevents reads from being reordered before it. This enables high-performance lock-free ring buffers between a producer and consumer without mutex locks.',
          tips: ['Distinguish compiler reordering from CPU out-of-order execution.', 'State when a lock-free queue needs CAS (Compare-And-Swap) vs atomic load/store.'],
        ),
        InterviewQuestionModel(
          id: 'q-cpp-3',
          type: 'SYSTEM_DESIGN',
          question: 'Design a High-Frequency Order Book in C++ with sub-microsecond matching latency and zero heap allocations in the critical path.',
          difficulty: 'Hard',
          category: 'System Design',
          context: 'Evaluates architectural design for low-latency quantitative finance and systems performance optimization.',
          keyPoints: ['Pre-allocated contiguous memory arena', 'Price level limit order tree', 'Doubly linked list of orders', 'Zero-copy ring buffer IPC', 'Cache line alignment & false sharing'],
          sampleAnswer: 'To achieve sub-microsecond latency, avoid malloc/free in the matching loop by pre-allocating an order pool arena. Organize the limit order book using an array of price points or a B-Tree for fast lookups, with a doubly-linked list of orders at each price for FIFO matching. Align shared atomic data structures to 64-byte cache lines using alignas(64) to eliminate false sharing between matching and ingestion threads.',
          tips: ['Highlight CPU cache prefetching and branch prediction optimization.', 'Discuss why kernel bypass (Solarflare OpenOnload / DPDK) is used in HFT.'],
        ),
        InterviewQuestionModel(
          id: 'q-cpp-4',
          type: 'BEHAVIORAL',
          question: 'Tell me about a time you tracked down an elusive memory corruption or concurrency race condition in your code.',
          difficulty: 'Intermediate',
          category: 'Behavioral',
          context: 'Tests real-world debugging resilience, diagnostic tool fluency, and structured post-mortem reasoning (STAR format).',
          keyPoints: ['Situation: Non-deterministic crash in production/testing', 'Task: Diagnose root cause without masking bug', 'Action: AddressSanitizer (ASan), Valgrind, ThreadSanitizer (TSan)', 'Result: Verified fix with regression test'],
          sampleAnswer: 'Situation: An intermittent segmentation fault occurred under heavy load. Task: Identify the root cause without using ad-hoc sleeps. Action: Compiled the binary with -fsanitize=address,undefined and simulated load. ASan immediately caught a use-after-free where a lambda captured a pointer to a temporary object. I refactored the ownership to std::shared_ptr and added a stress regression test in the CI pipeline. Result: Zero memory incidents recorded thereafter.',
          tips: ['Use the STAR framework explicitly.', 'Emphasize automated prevention via CI sanitizer builds.'],
        ),
      ];
    } else if (lower.contains('flutter') || lower.contains('mobile')) {
      return [
        InterviewQuestionModel(
          id: 'q-flt-1',
          type: 'TECHNICAL',
          question: 'Explain how Flutter builds and renders UI: Widget Tree vs Element Tree vs RenderObject Tree, and how RepaintBoundary works.',
          difficulty: 'Intermediate',
          category: 'Technical',
          context: 'Assesses understanding of Flutter pipeline internals, rebuild optimizations, and frame rendering performance.',
          keyPoints: ['Widget (Immutable configuration)', 'Element (Structural identity & lifecycle)', 'RenderObject (Layout, paint, hit testing)', 'RepaintBoundary display list caching', 'const constructor widget deduplication'],
          sampleAnswer: 'Widgets are lightweight immutable blueprint configurations. Elements represent the live instantiated tree that manages state and lifecycle. When a widget rebuilds, the element determines whether the runtimeType and key match. If they do, the existing RenderObject is updated rather than recreated. RepaintBoundary isolates a subtree into a separate Layer so that changes in an animated child do not trigger repainting of the parent canvas.',
          tips: ['Mention how const widgets enable Flutter to skip element tree comparisons.', 'Explain the difference between build phase and layout/paint phase.'],
        ),
        InterviewQuestionModel(
          id: 'q-flt-2',
          type: 'TECHNICAL',
          question: 'How does Dart handle concurrency with the Event Loop, Microtask Queue, and Isolates? When must you use an Isolate?',
          difficulty: 'Hard',
          category: 'Technical',
          context: 'Tests concurrency mechanics in Dart, avoiding UI frame drops (jank), and heavy background computation.',
          keyPoints: ['Single-threaded event loop', 'Microtask queue vs Event queue priority', 'Isolates separate memory heap', 'Isolate.run / compute helper', '16.6ms frame budget (60 FPS)'],
          sampleAnswer: 'Dart runs on a single thread powered by an event loop with two queues: Microtask Queue (processed first to completion) and Event Queue (I/O, timers, clicks). If a CPU-bound task (e.g. image filtering or parsing a 50MB JSON) takes more than 16ms on the UI isolate, it causes dropped frames (jank). Spawning a background Isolate via Isolate.run creates an isolated memory heap that runs in parallel without freezing the UI.',
          tips: ['Clarify that async/await does NOT run on a separate thread; it runs cooperatively on the same event loop.', 'Explain message passing serialization overhead between Isolates.'],
        ),
        InterviewQuestionModel(
          id: 'q-flt-3',
          type: 'SYSTEM_DESIGN',
          question: 'Design an Offline-First Mobile Sync Engine in Flutter with local SQLite/Hive caching, optimistic UI updates, and conflict resolution.',
          difficulty: 'Hard',
          category: 'System Design',
          context: 'Evaluates production mobile architecture for resilient distributed synchronization across intermittent networks.',
          keyPoints: ['Local-first write with pending status', 'Optimistic UI update via Riverpod/StateNotifier', 'Outbox mutation queue with retries & backoff', 'Last-Write-Wins vs Vector Clocks conflict resolution', 'Delta sync with updated_at timestamp'],
          sampleAnswer: 'The app writes mutations directly to local storage (SQLite/Isar) with a status of PENDING and immediately updates the UI optimistically. An Outbox Sync Worker reads pending mutations in FIFO order, transmitting them with exponential backoff. The server validates mutations and returns authoritative timestamps. If concurrent modifications conflict, use versioned timestamps (or field-level merge) and broadcast updates to reactive providers to synchronize UI state.',
          tips: ['Explain how connectivity_plus monitors network transitions to trigger background flushing.', 'Discuss idempotency keys in API headers to prevent double submissions.'],
        ),
        InterviewQuestionModel(
          id: 'q-flt-4',
          type: 'BEHAVIORAL',
          question: 'Describe a situation where your mobile app had noticeable rendering jank or memory leaks. How did you identify and resolve it?',
          difficulty: 'Intermediate',
          category: 'Behavioral',
          context: 'Tests performance profiling fluency with Flutter DevTools, memory profiling, and disciplined engineering.',
          keyPoints: ['Flutter DevTools Performance view', 'Raster vs UI thread frame time', 'Unbounded list views without ListView.builder', 'Image cache memory bloat', 'StreamSubscription / Controller leaks'],
          sampleAnswer: 'In a feed screen, scrolling caused noticeable stutter. I attached Flutter DevTools Performance overlay and noticed UI thread times spiking to 35ms. Profiling revealed an unindexed ListView generating all items eagerly and uncompressed high-resolution images. I refactored to ListView.builder, added memCacheWidth/Height constraints to image decoders, and ensured AnimationControllers were disposed in dispose(). Frame times dropped consistently to under 8ms.',
          tips: ['Mention specific DevTools tabs (Memory allocations, Timeline, CPU Profiler).', 'Quantify the improvement in FPS or memory footprint.'],
        ),
      ];
    } else if (lower.contains('python')) {
      return [
        InterviewQuestionModel(
          id: 'q-py-1',
          type: 'TECHNICAL',
          question: 'Explain the CPython Global Interpreter Lock (GIL), how it impacts CPU vs I/O bound code, and free-threaded Python 3.13.',
          difficulty: 'Hard',
          category: 'Technical',
          context: 'Tests deep knowledge of CPython runtime internals, multi-threading vs multi-processing, and modern Python evolution.',
          keyPoints: ['CPython reference count safety', 'GIL preemptive thread switching', 'I/O-bound concurrency benefit', 'Multiprocessing for CPU parallelization', 'PEP 703 Free-Threaded Python 3.13'],
          sampleAnswer: 'The GIL is a mutex that prevents multiple native threads from executing Python bytecodes simultaneously to protect CPython memory management and reference counts. For I/O-bound tasks, the GIL is released during socket/file syscalls, making threading effective. For CPU-bound workloads, threading degrades performance due to mutex contention; multiprocessing or native C extensions must be used. PEP 703 introduces experimental free-threaded Python (disabling GIL with biased reference counting and mimalloc).',
          tips: ['Explain the 5ms switch interval / check interval in CPython.', 'Mention sub-interpreters (PEP 684) as an alternative to multiprocessing.'],
        ),
        InterviewQuestionModel(
          id: 'q-py-2',
          type: 'SYSTEM_DESIGN',
          question: 'Design a Distributed Asynchronous Task Queue in Python (like Celery) handling 50,000 tasks/second with retries and dead-letter queues.',
          difficulty: 'Hard',
          category: 'System Design',
          context: 'Assesses backend distributed systems, message brokers, worker thread pools, and error recovery architectures.',
          keyPoints: ['Redis Streams or RabbitMQ as broker', 'Prefetch count & worker concurrency', 'Idempotency keys & at-least-once delivery', 'Exponential backoff with jitter', 'Dead-letter queue (DLQ) for poisoned tasks'],
          sampleAnswer: 'Clients produce serialized JSON/MessagePack tasks to a durable Redis Stream or RabbitMQ exchange. Preforked worker pools acknowledge tasks only after execution (ack_late=True). For transient errors, tasks are republished with exponential backoff and jitter into a delayed exchange. After N retries, tasks are routed to a Dead-Letter Queue (DLQ) for alerting. Idempotency keys stored in Redis ensure duplicate deliveries do not duplicate side-effects.',
          tips: ['Discuss heartbeat mechanisms to detect crashed workers.', 'Highlight monitoring using Prometheus metrics and Flower.'],
        ),
        InterviewQuestionModel(
          id: 'q-py-3',
          type: 'TECHNICAL',
          question: 'Explain Python memory management: pymalloc, memory arenas, reference counting, and the cyclic garbage collector.',
          difficulty: 'Hard',
          category: 'Technical',
          context: 'Evaluates understanding of low-level memory allocation, avoidance of memory leaks, and GC tuning in production.',
          keyPoints: ['Arenas (256KB), Pools (4KB), Blocks (<=512 bytes)', 'Reference counting (primary deallocator)', 'Generational cyclic GC (Gen 0, 1, 2)', 'Tri-color marking algorithm', 'gc.disable() optimization in high-throughput workers'],
          sampleAnswer: 'Python uses pymalloc for small objects (<= 512 bytes) divided into 256KB Arenas, 4KB Pools, and fixed-size Blocks to eliminate OS malloc fragmentation. Reference counting deallocates memory immediately when count reaches zero. To break cyclic references (e.g. A->B->A), CPython runs a generational cyclic collector across 3 generations using double-linked lists to detect isolated reference cycles. Objects surviving collections are promoted to older generations.',
          tips: ['Explain why __del__ methods previously hindered cyclic GC.', 'Mention how __slots__ drastically reduces memory usage by eliminating instance __dict__.'],
        ),
      ];
    } else {
      return [
        InterviewQuestionModel(
          id: 'q-gen-1',
          type: 'TECHNICAL',
          question: 'Explain how B+ Tree and LSM Tree database indexes work under the hood. How do you design an indexing strategy for write-heavy vs read-heavy workloads?',
          difficulty: 'Hard',
          category: 'Technical',
          context: 'Tests deep knowledge of database storage engines, disk I/O, cache locality, and indexing optimization.',
          keyPoints: ['B+ Tree: balanced tree, sorted leaf nodes, sequential range scans', 'LSM Tree: MemTable, Write-Ahead Log (WAL), SSTables, Compaction', 'B+ Tree ideal for read-heavy / low latency reads', 'LSM Tree (Cassandra/RocksDB) ideal for high-throughput writes', 'Index selectivity & composite index column ordering'],
          sampleAnswer: 'B+ Trees store all data in leaf nodes linked sequentially, making point lookups and range scans O(log N) with high cache locality. However, random updates cause costly page splits. LSM (Log-Structured Merge) Trees append all writes sequentially to a WAL and in-memory MemTable, then flush immutable SSTables to disk with background compaction. B+ Trees (Postgres/MySQL InnoDB) excel for read-heavy transactional queries, while LSM Trees excel for write-heavy ingestion workloads.',
          tips: ['Discuss Bloom Filters in LSM trees to skip SSTables for absent keys.', 'Explain how leftmost prefix matching applies to composite B+ Tree indexes.'],
        ),
        InterviewQuestionModel(
          id: 'q-gen-2',
          type: 'SYSTEM_DESIGN',
          question: 'Design a Distributed Rate Limiter for an API Gateway serving 100,000 requests per second across multiple regional servers.',
          difficulty: 'Hard',
          category: 'System Design',
          context: 'Evaluates distributed systems architecture, caching, race condition prevention, and algorithm trade-offs.',
          keyPoints: ['Token Bucket vs Leaky Bucket vs Sliding Window Log vs Sliding Window Counter', 'Redis with Lua scripting for atomic execution', 'Local in-memory token bucket + periodic sync to reduce latency', 'HTTP 429 Too Many Requests with Retry-After header', 'Fallback mode on cache failure (graceful degradation)'],
          sampleAnswer: 'Use a Sliding Window Counter algorithm implemented with Redis and executed via an atomic Lua script to prevent race conditions. To avoid making a network call to Redis for every single request at 100k RPS, combine an in-memory local token bucket on each gateway node that requests batches of tokens (e.g. 500 tokens) from the central Redis cluster every second. If Redis is temporarily unreachable, fail-open to ensure service availability while logging security alerts.',
          tips: ['Show mathematical calculation for sliding window counter estimation error (<0.05%).', 'Mention RateLimit-Limit, RateLimit-Remaining, and Retry-After HTTP headers.'],
        ),
        InterviewQuestionModel(
          id: 'q-gen-3',
          type: 'BEHAVIORAL',
          question: 'STAR Behavioral: Tell me about a time when a critical production bug occurred. Walk me through your triage, mitigation, and post-mortem.',
          difficulty: 'Intermediate',
          category: 'Behavioral',
          context: 'Assesses engineering maturity, calmness under pressure, blameless post-mortem culture, and systematic incident management.',
          keyPoints: ['Situation: Production incident impact & detection', 'Task: Mitigate user impact immediately before finding root cause', 'Action: Rollback or feature flag toggle, then isolated RCA', 'Result: SLA restored, added automated integration tests & alerts'],
          sampleAnswer: 'Situation: Following a Friday deployment, checkout transactions failed for 12% of users due to an unhandled null in a newly added currency conversion helper. Task: Restore checkout functionality immediately within our 15-minute SLA. Action: Rather than attempting a live hotfix, I triggered an immediate rollback to the previous stable release, restoring service in 4 minutes. Afterward, I led a blameless post-mortem, identified missing test coverage for non-USD currencies, added automated CI regression tests, and implemented automated canary deployments. Result: 99.98% checkout availability maintained for subsequent releases.',
          tips: ['Highlight the distinction between immediate mitigation (rollback/flags) and long-term fix.', 'Mention blameless post-mortem and actionable preventative checklist items.'],
        ),
        InterviewQuestionModel(
          id: 'q-gen-4',
          type: 'TECHNICAL',
          question: 'Explain SQL transaction isolation levels (Read Committed, Repeatable Read, Serializable) and how MVCC works in modern databases.',
          difficulty: 'Hard',
          category: 'Technical',
          context: 'Evaluates concurrency control, ACID guarantees, and database transaction anomaly prevention.',
          keyPoints: ['Dirty Read, Non-Repeatable Read, Phantom Read, Write Skew', 'Read Committed: reads latest committed snapshot', 'Repeatable Read: snapshot established at transaction start', 'MVCC (Multi-Version Concurrency Control): readers never block writers', 'xmin and xmax row headers in PostgreSQL'],
          sampleAnswer: 'SQL defines isolation levels based on prohibited read anomalies. Read Committed prevents dirty reads by taking a snapshot before each query. Repeatable Read takes a snapshot at the start of the transaction, preventing non-repeatable reads. Serializable guarantees an execution order equivalent to sequential execution. Databases like PostgreSQL implement MVCC by storing multiple versions of tuples with xmin (creation transaction ID) and xmax (deletion transaction ID) metadata so readers read historical snapshots without blocking active writers.',
          tips: ['Explain Write Skew anomaly which can occur in Repeatable Read and requires Serializable or SELECT FOR UPDATE.', 'Discuss vacuuming/garbage collection of dead tuples in MVCC.'],
        ),
      ];
    }
  }

  Widget _buildJobReadinessTab() {
    final theme = Theme.of(context);
    final activeAsync = ref.watch(activeUserRoadmapProvider);

    return activeAsync.when(
      data: (activeRoadmap) {
        final roadmapId = activeRoadmap?.roadmapId ?? '';
        final role = activeRoadmap?.targetRole ?? 'Modern Full-Stack & Cloud Engineer';

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(jobReadinessProvider);
            ref.invalidate(weeklyReviewProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildWeeklyReviewReadinessSection(roadmapId, role, theme),
              const SizedBox(height: 18),
              _buildReadinessPrioritiesChecklist(roadmapId, theme),
            ],
          ),
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildReadinessPrioritiesChecklist(String roadmapId, ThemeData theme) {
    final readinessAsync = ref.watch(jobReadinessProvider(roadmapId));

    return readinessAsync.when(
      data: (data) {
        if (data.topPriorities.isEmpty) return const SizedBox.shrink();

        return Card(
          elevation: 0,
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.flag, color: Colors.deepOrange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Top Priorities to Reach Placement Readiness',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...data.topPriorities.map((priority) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.arrow_right, color: Colors.deepOrange),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              priority,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showResumeTipsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, sc) => Column(
          children: [
            Container(margin: const EdgeInsets.symmetric(vertical: 8), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
            Expanded(child: _buildResumeTipsTab()),
          ],
        ),
      ),
    );
  }

  void _showPlacementPrepSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, sc) => Column(
          children: [
            Container(margin: const EdgeInsets.symmetric(vertical: 8), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
            Expanded(child: _buildPlacementPrepTab()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
            Colors.indigo.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.indigo, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'AI CAREER ROADMAP',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Build Your Path',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Adaptive curriculum tuned to your pace, projects, and placement goals.',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const EvaAiAvatar(size: 54),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('+ Create AI', style: TextStyle(fontSize: 11.5)),
                  onPressed: _showOnboardingSheet,
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                icon: const Icon(Icons.checklist_rtl, size: 15),
                label: const Text('Next Up', style: TextStyle(fontSize: 11.5)),
                onPressed: () {
                  final active = ref.read(activeUserRoadmapProvider).valueOrNull;
                  if (active != null && active.roadmapId.isNotEmpty) {
                    _showWhatNextSheet(active);
                  } else {
                    _showOnboardingSheet();
                  }
                },
              ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                icon: const Icon(Icons.help_outline, size: 15),
                label: const Text("🤔 Confused?", style: TextStyle(fontSize: 11.5)),
                onPressed: _showDecisionHelperDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRoadmapCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const EvaAiAvatar(size: 58),
            const SizedBox(height: 14),
            const Text(
              'No Active Career Roadmap Yet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Let EVA AI analyze your goals and generate a custom multi-phase engineering curriculum with real-world projects and quizzes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Create Your AI Roadmap'),
              onPressed: _showOnboardingSheet,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_user_outlined, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        '100% Personalized — Zero Generic Templates',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'CampusHub generates prerequisite-aware roadmaps per student through interactive discovery with EVA AI. Your curriculum continuously adapts based on your quiz checkpoints, code submissions, and mock interview performance.',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueLearningCard(ActiveRoadmapState activeRoadmap, ThemeData theme) {
    final percent = activeRoadmap.progressPercent.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row (Reference Image 2)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CAREER LEVEL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${activeRoadmap.targetRole} (${activeRoadmap.level})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'v${activeRoadmap.version}.0',
                  style: const TextStyle(color: Colors.indigo, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: 'Tap to update status',
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => _showUpdateStatusDialog(activeRoadmap.roadmapId, activeRoadmap.status),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (activeRoadmap.status == 'ACTIVE'
                              ? Colors.green
                              : (activeRoadmap.status == 'COMPLETED' ? Colors.blue : Colors.orange))
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: (activeRoadmap.status == 'ACTIVE'
                                ? Colors.green
                                : (activeRoadmap.status == 'COMPLETED' ? Colors.blue : Colors.orange))
                            .withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          activeRoadmap.status,
                          style: TextStyle(
                            color: activeRoadmap.status == 'ACTIVE'
                                ? Colors.green
                                : (activeRoadmap.status == 'COMPLETED' ? Colors.blue : Colors.orange),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 14,
                          color: activeRoadmap.status == 'ACTIVE'
                              ? Colors.green
                              : (activeRoadmap.status == 'COMPLETED' ? Colors.blue : Colors.orange),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Your Milestone Card (Reference Image 2)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.emoji_events, color: Colors.amber, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Milestone',
                            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activeRoadmap.currentFocus.isNotEmpty
                                ? activeRoadmap.currentFocus
                                : 'Phase 1: Foundations & Core Concepts',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'Phase 1/5',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
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
          ),
          const SizedBox(height: 12),

          // Next Up Action Banner
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showWhatNextSheet(activeRoadmap),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    Colors.indigo.withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.checklist_rtl, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'What To Finish Next',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'View upcoming daily tasks, checkpoint tests & challenges',
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 12, color: theme.colorScheme.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Quick Action Bar
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.checklist_rtl, size: 14),
                  label: const Text('Next Up', style: TextStyle(fontSize: 11)),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  ),
                  onPressed: () => _showWhatNextSheet(activeRoadmap),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline, size: 14),
                  label: const Text('Ask EVA', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  ),
                  onPressed: () => _showAskAiSheet(activeRoadmap.roadmapId, activeRoadmap.targetRole, 1),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.account_tree, size: 14),
                  label: const Text('Skill Map', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  ),
                  onPressed: () => _showSkillMapSheet(activeRoadmap.roadmapId, activeRoadmap.targetRole),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.auto_awesome, size: 14),
                  label: const Text('Adapt AI', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  ),
                  onPressed: () => _adaptRoadmap(activeRoadmap.roadmapId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysLearningSection(String roadmapId, ThemeData theme) {
    final dailyAsync = ref.watch(dailyPlanProvider(roadmapId));

    return dailyAsync.when(
      data: (plan) {
        if (plan == null) return const SizedBox.shrink();

        final tasks = plan.tasks;
        Color priorityColor = plan.priority.toUpperCase() == 'HIGH'
            ? Colors.red
            : (plan.priority.toUpperCase() == 'MEDIUM' ? Colors.orange : Colors.blue);

        return Card(
          elevation: 0,
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          "TODAY'S LEARNING",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            plan.priority,
                            style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '~${plan.estimatedMinutes} mins',
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _todayGoalDone,
                        activeColor: Colors.green,
                        onChanged: (val) {
                          setState(() => _todayGoalDone = val ?? false);
                          if (val == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Daily micro-goal complete! Keep up the great streak! 🔥')),
                            );
                          }
                        },
                      ),
                      Expanded(
                        child: Text(
                          plan.microGoal.isNotEmpty ? plan.microGoal : 'Complete 45 minutes of focused learning.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            decoration: _todayGoalDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (tasks.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...tasks.map((task) {
                    IconData catIcon;
                    Color catColor;
                    switch (task.category.toUpperCase()) {
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: task.isCompleted,
                              activeColor: catColor,
                              onChanged: (val) async {
                                final repo = ref.read(careerRepositoryProvider);
                                await repo.toggleDailyTask(roadmapId, task.id, val ?? false);
                                ref.invalidate(dailyPlanProvider(roadmapId));
                                ref.invalidate(activeUserRoadmapProvider);
                              },
                            ),
                            Icon(catIcon, size: 16, color: catColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  if (task.description.isNotEmpty)
                                    Text(
                                      task.description,
                                      style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            Text('~${task.estimatedMinutes}m', style: TextStyle(fontSize: 10, color: theme.colorScheme.outline)),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSkillsImprovementSection(String roadmapId, ThemeData theme) {
    final skillGapAsync = ref.watch(skillGapProvider(roadmapId));

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Skills that need improvement',
              style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            skillGapAsync.when(
              data: (analysis) {
                final skills = analysis.skillsThatNeedImprovement;
                if (skills.isEmpty) {
                  return Text(
                    'No skill gaps detected yet. Excellent job mastering your foundations!',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                  );
                }

                return Column(
                  children: List.generate(skills.length, (idx) {
                    final item = skills[idx];
                    final skillName = item['skill']?.toString() ?? 'Core Engineering';
                    final desc = item['description']?.toString() ?? item['reason']?.toString() ?? 'Practice core fundamentals and code examples.';
                    final status = item['status']?.toString() ?? 'Needs Work';

                    Color statusColor = status == 'Missing'
                        ? Colors.red
                        : (status == 'Strong' ? Colors.green : Colors.orange);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        skillName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  desc,
                                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
              error: (_, __) => Column(
                children: [
                  _buildFallbackSkillItem(1, 'API Architecture & State Management', 'Understand how to create scalable, predictable data flow.', 'Needs Work'),
                  _buildFallbackSkillItem(2, 'Database Indexing & Queries', 'Practice query plans and eliminating full table scans.', 'Needs Work'),
                  _buildFallbackSkillItem(3, 'Automated Unit & Integration Testing', 'Build robust test suites for enterprise reliability.', 'Missing'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackSkillItem(int num, String title, String desc, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            child: Text('$num', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadmapPhasesSection(ActiveRoadmapState activeRoadmap, ThemeData theme) {
    final phases = _getRoadmapPhases(activeRoadmap);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        JourneyMapWidget(
          activeRoadmap: activeRoadmap,
          phases: phases,
          onPhaseTap: (pNum) {
            // Tapping a phase milestone in the Journey Map
          },
          onViewChanges: () => RoadmapChangesDialog.show(context, activeRoadmap.roadmapId),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Curriculum Modules',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '5 Phases',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...phases.map((ph) {
          final pNum = ph['num'] as int;
          final title = ph['title'] as String;
          final weeks = ph['weeks'] as String;
          final objectives = ph['objectives'] as List<String>;
          final skills = ph['skills'] as List<String>;
          final challenge = ph['challenge'] as RoadmapPracticalChallengeModel;
          final project = ph['project'] as RoadmapProjectModel;

          final scoreKey = 'phase_$pNum';
          final scoreData = activeRoadmap.quizScores?[scoreKey];
          final isCompleted = scoreData != null && scoreData['passed'] == true;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isCompleted
                    ? Colors.green.withValues(alpha: 0.5)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: ExpansionTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: isCompleted
                    ? Colors.green.withValues(alpha: 0.15)
                    : theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.green, size: 18)
                    : Text(
                        '$pNum',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.primary),
                      ),
              ),
              title: Text(
                'Phase $pNum: $title',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              subtitle: Text(
                '$weeks • ${isCompleted ? "Quiz Passed ✓" : "In Progress"}',
                style: TextStyle(fontSize: 11, color: isCompleted ? Colors.green : theme.colorScheme.onSurfaceVariant),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Milestone Objectives:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 6),
                      ...objectives.map((obj) => Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Expanded(child: Text(obj, style: const TextStyle(fontSize: 12))),
                              ],
                            ),
                          )),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: skills.map((s) => Chip(
                              label: Text(s, style: const TextStyle(fontSize: 10)),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            )).toList(),
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 10),

                      // Phase Action Buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.quiz, size: 15),
                            label: Text(scoreData != null ? 'Retake Quiz' : 'Take Checkpoint Quiz', style: const TextStyle(fontSize: 11)),
                            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                            onPressed: () => _showPhaseQuizDialog(pNum, activeRoadmap.targetRole, activeRoadmap.roadmapId),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.lightbulb_outline, size: 15),
                            label: const Text('Practical Challenge', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                            onPressed: () => _showPracticalChallengeDialog(challenge),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.rocket_launch, size: 15),
                            label: const Text('Project & Portfolio', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                            onPressed: () => _showPhaseProjectDialog(activeRoadmap.roadmapId, project),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWeeklyReviewReadinessSection(String roadmapId, String role, ThemeData theme) {
    final readinessAsync = ref.watch(jobReadinessProvider(roadmapId));

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Job Readiness Analytics',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.insights, color: Colors.indigo, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Calibrated based on quiz checkpoints, code tasks, and projects.',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),

            readinessAsync.when(
              data: (data) {
                final isAssessed = data.isAssessed;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: isAssessed ? (data.readinessPercentage / 100.0) : 0.0,
                                strokeWidth: 6,
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                color: isAssessed ? Colors.indigo : Colors.grey.withValues(alpha: 0.5),
                              ),
                              Center(
                                child: Text(
                                  isAssessed ? '${data.readinessPercentage}%' : '0%',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.readinessLevel,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isAssessed ? Colors.indigo : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isAssessed
                                    ? '${data.passedQuizzes} quizzes passed • ${data.completedProjects} projects submitted'
                                    : 'Complete checkpoint quizzes & mini projects to calculate your score.',
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Dimension Breakdown Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildDimensionChip('Technical', data.technical.status, data.technical.isAssessed, theme),
                          const SizedBox(width: 6),
                          _buildDimensionChip('Projects', data.projects.status, data.projects.isAssessed, theme),
                          const SizedBox(width: 6),
                          _buildDimensionChip('Interview', data.interview.status, data.interview.isAssessed, theme),
                          const SizedBox(width: 6),
                          _buildDimensionChip('Problem Solving', data.problemSolving.status, data.problemSolving.isAssessed, theme),
                          const SizedBox(width: 6),
                          _buildDimensionChip('Portfolio', data.portfolio.status, data.portfolio.isAssessed, theme),
                          const SizedBox(width: 6),
                          _buildDimensionChip('Consistency', data.learningConsistency.status, data.learningConsistency.isAssessed, theme),
                        ],
                      ),
                    ),

                    if (data.whyThisScore.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () => _showWhyThisScoreDialog(context, data),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 14, color: Colors.indigo),
                            const SizedBox(width: 4),
                            Text(
                              'Why this score? View verified evidence',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.indigo.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator())),
              error: (_, __) => Row(
                children: [
                  const Icon(Icons.insights, color: Colors.indigo, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Not Assessed Yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Complete your first checkpoint quiz to calibrate readiness.', style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Banner: Simulate an Interview with EVA AI
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const EvaAiAvatar(size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Simulate an Interview With EVA AI',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Practice 1-on-1 branching questions for $role',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF38BDF8),
                          foregroundColor: const Color(0xFF0F172A),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        onPressed: () => EvaInterviewRoomView.open(context, roadmapId: roadmapId, targetRole: role),
                        child: const Text('Live Mock', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => _showInterviewPrepSheet(roadmapId, role),
                        child: const Text(
                          'Question Bank',
                          style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, decoration: TextDecoration.underline),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Ask Mentor button
            OutlinedButton.icon(
              icon: const Icon(Icons.supervisor_account, size: 16),
              label: const Text('Ask Faculty Mentor', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(38)),
              onPressed: () => _showAskMentorDialog(roadmapId, role),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDimensionChip(String label, String status, bool isAssessed, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAssessed
            ? Colors.indigo.withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAssessed
              ? Colors.indigo.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
          ),
          Text(
            status,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: isAssessed ? Colors.indigo : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showWhyThisScoreDialog(BuildContext context, JobReadinessModel data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified, color: Colors.indigo, size: 20),
            SizedBox(width: 8),
            Text('Why This Score?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CampusHub calculates readiness strictly from verified evidence — zero fabricated scores:',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 12),
              ...data.whyThisScore.map((reason) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                      Expanded(child: Text(reason, style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                );
              }),
              if (data.topPriorities.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Recommended Immediate Steps:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
                const SizedBox(height: 6),
                ...data.topPriorities.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('➔ ', style: TextStyle(color: Colors.indigo, fontSize: 11)),
                        Expanded(child: Text(p, style: const TextStyle(fontSize: 11.5))),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRoadmapsSection(AsyncValue<List<UserRoadmapItemModel>> roadmapsAsync, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Roadmaps',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.indigo),
              onPressed: _showOnboardingSheet,
              tooltip: 'Create New Roadmap',
            ),
          ],
        ),
        const SizedBox(height: 8),

        roadmapsAsync.when(
          data: (roadmaps) {
            if (roadmaps.isEmpty) {
              return Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text('No saved roadmaps yet. Tap "+ Create AI Roadmap" above to start!'),
                  ),
                ),
              );
            }

            return Column(
              children: roadmaps.map((rm) {
                final percent = rm.progressPercent.clamp(0.0, 1.0);
                Color statusColor = rm.status == 'ACTIVE'
                    ? Colors.green
                    : (rm.status == 'PAUSED' ? Colors.orange : (rm.status == 'COMPLETED' ? Colors.blue : Colors.grey));

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0,
                  color: rm.isActive
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
                      : theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: rm.isActive
                          ? theme.colorScheme.primary.withValues(alpha: 0.4)
                          : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withValues(alpha: 0.15),
                      child: Icon(
                        rm.isActive ? Icons.play_arrow : Icons.timeline,
                        color: statusColor,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            rm.targetRole,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'v${rm.version}.0',
                            style: const TextStyle(color: Colors.indigo, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              rm.level,
                              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•  ${(percent * 100).toStringAsFixed(0)}% Done',
                              style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold),
                            ),
                            if (rm.isActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: percent,
                            minHeight: 4,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (action) async {
                        final repo = ref.read(careerRepositoryProvider);
                        switch (action) {
                          case 'activate':
                            await repo.setActiveRoadmap(rm.id);
                            ref.invalidate(activeUserRoadmapProvider);
                            ref.invalidate(userRoadmapsProvider);
                            break;
                          case 'pause':
                            await repo.updateRoadmap(rm.id, status: rm.status == 'PAUSED' ? 'ACTIVE' : 'PAUSED');
                            ref.invalidate(userRoadmapsProvider);
                            ref.invalidate(activeUserRoadmapProvider);
                            break;
                          case 'complete':
                            await repo.updateRoadmap(rm.id, status: 'COMPLETED');
                            ref.invalidate(userRoadmapsProvider);
                            ref.invalidate(activeUserRoadmapProvider);
                            break;
                          case 'status':
                            _showUpdateStatusDialog(rm.id, rm.status);
                            break;
                          case 'rename':
                            _showRenameRoadmapDialog(rm);
                            break;
                          case 'archive':
                            await repo.updateRoadmap(rm.id, status: 'ARCHIVED');
                            ref.invalidate(userRoadmapsProvider);
                            ref.invalidate(activeUserRoadmapProvider);
                            break;
                          case 'delete':
                            _showDeleteRoadmapDialog(rm);
                            break;
                        }
                      },
                      itemBuilder: (ctx) => [
                        if (!rm.isActive)
                          const PopupMenuItem(value: 'activate', child: Text('Set as Active')),
                        PopupMenuItem(
                          value: 'pause',
                          child: Text(rm.status == 'PAUSED' ? 'Resume Roadmap' : 'Pause Roadmap'),
                        ),
                        if (rm.status != 'COMPLETED')
                          const PopupMenuItem(value: 'complete', child: Text('Mark as Completed')),
                        const PopupMenuItem(value: 'status', child: Text('Change Status...')),
                        const PopupMenuItem(value: 'rename', child: Text('Rename')),
                        const PopupMenuItem(value: 'archive', child: Text('Archive')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                    onTap: () async {
                      if (!rm.isActive) {
                        final repo = ref.read(careerRepositoryProvider);
                        await repo.setActiveRoadmap(rm.id);
                        ref.invalidate(activeUserRoadmapProvider);
                        ref.invalidate(userRoadmapsProvider);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Switched to ${rm.targetRole} (v${rm.version}.0)!')),
                          );
                        }
                      }
                    },
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Error loading roadmaps: $err'),
        ),
      ],
    );
  }

  void _showPhaseQuizDialog(int phaseNumber, String targetRole, String roadmapId) {
    final questions = [
      {
        'q': 'What is the primary difference between synchronous and asynchronous execution in modern runtimes?',
        'options': [
          'Asynchronous execution blocks all background threads until complete.',
          'Asynchronous execution allows non-blocking operations via event loops and callbacks/promises.',
          'Synchronous execution runs faster on all multi-core CPUs.',
          'There is no performance or concurrency difference.',
        ],
      },
      {
        'q': 'Why are Database Indexes (e.g. B-Trees) critical for high-throughput queries?',
        'options': [
          'They compress tables so they fit into RAM permanently.',
          'They eliminate the need for primary keys.',
          'They allow logarithmic O(log N) lookups instead of full table scans O(N).',
          'They encrypt data stored at rest automatically.',
        ],
      },
      {
        'q': 'In the Cache-Aside pattern, what happens when a cache miss occurs?',
        'options': [
          'The application returns an error to the user immediately.',
          'The database updates the cache in the background automatically.',
          'The application reads from the database, writes the result into cache, and returns it.',
          'The cache invalidates all existing records.',
        ],
      },
    ];

    final Map<int, int> selectedAnswers = {};
    bool isSubmitting = false;
    PhaseQuizResult? quizResult;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final theme = Theme.of(ctx);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.quiz, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Phase $phaseNumber Checkpoint Quiz', style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: quizResult == null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Answer the 3 concept questions below to test your understanding for Phase $phaseNumber.',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(questions.length, (qIdx) {
                            final qData = questions[qIdx];
                            final opts = qData['options'] as List<String>;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${qIdx + 1}. ${qData['q']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  ...List.generate(opts.length, (optIdx) {
                                    final isSelected = selectedAnswers[qIdx] == optIdx;
                                    return InkWell(
                                      onTap: () => setDialogState(() => selectedAnswers[qIdx] = optIdx),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                              size: 18,
                                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(opts[optIdx], style: const TextStyle(fontSize: 12)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          }),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: quizResult!.passed ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  quizResult!.passed ? Icons.check_circle : Icons.info,
                                  color: quizResult!.passed ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        quizResult!.passed ? 'Passed! Excellent job.' : 'Needs Review',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: quizResult!.passed ? Colors.green : Colors.orange,
                                        ),
                                      ),
                                      Text(
                                        'Score: ${quizResult!.score} / ${quizResult!.totalQuestions} (${quizResult!.percentage}%)',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text('Review Explanations:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 8),
                          ...quizResult!.feedback.map((fb) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(fb.isCorrect ? Icons.check : Icons.close, size: 16, color: fb.isCorrect ? Colors.green : Colors.red),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(fb.question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(fb.explanation, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                                    ],
                                  ),
                                ),
                              )),
                        ],
                      ),
              ),
            ),
            actions: [
              if (quizResult == null) ...[
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: (selectedAnswers.length == questions.length && !isSubmitting)
                      ? () async {
                          setDialogState(() => isSubmitting = true);
                          try {
                            final repo = ref.read(careerRepositoryProvider);
                            final res = await repo.submitPhaseQuiz(
                              phaseNumber: phaseNumber,
                              role: targetRole,
                              answers: selectedAnswers,
                              roadmapId: roadmapId,
                            );
                            ref.invalidate(activeUserRoadmapProvider);
                            ref.invalidate(skillGapProvider);
                            ref.invalidate(jobReadinessProvider);
                            ref.invalidate(userRoadmapsProvider);
                            ref.invalidate(userCareerProgressProvider);
                            setDialogState(() {
                              quizResult = res;
                              isSubmitting = false;
                            });
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        }
                      : null,
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Submit'),
                ),
              ] else ...[
                FilledButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Done'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // Weekly Goals & Milestones Section in Learn Workspace
  Widget _buildWeeklyGoalsSection(ThemeData theme) {
    final goalsAsync = ref.watch(weeklyGoalsProvider);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.deepOrange.withValues(alpha: 0.15),
                  child: const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weekly Goals & Milestones',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'Paced weekly objectives aligned with your career focus.',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add, size: 18),
                  tooltip: 'Add Goal',
                  onPressed: _showAddGoalDialog,
                ),
              ],
            ),
            const SizedBox(height: 12),
            goalsAsync.when(
              data: (goals) {
                if (goals.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No weekly goals set yet. Tap + to set this week\'s goal.',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  );
                }
                return Column(
                  children: goals.map((goal) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Checkbox(
                            value: goal.isCompleted,
                            activeColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) async {
                              final repo = ref.read(careerRepositoryProvider);
                              await repo.toggleWeeklyGoal(goal.id, val ?? false);
                              ref.invalidate(weeklyGoalsProvider);
                            },
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  goal.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
                                    color: goal.isCompleted
                                        ? theme.colorScheme.outline
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                                if (goal.category.isNotEmpty)
                                  Text(
                                    goal.category,
                                    style: TextStyle(fontSize: 11, color: theme.colorScheme.primary),
                                  ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, size: 16, color: theme.colorScheme.outline),
                            onSelected: (action) {
                              if (action == 'edit') {
                                _showEditGoalDialog(goal);
                              } else if (action == 'delete') {
                                _showDeleteGoalDialog(goal);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 16),
                                    SizedBox(width: 8),
                                    Text('Edit Goal'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 16, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2))),
              error: (err, _) => Text('Error loading goals: $err', style: const TextStyle(fontSize: 12, color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Learning Resources Tab (Verified Books & External Documentation)
  Widget _buildLearningResourcesTab() {
    final theme = Theme.of(context);
    final docsAsync = ref.watch(verifiedDocumentsProvider);
    final roadmapsAsync = ref.watch(careerRoadmapsProvider);

    final roadmaps = roadmapsAsync.valueOrNull ?? [];
    final allResources = roadmaps.expand((r) => r.nodes.expand((n) => n.resources)).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(verifiedDocumentsProvider);
        ref.invalidate(careerRoadmapsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section 1: In-App Verified Technical Books Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0F172A),
                  const Color(0xFF1E293B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_book, color: Color(0xFF38BDF8), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verified Technical Books & Docs',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Offline-ready in-app reader with table of contents, font resizing, dark/sepia themes, and reading progress.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Verified Books List
          docsAsync.when(
            data: (docs) {
              if (docs.isEmpty) {
                return Card(
                  elevation: 0,
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('No verified books available.')),
                  ),
                );
              }

              return Column(
                children: docs.map((doc) => _buildVerifiedDocumentBookCard(doc, theme)).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Card(
              color: Colors.red.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading verified books: $err'),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Curated External Resources
          Row(
            children: [
              Icon(Icons.public, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                'Curated External Tutorials & Practice',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Official reference links, video playlists, and practice problem sets from your roadmaps.',
            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),

          if (allResources.isEmpty)
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.hub_outlined, size: 32, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 8),
                      Text(
                        'Start a personalized roadmap in AI Pathfinder to generate dynamic web tutorials.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...allResources.map((res) {
              IconData typeIcon = Icons.article;
              Color typeColor = Colors.blue;

              if (res.type == 'VIDEO') {
                typeIcon = Icons.play_circle_fill;
                typeColor = Colors.red;
              } else if (res.type == 'PRACTICE') {
                typeIcon = Icons.code;
                typeColor = Colors.green;
              } else if (res.type == 'DOCS') {
                typeIcon = Icons.menu_book;
                typeColor = Colors.orange;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: typeColor.withValues(alpha: 0.15),
                    child: Icon(typeIcon, color: typeColor, size: 20),
                  ),
                  title: Text(
                    res.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: theme.colorScheme.onSurface),
                  ),
                  subtitle: Text(
                    'Type: ${res.type} • ${res.isFree ? 'Free' : 'Premium'}',
                    style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.open_in_new, color: theme.colorScheme.primary, size: 18),
                    tooltip: 'Open link',
                    onPressed: () => UrlLauncherService.openUrl(context, res.url),
                  ),
                  onTap: () => UrlLauncherService.openUrl(context, res.url),
                ),
              );
            }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildVerifiedDocumentBookCard(VerifiedDocumentModel doc, ThemeData theme) {
    Color badgeColor = Colors.blue;
    IconData badgeIcon = Icons.book;
    if (doc.domain == 'C++') {
      badgeColor = Colors.indigo;
      badgeIcon = Icons.memory;
    } else if (doc.domain == 'Python') {
      badgeColor = Colors.amber.shade800;
      badgeIcon = Icons.terminal;
    } else if (doc.domain == 'Flutter') {
      badgeColor = Colors.cyan.shade700;
      badgeIcon = Icons.phone_android;
    } else if (doc.domain == 'Backend') {
      badgeColor = Colors.teal;
      badgeIcon = Icons.dns;
    } else if (doc.domain == 'DSA') {
      badgeColor = Colors.purple;
      badgeIcon = Icons.account_tree;
    } else if (doc.domain == 'System Design') {
      badgeColor = Colors.deepOrange;
      badgeIcon = Icons.cloud;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, size: 13, color: badgeColor),
                      const SizedBox(width: 5),
                      Text(
                        doc.domain,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 11, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'Verified Offline Book',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              doc.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              doc.description,
              style: TextStyle(
                fontSize: 12.5,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            if (doc.tags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: doc.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(fontSize: 10.5, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  '${doc.chapters.length} In-Depth Chapters',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                if (doc.canonicalUrl.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 18),
                    tooltip: 'Official Web Docs',
                    onPressed: () => UrlLauncherService.openUrl(context, doc.canonicalUrl),
                  ),
                const SizedBox(width: 6),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: badgeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.auto_stories, size: 16),
                  label: const Text('Open Reader', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => DocumentReaderView.open(context, document: doc),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 4. Resume Tips Tab (Audited Dark Mode Contrast)
  Widget _buildResumeTipsTab() {
    final theme = Theme.of(context);
    final tipsAsync = ref.watch(resumeTipsProvider);

    return tipsAsync.when(
      data: (tips) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tips.length,
          itemBuilder: (ctx, idx) {
            final tip = tips[idx];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tip.category,
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tip.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tip.content,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                    if (tip.bulletPoints.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...tip.bulletPoints.map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  fontSize: 14,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  b,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading tips: $err')),
    );
  }

  // 5. Placement Prep Tab (Audited Dark Mode + External Link Opening)
  Widget _buildPlacementPrepTab() {
    final theme = Theme.of(context);
    final prepAsync = ref.watch(placementPrepProvider);

    return prepAsync.when(
      data: (modules) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: modules.length,
          itemBuilder: (ctx, idx) {
            final mod = modules[idx];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: ExpansionTile(
                title: Text(
                  mod.title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
                subtitle: Text(
                  'Category: ${mod.category}',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
                trailing: mod.resourceUrl != null && mod.resourceUrl!.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.open_in_new, color: theme.colorScheme.primary, size: 20),
                        tooltip: 'Open preparation resource',
                        onPressed: () => UrlLauncherService.openUrl(context, mod.resourceUrl),
                      )
                    : null,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: mod.contentItems.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Q: ${item['question'] ?? 'Question'}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Approach: ${item['approach'] ?? ''}',
                                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading prep modules: $err')),
    );
  }

  // 6. Mini Projects Tab
  Widget _buildMiniProjectsTab() {
    final theme = Theme.of(context);
    final projectsAsync = ref.watch(miniProjectsProvider);

    return projectsAsync.when(
      data: (projects) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: projects.length,
          itemBuilder: (ctx, idx) {
            final proj = projects[idx];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            proj.title,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                          ),
                        ),
                        Chip(
                          label: Text(proj.difficulty),
                          backgroundColor: proj.difficulty == 'Beginner'
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.orange.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: proj.difficulty == 'Beginner' ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          side: BorderSide.none,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      proj.problemStatement,
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13.5),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: proj.techStack
                          .map(
                            (tech) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tech,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (proj.isSubmitted)
                          const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 20),
                              SizedBox(width: 4),
                              Text('Submitted', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          )
                        else
                          FilledButton.icon(
                            onPressed: () => _showSubmitProjectDialog(proj),
                            icon: const Icon(Icons.upload, size: 16),
                            label: const Text('Submit Solution'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading projects: $err')),
    );
  }
}
