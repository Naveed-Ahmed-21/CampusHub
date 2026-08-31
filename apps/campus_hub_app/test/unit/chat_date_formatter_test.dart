import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_hub_app/features/chat/presentation/utils/chat_date_formatter.dart';

void main() {
  group('ChatDateFormatter Tests', () {
    testWidgets('formats today conversation timestamp using device format', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      final now = DateTime.now();
      final todayTime = DateTime(now.year, now.month, now.day, 14, 30);
      final formatted = ChatDateFormatter.formatConversationTime(todayTime, capturedContext);

      expect(formatted.isNotEmpty, true);
      // In default 12-hour US locale, should be "2:30 PM" or match localized time
      expect(formatted.contains('2:30') || formatted.contains('14:30'), true);
    });

    testWidgets('formats yesterday conversation timestamp as "Yesterday"', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final formatted = ChatDateFormatter.formatConversationTime(yesterday, capturedContext);

      expect(formatted, equals('Yesterday'));
    });

    testWidgets('formats within last 6 days as weekday name', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      final now = DateTime.now();
      final threeDaysAgo = now.subtract(const Duration(days: 3));
      final formatted = ChatDateFormatter.formatConversationTime(threeDaysAgo, capturedContext);

      final weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      expect(weekdays.contains(formatted), true);
    });

    testWidgets('formats older conversation as localized date', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      final oldDate = DateTime(2023, 5, 15, 10, 0);
      final formatted = ChatDateFormatter.formatConversationTime(oldDate, capturedContext);

      expect(formatted.contains('2023') || formatted.contains('23'), true);
    });

    test('formatDateSeparator returns "Today" for current day', () {
      final now = DateTime.now();
      expect(ChatDateFormatter.formatDateSeparator(now), equals('Today'));
    });

    test('formatDateSeparator returns "Yesterday" for previous day', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(ChatDateFormatter.formatDateSeparator(yesterday), equals('Yesterday'));
    });
  });
}
