import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/career_repository.dart';
import '../../domain/career_models.dart';
import 'eva_ai_avatar.dart';

class AskAiDoubtSheet extends ConsumerStatefulWidget {
  final String? roadmapId;
  final String? targetRole;

  const AskAiDoubtSheet({
    super.key,
    this.roadmapId,
    this.targetRole,
  });

  static Future<void> show(
    BuildContext context, {
    String? roadmapId,
    String? targetRole,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AskAiDoubtSheet(
        roadmapId: roadmapId,
        targetRole: targetRole,
      ),
    );
  }

  @override
  ConsumerState<AskAiDoubtSheet> createState() => _AskAiDoubtSheetState();
}

class _AskAiDoubtSheetState extends ConsumerState<AskAiDoubtSheet> {
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = false;
  AskAiResponseModel? _response;
  String? _errorMessage;

  final List<String> _quickDoubts = [
    'Explain Async/Await vs Streams in simple terms',
    'How do I model one-to-many relations in PostgreSQL?',
    'What is the difference between StateNotifier and Riverpod Generator?',
    'How can I optimize slow database queries?',
    'What should I build for my Phase 1 capstone project?',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _askDoubt(String prompt) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(careerRepositoryProvider);
      final res = await repo.askAiDoubt(
        prompt: trimmed,
        roadmapId: widget.roadmapId,
      );

      setState(() {
        _response = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not reach EVA AI. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Sheet Header
          Row(
            children: [
              const EvaAiAvatar(size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ask EVA AI — Doubt Solver',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      widget.targetRole != null
                          ? 'Tailored to your ${widget.targetRole} curriculum'
                          : 'Context-aware guidance for your active roadmap',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 20),

          // Scrollable content area: quick chips or AI answer
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_response == null && !_isLoading && _errorMessage == null) ...[
                    const Text(
                      'Suggested Questions:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ..._quickDoubts.map((doubt) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            _promptController.text = doubt;
                            _askDoubt(doubt);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.help_outline,
                                    size: 16, color: Colors.indigo),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    doubt,
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios,
                                    size: 12, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],

                  if (_isLoading) ...[
                    const SizedBox(height: 40),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 14),
                          Text(
                            'EVA AI is analyzing your doubt & curriculum context...',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_response != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.indigo.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.indigo.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.auto_awesome,
                                      size: 16, color: Colors.indigo),
                                  SizedBox(width: 6),
                                  Text(
                                    'EVA Response',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                ],
                              ),
                              if (_response!.intent != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _response!.intent!.replaceAll('_', ' '),
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _response!.answer,
                            style: const TextStyle(fontSize: 13, height: 1.45),
                          ),
                          if (_response!.suggestedActions.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            const Text(
                              'Suggested Actions:',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ..._response!.suggestedActions.map((action) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('→ ',
                                        style: TextStyle(
                                            color: Colors.indigo,
                                            fontWeight: FontWeight.bold)),
                                    Expanded(
                                      child: Text(
                                        action,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _response = null;
                          _promptController.clear();
                        });
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Ask Another Question'),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Input Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promptController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _askDoubt,
                  decoration: InputDecoration(
                    hintText: 'Ask any technical or roadmap doubt...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: Colors.indigo,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isLoading
                    ? null
                    : () => _askDoubt(_promptController.text),
                icon: const Icon(Icons.send_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
