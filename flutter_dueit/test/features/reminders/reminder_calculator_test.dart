import 'package:flutter_test/flutter_test.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';
import 'package:dueit/features/reminders/domain/services/reminder_calculator.dart';

void main() {
  group('ReminderCalculator Domain & Logic Unit Tests', () {
    const testDueDateStr = '2026-08-25';

    test('1. ReminderType string serialization and parsing', () {
      expect(ReminderType.fromString('none'), ReminderType.none);
      expect(ReminderType.fromString('None'), ReminderType.none);
      expect(ReminderType.fromString('on due date'), ReminderType.onDueDate);
      expect(ReminderType.fromString('on_due_date'), ReminderType.onDueDate);
      expect(
          ReminderType.fromString('1 day before'), ReminderType.oneDayBefore);
      expect(
          ReminderType.fromString('2 days before'), ReminderType.twoDaysBefore);
      expect(ReminderType.fromString('3 days before'),
          ReminderType.threeDaysBefore);
      expect(ReminderType.fromString('1 week before'),
          ReminderType.sevenDaysBefore);
      expect(ReminderType.fromString('7 days before'),
          ReminderType.sevenDaysBefore);
      expect(ReminderType.fromString('daily'), ReminderType.daily);
    });

    test('2. Calculate reminder date: On Due Date', () {
      final date = ReminderCalculator.calculateReminderDate(
        testDueDateStr,
        ReminderType.onDueDate,
      );
      expect(date, '2026-08-25');
    });

    test('3. Calculate reminder date: 1 Day Before', () {
      final date = ReminderCalculator.calculateReminderDate(
        testDueDateStr,
        ReminderType.oneDayBefore,
      );
      expect(date, '2026-08-24');
    });

    test('4. Calculate reminder date: 2 Days Before', () {
      final date = ReminderCalculator.calculateReminderDate(
        testDueDateStr,
        ReminderType.twoDaysBefore,
      );
      expect(date, '2026-08-23');
    });

    test('5. Calculate reminder date: 3 Days Before', () {
      final date = ReminderCalculator.calculateReminderDate(
        testDueDateStr,
        ReminderType.threeDaysBefore,
      );
      expect(date, '2026-08-22');
    });

    test('6. Calculate reminder date: 1 Week Before (7 days)', () {
      final date = ReminderCalculator.calculateReminderDate(
        testDueDateStr,
        ReminderType.sevenDaysBefore,
      );
      expect(date, '2026-08-18');
    });

    test('7. Calculate reminder date: None returns null', () {
      final date = ReminderCalculator.calculateReminderDate(
        testDueDateStr,
        ReminderType.none,
      );
      expect(date, isNull);
    });

    test('8. Calculate reminder DateTime uses default 9:00 AM local time', () {
      final dt = ReminderCalculator.calculateReminderDateTime(
        testDueDateStr,
        ReminderType.oneDayBefore,
      );
      expect(dt, isNotNull);
      expect(dt!.year, 2026);
      expect(dt.month, 8);
      expect(dt.day, 24);
      expect(dt.hour, 9);
      expect(dt.minute, 0);
      expect(dt.second, 0);
    });

    test('9. Past reminder time detection correctly identifies past reminders',
        () {
      final now = DateTime(2026, 8, 24, 15, 30); // 3:30 PM on Aug 24
      final pastReminder =
          DateTime(2026, 8, 24, 9, 0); // 9:00 AM on Aug 24 (past)
      final futureReminder =
          DateTime(2026, 8, 25, 9, 0); // 9:00 AM on Aug 25 (future)

      expect(ReminderCalculator.isPastReminder(pastReminder, now: now), isTrue);
      expect(
          ReminderCalculator.isPastReminder(futureReminder, now: now), isFalse);
    });

    test('10. Deterministic positive 31-bit Notification ID generation', () {
      final id1 = ReminderCalculator.generateNotificationId('due_100');
      final id2 = ReminderCalculator.generateNotificationId('due_100');
      final id3 = ReminderCalculator.generateNotificationId('due_200');

      expect(id1, equals(id2)); // Same dueId yields exact same notification ID
      expect(id1, isNonNegative);
      expect(id3, isNonNegative);
      expect(id1, isNot(equals(id3)));
    });

    test('11. Notification Title generation based on due date proximity', () {
      final todayStr = '2026-08-21';
      final tomorrowStr = '2026-08-22';
      final pastStr = '2026-08-15';
      final futureStr = '2026-08-30';

      expect(ReminderCalculator.buildNotificationTitle(dueDateStr: todayStr),
          'Payment due today');
      expect(ReminderCalculator.buildNotificationTitle(dueDateStr: tomorrowStr),
          'Payment due tomorrow');
      expect(ReminderCalculator.buildNotificationTitle(dueDateStr: pastStr),
          'Payment overdue');
      expect(ReminderCalculator.buildNotificationTitle(dueDateStr: futureStr),
          'Payment reminder');
    });

    test(
        '12. Notification Body generation formats client name, remaining balance, and description',
        () {
      final body = ReminderCalculator.buildNotificationBody(
        customerName: 'Rahul Kumar',
        remainingAmount: 1500.0,
        description: 'August Karate Fee',
      );

      expect(body, 'Rahul Kumar owes ₹1,500 for August Karate Fee.');
    });

    test(
        '13. Notification Body with partial payment reflects updated remaining amount',
        () {
      final body = ReminderCalculator.buildNotificationBody(
        customerName: 'Rahul Kumar',
        remainingAmount: 3000.0, // Remaining out of ₹5,000
        description: 'Coaching Fees',
      );

      expect(body, 'Rahul Kumar owes ₹3,000 for Coaching Fees.');
    });
  });
}
