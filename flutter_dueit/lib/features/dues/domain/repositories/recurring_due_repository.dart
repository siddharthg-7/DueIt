import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/recurring_due_repository_impl.dart';
import '../entities/recurring_due_schedule_entity.dart';

/// Abstract repository interface for Recurring Due Schedules
abstract class RecurringDueRepository {
  /// Emits real-time updates for all recurring schedules owned by [ownerId]
  Stream<List<RecurringDueScheduleEntity>> watchSchedules(String ownerId);

  /// Retrieves a snapshot list of all recurring schedules owned by [ownerId]
  Future<List<RecurringDueScheduleEntity>> getSchedules(String ownerId);

  /// Retrieves a single recurring schedule by ID
  Future<RecurringDueScheduleEntity?> getSchedule(
      String ownerId, String scheduleId);

  /// Creates a new recurring schedule in Firestore
  Future<void> createSchedule(
      String ownerId, RecurringDueScheduleEntity schedule);

  /// Updates an existing recurring schedule in Firestore
  Future<void> updateSchedule(
      String ownerId, RecurringDueScheduleEntity schedule);

  /// Pauses a recurring schedule (stops future automatic generation)
  Future<void> pauseSchedule(String ownerId, String scheduleId);

  /// Resumes a paused recurring schedule
  Future<void> resumeSchedule(String ownerId, String scheduleId);

  /// Stops / Ends a recurring schedule permanently
  Future<void> stopSchedule(String ownerId, String scheduleId);

  /// Deletes a recurring schedule document
  Future<void> deleteSchedule(String ownerId, String scheduleId);
}

/// Global provider for RecurringDueRepository
final recurringDueRepositoryProvider = Provider<RecurringDueRepository>((ref) {
  return RecurringDueRepositoryImpl();
});
