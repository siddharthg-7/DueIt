import 'package:dueit/core/utils/currency_formatter.dart';
import 'package:dueit/core/utils/date_formatter.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';

/// Centralized pure calculation service for reminder scheduling, notification IDs,
/// date offsets, and notification content.
abstract class ReminderCalculator {
  /// Default hour for notification reminders (9:00 AM)
  static const int defaultReminderHour = 9;

  /// Default minute for notification reminders (00)
  static const int defaultReminderMinute = 0;

  /// Computes the target ISO date string ('YYYY-MM-DD') for a given reminder type.
  /// Returns `null` if reminder type is `none` or disabled.
  static String? calculateReminderDate(
    String dueDateStr,
    ReminderType reminderType,
  ) {
    if (reminderType == ReminderType.none) {
      return null;
    }

    final dueDate = DateFormatter.parseLocalDate(dueDateStr);

    switch (reminderType) {
      case ReminderType.none:
        return null;
      case ReminderType.onDueDate:
      case ReminderType.daily:
        return dueDateStr;
      case ReminderType.oneDayBefore:
        return DateFormatter.formatIsoDate(
          dueDate.subtract(const Duration(days: 1)),
        );
      case ReminderType.twoDaysBefore:
        return DateFormatter.formatIsoDate(
          dueDate.subtract(const Duration(days: 2)),
        );
      case ReminderType.threeDaysBefore:
        return DateFormatter.formatIsoDate(
          dueDate.subtract(const Duration(days: 3)),
        );
      case ReminderType.sevenDaysBefore:
        return DateFormatter.formatIsoDate(
          dueDate.subtract(const Duration(days: 7)),
        );
    }
  }

  /// Calculates the full local DateTime for when a notification should be scheduled.
  /// Returns `null` if reminder type is `none`.
  static DateTime? calculateReminderDateTime(
    String dueDateStr,
    ReminderType reminderType, {
    int hour = defaultReminderHour,
    int minute = defaultReminderMinute,
  }) {
    final targetDateStr = calculateReminderDate(dueDateStr, reminderType);
    if (targetDateStr == null) return null;

    final targetDate = DateFormatter.parseLocalDate(targetDateStr);
    return DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      hour,
      minute,
      0,
    );
  }

  /// Determines whether a calculated reminder datetime is already in the past.
  static bool isPastReminder(
    DateTime reminderDateTime, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    return reminderDateTime.isBefore(reference);
  }

  /// Generates a deterministic, positive 31-bit integer ID for local notifications
  /// based on the Due's unique ID using the standard 32-bit FNV-1a hash algorithm.
  ///
  /// Unlike Dart's runtime `Object.hashCode` (which is VM-implementation dependent
  /// and may vary across process restarts or build modes), FNV-1a produces an exact,
  /// immutable hash for the same string across all platforms, app restarts, and architectures.
  ///
  /// Range: [0, 2147483647] (signed 32-bit positive integer safe for Android NotificationManager).
  static int generateNotificationId(String dueId) {
    if (dueId.isEmpty) return 0;

    const int fnvOffsetBasis = 0x811C9DC5;
    const int fnvPrime = 0x01000193;

    int hash = fnvOffsetBasis;
    for (int i = 0; i < dueId.length; i++) {
      hash ^= dueId.codeUnitAt(i);
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }

    // Force to positive 31-bit integer range [0, 0x7FFFFFFF] (2,147,483,647)
    return hash & 0x7FFFFFFF;
  }

  /// Builds a concise, friendly notification title based on due date.
  static String buildNotificationTitle({
    required String dueDateStr,
    ReminderType reminderType = ReminderType.oneDayBefore,
  }) {
    if (DateFormatter.isToday(dueDateStr)) {
      return 'Payment due today';
    } else if (DateFormatter.isTomorrow(dueDateStr)) {
      return 'Payment due tomorrow';
    } else if (DateFormatter.isBeforeToday(dueDateStr)) {
      return 'Payment overdue';
    } else {
      return 'Payment reminder';
    }
  }

  /// Builds a clear notification body stating client name, remaining unpaid amount, and description.
  static String buildNotificationBody({
    required String customerName,
    required double remainingAmount,
    required String description,
  }) {
    final formattedAmount = CurrencyFormatter.format(remainingAmount);
    final cName =
        customerName.trim().isEmpty ? 'Customer' : customerName.trim();
    final desc = description.trim().isEmpty ? 'payment' : description.trim();
    return '$cName owes $formattedAmount for $desc.';
  }
}
