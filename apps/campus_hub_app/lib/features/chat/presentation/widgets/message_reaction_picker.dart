import 'package:flutter/material.dart';

class MessageReactionPicker extends StatefulWidget {
  final List<String> currentSelectedEmojis;
  final ValueChanged<String> onSelectEmoji;

  const MessageReactionPicker({
    super.key,
    this.currentSelectedEmojis = const [],
    required this.onSelectEmoji,
  });

  static const List<String> availableEmojis = ['❤️', '😂', '😮', '😢', '👍', '👎'];

  @override
  State<MessageReactionPicker> createState() => _MessageReactionPickerState();
}

class _MessageReactionPickerState extends State<MessageReactionPicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  String? _tappedEmoji;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black12,
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: MessageReactionPicker.availableEmojis.map((emoji) {
              final isSelected = widget.currentSelectedEmojis.contains(emoji);
              final isBeingTapped = _tappedEmoji == emoji;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _tappedEmoji = emoji;
                  });
                  Future.delayed(const Duration(milliseconds: 150), () {
                    if (mounted) {
                      widget.onSelectEmoji(emoji);
                    }
                  });
                },
                child: AnimatedScale(
                  scale: isBeingTapped ? 1.35 : (isSelected ? 1.15 : 1.0),
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutBack,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(6),
                    decoration: isSelected
                        ? BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          )
                        : null,
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
