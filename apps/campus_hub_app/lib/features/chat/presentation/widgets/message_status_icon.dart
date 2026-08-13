import 'package:flutter/material.dart';

enum MessageDeliveryStatus { sending, sent, delivered, read }

class MessageStatusIcon extends StatelessWidget {
  final MessageDeliveryStatus status;

  const MessageStatusIcon({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageDeliveryStatus.sending:
        return const Icon(
          Icons.schedule,
          size: 14,
          color: Colors.black54,
        );

      case MessageDeliveryStatus.sent:
        return const Icon(
          Icons.done,
          size: 14,
          color: Colors.black87,
        );

      case MessageDeliveryStatus.delivered:
        return const Icon(
          Icons.done_all,
          size: 14,
          color: Colors.black87,
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
