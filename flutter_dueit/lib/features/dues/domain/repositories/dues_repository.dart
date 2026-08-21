import '../entities/due_entity.dart';
import '../entities/payment_record_entity.dart';

abstract class DuesRepository {
  Stream<List<DueEntity>> watchDues(String ownerId);
  Future<List<DueEntity>> getDues(String ownerId);
  Future<DueEntity?> getDue({
    required String ownerId,
    required String dueId,
  });
  Future<DueEntity> createDue(DueEntity due);
  Future<DueEntity> updateDue(DueEntity due);
  Future<void> deleteDue({
    required String ownerId,
    required String dueId,
  });
  Future<void> cancelDue({
    required String ownerId,
    required String dueId,
  });

  // Payments Ledger (For Step 7 / future integration)
  Future<List<PaymentRecordEntity>> getPayments([String? ownerId]);
  Future<PaymentRecordEntity> recordPayment({
    required String dueId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? notes,
  });
}
