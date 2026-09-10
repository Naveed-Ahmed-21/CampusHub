import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/career_models.dart';

class JourneyMapWidget extends StatefulWidget {
  final ActiveRoadmapState activeRoadmap;
  final List<Map<String, dynamic>> phases;
  final Function(int phaseNum) onPhaseTap;
  final VoidCallback onViewChanges;

  const JourneyMapWidget({
    super.key,
    required this.activeRoadmap,
    required this.phases,
    required this.onPhaseTap,
    required this.onViewChanges,
  });

  @override
  State<JourneyMapWidget> createState() => _JourneyMapWidgetState();
}

class _JourneyMapWidgetState extends State<JourneyMapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  int _calculateCurrentPhase() {
    for (int i = 0; i < widget.phases.length; i++) {
      final pNum = widget.phases[i]['num'] as int;
      final scoreData = widget.activeRoadmap.quizScores?['phase_$pNum'];
      final isPassed = scoreData != null && scoreData['passed'] == true;
      if (!isPassed) {
        return pNum;
      }
    }
    return widget.phases.isNotEmpty ? widget.phases.last['num'] as int : 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPhase = _calculateCurrentPhase();

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title + Version History Chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Curriculum Journey Map',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'AI adaptive milestones & skill checkpoints',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.history, size: 16, color: Colors.indigo),
                  label: Text(
                    'v${widget.activeRoadmap.version} Changes',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  backgroundColor: Colors.indigo.withValues(alpha: 0.08),
                  side: BorderSide(
                    color: Colors.indigo.withValues(alpha: 0.25),
                  ),
                  onPressed: widget.onViewChanges,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Journey Path Items
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.phases.length,
              itemBuilder: (context, index) {
                final ph = widget.phases[index];
                final pNum = ph['num'] as int;
                final title = ph['title'] as String;
                final weeks = ph['weeks'] as String;
                final skills = (ph['skills'] as List<dynamic>?)
                        ?.map((s) => s.toString())
                        .toList() ??
                    [];

                final scoreData =
                    widget.activeRoadmap.quizScores?['phase_$pNum'];
                final isCompleted =
                    scoreData != null && scoreData['passed'] == true;
                final isCurrent = pNum == currentPhase && !isCompleted;
                final isLocked = pNum > currentPhase;
                final isNeedsWork =
                    scoreData != null && scoreData['passed'] == false;

                final isLast = index == widget.phases.length - 1;

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Node Column: Circle Marker + Connector Line
                      SizedBox(
                        width: 44,
                        child: Column(
                          children: [
                            _buildMilestoneMarker(
                              isCompleted: isCompleted,
                              isCurrent: isCurrent,
                              isLocked: isLocked,
                              isNeedsWork: isNeedsWork,
                              phaseNum: pNum,
                              theme: theme,
                            ),
                            if (!isLast)
                              Expanded(
                                child: CustomPaint(
                                  size: const Size(20, double.infinity),
                                  painter: _CurvedConnectorPainter(
                                    isCompleted: isCompleted,
                                    index: index,
                                    color: isCompleted
                                        ? Colors.green
                                        : (isCurrent
                                            ? Colors.indigo
                                            : theme.colorScheme.outlineVariant
                                                .withValues(alpha: 0.4)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Phase Content Card
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => widget.onPhaseTap(pNum),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? Colors.indigo.withValues(alpha: 0.05)
                                    : (isCompleted
                                        ? Colors.green.withValues(alpha: 0.03)
                                        : theme.colorScheme.surfaceContainerHighest
                                            .withValues(alpha: 0.25)),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isCurrent
                                      ? Colors.indigo.withValues(alpha: 0.4)
                                      : (isCompleted
                                          ? Colors.green.withValues(alpha: 0.3)
                                          : theme.colorScheme.outlineVariant
                                              .withValues(alpha: 0.4)),
                                  width: isCurrent ? 1.5 : 1.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isCurrent
                                              ? Colors.indigo
                                              : (isCompleted
                                                  ? Colors.green
                                                  : theme.colorScheme
                                                      .onSurfaceVariant
                                                      .withValues(alpha: 0.15)),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'PHASE $pNum',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: (isCurrent || isCompleted)
                                                ? Colors.white
                                                : theme.colorScheme
                                                    .onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        weeks,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (isCompleted)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.check,
                                                  size: 12, color: Colors.green),
                                              SizedBox(width: 4),
                                              Text(
                                                'Mastered',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green),
                                              ),
                                            ],
                                          ),
                                        )
                                      else if (isCurrent)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.indigo
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'In Progress',
                                            style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.indigo),
                                          ),
                                        )
                                      else if (isNeedsWork)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.amber
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'Needs Review',
                                            style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 5,
                                    runSpacing: 4,
                                    children: skills.take(4).map((sk) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: theme
                                              .colorScheme.surfaceContainerHighest
                                              .withValues(alpha: 0.5),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          sk,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneMarker({
    required bool isCompleted,
    required bool isCurrent,
    required bool isLocked,
    required bool isNeedsWork,
    required int phaseNum,
    required ThemeData theme,
  }) {
    if (isCompleted) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 20),
      );
    }

    if (isCurrent) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.indigo, Colors.cyan],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$phaseNum',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    if (isNeedsWork) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.amber.shade700,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.3),
              blurRadius: 6,
            ),
          ],
        ),
        child: const Icon(Icons.warning_amber_rounded,
            color: Colors.white, size: 20),
      );
    }

    // Locked / Upcoming
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          isLocked ? Icons.lock_outline : Icons.radio_button_unchecked,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _CurvedConnectorPainter extends CustomPainter {
  final bool isCompleted;
  final int index;
  final Color color;

  _CurvedConnectorPainter({
    required this.isCompleted,
    required this.index,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = isCompleted ? 3.0 : 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final midX = size.width / 2;
    // S-curve slight wave to look like an organic journey
    final curveOffset = (index % 2 == 0) ? 6.0 : -6.0;

    path.moveTo(midX, 0);
    path.cubicTo(
      midX + curveOffset,
      size.height * 0.3,
      midX - curveOffset,
      size.height * 0.7,
      midX,
      size.height,
    );

    if (!isCompleted) {
      // Draw dashed line for upcoming/in-progress
      _drawDashedPath(canvas, path, paint);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path source, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    final metrics = source.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = math.min(dashWidth, metric.length - distance);
        final extractPath = metric.extractPath(distance, distance + len);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CurvedConnectorPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isCompleted != isCompleted;
}
