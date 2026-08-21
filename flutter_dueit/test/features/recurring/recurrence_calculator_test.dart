import 'package:flutter_test/flutter_test.dart';
import 'package:dueit/features/dues/domain/entities/recurring_due_schedule_entity.dart';
import 'package:dueit/features/dues/domain/services/recurrence_calculator.dart';

void main() {
  group('RecurrenceCalculator Domain & Date Arithmetic Unit Tests', () {
    test('1. Monthly calculation on standard day (e.g. 15th)', () {
      final next = RecurrenceCalculator.calculateNextDueDate(
        currentDueDateStr: '2026-08-15',
        frequency: RecurrenceFrequency.monthly,
        originalDayOfMonth: 15,
      );
      expect(next, '2026-09-15');
    });

    test(
        '2. Month-end clamping: Jan 31 -> Feb 28 -> Mar 31 -> Apr 30 -> May 31',
        () {
      // Jan 31, 2026 -> Feb 28, 2026 (clamped from 31 to 28)
      final feb = RecurrenceCalculator.calculateNextDueDate(
        currentDueDateStr: '2026-01-31',
        frequency: RecurrenceFrequency.monthly,
        originalDayOfMonth: 31,
      );
      expect(feb, '2026-02-28');

      // Feb 28, 2026 -> Mar 31, 2026 (preserves originalDayOfMonth = 31!)
      final mar = RecurrenceCalculator.calculateNextDueDate(
        currentDueDateStr: feb,
        frequency: RecurrenceFrequency.monthly,
        originalDayOfMonth: 31,
      );
      expect(mar, '2026-03-31');

      // Mar 31, 2026 -> Apr 30, 2026 (clamped from 31 to 30)
      final apr = RecurrenceCalculator.calculateNextDueDate(
        currentDueDateStr: mar,
        frequency: RecurrenceFrequency.monthly,
        originalDayOfMonth: 31,
      );
      expect(apr, '2026-04-30');

      // Apr 30, 2026 -> May 31, 2026 (preserves 31st!)
      final may = RecurrenceCalculator.calculateNextDueDate(
        currentDueDateStr: apr,
        frequency: RecurrenceFrequency.monthly,
        originalDayOfMonth: 31,
      );
      expect(may, '2026-05-31');
    });

    test('3. Leap year calculation: Feb 29 2024 -> Feb 28 2025 -> Feb 28 2026',
        () {
      final next2025 = RecurrenceCalculator.calculateNextDueDate(
        currentDueDateStr: '2024-02-29',
        frequency: RecurrenceFrequency.yearly,
        originalDayOfMonth: 29,
      );
      expect(next2025, '2025-02-28');

      final next2026 = RecurrenceCalculator.calculateNextDueDate(
        currentDueDateStr: next2025,
        frequency: RecurrenceFrequency.yearly,
        originalDayOfMonth: 29,
      );
      expect(next2026, '2026-02-28');
    });

    test('4. Year transition: Dec 25 2026 -> Jan 25 2027', () {
      final jan2027 = RecurrenceCalculator.calculateNextDueDate(
        currentDueDateStr: '2026-12-25',
        frequency: RecurrenceFrequency.monthly,
        originalDayOfMonth: 25,
      );
      expect(jan2027, '2027-01-25');
    });

    test(
        '5. Quarterly calculation: Jan 10 -> Apr 10 -> Jul 10 -> Oct 10 -> Jan 10 2027',
        () {
      final q1 = RecurrenceCalculator.calculateNextDueDate(
        currentDueDateStr: '2026-01-10',
        frequency: RecurrenceFrequency.quarterly,
        originalDayOfMonth: 10,
      );
      expect(q1, '2026-04-10');

      final q2 = RecurrenceCalculator.calculateNextDueDate(
        currentDueDateStr: q1,
        frequency: RecurrenceFrequency.quarterly,
        originalDayOfMonth: 10,
      );
      expect(q2, '2026-07-10');

      final q3 = RecurrenceCalculator.calculateNextDueDate(
        currentDueDateStr: q2,
        frequency: RecurrenceFrequency.quarterly,
        originalDayOfMonth: 10,
      );
      expect(q3, '2026-10-10');

      final q4 = RecurrenceCalculator.calculateNextDueDate(
        currentDueDateStr: q3,
        frequency: RecurrenceFrequency.quarterly,
        originalDayOfMonth: 10,
      );
      expect(q4, '2027-01-10');
    });

    test(
        '6. Quarterly with month-end: Nov 30 2026 -> Feb 28 2027 -> May 30 2027',
        () {
      final feb = RecurrenceCalculator.calculateNextDueDate(
        currentDueDateStr: '2026-11-30',
        frequency: RecurrenceFrequency.quarterly,
        originalDayOfMonth: 30,
      );
      expect(feb, '2027-02-28');

      final may = RecurrenceCalculator.calculateNextDueDate(
        currentDueDateStr: feb,
        frequency: RecurrenceFrequency.quarterly,
        originalDayOfMonth: 30,
      );
      expect(may, '2027-05-30');
    });

    test('7. Yearly calculation: Aug 15 2026 -> Aug 15 2027 -> Aug 15 2028',
        () {
      final y1 = RecurrenceCalculator.calculateNextDueDate(
        currentDueDateStr: '2026-08-15',
        frequency: RecurrenceFrequency.yearly,
        originalDayOfMonth: 15,
      );
      expect(y1, '2027-08-15');

      final y2 = RecurrenceCalculator.calculateNextDueDate(
        currentDueDateStr: y1,
        frequency: RecurrenceFrequency.yearly,
        originalDayOfMonth: 15,
      );
      expect(y2, '2028-08-15');
    });

    test('8. Weekly calculation: Monday -> next Monday (weekday alignment)',
        () {
      // 2026-08-17 is a Monday (DateTime.monday = 1)
      final monday = DateTime.parse('2026-08-17');
      expect(monday.weekday, DateTime.monday);

      final nextMonday = RecurrenceCalculator.calculateNextDueDate(
        currentDueDateStr: '2026-08-17',
        frequency: RecurrenceFrequency.weekly,
        originalDayOfMonth: 17,
        dayOfWeek: DateTime.monday,
      );
      expect(nextMonday, '2026-08-24');
      expect(DateTime.parse(nextMonday).weekday, DateTime.monday);
    });

    test('9. Weekly calculation: Sunday -> next Sunday (weekday alignment)',
        () {
      // 2026-08-23 is a Sunday (DateTime.sunday = 7)
      final sunday = DateTime.parse('2026-08-23');
      expect(sunday.weekday, DateTime.sunday);

      final nextSunday = RecurrenceCalculator.calculateNextDueDate(
        currentDueDateStr: '2026-08-23',
        frequency: RecurrenceFrequency.weekly,
        originalDayOfMonth: 23,
        dayOfWeek: DateTime.sunday,
      );
      expect(nextSunday, '2026-08-30');
      expect(DateTime.parse(nextSunday).weekday, DateTime.sunday);
    });

    test(
        '10. Weekly calculation: Cross-month transition (Aug 28 Friday -> Sep 04 Friday)',
        () {
      // 2026-08-28 is a Friday
      final friday = DateTime.parse('2026-08-28');
      expect(friday.weekday, DateTime.friday);

      final nextFriday = RecurrenceCalculator.calculateNextDueDate(
        currentDueDateStr: '2026-08-28',
        frequency: RecurrenceFrequency.weekly,
        originalDayOfMonth: 28,
        dayOfWeek: DateTime.friday,
      );
      expect(nextFriday, '2026-09-04');
      expect(DateTime.parse(nextFriday).weekday, DateTime.friday);
    });

    test(
        '11. Weekly calculation: Cross-year transition (Dec 28 Monday -> Jan 04 Monday)',
        () {
      // 2026-12-28 is a Monday
      final monday = DateTime.parse('2026-12-28');
      expect(monday.weekday, DateTime.monday);

      final nextMonday = RecurrenceCalculator.calculateNextDueDate(
        currentDueDateStr: '2026-12-28',
        frequency: RecurrenceFrequency.weekly,
        originalDayOfMonth: 28,
        dayOfWeek: DateTime.monday,
      );
      expect(nextMonday, '2027-01-04');
      expect(DateTime.parse(nextMonday).weekday, DateTime.monday);
    });

    test(
        '12. Weekly calculation does not depend on month length (28, 29, 30, 31 days)',
        () {
      // Leap February 2024: Feb 26 (Monday) -> Mar 04 (Monday)
      final leapFeb = RecurrenceCalculator.calculateNextDueDate(
        currentDueDateStr: '2024-02-26',
        frequency: RecurrenceFrequency.weekly,
        originalDayOfMonth: 26,
        dayOfWeek: DateTime.monday,
      );
      expect(leapFeb, '2024-03-04');

      // Non-leap February 2026: Feb 23 (Monday) -> Mar 02 (Monday)
      final nonLeapFeb = RecurrenceCalculator.calculateNextDueDate(
        currentDueDateStr: '2026-02-23',
        frequency: RecurrenceFrequency.weekly,
        originalDayOfMonth: 23,
        dayOfWeek: DateTime.monday,
      );
      expect(nonLeapFeb, '2026-03-02');

      // 30-day April 2026: Apr 28 (Tuesday) -> May 05 (Tuesday)
      final april = RecurrenceCalculator.calculateNextDueDate(
        currentDueDateStr: '2026-04-28',
        frequency: RecurrenceFrequency.weekly,
        originalDayOfMonth: 28,
        dayOfWeek: DateTime.tuesday,
      );
      expect(april, '2026-05-05');
    });

    test('13. AppDayOfWeek enum mappings and helper methods', () {
      expect(AppDayOfWeek.monday.displayName, 'Monday');
      expect(AppDayOfWeek.monday.weekdayNumber, 1);
      expect(AppDayOfWeek.sunday.displayName, 'Sunday');
      expect(AppDayOfWeek.sunday.weekdayNumber, 7);

      expect(AppDayOfWeek.fromDateTimeWeekday(1), AppDayOfWeek.monday);
      expect(AppDayOfWeek.fromDateTimeWeekday(7), AppDayOfWeek.sunday);

      expect(AppDayOfWeek.fromString('Wednesday'), AppDayOfWeek.wednesday);
      expect(AppDayOfWeek.fromString('thu'), AppDayOfWeek.thursday);
    });

    test('14. Deterministic occurrence key generation', () {
      final key1 = RecurrenceCalculator.generateOccurrenceDueId(
          'sched_100', '2026-08-25');
      final key2 = RecurrenceCalculator.generateOccurrenceDueId(
          'sched_100', '2026-08-25');
      final key3 = RecurrenceCalculator.generateOccurrenceDueId(
          'sched_100', '2026-09-25');

      expect(key1, 'due_sched_100_2026-08-25');
      expect(key1, equals(key2));
      expect(key1, isNot(equals(key3)));
    });

    test(
        '15. Schedule eligibility check with start/end boundaries and active status',
        () {
      final schedule = RecurringDueScheduleEntity(
        id: 'sched_1',
        ownerId: 'owner_1',
        customerId: 'cust_1',
        amount: 1500,
        description: 'Karate Fee',
        frequency: RecurrenceFrequency.monthly,
        dayOfMonth: 25,
        startDate: '2026-08-25',
        endDate: '2026-12-25',
        status: RecurringScheduleStatus.active,
        nextDueDate: '2026-08-25',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
          RecurrenceCalculator.isScheduleEligibleForDate(
            schedule: schedule,
            targetDateStr: '2026-08-25',
          ),
          isTrue);

      expect(
          RecurrenceCalculator.isScheduleEligibleForDate(
            schedule: schedule,
            targetDateStr: '2026-07-25', // Before start
          ),
          isFalse);

      expect(
          RecurrenceCalculator.isScheduleEligibleForDate(
            schedule: schedule,
            targetDateStr: '2027-01-25', // After end
          ),
          isFalse);

      final pausedSchedule =
          schedule.copyWith(status: RecurringScheduleStatus.paused);
      expect(
          RecurrenceCalculator.isScheduleEligibleForDate(
            schedule: pausedSchedule,
            targetDateStr: '2026-09-25',
          ),
          isFalse);
    });
  });
}
