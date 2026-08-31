import 'package:flutter_test/flutter_test.dart';
import 'package:campus_hub_app/features/chat/presentation/utils/presence_formatter.dart';

void main() {
  group('PresenceFormatter Tests', () {
    test('formats typing status', () {
      final status = PresenceFormatter.formatUserStatus(
        isOnline: true,
        isTyping: true,
      );
      expect(status, 'Typing...');
    });

    test('formats online status', () {
      final status = PresenceFormatter.formatUserStatus(
        isOnline: true,
        isTyping: false,
      );
      expect(status, 'Online');
    });

    test('formats null lastSeen as Offline', () {
      final status = PresenceFormatter.formatUserStatus(
        isOnline: false,
        lastSeen: null,
      );
      expect(status, 'Offline');
    });

    test('formats recent lastSeen as Last seen recently', () {
      final status = PresenceFormatter.formatUserStatus(
        isOnline: false,
        lastSeen: DateTime.now().subtract(const Duration(seconds: 20)),
      );
      expect(status, 'Last seen recently');
    });

    test('formats lastSeen minutes ago', () {
      final status = PresenceFormatter.formatUserStatus(
        isOnline: false,
        lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      expect(status, 'Last seen 5 minutes ago');
    });

    test('formats group status with typing user', () {
      final status = PresenceFormatter.formatGroupStatus(
        memberCount: 20,
        onlineMemberCount: 5,
        typingUserName: 'Aarav',
      );
      expect(status, 'Aarav is typing...');
    });

    test('formats group status with members and online count', () {
      final status = PresenceFormatter.formatGroupStatus(
        memberCount: 124,
        onlineMemberCount: 18,
      );
      expect(status, '124 members • 18 online');
    });

    test('formats group status without online members', () {
      final status = PresenceFormatter.formatGroupStatus(
        memberCount: 10,
        onlineMemberCount: 0,
      );
      expect(status, '10 members');
    });
  });
}
