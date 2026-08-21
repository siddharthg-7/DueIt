import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';
import 'package:dueit/features/reminders/data/services/local_notification_service.dart';
import 'package:dueit/features/reminders/domain/services/reminder_calculator.dart';

class FakeNotificationService implements NotificationService {
  final List<DueEntity> scheduledDues = [];
  final List<String> cancelledDueIds = [];
  bool allCancelled = false;
  bool permissionGranted = true;
  void Function(String? payload)? notificationTapCallback;

  @override
  Future<void> initialize({
    void Function(String? payload)? onNotificationTap,
  }) async {
    notificationTapCallback = onNotificationTap;
  }

  @override
  Future<bool> requestPermissions() async {
    return permissionGranted;
  }

  @override
  Future<bool> scheduleDueReminder(
    DueEntity due, {
    String? customerName,
  }) async {
    if (!due.reminderEnabled || due.reminderType == ReminderType.none) {
      await cancelReminderForDue(due.id);
      return false;
    }

    if (due.status == DueStatus.paid || due.status == DueStatus.cancelled) {
      await cancelReminderForDue(due.id);
      return false;
    }

    final scheduledDateTime = ReminderCalculator.calculateReminderDateTime(
      due.dueDate,
      due.reminderType,
    );

    if (scheduledDateTime == null) {
      await cancelReminderForDue(due.id);
      return false;
    }

    if (ReminderCalculator.isPastReminder(scheduledDateTime)) {
      await cancelReminderForDue(due.id);
      return false;
    }

    // Remove existing before re-adding
    scheduledDues.removeWhere((d) => d.id == due.id);
    scheduledDues.add(due);
    return true;
  }

  @override
  Future<void> cancelReminderForDue(String dueId) async {
    cancelledDueIds.add(dueId);
    scheduledDues.removeWhere((d) => d.id == dueId);
  }

  @override
  Future<void> cancelAllReminders() async {
    allCancelled = true;
    scheduledDues.clear();
  }

  @override
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return scheduledDues.map((d) {
      return PendingNotificationRequest(
        ReminderCalculator.generateNotificationId(d.id),
        ReminderCalculator.buildNotificationTitle(dueDateStr: d.dueDate),
        d.description,
        d.id,
      );
    }).toList();
  }

  void triggerNotificationTap(String dueId) {
    notificationTapCallback?.call(dueId);
  }
}
