import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/career_repository.dart';
import '../providers/career_provider.dart';
import 'eva_ai_avatar.dart';

class EvaAiOnboardingSheet extends ConsumerStatefulWidget {
  final VoidCallback? onRoadmapReady;

  const EvaAiOnboardingSheet({
    super.key,
    this.onRoadmapReady,
  });

  @override
  ConsumerState<EvaAiOnboardingSheet> createState() => _EvaAiOnboardingSheetState();
}

class _EvaAiOnboardingSheetState extends ConsumerState<EvaAiOnboardingSheet> {
  int _step = 0; // 0: Role, 1: Level, 2: Weekly Hours, 3: Goal, 4: Generating
  final TextEditingController _customRoleController = TextEditingController();

  String _selectedRole = '';
  String _selectedLevel = 'Beginner';
  String _selectedLevelDisplay = 'Beginner / Zero';
  int _selectedHours = 10;
  String _selectedGoal = 'Campus Placements & Interviews';
  bool _isPlacementFocused = true;

  // Staged generation steps
  int _generationStage = 0;
  final List<String> _stages = [
    'Understanding your career goal...',
    'Analyzing current technical skills...',
    'Detecting skill gaps & dependencies...',
    'Structuring milestone phases & timeline...',
    'Selecting real-world practical projects...',
    "Generating today's personalized learning plan...",
  ];

  @override
  void dispose() {
    _customRoleController.dispose();
    super.dispose();
  }

  void _onSelectRole(String role) {
    setState(() {
      _selectedRole = role;
      _step = 1;
    });
  }

  void _onSelectLevel(String levelKey, String levelTitle) {
    setState(() {
      _selectedLevel = levelKey;
      _selectedLevelDisplay = levelTitle;
      _step = 2;
    });
  }

  void _onSelectHours(int hours) {
    setState(() {
      _selectedHours = hours;
      _step = 3;
    });
  }

  void _onSelectGoal(String goal, bool isPlacement) {
    setState(() {
      _selectedGoal = goal;
      _isPlacementFocused = isPlacement;
    });
    _startDuplicateCheckAndGeneration();
  }

  Future<void> _startDuplicateCheckAndGeneration({bool forceNewVersion = false}) async {
    final repo = ref.read(careerRepositoryProvider);

    if (!forceNewVersion) {
      try {
        final dupCheck = await repo.checkDuplicate(_selectedRole);
        if (dupCheck.hasExisting && dupCheck.existingRoadmap != null && mounted) {
          final existing = dupCheck.existingRoadmap!;
          final existingId = existing['id']?.toString() ?? '';
          final existingTargetRole = existing['target_role']?.toString() ?? existing['targetRole']?.toString() ?? _selectedRole;
          final existingVersion = (existing['version'] as num?)?.toInt() ?? 1;

          final shouldCreateNew = await _showDuplicateDialog(
            targetRole: existingTargetRole,
            version: existingVersion,
            existingId: existingId,
          );

          if (shouldCreateNew == null) return; // user cancelled
          if (!shouldCreateNew) {
            // User chose Continue Existing
            if (existingId.isNotEmpty) {
              await repo.setActiveRoadmap(existingId);
            }
            _refreshProviders();
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Switched to existing $_selectedRole roadmap!'),
                  backgroundColor: Colors.blue,
                ),
              );
            }
            return;
          }
        }
      } catch (_) {
        // If check duplicate fails for any reason, continue with generation
      }
    }

    // Proceed to Generation with Staged Progress Animation
    if (!mounted) return;
    setState(() {
      _step = 4;
      _generationStage = 0;
    });

    // Run staged timer
    Timer? stageTimer;
    stageTimer = Timer.periodic(const Duration(milliseconds: 650), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_generationStage < _stages.length - 1) {
        setState(() => _generationStage++);
      } else {
        timer.cancel();
      }
    });

    try {
      await repo.generateOrActivateRoadmap(
        role: _selectedRole,
        level: _selectedLevel,
        weeklyHours: _selectedHours,
        goal: _selectedGoal,
        isPlacementFocused: _isPlacementFocused,
        createNewVersion: forceNewVersion,
      );

      stageTimer.cancel();
      if (mounted) setState(() => _generationStage = _stages.length);

      await Future.delayed(const Duration(milliseconds: 400));
      _refreshProviders();

      if (mounted) {
        Navigator.pop(context);
        widget.onRoadmapReady?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Personalized AI roadmap generated for $_selectedRole! 🚀'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      stageTimer.cancel();
      if (mounted) {
        setState(() => _step = 3);
        String msg = e.toString();
        if (e is DioException) {
          msg = e.response?.data?['message']?.toString() ?? e.message ?? msg;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generation failed: $msg'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool?> _showDuplicateDialog({
    required String targetRole,
    required int version,
    required String existingId,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.indigo),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Existing Roadmap Found',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'You already have an active $targetRole roadmap (v$version.0).\n\nWould you like to continue your existing progress or generate a new customized version (v${version + 1}.0)?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false), // Continue Existing
            child: const Text('Continue Existing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true), // Create New Version
            child: const Text('Create New Version'),
          ),
        ],
      ),
    );
  }

  void _refreshProviders() {
    ref.invalidate(activeUserRoadmapProvider);
    ref.invalidate(userRoadmapsProvider);
    ref.invalidate(userCareerProgressProvider);
    ref.invalidate(dailyPlanProvider);
    ref.invalidate(skillGapProvider);
    ref.invalidate(skillMapProvider);
    ref.invalidate(weeklyReviewProvider);
    ref.invalidate(jobReadinessProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // EVA Avatar & Header
          Center(
            child: EvaAiAvatar(
              size: _step == 4 ? 76 : 60,
              isPulsing: _step == 4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _step == 4 ? 'EVA is crafting your roadmap...' : 'EVA AI Career Architect',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(
            _step == 4
                ? 'Synthesizing verified industry milestones & projects'
                : 'Adaptive AI Onboarding • Step ${_step + 1} of 4',
            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Content body based on step
          Flexible(
            child: SingleChildScrollView(
              child: _buildStepContent(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(ThemeData theme) {
    switch (_step) {
      case 0:
        return _buildRoleStep(theme);
      case 1:
        return _buildLevelStep(theme);
      case 2:
        return _buildHoursStep(theme);
      case 3:
        return _buildGoalStep(theme);
      case 4:
        return _buildGeneratingStep(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRoleStep(ThemeData theme) {
    final roles = [
      {'title': 'Full-Stack Web Engineering', 'icon': Icons.web, 'tag': 'React, Node, SQL'},
      {'title': 'Mobile App Engineering (Flutter)', 'icon': Icons.phone_android, 'tag': 'Flutter, Dart, Clean Arch'},
      {'title': 'Backend & Cloud Systems', 'icon': Icons.dns, 'tag': 'APIs, Microservices, Docker'},
      {'title': 'AI & Machine Learning Engineering', 'icon': Icons.psychology, 'tag': 'Python, PyTorch, LLMs'},
      {'title': 'Cloud DevOps & Infrastructure', 'icon': Icons.cloud, 'tag': 'AWS, Kubernetes, CI/CD'},
      {'title': 'Cybersecurity & Ethical Hacking', 'icon': Icons.security, 'tag': 'Networking, Pentesting, SIEM'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEvaBubble(
          'Hey there! 👋 What engineering role would you like to master?',
          theme,
        ),
        const SizedBox(height: 16),
        ...roles.map((r) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _onSelectRole(r['title'] as String),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(r['icon'] as IconData, size: 22, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(r['tag'] as String, style: TextStyle(fontSize: 11, color: theme.colorScheme.outline)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        // Custom Role input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customRoleController,
                decoration: InputDecoration(
                  hintText: 'Or type custom role (e.g. Data Analyst)...',
                  hintStyle: const TextStyle(fontSize: 13),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) _onSelectRole(val.trim());
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.arrow_forward, size: 18),
              onPressed: () {
                final val = _customRoleController.text.trim();
                if (val.isNotEmpty) _onSelectRole(val);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLevelStep(ThemeData theme) {
    final levels = [
      {
        'title': 'Beginner / Zero',
        'key': 'Beginner',
        'desc': 'Starting from absolute scratch. Need foundational concepts and guided syntax.',
      },
      {
        'title': 'Basic Syntax',
        'key': 'Beginner',
        'desc': 'Understand variables, loops, conditionals, and functions in at least one language.',
      },
      {
        'title': 'Intermediate / Builder',
        'key': 'Intermediate',
        'desc': 'Have completed 1-2 small projects independently, comfortable with basic Git and APIs.',
      },
      {
        'title': 'Advanced / Production',
        'key': 'Expert',
        'desc': 'Have industry/internship experience, looking for high-scale system design and interview prep.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUserBubble(_selectedRole, theme),
        const SizedBox(height: 12),
        _buildEvaBubble(
          'Targeting $_selectedRole! What is your current hands-on coding experience level?',
          theme,
        ),
        const SizedBox(height: 16),
        ...levels.map((lvl) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _onSelectLevel(lvl['key']!, lvl['title']!),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lvl['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(lvl['desc']!, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHoursStep(ThemeData theme) {
    final hourOptions = [
      {'hours': 5, 'label': '5 hrs / week', 'desc': 'Light pace (~45 mins / day). Great for busy exam weeks.'},
      {'hours': 10, 'label': '10 hrs / week', 'desc': 'Recommended (~1.5 hrs / day). Ideal balance of depth and velocity.'},
      {'hours': 15, 'label': '15+ hrs / week', 'desc': 'Intensive (~2+ hrs / day). Fast-track for upcoming placement drives.'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUserBubble(_selectedLevelDisplay, theme),
        const SizedBox(height: 12),
        _buildEvaBubble(
          'How many hours per week can you realistically commit to learning?',
          theme,
        ),
        const SizedBox(height: 16),
        ...hourOptions.map((opt) {
          final h = opt['hours'] as int;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _onSelectHours(h),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: Colors.indigo, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(opt['label'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(opt['desc'] as String, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGoalStep(ThemeData theme) {
    final goals = [
      {
        'title': 'Campus Placements & Tech Interviews',
        'desc': 'Optimized for campus placement drives, technical MCQs, live coding, and behavioral interviews.',
        'placement': true,
      },
      {
        'title': 'Build Portfolio Projects',
        'desc': 'Focuses on production-grade GitHub repositories, full-stack deployment, and portfolio showcase.',
        'placement': false,
      },
      {
        'title': 'Master Deep Engineering Fundamentals',
        'desc': 'Prioritizes distributed architectures, database internals, and performance optimization.',
        'placement': false,
      },
      {
        'title': 'Crack Top Product Companies (FAANG)',
        'desc': 'Includes advanced data structures, system design checklists, and competitive problem solving.',
        'placement': true,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUserBubble('$_selectedHours hrs / week committed', theme),
        const SizedBox(height: 12),
        _buildEvaBubble(
          'Almost done! What is your primary milestone right now?',
          theme,
        ),
        const SizedBox(height: 16),
        ...goals.map((g) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _onSelectGoal(g['title'] as String, g['placement'] as bool),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.track_changes, color: Colors.indigo, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(g['desc'] as String, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGeneratingStep(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.indigo),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Synthesizing curriculum for $_selectedRole...',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(_stages.length, (idx) {
            final isDone = idx < _generationStage;
            final isCurrent = idx == _generationStage;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? Colors.green
                          : (isCurrent ? Colors.indigo : theme.colorScheme.surfaceContainerHighest),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : (isCurrent
                              ? const SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(strokeWidth: 1.8, color: Colors.white),
                                )
                              : Text('${idx + 1}', style: const TextStyle(fontSize: 10, color: Colors.grey))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _stages[idx],
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isDone
                            ? theme.colorScheme.onSurface
                            : (isCurrent ? Colors.indigo : theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEvaBubble(String text, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13.5, height: 1.4),
      ),
    );
  }

  Widget _buildUserBubble(String text, ThemeData theme) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
