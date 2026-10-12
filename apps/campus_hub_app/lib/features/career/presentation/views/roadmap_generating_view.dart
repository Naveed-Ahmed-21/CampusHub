import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/career_repository.dart';
import '../providers/career_provider.dart';
import '../theme/career_theme.dart';
import '../widgets/career_shared_widgets.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import 'career_roadmap_view.dart';

class RoadmapGeneratingView extends ConsumerStatefulWidget {
  final String targetRole;
  final int timeframeWeeks;
  final String level;
  final String department;
  final String learningFocus;
  final String preferredLanguage;

  const RoadmapGeneratingView({
    super.key,
    required this.targetRole,
    this.timeframeWeeks = 8,
    this.level = 'Intermediate',
    this.department = 'Computer Science & Engineering',
    this.learningFocus = 'Practical + Projects',
    this.preferredLanguage = 'English',
  });

  static void open(
    BuildContext context, {
    required String targetRole,
    int timeframeWeeks = 8,
    String level = 'Intermediate',
    String department = 'Computer Science & Engineering',
    String learningFocus = 'Practical + Projects',
    String preferredLanguage = 'English',
  }) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RoadmapGeneratingView(
          targetRole: targetRole,
          timeframeWeeks: timeframeWeeks,
          level: level,
          department: department,
          learningFocus: learningFocus,
          preferredLanguage: preferredLanguage,
        ),
      ),
    );
  }

  @override
  ConsumerState<RoadmapGeneratingView> createState() => _RoadmapGeneratingViewState();
}

class _RoadmapGeneratingViewState extends ConsumerState<RoadmapGeneratingView> {
  int _currentStepIndex = 0;
  double _progressPercentage = 15.0;
  Timer? _stepTimer;
  String? _errorMessage;
  bool _isFinished = false;

  final List<String> _generationSteps = [
    'Understanding your goal',
    'Analyzing required skills',
    'Finding best learning resources',
    'Creating milestone structure',
    'Fetching YouTube videos',
    'Adding documentation',
    'Finalizing your roadmap',
  ];

  @override
  void initState() {
    super.initState();
    _startSimulatedSteps();
    _executeGeneration();
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  void _startSimulatedSteps() {
    // Advance progress smoothly while the real AI backend executes
    _stepTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (_currentStepIndex < _generationSteps.length - 2 && !_isFinished) {
        setState(() {
          _currentStepIndex++;
          _progressPercentage = (_currentStepIndex / _generationSteps.length) * 100;
        });
      }
    });
  }

  Future<void> _executeGeneration() async {
    try {
      final repo = ref.read(careerRepositoryProvider);
      final roadmap = await repo.generatePersonalizedRoadmap(
        targetRole: widget.targetRole,
        timelineWeeks: widget.timeframeWeeks,
        hoursPerWeek: 10,
        primaryGoal: '${widget.learningFocus} in ${widget.targetRole}',
      );

      _stepTimer?.cancel();

      setState(() {
        _currentStepIndex = _generationSteps.length - 1;
        _progressPercentage = 100.0;
        _isFinished = true;
      });

      ref.invalidate(activeUserRoadmapProvider);
      ref.invalidate(userRoadmapsProvider);

      await Future.delayed(const Duration(milliseconds: 900));

      if (mounted) {
        CareerRoadmapView.open(context, roadmapId: roadmap.id);
      }
    } catch (e) {
      _stepTimer?.cancel();
      setState(() {
        _errorMessage = 'Failed to construct curriculum: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : AppColors.primaryText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CampusAppBar(
        title: 'Building Your Roadmap',
        leading: CampusBackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title & Subtitle
              Text(
                'Building Your Roadmap',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: primaryTextColor,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Our AI is analyzing your goals and creating a personalized curriculum...',
                style: TextStyle(fontSize: 13, color: secondaryTextColor, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Glowing AI Orb
              const Center(
                child: CareerAIOrb(
                  size: 130,
                  showText: true,
                  text: 'AI',
                ),
              ),
              const SizedBox(height: 36),

              // Checklist Cards
              if (_errorMessage != null)
                CareerGlassCard(
                  padding: const EdgeInsets.all(16),
                  borderColor: AppColors.error.withValues(alpha: 0.4),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 36),
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        style: TextStyle(fontSize: 13, color: secondaryTextColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      CareerPrimaryButton(
                        label: 'Retry Generation',
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                            _currentStepIndex = 0;
                            _progressPercentage = 15.0;
                          });
                          _startSimulatedSteps();
                          _executeGeneration();
                        },
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: List.generate(_generationSteps.length, (idx) {
                    final title = _generationSteps[idx];
                    final isDone = idx < _currentStepIndex || _isFinished;
                    final isCurrent = idx == _currentStepIndex && !_isFinished;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          if (isDone)
                            Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, size: 14, color: Colors.white),
                            )
                          else if (isCurrent)
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: isDark ? Colors.white : AppColors.pureBlack,
                              ),
                            )
                          else
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                color: isDone
                                    ? primaryTextColor
                                    : (isCurrent ? primaryTextColor : secondaryTextColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              const SizedBox(height: 24),

              // Progress Bar with Percentage
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondaryTextColor),
                  ),
                  Text(
                    '${_progressPercentage.round()}%',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: primaryTextColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progressPercentage / 100.0,
                  minHeight: 8,
                  backgroundColor: isDark ? AppColors.darkElevatedSurface : const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.white : AppColors.pureBlack,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Lightbulb Info Box
              CareerGlassCard(
                padding: const EdgeInsets.all(14),
                borderRadius: CareerTheme.radiusMedium,
                backgroundColor: isDark ? AppColors.darkElevatedSurface.withValues(alpha: 0.6) : const Color(0xFFF7F9F9),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'This usually takes 20-40 seconds',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primaryTextColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "We're searching real-time resources from YouTube and trusted documentation.",
                            style: TextStyle(fontSize: 11, color: secondaryTextColor, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
