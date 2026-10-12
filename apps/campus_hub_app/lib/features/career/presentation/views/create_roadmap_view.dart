import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/campus_back_button.dart';
import '../../../../core/widgets/campus_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../theme/career_theme.dart';
import '../widgets/career_shared_widgets.dart';
import 'roadmap_generating_view.dart';

class CreateRoadmapView extends ConsumerStatefulWidget {
  final String? initialTrack;

  const CreateRoadmapView({
    super.key,
    this.initialTrack,
  });

  static void open(BuildContext context, {String? initialTrack}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateRoadmapView(initialTrack: initialTrack),
      ),
    );
  }

  @override
  ConsumerState<CreateRoadmapView> createState() => _CreateRoadmapViewState();
}

class _CreateRoadmapViewState extends ConsumerState<CreateRoadmapView> {
  late TextEditingController _goalController;
  double _timeframeWeeks = 8;
  String _selectedLevel = 'Intermediate';

  // Additional Preferences
  String _selectedDepartment = 'Computer Science & Engineering';
  String _selectedFocus = 'Practical + Projects';
  String _selectedLanguage = 'English';
  bool _showPreferences = true;

  final List<String> _quickSuggestions = [
    'Full Stack Developer',
    'AI & Data Scientist',
    'Cloud Architect (AWS)',
    'Embedded & IoT Engineer',
    'Cybersecurity Analyst',
  ];

  final List<String> _departments = [
    'Computer Science & Engineering',
    'Information Technology',
    'Artificial Intelligence & Data Science',
    'Electronics & Communication Engineering',
    'Electrical & Electronics Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Automobile Engineering',
  ];

  final List<String> _focusOptions = [
    'Practical + Projects',
    'Theory & Foundations',
    'Placement & Interview Prep',
    'Balanced Learning',
  ];

  final List<String> _languages = ['English', 'Tamil', 'Hindi'];

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController(text: widget.initialTrack ?? '');
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  void _onGeneratePressed() {
    final goal = _goalController.text.trim();
    if (goal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify what you want to learn.'),
          backgroundColor: CareerTheme.error,
        ),
      );
      return;
    }

    RoadmapGeneratingView.open(
      context,
      targetRole: goal,
      timeframeWeeks: _timeframeWeeks.round(),
      level: _selectedLevel,
      department: _selectedDepartment,
      learningFocus: _selectedFocus,
      preferredLanguage: _selectedLanguage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : AppColors.primaryText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CampusAppBar(
        title: 'Create Your Roadmap',
        leading: CampusBackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtitle
              Text(
                "Tell us your goal and we'll create a personalized learning path.",
                style: TextStyle(fontSize: 13, color: secondaryTextColor, height: 1.4),
              ),
              const SizedBox(height: 24),

              // 1. WHAT DO YOU WANT TO LEARN?
              Text(
                'What do you want to learn?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primaryTextColor),
              ),
              const SizedBox(height: 10),
              CareerGlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                borderRadius: CareerTheme.radiusMedium,
                child: TextField(
                  controller: _goalController,
                  style: TextStyle(color: primaryTextColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Full Stack Developer, Data Scientist',
                    hintStyle: TextStyle(color: secondaryTextColor, fontSize: 13),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Quick Suggestions Pills
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickSuggestions.map((suggestion) {
                  return GestureDetector(
                    onTap: () => setState(() => _goalController.text = suggestion),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSecondary : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(CareerTheme.radiusSmall),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        suggestion,
                        style: TextStyle(fontSize: 11, color: primaryTextColor),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // 2. TIMEFRAME SLIDER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Timeframe',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primaryTextColor),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSecondary : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      '${_timeframeWeeks.round()} weeks',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CareerGlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                borderRadius: CareerTheme.radiusMedium,
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: isDark ? Colors.white : AppColors.pureBlack,
                        inactiveTrackColor: isDark ? AppColors.darkElevatedSurface : const Color(0xFFE2E8F0),
                        thumbColor: isDark ? Colors.white : AppColors.pureBlack,
                        overlayColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _timeframeWeeks,
                        min: 1,
                        max: 24,
                        divisions: 23,
                        onChanged: (val) => setState(() => _timeframeWeeks = val),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('1 week', style: TextStyle(fontSize: 11, color: secondaryTextColor)),
                          Text('24 weeks', style: TextStyle(fontSize: 11, color: secondaryTextColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 3. YOUR CURRENT LEVEL
              Text(
                'Your current level',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primaryTextColor),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CareerPill(
                      text: 'Beginner',
                      isSelected: _selectedLevel == 'Beginner',
                      onTap: () => setState(() => _selectedLevel = 'Beginner'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CareerPill(
                      text: 'Intermediate',
                      isSelected: _selectedLevel == 'Intermediate',
                      onTap: () => setState(() => _selectedLevel = 'Intermediate'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CareerPill(
                      text: 'Advanced',
                      isSelected: _selectedLevel == 'Advanced',
                      onTap: () => setState(() => _selectedLevel = 'Advanced'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 4. ADDITIONAL PREFERENCES (OPTIONAL)
              GestureDetector(
                onTap: () => setState(() => _showPreferences = !_showPreferences),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Additional preferences (optional)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primaryTextColor),
                    ),
                    Icon(
                      _showPreferences ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: secondaryTextColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (_showPreferences) ...[
                CareerGlassCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: CareerTheme.radiusMedium,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Department
                      Text('Your Department', style: TextStyle(fontSize: 11, color: secondaryTextColor)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedDepartment,
                        dropdownColor: isDark ? AppColors.darkElevatedSurface : Colors.white,
                        style: TextStyle(fontSize: 13, color: primaryTextColor),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: borderColor),
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: borderColor),
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                          ),
                        ),
                        items: _departments.map((d) {
                          return DropdownMenuItem(
                            value: d,
                            child: Text(d, overflow: TextOverflow.ellipsis, maxLines: 1),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedDepartment = val!),
                      ),
                      const SizedBox(height: 14),

                      // Learning Focus
                      Text('Learning Focus', style: TextStyle(fontSize: 11, color: secondaryTextColor)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedFocus,
                        dropdownColor: isDark ? AppColors.darkElevatedSurface : Colors.white,
                        style: TextStyle(fontSize: 13, color: primaryTextColor),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: borderColor),
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: borderColor),
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                          ),
                        ),
                        items: _focusOptions.map((f) {
                          return DropdownMenuItem(
                            value: f,
                            child: Text(f, overflow: TextOverflow.ellipsis, maxLines: 1),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedFocus = val!),
                      ),
                      const SizedBox(height: 14),

                      // Preferred Language
                      Text('Preferred Language', style: TextStyle(fontSize: 11, color: secondaryTextColor)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedLanguage,
                        dropdownColor: isDark ? AppColors.darkElevatedSurface : Colors.white,
                        style: TextStyle(fontSize: 13, color: primaryTextColor),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: borderColor),
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: borderColor),
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                          ),
                        ),
                        items: _languages.map((l) {
                          return DropdownMenuItem(
                            value: l,
                            child: Text(l, overflow: TextOverflow.ellipsis, maxLines: 1),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedLanguage = val!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // 5. GENERATE BUTTON
              CareerPrimaryButton(
                label: 'Generate My Roadmap →',
                onPressed: _onGeneratePressed,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
