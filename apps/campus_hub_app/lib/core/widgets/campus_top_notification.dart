import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_glass.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

enum TopNotificationType { error, success, warning, info }

/// Premium iOS / Dynamic Island style floating top notification banner with glassmorphism.
class CampusTopNotification {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void showError(
    BuildContext context, {
    required String message,
    String title = 'Notice',
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      title: title,
      message: message,
      type: TopNotificationType.error,
      duration: duration,
    );
  }

  static void showSuccess(
    BuildContext context, {
    required String message,
    String title = 'Success',
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      title: title,
      message: message,
      type: TopNotificationType.success,
      duration: duration,
    );
  }

  static void showNotice(
    BuildContext context, {
    required String message,
    String title = 'Notification',
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      title: title,
      message: message,
      type: TopNotificationType.info,
      duration: duration,
    );
  }

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    TopNotificationType type = TopNotificationType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _TopNotificationWidget(
        title: title,
        message: message,
        type: type,
        onDismiss: () {
          _dismissTimer?.cancel();
          if (_currentEntry == entry) {
            entry.remove();
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, () {
      if (_currentEntry == entry) {
        entry.remove();
        _currentEntry = null;
      }
    });
  }
}

class _TopNotificationWidget extends StatefulWidget {
  final String title;
  final String message;
  final TopNotificationType type;
  final VoidCallback onDismiss;

  const _TopNotificationWidget({
    required this.title,
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_TopNotificationWidget> createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _dismissWithAnimation() async {
    await _animController.reverse();
    widget.onDismiss();
  }

  Color _getAccentColor(bool isDark) {
    switch (widget.type) {
      case TopNotificationType.error:
        return const Color(0xFFEF4444);
      case TopNotificationType.success:
        return const Color(0xFF10B981);
      case TopNotificationType.warning:
        return const Color(0xFFF59E0B);
      case TopNotificationType.info:
        return isDark ? Colors.white : AppColors.primaryText;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case TopNotificationType.error:
        return Icons.error_outline_rounded;
      case TopNotificationType.success:
        return Icons.check_circle_outline_rounded;
      case TopNotificationType.warning:
        return Icons.warning_amber_rounded;
      case TopNotificationType.info:
        return Icons.notifications_active_outlined;
    }
  }

  String _getBadgeLabel() {
    switch (widget.type) {
      case TopNotificationType.error:
        return 'ALERT';
      case TopNotificationType.success:
        return 'SUCCESS';
      case TopNotificationType.warning:
        return 'WARNING';
      case TopNotificationType.info:
        return 'NOTIFICATION';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final accentColor = _getAccentColor(isDark);

    final bgColor = isDark
        ? AppColors.darkElevatedSurface
        : Colors.white;
    final borderColor = accentColor.withValues(alpha: isDark ? 0.35 : 0.4);

    return Positioned(
      top: topPadding + 8,
      left: 14,
      right: 14,
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value * 60),
              child: Opacity(
                opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta != null && details.primaryDelta! < -5) {
                _dismissWithAnimation();
              }
            },
            onTap: _dismissWithAnimation,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppRadius.br16,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: AppRadius.br16,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: AppGlassTheme.blurStrong,
                    sigmaY: AppGlassTheme.blurStrong,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: AppRadius.br16,
                      border: Border.all(color: borderColor, width: 1.2),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Glowing Icon Container
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(_getIcon(), color: accentColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        // Title & Message Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _getBadgeLabel(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: accentColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      widget.title,
                                      style: AppTypography.cardTitle.copyWith(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.darkText : AppColors.primaryText,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.message,
                                style: AppTypography.caption.copyWith(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Close Icon
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          onPressed: _dismissWithAnimation,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
