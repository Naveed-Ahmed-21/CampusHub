import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/career_theme.dart';

// ==========================================
// 1. CAREER GLASS CARD
// ==========================================
class CareerGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? borderColor;
  final Gradient? gradient;
  final Color? backgroundColor;

  const CareerGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.onTap,
    this.borderRadius = CareerTheme.radiusLarge,
    this.borderColor,
    this.gradient,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? (gradient == null ? CareerTheme.surface : null),
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? CareerTheme.glassBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: CareerTheme.primaryCyan.withValues(alpha: 0.1),
          highlightColor: CareerTheme.accentIndigo.withValues(alpha: 0.05),
          child: content,
        ),
      );
    }

    return content;
  }
}

// ==========================================
// 2. CAREER AI ORB (Pulsating & Rotating Concentric Rings)
// ==========================================
class CareerAIOrb extends StatefulWidget {
  final double size;
  final bool showText;
  final String text;

  const CareerAIOrb({
    super.key,
    this.size = 80.0,
    this.showText = true,
    this.text = 'AI',
  });

  @override
  State<CareerAIOrb> createState() => _CareerAIOrbState();
}

class _CareerAIOrbState extends State<CareerAIOrb> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _rotationController]),
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Ambient Glow
              Container(
                width: widget.size * _pulseAnimation.value,
                height: widget.size * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: CareerTheme.primaryCyan.withValues(alpha: 0.25),
                      blurRadius: widget.size * 0.35,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: CareerTheme.accentIndigo.withValues(alpha: 0.3),
                      blurRadius: widget.size * 0.5,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),

              // Rotating Concentric Dash Ring 1
              Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: CustomPaint(
                  size: Size(widget.size * 0.95, widget.size * 0.95),
                  painter: _DashedRingPainter(
                    color: CareerTheme.primaryCyan.withValues(alpha: 0.6),
                    strokeWidth: 1.5,
                    dashCount: 16,
                  ),
                ),
              ),

              // Rotating Reverse Dash Ring 2
              Transform.rotate(
                angle: -_rotationController.value * 2 * math.pi * 0.7,
                child: CustomPaint(
                  size: Size(widget.size * 0.78, widget.size * 0.78),
                  painter: _DashedRingPainter(
                    color: CareerTheme.accentLavender.withValues(alpha: 0.5),
                    strokeWidth: 1.2,
                    dashCount: 12,
                  ),
                ),
              ),

              // Inner Glowing Orb Core
              Container(
                width: widget.size * 0.6 * _pulseAnimation.value,
                height: widget.size * 0.6 * _pulseAnimation.value,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFF38BDF8),
                      Color(0xFF6366F1),
                      Color(0xFF1E1B4B),
                    ],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
                child: widget.showText
                    ? Center(
                        child: Text(
                          widget.text,
                          style: TextStyle(
                            fontSize: widget.size * 0.22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final int dashCount;

  _DashedRingPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final arcLength = (2 * math.pi) / (dashCount * 2);

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * arcLength * 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        arcLength,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

// ==========================================
// 3. CAREER PROGRESS RING (Animated Circular Gauge)
// ==========================================
class CareerProgressRing extends StatelessWidget {
  final double percentage; // 0.0 to 100.0
  final double size;
  final double strokeWidth;
  final String? centerLabel;
  final TextStyle? labelStyle;
  final Color? progressColor;
  final Color? backgroundColor;

  const CareerProgressRing({
    super.key,
    required this.percentage,
    this.size = 54.0,
    this.strokeWidth = 5.0,
    this.centerLabel,
    this.labelStyle,
    this.progressColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = percentage.clamp(0.0, 100.0);
    final text = centerLabel ?? '${clamped.round()}%';

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: clamped / 100.0),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return CustomPaint(
                size: Size(size, size),
                painter: _CircularProgressPainter(
                  progress: value,
                  strokeWidth: strokeWidth,
                  progressColor: progressColor ?? CareerTheme.primaryCyan,
                  backgroundColor: backgroundColor ?? CareerTheme.surfaceElevated,
                ),
              );
            },
          ),
          Text(
            text,
            style: labelStyle ??
                TextStyle(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color progressColor;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Active progress arc
    final fgPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.progressColor != progressColor;
}

// ==========================================
// 4. CAREER SEGMENTED CONTROL
// ==========================================
class CareerSegmentedControl extends StatelessWidget {
  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onSegmentSelected;

  const CareerSegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onSegmentSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CareerTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(CareerTheme.radiusPill),
        border: Border.all(color: CareerTheme.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: segments.asMap().entries.map((entry) {
          final idx = entry.key;
          final title = entry.value;
          final isSelected = idx == selectedIndex;

          return GestureDetector(
            onTap: () => onSegmentSelected(idx),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? CareerTheme.primaryCyan : Colors.transparent,
                borderRadius: BorderRadius.circular(CareerTheme.radiusPill),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: CareerTheme.primaryCyan.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? const Color(0xFF0F172A) : CareerTheme.textMuted,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ==========================================
// 5. CAREER PILL (Beginner / Intermediate / Advanced)
// ==========================================
class CareerPill extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const CareerPill({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? CareerTheme.primaryCyan.withValues(alpha: 0.2)
              : CareerTheme.surface,
          borderRadius: BorderRadius.circular(CareerTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? CareerTheme.primaryCyan : CareerTheme.glassBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: CareerTheme.primaryCyan.withValues(alpha: 0.2),
                    blurRadius: 10,
                  )
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? CareerTheme.primaryCyan : CareerTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 6. CAREER PRIMARY BUTTON
// ==========================================
class CareerPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const CareerPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  State<CareerPrimaryButton> createState() => _CareerPrimaryButtonState();
}

class _CareerPrimaryButtonState extends State<CareerPrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.width ?? double.infinity,
          height: 48,
          decoration: BoxDecoration(
            gradient: CareerTheme.primaryGradient,
            borderRadius: BorderRadius.circular(CareerTheme.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: CareerTheme.primaryCyan.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          widget.label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.icon != null) ...[
                        const SizedBox(width: 8),
                        Icon(widget.icon, size: 16, color: Colors.white),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 7. CAREER SECTION HEADER
// ==========================================
class CareerSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const CareerSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: CareerTheme.sectionHeader,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (actionLabel != null && onActionTap != null)
              GestureDetector(
                onTap: onActionTap,
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CareerTheme.primaryCyan,
                  ),
                ),
              ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(subtitle!, style: CareerTheme.caption),
        ],
      ],
    );
  }
}

// ==========================================
// 8. CAREER ANIMATED AUDIO WAVEFORM
// ==========================================
class CareerAnimatedWaveform extends StatefulWidget {
  final bool isRecording;
  final Color? color;

  const CareerAnimatedWaveform({
    super.key,
    required this.isRecording,
    this.color,
  });

  @override
  State<CareerAnimatedWaveform> createState() => _CareerAnimatedWaveformState();
}

class _CareerAnimatedWaveformState extends State<CareerAnimatedWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isRecording) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant CareerAnimatedWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _controller.repeat();
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const barCount = 20;
    final waveColor = widget.color ?? CareerTheme.primaryCyan;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: 36,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(barCount, (i) {
              final offset = (i / barCount) * 2 * math.pi;
              final sinValue = widget.isRecording
                  ? (math.sin(_controller.value * 2 * math.pi + offset).abs())
                  : 0.15;
              final height = (sinValue * 28.0).clamp(6.0, 32.0);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 3.5,
                height: height,
                decoration: BoxDecoration(
                  color: waveColor.withValues(alpha: widget.isRecording ? 0.85 : 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
