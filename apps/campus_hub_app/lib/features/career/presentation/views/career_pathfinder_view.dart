import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/career_repository.dart';
import '../../domain/career_models.dart';
import 'career_analysis_result_view.dart';

class CareerPathfinderView extends ConsumerStatefulWidget {
  const CareerPathfinderView({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CareerPathfinderView()),
    );
  }

  @override
  ConsumerState<CareerPathfinderView> createState() => _CareerPathfinderViewState();
}

class _CareerPathfinderViewState extends ConsumerState<CareerPathfinderView> {
  DynamicPathfinderSessionModel? _session;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  String? _selectedOption;
  final TextEditingController _customInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  @override
  void dispose() {
    _customInputController.dispose();
    super.dispose();
  }

  Future<void> _initSession() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(careerRepositoryProvider);
      final session = await repo.startPathfinderSessionV2();
      setState(() {
        _session = session;
        _isLoading = false;
      });

      if (session.isCompleted && session.careerAnalysis != null) {
        if (mounted) {
          CareerAnalysisResultView.open(context, analysisData: session.careerAnalysis!);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to connect with AI Pathfinder: $e';
      });
    }
  }

  Future<void> _submitAnswer() async {
    final answerText = _customInputController.text.trim().isNotEmpty
        ? _customInputController.text.trim()
        : _selectedOption;

    if (answerText == null || answerText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an option or type your response.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(careerRepositoryProvider);
      final result = await repo.answerPathfinderQuestionV2(
        sessionId: _session!.id,
        answer: answerText,
      );

      final isCompleted = result['isCompleted'] == true;
      if (isCompleted && result['analysis'] != null) {
        if (mounted) {
          CareerAnalysisResultView.open(
            context,
            analysisData: result['analysis'] as Map<String, dynamic>,
          );
        }
      } else {
        // Refresh session to get next dynamic question
        final updated = await repo.getPathfinderSessionV2(_session!.id);
        setState(() {
          _session = updated;
          _selectedOption = null;
          _customInputController.clear();
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Submission error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          leading: const BackButton(color: Colors.white),
          title: const Text('AI Career Pathfinder', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF6366F1)),
              SizedBox(height: 16),
              Text('Consulting Pathfinder Neural Model...', style: TextStyle(color: Color(0xFF94A3B8))),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null && _session == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          leading: const BackButton(color: Colors.white),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
                const SizedBox(height: 16),
                Text(_errorMessage!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _initSession,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                  child: const Text('Retry Session'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final step = _session?.step ?? 1;
    final totalSteps = _session?.totalSteps ?? 8;
    final progress = (step / totalSteps).clamp(0.0, 1.0);
    final percentInt = (progress * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'AI Career Pathfinder',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        actions: [
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              'Step $step of $totalSteps ($percentInt%)',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF38BDF8)),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF1E293B),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stage indicator
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _session?.stage.replaceAll('_', ' ') ?? 'DISCOVERY',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF818CF8)),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _session?.difficulty ?? 'Adaptive',
                    style: const TextStyle(fontSize: 10, color: Color(0xFFCBD5E1)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Question Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI QUESTION',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _session?.question ?? '',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white, height: 1.35),
                  ),
                  if (_session?.reason.isNotEmpty ?? false) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _session!.reason,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF38BDF8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Options list
            const Text(
              'Select the best fit for your current interests:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 12),
            ...(_session?.options ?? []).map((option) {
              final isSelected = _selectedOption == option;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6366F1).withValues(alpha: 0.15) : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF334155),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: ListTile(
                  onTap: () {
                    setState(() {
                      _selectedOption = option;
                      _customInputController.clear();
                    });
                  },
                  leading: Radio<String>(
                    value: option,
                    // ignore: deprecated_member_use
                    groupValue: _selectedOption,
                    activeColor: const Color(0xFF6366F1),
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      setState(() {
                        _selectedOption = val;
                        _customInputController.clear();
                      });
                    },
                  ),
                  title: Text(
                    option,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 14),

            // Custom Text Box
            TextField(
              controller: _customInputController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Or describe in your own words (e.g. "I want to build robotics sensors with C++")...',
                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                ),
              ),
              onChanged: (_) {
                if (_selectedOption != null) {
                  setState(() => _selectedOption = null);
                }
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
            ],
            const SizedBox(height: 28),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            step >= totalSteps ? 'Generate Final Analysis' : 'Next Step',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
