import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SwipeToReplyWrapper extends StatefulWidget {
  final Widget child;
  final bool isMe;
  final VoidCallback onReply;

  const SwipeToReplyWrapper({
    super.key,
    required this.child,
    required this.isMe,
    required this.onReply,
  });

  @override
  State<SwipeToReplyWrapper> createState() => _SwipeToReplyWrapperState();
}

class _SwipeToReplyWrapperState extends State<SwipeToReplyWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _dragOffset = 0.0;
  bool _hasTriggeredHaptic = false;

  static const double _threshold = 48.0;
  static const double _maxDrag = 72.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _animation = Tween<double>(begin: 0.0, end: 0.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_controller.isAnimating) return;

    if (widget.isMe) {
      // SENT / OUTGOING messages: Swipe LEFT (negative dx) to reply
      if (details.delta.dx < 0 || _dragOffset < 0) {
        final newOffset = (_dragOffset + details.delta.dx).clamp(-_maxDrag, 0.0);
        if (newOffset != _dragOffset) {
          setState(() {
            _dragOffset = newOffset;
          });
          if (_dragOffset.abs() >= _threshold && !_hasTriggeredHaptic) {
            _hasTriggeredHaptic = true;
            HapticFeedback.lightImpact();
          } else if (_dragOffset.abs() < _threshold) {
            _hasTriggeredHaptic = false;
          }
        }
      }
    } else {
      // RECEIVED / INCOMING messages: Swipe RIGHT (positive dx) to reply
      if (details.delta.dx > 0 || _dragOffset > 0) {
        final newOffset = (_dragOffset + details.delta.dx).clamp(0.0, _maxDrag);
        if (newOffset != _dragOffset) {
          setState(() {
            _dragOffset = newOffset;
          });
          if (_dragOffset >= _threshold && !_hasTriggeredHaptic) {
            _hasTriggeredHaptic = true;
            HapticFeedback.lightImpact();
          } else if (_dragOffset < _threshold) {
            _hasTriggeredHaptic = false;
          }
        }
      }
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final reached = _dragOffset.abs() >= _threshold;
    if (reached) {
      widget.onReply();
    }

    _hasTriggeredHaptic = false;
    _animation = Tween<double>(
      begin: _dragOffset,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _dragOffset = 0.0;
        });
      }
    });
  }

  void _onHorizontalDragCancel() {
    _hasTriggeredHaptic = false;
    if (_dragOffset != 0.0) {
      _animation = Tween<double>(
        begin: _dragOffset,
        end: 0.0,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0.0).then((_) {
        if (mounted) {
          setState(() {
            _dragOffset = 0.0;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onHorizontalDragCancel: _onHorizontalDragCancel,
      behavior: HitTestBehavior.translucent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final offset = _controller.isAnimating ? _animation.value : _dragOffset;
          final progress = (offset.abs() / _threshold).clamp(0.0, 1.0);
          final isThresholdReached = offset.abs() >= _threshold;

          return Stack(
            clipBehavior: Clip.none,
            alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
            children: [
              // Animated Reply Icon behind the bubble
              if (offset.abs() > 4)
                Positioned(
                  left: !widget.isMe ? 8 : null,
                  right: widget.isMe ? 8 : null,
                  child: Opacity(
                    opacity: progress,
                    child: Transform.scale(
                      scale: (0.6 + 0.5 * progress).clamp(0.6, 1.15),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: isThresholdReached
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.reply_rounded,
                          size: 18,
                          color: isThresholdReached
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),

              // Swiping Message Content
              Transform.translate(
                offset: Offset(offset, 0),
                child: widget.child,
              ),
            ],
          );
        },
      ),
    );
  }
}
