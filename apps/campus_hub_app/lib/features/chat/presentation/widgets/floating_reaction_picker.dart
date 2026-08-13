import 'package:flutter/material.dart';

class FloatingReactionPicker extends StatefulWidget {
  final ValueChanged<String> onSelected;

  const FloatingReactionPicker({
    super.key,
    required this.onSelected,
  });

  @override
  State<FloatingReactionPicker> createState() => _FloatingReactionPickerState();
}

class _FloatingReactionPickerState extends State<FloatingReactionPicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  final List<String> emojis = const ["👍", "❤️", "😂", "😮", "😢", "🙏"];
  int hoveredIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildEmoji(String emoji, int index) {
    final isSelected = hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => hoveredIndex = index),
      onExit: (_) => setState(() => hoveredIndex = -1),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onSelected(emoji),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: isSelected ? 1.35 : 1.0,
          curve: Curves.easeOut,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 26),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 8),
              color: Colors.black.withValues(alpha: 0.2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            emojis.length,
            (index) => _buildEmoji(emojis[index], index),
          ),
        ),
      ),
    );
  }
}
