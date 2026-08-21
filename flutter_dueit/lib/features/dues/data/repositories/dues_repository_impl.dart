import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/due_entity.dart';
import '../../domain/entities/payment_record_entity.dart';
import '../../domain/repositories/dues_repository.dart';
import '../../domain/services/due_payment_calculator.dart';

class DuesRepositoryImpl implements DuesRepository {
  final FirebaseFirestore _firestore;

  DuesRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _duesCollection(String ownerId) {
    return _firestore.collection('users').doc(ownerId).collection('dues');
  }

  CollectionReference<Map<String, dynamic>> _paymentsCollection(
      String ownerId) {
    return _firestore.collection('users').doc(ownerId).collection('payments');
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
      }).handleError((_) {
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

  // ==========================================
  // Payments Subcollection: users/{uid}/payments
  // ==========================================

  @override
  Stream<List<PaymentRecordEntity>> watchPayments(String ownerId) {
    if (ownerId.isEmpty) {
      return Stream.value([]);
    }

    try {
      return _paymentsCollection(ownerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return PaymentRecordEntity.fromMap(doc.data(), docId: doc.id);
        }).toList();
      }).handleError((_) {
        return <PaymentRecordEntity>[];
      });
    } catch (_) {
      return Stream.value([]);
    }
  }

  @override
  Future<List<PaymentRecordEntity>> getPayments([String? ownerId]) async {
    if (ownerId == null || ownerId.isEmpty) return [];
    try {
      final snapshot = await _paymentsCollection(ownerId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        return PaymentRecordEntity.fromMap(doc.data(), docId: doc.id);
      }).toList();
    } catch (e) {
      throw Exception(_mapFirestoreError(e));
    }
  }

  @override
  Future<PaymentRecordEntity> recordPayment(PaymentRecordEntity payment) async {
    if (payment.ownerId.isEmpty) {
      throw Exception('Cannot record payment without authenticated owner.');
    }
    if (payment.amount <= 0) {
      throw Exception('Please enter a valid amount greater than ₹0.');
    }
    if (payment.dueId.isEmpty) {
      throw Exception('Payment must be associated with a due record.');
    }

    try {
      // 1. Verify Due exists and belongs to owner
      final dueDoc =
          await _duesCollection(payment.ownerId).doc(payment.dueId).get();
      if (!dueDoc.exists || dueDoc.data() == null) {
        throw Exception('Associated due record not found.');
      }
      final due = DueEntity.fromMap(dueDoc.data()!, docId: dueDoc.id);

      if (due.isCancelled) {
        throw Exception('Cannot record payment for a cancelled due.');
      }

      // 2. Fetch existing payments for this due to verify remaining amount
      final existingPaymentsSnapshot =
          await _paymentsCollection(payment.ownerId)
              .where('dueId', isEqualTo: payment.dueId)
              .get();
      final existingPayments = existingPaymentsSnapshot.docs
          .map((doc) => PaymentRecordEntity.fromMap(doc.data(), docId: doc.id))
          .toList();

      final totalPaidAlready =
          DuePaymentCalculator.calculateTotalPaid(due.id, existingPayments);
      final remaining =
          DuePaymentCalculator.calculateRemaining(due.amount, totalPaidAlready);

      if (payment.amount > remaining + 0.001) {
        throw Exception('Payment cannot be greater than the remaining amount.');
      }

      // 3. Save payment record
      final docRef = payment.id.isNotEmpty
          ? _paymentsCollection(payment.ownerId).doc(payment.id)
          : _paymentsCollection(payment.ownerId).doc();

      final now = DateTime.now();
      final paymentToSave = payment.copyWith(
        id: docRef.id,
        createdAt: now,
      );

      await docRef.set(paymentToSave.toMap());
      return paymentToSave;
    } catch (e) {
      throw Exception(_mapFirestoreError(e));
    }
  }

  @override
  Future<void> deletePayment({
    required String ownerId,
    required String paymentId,
  }) async {
    if (ownerId.isEmpty || paymentId.isEmpty) {
      throw Exception('Payment identification missing for deletion.');
    }
    try {
      await _paymentsCollection(ownerId).doc(paymentId).delete();
    } catch (e) {
      throw Exception(_mapFirestoreError(e));
    }
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
