import '../entities/due_entity.dart';
import '../entities/payment_record_entity.dart';

abstract class DuesRepository {
  Future<List<DueEntity>> getDues();
  Future<DueEntity> createDue(DueEntity due);
  Future<DueEntity> updateDue(DueEntity due);
  Future<void> deleteDue(String id);
  Future<void> cancelDue(String id);

  // Payments Ledger
  Future<List<PaymentRecordEntity>> getPayments();
  Future<PaymentRecordEntity> recordPayment({
    required String dueId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? notes,
  });
}
