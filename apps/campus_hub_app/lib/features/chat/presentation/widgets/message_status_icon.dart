import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum MessageDeliveryStatus { sending, sent, delivered, read }

class MessageStatusIcon extends StatelessWidget {
  final MessageDeliveryStatus status;
  final Color? color;

  const MessageStatusIcon({
    super.key,
    required this.status,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = color ?? (isDark ? AppColors.darkSecondaryText : Colors.black54);

    switch (status) {
      case MessageDeliveryStatus.sending:
        return Icon(
          Icons.schedule,
          size: 14,
          color: defaultColor.withValues(alpha: 0.7),
        );

      case MessageDeliveryStatus.sent:
        return Icon(
          Icons.done,
          size: 14,
          color: defaultColor,
        );

      case MessageDeliveryStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 14,
          color: defaultColor,
        );

      case MessageDeliveryStatus.read:
        return const Icon(
          Icons.done_all,
          size: 14,
          color: Colors.blue,
        );
    }
  }
}
