import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatDateFormatter {
  const ChatDateFormatter._();

  /// Formats time in 12-hour AM/PM format (e.g. "3:45 PM")
  static String formatMessageTime(DateTime dateTime, [BuildContext? context]) {
    final local = dateTime.toLocal();
    return DateFormat('h:mm a').format(local);
  }

  /// Smart conversation list timestamp formatter:
  /// - Today -> "3:45 PM" (12-hour AM/PM)
  /// - Yesterday -> "Yesterday"
  /// - Within last 6 days -> Weekday name (e.g. "Monday")
  /// - Older -> "dd/MM/yyyy" (e.g. "03/10/2026")
  static String formatConversationTime(DateTime? dateTime, [BuildContext? context]) {
    if (dateTime == null) return '';
    final local = dateTime.toLocal();
    final now = DateTime.now();

    // Check if today
    if (local.year == now.year && local.month == now.month && local.day == now.day) {
      return formatMessageTime(local);
    }

    // Check if yesterday
    final yesterday = now.subtract(const Duration(days: 1));
    if (local.year == yesterday.year && local.month == yesterday.month && local.day == yesterday.day) {
      return 'Yesterday';
    }

    // Check if within the last 6 days
    final diffDays = now.difference(local).inDays;
    if (diffDays >= 1 && diffDays < 7) {
      return DateFormat.EEEE().format(local);
    }

    // Older conversation: format using dd/MM/yyyy
    return DateFormat('dd/MM/yyyy').format(local);
  }

  /// Header date separator inside message thread (e.g. "Today", "Yesterday", "03/10/2026")
  static String formatDateSeparator(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();

    if (local.year == now.year && local.month == now.month && local.day == now.day) {
      return 'Today';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (local.year == yesterday.year && local.month == yesterday.month && local.day == yesterday.day) {
      return 'Yesterday';
    }

    return DateFormat('dd/MM/yyyy').format(local);
  }
}
