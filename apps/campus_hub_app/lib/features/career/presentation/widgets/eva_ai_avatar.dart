import 'package:flutter/material.dart';

class EvaAiAvatar extends StatefulWidget {
  final double size;
  final bool isPulsing;

  const EvaAiAvatar({
    super.key,
    this.size = 64,
    this.isPulsing = false,
  });

  @override
  State<EvaAiAvatar> createState() => _EvaAiAvatarState();
}

class _EvaAiAvatarState extends State<EvaAiAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant EvaAiAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 0.8;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final glowOpacity = widget.isPulsing ? _glowAnimation.value : 0.8;

        return Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFE0E7FF),
                Color(0xFFC7D2FE),
              ],
              stops: [0.3, 0.7, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.35 * glowOpacity),
                blurRadius: s * 0.35,
                spreadRadius: s * 0.08,
              ),
              BoxShadow(
                color: const Color(0xFF06B6D4).withValues(alpha: 0.25 * glowOpacity),
                blurRadius: s * 0.2,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(
              color: Colors.white,
              width: s * 0.04,
            ),
          ),
          child: Center(
            child: Container(
              width: s * 0.72,
              height: s * 0.52,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(s * 0.28),
                border: Border.all(
                  color: const Color(0xFF818CF8).withValues(alpha: 0.6),
                  width: s * 0.025,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.5 * glowOpacity),
                    blurRadius: s * 0.1,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Left glowing eye
                  Container(
                    width: s * 0.16,
                    height: s * 0.22,
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8),
                      borderRadius: BorderRadius.circular(s * 0.08),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withValues(alpha: glowOpacity),
                          blurRadius: s * 0.08,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  // Right glowing eye
                  Container(
                    width: s * 0.16,
                    height: s * 0.22,
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8),
                      borderRadius: BorderRadius.circular(s * 0.08),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withValues(alpha: glowOpacity),
                          blurRadius: s * 0.08,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
