import 'package:flutter/foundation.dart';
import 'package:dueit/core/utils/date_formatter.dart';
import 'package:dueit/features/reminders/data/services/local_notification_service.dart';
import '../entities/due_entity.dart';
import '../entities/recurring_due_schedule_entity.dart';
import '../repositories/dues_repository.dart';
import '../repositories/recurring_due_repository.dart';
import 'recurrence_calculator.dart';

/// Pure application service that orchestrates the generation of Due records
/// from active recurring collection schedules with deterministic duplicate prevention.
class RecurringDueGenerationService {
  final DuesRepository _duesRepository;
  final RecurringDueRepository _recurringRepository;
  final NotificationService? _notificationService;

  RecurringDueGenerationService({
    required DuesRepository duesRepository,
    required RecurringDueRepository recurringRepository,
    NotificationService? notificationService,
  })  : _duesRepository = duesRepository,
        _recurringRepository = recurringRepository,
        _notificationService = notificationService;

  /// Inspects all active schedules for [ownerId], generating missing Due occurrences
  /// up to [referenceDateStr] (defaults to today) while strictly observing idempotency
  /// and the catch-up safety limit.
  Future<int> generatePendingDues({
    required String ownerId,
    List<RecurringDueScheduleEntity>? schedules,
    String? referenceDateStr,
  }) async {
    if (ownerId.isEmpty) return 0;

    final targetDateStr = referenceDateStr ?? DateFormatter.todayIsoDate();
    final activeSchedules = schedules ??
        (await _recurringRepository.getSchedules(ownerId))
            .where((s) => s.isActive)
            .toList();

    int generatedCount = 0;

    for (var schedule in activeSchedules) {
      if (!schedule.isActive) continue;

      String checkDate = schedule.nextDueDate;
      int cycles = 0;
      bool scheduleUpdated = false;

      while (checkDate.compareTo(targetDateStr) <= 0 &&
          cycles < RecurrenceCalculator.maxCatchUpCycles) {
        // Check end date boundary
        if (!RecurrenceCalculator.isScheduleEligibleForDate(
          schedule: schedule,
          targetDateStr: checkDate,
        )) {
          // If schedule passed its end date, mark it ended
          if (schedule.endDate != null &&
              checkDate.compareTo(schedule.endDate!) > 0) {
            await _recurringRepository.stopSchedule(ownerId, schedule.id);
          }
          break;
        }

        final deterministicDueId = RecurrenceCalculator.generateOccurrenceDueId(
          schedule.id,
          checkDate,
        );

        // Check if this occurrence Due already exists (Idempotency)
        DueEntity? existingDue;
        try {
          existingDue = await _duesRepository.getDue(
            ownerId: ownerId,
            dueId: deterministicDueId,
          );
        } catch (_) {
          existingDue = null;
        }

        if (existingDue == null) {
          final newDue = DueEntity(
            id: deterministicDueId,
            ownerId: ownerId,
            businessId: ownerId,
            customerId: schedule.customerId,
            customerName: schedule.customerName,
            amount: schedule.amount,
            paidAmount: 0.0,
            description: schedule.description,
            dueDate: checkDate,
            status: DueEntity.deriveStatus(dueDate: checkDate),
            reminderType: schedule.reminderType,
            reminderEnabled: schedule.reminderEnabled,
            recurrence: RecurrenceType.none,
            recurringScheduleId: schedule.id,
            occurrenceDate: checkDate,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          try {
            await _duesRepository.createDue(newDue);
            generatedCount++;

            // Schedule notification if reminder enabled
            if (_notificationService != null && schedule.reminderEnabled) {
              try {
                await _notificationService.scheduleDueReminder(
                  newDue,
                  customerName: schedule.customerName,
                );
              } catch (notifErr) {
                debugPrint(
                    'Notification scheduling notice on generation: $notifErr');
              }
            }
          } catch (e) {
            debugPrint('Error generating due for schedule ${schedule.id}: $e');
            break;
          }
        }

        // Advance to next period
        final nextDate = RecurrenceCalculator.calculateNextDueDate(
          currentDueDateStr: checkDate,
          frequency: schedule.frequency,
          originalDayOfMonth: schedule.dayOfMonth,
          dayOfWeek: schedule.dayOfWeek,
        );

        schedule = schedule.copyWith(nextDueDate: nextDate);
        checkDate = nextDate;
        cycles++;
        scheduleUpdated = true;
      }

      if (scheduleUpdated) {
        try {
          await _recurringRepository.updateSchedule(ownerId, schedule);
        } catch (e) {
          debugPrint(
              'Error advancing nextDueDate on schedule ${schedule.id}: $e');
        }
      }
    }

    return generatedCount;
  }
}
