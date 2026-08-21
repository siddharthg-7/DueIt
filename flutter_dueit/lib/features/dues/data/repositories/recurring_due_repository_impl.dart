import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/recurring_due_schedule_entity.dart';
import '../../domain/repositories/recurring_due_repository.dart';

/// Production Firestore implementation of RecurringDueRepository
/// Path: users/{uid}/recurring_due_schedules/{scheduleId}
class RecurringDueRepositoryImpl implements RecurringDueRepository {
  final FirebaseFirestore _firestore;

  RecurringDueRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _schedulesCollection(
      String ownerId) {
    return _firestore
        .collection('users')
        .doc(ownerId)
        .collection('recurring_due_schedules');
  }

  @override
  Stream<List<RecurringDueScheduleEntity>> watchSchedules(String ownerId) {
    if (ownerId.isEmpty) {
      return Stream.value([]);
    }

    try {
      return _schedulesCollection(ownerId)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return RecurringDueScheduleEntity.fromMap(doc.data(), docId: doc.id);
        }).toList();
      }).handleError((_) {
        return <RecurringDueScheduleEntity>[];
      });
    } catch (_) {
      return Stream.value([]);
    }
  }

  @override
  Future<List<RecurringDueScheduleEntity>> getSchedules(String ownerId) async {
    if (ownerId.isEmpty) return [];
    try {
      final snapshot = await _schedulesCollection(ownerId)
          .orderBy('updatedAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        return RecurringDueScheduleEntity.fromMap(doc.data(), docId: doc.id);
      }).toList();
    } catch (e) {
      throw Exception(_mapFirestoreError(e));
    }
  }

  @override
  Future<RecurringDueScheduleEntity?> getSchedule(
    String ownerId,
    String scheduleId,
  ) async {
    if (ownerId.isEmpty || scheduleId.isEmpty) return null;
    try {
      final doc = await _schedulesCollection(ownerId).doc(scheduleId).get();
      if (!doc.exists || doc.data() == null) return null;
      return RecurringDueScheduleEntity.fromMap(doc.data()!, docId: doc.id);
    } catch (e) {
      throw Exception(_mapFirestoreError(e));
    }
  }

  @override
  Future<void> createSchedule(
    String ownerId,
    RecurringDueScheduleEntity schedule,
  ) async {
    if (ownerId.isEmpty) {
      throw Exception(
          'Authentication required to create a recurring schedule.');
    }
    try {
      final docRef = schedule.id.isNotEmpty
          ? _schedulesCollection(ownerId).doc(schedule.id)
          : _schedulesCollection(ownerId).doc();

      final toSave = schedule.copyWith(
        id: docRef.id,
        ownerId: ownerId,
        businessId: ownerId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(toSave.toMap());
    } catch (e) {
      throw Exception(_mapFirestoreError(e));
    }
  }

  @override
  Future<void> updateSchedule(
    String ownerId,
    RecurringDueScheduleEntity schedule,
  ) async {
    if (ownerId.isEmpty || schedule.id.isEmpty) {
      throw Exception('Schedule ID and owner ID are required for updating.');
    }
    try {
      final toSave = schedule.copyWith(
        updatedAt: DateTime.now(),
      );
      await _schedulesCollection(ownerId).doc(schedule.id).set(
            toSave.toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      throw Exception(_mapFirestoreError(e));
    }
  }

  @override
  Future<void> pauseSchedule(String ownerId, String scheduleId) async {
    if (ownerId.isEmpty || scheduleId.isEmpty) return;
    try {
      await _schedulesCollection(ownerId).doc(scheduleId).update({
        'status': RecurringScheduleStatus.paused.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception(_mapFirestoreError(e));
    }
  }

  @override
  Future<void> resumeSchedule(String ownerId, String scheduleId) async {
    if (ownerId.isEmpty || scheduleId.isEmpty) return;
    try {
      await _schedulesCollection(ownerId).doc(scheduleId).update({
        'status': RecurringScheduleStatus.active.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception(_mapFirestoreError(e));
    }
  }

  @override
  Future<void> stopSchedule(String ownerId, String scheduleId) async {
    if (ownerId.isEmpty || scheduleId.isEmpty) return;
    try {
      await _schedulesCollection(ownerId).doc(scheduleId).update({
        'status': RecurringScheduleStatus.ended.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception(_mapFirestoreError(e));
    }
  }

  @override
  Future<void> deleteSchedule(String ownerId, String scheduleId) async {
    if (ownerId.isEmpty || scheduleId.isEmpty) return;
    try {
      await _schedulesCollection(ownerId).doc(scheduleId).delete();
    } catch (e) {
      throw Exception(_mapFirestoreError(e));
    }
  }

  String _mapFirestoreError(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Permission denied. You can only access your own schedules.';
        case 'unavailable':
          return 'Network unavailable. Please check your internet connection.';
        case 'not-found':
          return 'Schedule record not found.';
        default:
          return error.message ?? 'A database error occurred.';
      }
    }
    return error.toString();
  }
}
