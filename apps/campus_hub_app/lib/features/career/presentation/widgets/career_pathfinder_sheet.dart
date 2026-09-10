import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/career_repository.dart';
import '../../domain/career_models.dart';
import '../providers/career_provider.dart';
import 'eva_ai_avatar.dart';

class CareerPathfinderSheet extends ConsumerStatefulWidget {
  const CareerPathfinderSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CareerPathfinderSheet(),
    );
  }

  @override
  ConsumerState<CareerPathfinderSheet> createState() => _CareerPathfinderSheetState();
}

class _CareerPathfinderSheetState extends ConsumerState<CareerPathfinderSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  String? _conversationId;
  List<String> _suggestedChips = [
    'Flutter & Mobile Apps',
    'Full Stack Web Engineer',
    'Backend Engineer (Node/Postgres)',
    'DevOps & Cloud Architect',
    'AI & Data Systems',
  ];
  Map<String, dynamic>? _profileSummary;
  List<CareerDirectionMatchModel> _careerMatches = [];
  String? _selectedTrack;
  bool _isComplete = false;
  bool _isLoading = false;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _initializeSession() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(careerRepositoryProvider);
      final session = await repo.startPathfinderSession(resumeActive: true);
      if (mounted) {
        setState(() {
          _conversationId = session.conversationId;
          _messages.add({'isUser': false, 'text': session.message});
          if (session.suggestedChips.isNotEmpty) {
            _suggestedChips = session.suggestedChips;
          }
          if (session.profileSummary != null) {
            _profileSummary = session.profileSummary;
          }
          if (session.careerMatches.isNotEmpty) {
            _careerMatches = session.careerMatches;
          }
          _isComplete = session.isComplete;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _messages.add({
            'isUser': false,
            'text':
                "Hello! I am EVA, your personal Career & Learning Architect.\n\nLet's discover the best learning path for you. Which tech role or engineering domain excites you most?",
          });
        });
      }
    }
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'isUser': true, 'text': trimmed});
      _isLoading = true;
      _suggestedChips = [];
    });
    _textController.clear();
    _scrollToBottom();

    try {
      final repo = ref.read(careerRepositoryProvider);
      final response = await repo.pathfinderChat(
        message: trimmed,
        conversationId: _conversationId,
      );

      setState(() {
        _conversationId = response.conversationId;
        _messages.add({'isUser': false, 'text': response.message});
        _suggestedChips = response.suggestedChips;
        if (response.profileSummary != null) {
          _profileSummary = response.profileSummary;
        }
        if (response.careerMatches.isNotEmpty) {
          _careerMatches = response.careerMatches;
        }
        _isComplete = response.isComplete;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add({
          'isUser': false,
          'text':
              "I encountered a connection hiccup. Let's keep going: what is your current coding background or target timeline?",
        });
      });
      _scrollToBottom();
    }
  }

  Future<void> _confirmAndGenerateRoadmap() async {
    if (_conversationId == null || _isConfirming) return;

    setState(() {
      _isConfirming = true;
    });

    try {
      final repo = ref.read(careerRepositoryProvider);
      await repo.confirmPathfinderJourney(
        conversationId: _conversationId!,
        selectedDirection: _selectedTrack,
      );

      // Invalidate career roadmaps so user sees the newly generated roadmap immediately
      ref.invalidate(careerRoadmapsProvider);
      ref.invalidate(userRoadmapsProvider);
      ref.invalidate(activeUserRoadmapProvider);
      ref.invalidate(dailyPlanProvider);
      ref.invalidate(jobReadinessProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Your AI Career Journey & Roadmap is ready!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isConfirming = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm roadmap: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditProfileDialog() {
    if (_profileSummary == null) return;
    int currentHours = (_profileSummary!['daily_hours'] ?? _profileSummary!['dailyHours'] ?? 2) as int;
    String currentLang = (_profileSummary!['preferred_language'] ?? _profileSummary!['preferredLanguage'] ?? 'English').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customize Your Learning Preferences',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text('Daily Learning Commitment:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [1, 2, 3, 4].map((h) {
                      final isSel = currentHours == h;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('$h hr${h > 1 ? 's' : ''}/day'),
                          selected: isSel,
                          onSelected: (_) {
                            setModalState(() => currentHours = h);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Video / Resource Language:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['English', 'Tamil', 'Hindi', 'Malayalam'].map((l) {
                      final isSel = currentLang == l;
                      return ChoiceChip(
                        label: Text(l),
                        selected: isSel,
                        onSelected: (_) {
                          setModalState(() => currentLang = l);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
                      onPressed: () {
                        setState(() {
                          _profileSummary!['daily_hours'] = currentHours;
                          _profileSummary!['dailyHours'] = currentHours;
                          _profileSummary!['preferred_language'] = currentLang;
                          _profileSummary!['preferredLanguage'] = currentLang;
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Save & Update Summary'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalItems = _messages.length +
        (_careerMatches.isNotEmpty ? 1 : 0) +
        (_profileSummary != null ? 1 : 0) +
        (_isLoading ? 1 : 0);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const EvaAiAvatar(size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text(
                            'AI Career Pathfinder',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.auto_awesome, size: 14, color: Colors.cyan),
                        ],
                      ),
                      Text(
                        '1-on-1 conversational discovery with EVA AI',
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
          ),
          const Divider(height: 1),

          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: totalItems,
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  final msg = _messages[index];
                  final isUser = msg['isUser'] as bool;
                  final text = msg['text'] as String;
                  return _buildChatBubble(isUser, text, theme, isDark);
                }

                int offset = _messages.length;
                if (_careerMatches.isNotEmpty && index == offset) {
                  return _buildCareerMatchesCard(theme, isDark);
                }
                if (_careerMatches.isNotEmpty) offset++;

                if (_profileSummary != null && index == offset) {
                  return _buildSummaryCard(theme);
                }
                if (_profileSummary != null) offset++;

                if (_isLoading && index == offset) {
                  return _buildTypingBubble(theme, isDark);
                }

                return const SizedBox.shrink();
              },
            ),
          ),

          // Suggestion Chips
          if (_suggestedChips.isNotEmpty && !_isLoading && !_isComplete) ...[
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestedChips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final chipText = _suggestedChips[i];
                  return ActionChip(
                    label: Text(
                      chipText,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    onPressed: () => _sendMessage(chipText),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Confirm Button if Summary ready
          if (_profileSummary != null || _isComplete) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isConfirming ? null : _confirmAndGenerateRoadmap,
                  icon: _isConfirming
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.rocket_launch, size: 18),
                  label: Text(
                    _isConfirming
                        ? 'Synthesizing Your Learning Path...'
                        : 'Confirm & Generate My Roadmap',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],

          // Text Input Bar
          if (!_isComplete)
            Container(
              padding: EdgeInsets.only(
                left: 14,
                right: 14,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      decoration: InputDecoration(
                        hintText: 'Type your answer or select an option...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
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
                    onPressed: _isLoading ? null : () => _sendMessage(_textController.text),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(bool isUser, String text, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const EvaAiAvatar(size: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? Colors.indigo
                    : (isDark
                        ? const Color(0xFF1E293B)
                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isUser
                      ? Colors.white
                      : (isDark ? Colors.white : theme.colorScheme.onSurface),
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingBubble(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const EvaAiAvatar(size: 28),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B)
                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'EVA is thinking...',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerMatchesCard(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E33) : Colors.indigo.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.stars_rounded, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Text(
                'Personalized Career Track Matches',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._careerMatches.map((match) {
            final isSelected = _selectedTrack == match.role ||
                (_selectedTrack == null &&
                    (_profileSummary?['target_role'] == match.role ||
                        _profileSummary?['targetRole'] == match.role));

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.indigo.withValues(alpha: 0.15)
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.indigo : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          match.role,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: match.matchScore >= 90
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.blue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${match.matchScore}% Match',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: match.matchScore >= 90 ? Colors.green.shade700 : Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    match.rationale,
                    style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  if (match.gaps.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Gaps: ${match.gaps.take(2).join(', ')}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedTrack = match.role;
                          if (_profileSummary != null) {
                            _profileSummary!['target_role'] = match.role;
                            _profileSummary!['targetRole'] = match.role;
                          }
                        });
                      },
                      icon: Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 14,
                        color: isSelected ? Colors.indigo : Colors.grey,
                      ),
                      label: Text(
                        isSelected ? 'Active Selection' : 'Select Track',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.indigo : null,
                        ),
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

  Widget _buildSummaryCard(ThemeData theme) {
    final summary = _profileSummary!;
    final role = _selectedTrack ??
        summary['target_role'] ??
        summary['targetRole'] ??
        'Software Engineer';
    final level = summary['current_level'] ?? summary['experienceLevel'] ?? 'Beginner';
    final hours = summary['daily_hours'] ?? summary['dailyHours'] ?? 2;
    final lang = summary['preferred_language'] ?? summary['preferredLanguage'] ?? 'English';
    final goal = summary['goal'] ?? 'Placement Readiness';

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.withValues(alpha: 0.1),
            Colors.cyan.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.indigo.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, color: Colors.indigo, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Here's What I Understood About You",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: Colors.indigo,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.indigo),
                tooltip: 'Edit Preferences',
                onPressed: _showEditProfileDialog,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _summaryRow(Icons.work_outline, 'Target Track', role.toString()),
          _summaryRow(Icons.timeline, 'Starting Level', level.toString()),
          _summaryRow(Icons.schedule, 'Commitment', '$hours hours/day'),
          _summaryRow(Icons.translate, 'Resource Language', lang.toString()),
          _summaryRow(Icons.flag_outlined, 'Milestone Goal', goal.toString()),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.indigo.shade400),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
