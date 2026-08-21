import 'dart:async';
import 'package:dueit/features/dues/domain/entities/recurring_due_schedule_entity.dart';
import 'package:dueit/features/dues/domain/repositories/recurring_due_repository.dart';

class FakeRecurringDueRepository implements RecurringDueRepository {
  final String ownerId;
  final List<RecurringDueScheduleEntity> _schedules = [];
  final StreamController<List<RecurringDueScheduleEntity>> _streamController =
      StreamController<List<RecurringDueScheduleEntity>>.broadcast();

  FakeRecurringDueRepository({
    required this.ownerId,
    List<RecurringDueScheduleEntity>? initialSchedules,
  }) {
    if (initialSchedules != null) {
      _schedules.addAll(initialSchedules);
    }
  }

  void _notify() {
    if (!_streamController.isClosed) {
      _streamController.add(List.unmodifiable(_schedules));
    }
  }

  @override
  Stream<List<RecurringDueScheduleEntity>> watchSchedules(String ownerId) {
    scheduleMicrotask(() => _notify());
    return _streamController.stream;
  }

  @override
  Future<List<RecurringDueScheduleEntity>> getSchedules(String ownerId) async {
    return List.unmodifiable(_schedules);
  }

  @override
  Future<RecurringDueScheduleEntity?> getSchedule(
    String ownerId,
    String scheduleId,
  ) async {
    try {
      return _schedules.firstWhere((s) => s.id == scheduleId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> createSchedule(
    String ownerId,
    RecurringDueScheduleEntity schedule,
  ) async {
    final toAdd = schedule.copyWith(
      ownerId: ownerId,
      businessId: ownerId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _schedules.removeWhere((s) => s.id == schedule.id);
    _schedules.add(toAdd);
    _notify();
  }

  @override
  Future<void> updateSchedule(
    String ownerId,
    RecurringDueScheduleEntity schedule,
  ) async {
    final index = _schedules.indexWhere((s) => s.id == schedule.id);
    if (index != -1) {
      _schedules[index] = schedule.copyWith(updatedAt: DateTime.now());
      _notify();
    }
  }

  @override
  Future<void> pauseSchedule(String ownerId, String scheduleId) async {
    final index = _schedules.indexWhere((s) => s.id == scheduleId);
    if (index != -1) {
      _schedules[index] = _schedules[index].copyWith(
        status: RecurringScheduleStatus.paused,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> resumeSchedule(String ownerId, String scheduleId) async {
    final index = _schedules.indexWhere((s) => s.id == scheduleId);
    if (index != -1) {
      _schedules[index] = _schedules[index].copyWith(
        status: RecurringScheduleStatus.active,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> stopSchedule(String ownerId, String scheduleId) async {
    final index = _schedules.indexWhere((s) => s.id == scheduleId);
    if (index != -1) {
      _schedules[index] = _schedules[index].copyWith(
        status: RecurringScheduleStatus.ended,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> deleteSchedule(String ownerId, String scheduleId) async {
    _schedules.removeWhere((s) => s.id == scheduleId);
    _notify();
  }

  void dispose() {
    _streamController.close();
  }
}
