import 'package:intl/intl.dart';

/// Centralized Date & Time Formatter for CampusHub
/// Strict specifications:
/// - 12-hour AM/PM format: 'h:mm a' (e.g. 3:45 PM)
/// - Date format: 'dd/MM/yyyy' (e.g. 03/10/2026)
abstract class AppDateFormatter {
  static final DateFormat _timeFormat = DateFormat('h:mm a');
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy, h:mm a');

  /// Formats time in 12-hour AM/PM format (e.g., "3:45 PM")
  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime.toLocal());
  }

  /// Formats date as dd/MM/yyyy (e.g., "03/10/2026")
  static String formatDate(DateTime dateTime) {
    return _dateFormat.format(dateTime.toLocal());
  }

  /// Formats date and time as dd/MM/yyyy, h:mm a (e.g., "03/10/2026, 3:45 PM")
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime.toLocal());
  }

  /// Formats a date string (ISO 8601 or similar) as dd/MM/yyyy
  static String formatDateString(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) return dateStr;
    return formatDate(parsed);
  }

  /// Formats a date string as dd/MM/yyyy, h:mm a
  static String formatDateTimeString(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) return dateStr;
    return formatDateTime(parsed);
  }

  /// Relative or formatted date/time for social feeds:
  /// - Under 1 hour -> "Xm ago"
  /// - Under 24 hours -> "Xh ago"
  /// - Older -> "dd/MM/yyyy"
  static String formatFeedDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return formatDate(date);
  }

  /// Smart conversation timestamp:
  /// - Today -> 12-hour format e.g. "3:45 PM"
  /// - Yesterday -> "Yesterday"
  /// - Older -> "dd/MM/yyyy"
  static String formatConversationTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final local = dateTime.toLocal();
    final now = DateTime.now();

    if (local.year == now.year && local.month == now.month && local.day == now.day) {
      return formatTime(local);
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (local.year == yesterday.year && local.month == yesterday.month && local.day == yesterday.day) {
      return 'Yesterday';
    }

    return formatDate(local);
  }
}
