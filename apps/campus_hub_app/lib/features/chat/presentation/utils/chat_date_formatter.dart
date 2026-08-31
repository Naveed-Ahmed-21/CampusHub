import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatDateFormatter {
  const ChatDateFormatter._();

  /// Formats time respecting the user device's 12-hour / 24-hour setting and locale
  static String formatMessageTime(DateTime dateTime, BuildContext context) {
    final local = dateTime.toLocal();
    return TimeOfDay.fromDateTime(local).format(context);
  }

  /// Smart conversation list timestamp formatter:
  /// - Today -> e.g. "8:42 PM" or "20:42" (matches device 12/24hr format)
  /// - Yesterday -> "Yesterday"
  /// - Within last 6 days -> Weekday name (e.g. "Monday")
  /// - Older -> Localized date (e.g. "23/8/2026" or "8/23/2026")
  static String formatConversationTime(DateTime? dateTime, BuildContext context) {
    if (dateTime == null) return '';
    final local = dateTime.toLocal();
    final now = DateTime.now();

    // Check if today
    if (local.year == now.year && local.month == now.month && local.day == now.day) {
      return formatMessageTime(local, context);
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

    // Older conversation: format using device locale
    return DateFormat.yMd().format(local);
  }

  /// Header date separator inside message thread (e.g. "Today", "Yesterday", "August 23")
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

    if (local.year == now.year) {
      return DateFormat.MMMMd().format(local);
    }

    return DateFormat.yMMMMd().format(local);
  }
}
