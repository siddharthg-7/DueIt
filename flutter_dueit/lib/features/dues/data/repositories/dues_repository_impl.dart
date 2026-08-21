import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/due_entity.dart';
import '../../domain/entities/payment_record_entity.dart';
import '../../domain/repositories/dues_repository.dart';

class DuesRepositoryImpl implements DuesRepository {
  final FirebaseFirestore _firestore;

  DuesRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _duesCollection(String ownerId) {
    return _firestore.collection('users').doc(ownerId).collection('dues');
  }

  @override
  Stream<List<DueEntity>> watchDues(String ownerId) {
    if (ownerId.isEmpty) {
      return Stream.value([]);
    }

    try {
      return _duesCollection(ownerId)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return DueEntity.fromMap(doc.data(), docId: doc.id);
        }).toList();
      }).handleError((error) {
        return <DueEntity>[];
      });
    } catch (_) {
      return Stream.value([]);
    }
  }

  @override
  Future<List<DueEntity>> getDues(String ownerId) async {
    if (ownerId.isEmpty) return [];
    try {
      final snapshot = await _duesCollection(ownerId)
          .orderBy('updatedAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        return DueEntity.fromMap(doc.data(), docId: doc.id);
      }).toList();
    } catch (e) {
      throw Exception(_mapFirestoreError(e));
    }
  }

  @override
  Future<DueEntity?> getDue({
    required String ownerId,
    required String dueId,
  }) async {
    if (ownerId.isEmpty || dueId.isEmpty) return null;
    try {
      final doc = await _duesCollection(ownerId).doc(dueId).get();
      if (!doc.exists || doc.data() == null) return null;
      return DueEntity.fromMap(doc.data()!, docId: doc.id);
    } catch (e) {
      throw Exception(_mapFirestoreError(e));
    }
  }

  @override
  Future<DueEntity> createDue(DueEntity due) async {
    if (due.ownerId.isEmpty) {
      throw Exception('Cannot create due without authenticated owner.');
    }
    if (due.amount <= 0) {
      throw Exception('Due amount must be greater than zero.');
    }
    if (due.customerId.isEmpty) {
      throw Exception('Customer must be selected for due.');
    }

    try {
      final collection = _duesCollection(due.ownerId);
      final docRef =
          due.id.isNotEmpty ? collection.doc(due.id) : collection.doc();

      final now = DateTime.now();
      final dueToSave = due.copyWith(
        id: docRef.id,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(dueToSave.toMap());
      return dueToSave;
    } catch (e) {
      throw Exception(_mapFirestoreError(e));
    }
  }

  @override
  Future<DueEntity> updateDue(DueEntity due) async {
    if (due.ownerId.isEmpty || due.id.isEmpty) {
      throw Exception('Due identification missing.');
    }
    if (due.amount <= 0) {
      throw Exception('Due amount must be greater than zero.');
    }

    try {
      final now = DateTime.now();
      final updatedDue = due.copyWith(
        updatedAt: now,
      );
      await _duesCollection(due.ownerId)
          .doc(due.id)
          .set(updatedDue.toMap(), SetOptions(merge: true));
      return updatedDue;
    } catch (e) {
      throw Exception(_mapFirestoreError(e));
    }
  }

  @override
  Future<void> deleteDue({
    required String ownerId,
    required String dueId,
  }) async {
    if (ownerId.isEmpty || dueId.isEmpty) {
      throw Exception('Due identification missing for deletion.');
    }
    try {
      await _duesCollection(ownerId).doc(dueId).delete();
    } catch (e) {
      throw Exception(_mapFirestoreError(e));
    }
  }

  @override
  Future<void> cancelDue({
    required String ownerId,
    required String dueId,
  }) async {
    if (ownerId.isEmpty || dueId.isEmpty) {
      throw Exception('Due identification missing for cancellation.');
    }
    try {
      await _duesCollection(ownerId).doc(dueId).update({
        'status': DueStatus.cancelled.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception(_mapFirestoreError(e));
    }
  }

  @override
  Future<List<PaymentRecordEntity>> getPayments([String? ownerId]) async {
    // Payments feature ledger placeholder for Step 7
    return [];
  }

  @override
  Future<PaymentRecordEntity> recordPayment({
    required String dueId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    throw UnimplementedError('Payment recording is scheduled for Step 7.');
  }

  String _mapFirestoreError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Permission denied. Please verify your login status.';
        case 'unavailable':
          return 'Firestore is temporarily unavailable. Please check your connection.';
        default:
          return error.message ??
              'A database error occurred. Please try again.';
      }
    }
    var msg = error.toString();
    if (msg.startsWith('Exception: ')) {
      msg = msg.substring(11);
    }
    return msg;
  }
}
