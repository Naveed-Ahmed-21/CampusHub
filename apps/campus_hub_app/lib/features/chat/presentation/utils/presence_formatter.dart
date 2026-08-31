class PresenceFormatter {
  static String formatUserStatus({
    required bool isOnline,
    DateTime? lastSeen,
    bool isTyping = false,
  }) {
    if (isTyping) {
      return 'Typing...';
    }

    if (isOnline) {
      return 'Online';
    }

    if (lastSeen == null) {
      return 'Offline';
    }

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.isNegative || difference.inSeconds < 45) {
      return 'Last seen recently';
    }

    if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return mins == 1 ? 'Last seen 1 minute ago' : 'Last seen $mins minutes ago';
    }

    final isToday = now.year == lastSeen.year &&
        now.month == lastSeen.month &&
        now.day == lastSeen.day;

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = yesterday.year == lastSeen.year &&
        yesterday.month == lastSeen.month &&
        yesterday.day == lastSeen.day;

    final hour12 = lastSeen.hour == 0
        ? 12
        : (lastSeen.hour > 12 ? lastSeen.hour - 12 : lastSeen.hour);
    final minuteStr = lastSeen.minute.toString().padLeft(2, '0');
    final period = lastSeen.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour12:$minuteStr $period';

    if (isToday) {
      return 'Last seen today at $timeStr';
    }

    if (isYesterday) {
      return 'Last seen yesterday at $timeStr';
    }

    if (difference.inDays < 7) {
      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final dayName = days[lastSeen.weekday - 1];
      return 'Last seen $dayName at $timeStr';
    }

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthName = months[lastSeen.month - 1];
    return 'Last seen ${lastSeen.day} $monthName at $timeStr';
  }

  static String formatGroupStatus({
    required int memberCount,
    required int onlineMemberCount,
    String? typingUserName,
  }) {
    if (typingUserName != null && typingUserName.isNotEmpty) {
      return '$typingUserName is typing...';
    }

    final memberLabel = memberCount == 1 ? '1 member' : '$memberCount members';

    if (onlineMemberCount > 0) {
      return '$memberLabel • $onlineMemberCount online';
    }

    return memberLabel;
  }
}
