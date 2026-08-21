import 'package:dueit/core/utils/date_formatter.dart';
import '../entities/recurring_due_schedule_entity.dart';

/// Pure domain calculation service for calendar-aware recurrence scheduling,
/// month-end clamping, leap-year calculations, and deterministic occurrence keys.
abstract class RecurrenceCalculator {
  /// Maximum number of missed cycles generated during catch-up
  static const int maxCatchUpCycles = 6;

  /// Returns the exact number of days in the given [month] of [year] (handles leap years).
  static int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Clamps [targetDay] to the valid range [1, daysInMonth(year, month)].
  static int clampDay(int year, int month, int targetDay) {
    final maxDays = daysInMonth(year, month);
    return targetDay.clamp(1, maxDays);
  }

  /// Computes the next occurrence due date based on the current due date,
  /// recurrence frequency, original template [originalDayOfMonth], and optional [dayOfWeek].
  ///
  /// Preserving [originalDayOfMonth] ensures that month-end dates (e.g. Day 31)
  /// clamp properly in February/April without permanently downgrading subsequent 31-day months.
  ///
  /// Weekly recurrence strictly advances to the next occurrence of [dayOfWeek] (or adds 7 days)
  /// preserving day-of-week alignment across months and years regardless of month length.
  static String calculateNextDueDate({
    required String currentDueDateStr,
    required RecurrenceFrequency frequency,
    required int originalDayOfMonth,
    int? dayOfWeek,
  }) {
    final current = DateFormatter.parseLocalDate(currentDueDateStr);

    switch (frequency) {
      case RecurrenceFrequency.monthly:
        final nextYear = current.year + (current.month ~/ 12);
        final nextMonth = (current.month % 12) + 1;
        final nextDay = clampDay(nextYear, nextMonth, originalDayOfMonth);
        return DateFormatter.formatIsoDate(
            DateTime(nextYear, nextMonth, nextDay));

      case RecurrenceFrequency.quarterly:
        final totalMonths = current.month + 3;
        final nextYear = current.year + ((totalMonths - 1) ~/ 12);
        final nextMonth = ((totalMonths - 1) % 12) + 1;
        final nextDay = clampDay(nextYear, nextMonth, originalDayOfMonth);
        return DateFormatter.formatIsoDate(
            DateTime(nextYear, nextMonth, nextDay));

      case RecurrenceFrequency.yearly:
        final nextYear = current.year + 1;
        final nextMonth = current.month;
        final nextDay = clampDay(nextYear, nextMonth, originalDayOfMonth);
        return DateFormatter.formatIsoDate(
            DateTime(nextYear, nextMonth, nextDay));

      case RecurrenceFrequency.weekly:
        if (dayOfWeek != null && dayOfWeek >= 1 && dayOfWeek <= 7) {
          var daysToAdd = (dayOfWeek - current.weekday) % 7;
          if (daysToAdd <= 0) {
            daysToAdd += 7;
          }
          final nextDate = current.add(Duration(days: daysToAdd));
          return DateFormatter.formatIsoDate(nextDate);
        } else {
          final nextDate = current.add(const Duration(days: 7));
          return DateFormatter.formatIsoDate(nextDate);
        }
    }
  }

  /// Generates a deterministic, unique Due document ID for a given schedule occurrence.
  /// Guarantees exact idempotency so multiple generation runs never create duplicate dues.
  static String generateOccurrenceDueId(
      String scheduleId, String occurrenceDate) {
    return 'due_${scheduleId}_$occurrenceDate';
  }

  /// Evaluates whether a schedule is valid and eligible for generating a due on [targetDateStr].
  static bool isScheduleEligibleForDate({
    required RecurringDueScheduleEntity schedule,
    required String targetDateStr,
  }) {
    if (!schedule.isActive) return false;
    if (targetDateStr.compareTo(schedule.startDate) < 0) return false;
    if (schedule.endDate != null &&
        schedule.endDate!.isNotEmpty &&
        targetDateStr.compareTo(schedule.endDate!) > 0) {
      return false;
    }
    return true;
  }
}
