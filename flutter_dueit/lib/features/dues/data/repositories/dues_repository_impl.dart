import 'package:uuid/uuid.dart';
import '../../domain/entities/due_entity.dart';
import '../../domain/entities/payment_record_entity.dart';
import '../../domain/repositories/dues_repository.dart';

class DuesRepositoryImpl implements DuesRepository {
  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String _offsetDateStr(int days) {
    final d = DateTime.now().add(Duration(days: days));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  final List<DueEntity> _dues = [
    DueEntity(
      id: 'due_1',
      customerId: 'cust_1',
      customerName: 'Rahul Kumar',
      amount: 1500,
      paidAmount: 0,
      description: 'August Advanced Karate Fee',
      dueDate: _todayStr(),
      status: DueStatus.due,
      recurrence: RecurrenceType.monthly,
    ),
    DueEntity(
      id: 'due_2',
      customerId: 'cust_2',
      customerName: 'Sneha Reddy',
      amount: 2200,
      paidAmount: 0,
      description: 'Weekend Kids Batch Fee',
      dueDate: _offsetDateStr(-4),
      status: DueStatus.overdue,
      recurrence: RecurrenceType.monthly,
    ),
    DueEntity(
      id: 'due_3',
      customerId: 'cust_3',
      customerName: 'Vikram Malhotra',
      amount: 5000,
      paidAmount: 2000,
      description: 'Personal Training Retainer',
      dueDate: _todayStr(),
      status: DueStatus.partiallyPaid,
      recurrence: RecurrenceType.monthly,
    ),
    DueEntity(
      id: 'due_4',
      customerId: 'cust_4',
      customerName: 'Pooja Sharma',
      amount: 1200,
      paidAmount: 0,
      description: 'Yoga Evening Session',
      dueDate: _offsetDateStr(3),
      status: DueStatus.upcoming,
      recurrence: RecurrenceType.monthly,
    ),
    DueEntity(
      id: 'due_5',
      customerId: 'cust_5',
      customerName: 'Amitabh Sen',
      amount: 1500,
      paidAmount: 1500,
      description: 'July Karate Fee',
      dueDate: _offsetDateStr(-30),
      status: DueStatus.paid,
      paidAt: _offsetDateStr(-28),
      paymentMethod: 'UPI',
    ),
  ];

  final List<PaymentRecordEntity> _payments = [
    PaymentRecordEntity(
      id: 'pay_init_1',
      dueId: 'due_3',
      customerId: 'cust_3',
      customerName: 'Vikram Malhotra',
      amount: 2000,
      paymentMethod: PaymentMethod.upi,
      paidAt: DateTime.now().toIso8601String(),
      receiptNumber: 'REC-2026-0010',
      notes: 'Partial advance payment via GPay',
    ),
    PaymentRecordEntity(
      id: 'pay_init_2',
      dueId: 'due_5',
      customerId: 'cust_5',
      customerName: 'Amitabh Sen',
      amount: 1500,
      paymentMethod: PaymentMethod.upi,
      paidAt: DateTime.now().subtract(const Duration(days: 28)).toIso8601String(),
      receiptNumber: 'REC-2026-0005',
      notes: 'Full settlement on time',
    ),
  ];

  @override
  Future<List<DueEntity>> getDues() async {
    return List.unmodifiable(_dues);
  }

  @override
  Future<DueEntity> createDue(DueEntity due) async {
    _dues.insert(0, due);
    return due;
  }

  @override
  Future<DueEntity> updateDue(DueEntity due) async {
    final index = _dues.indexWhere((d) => d.id == due.id);
    if (index != -1) {
      _dues[index] = due;
    }
    return due;
  }

  @override
  Future<void> deleteDue(String id) async {
    _dues.removeWhere((d) => d.id == id);
    _payments.removeWhere((p) => p.dueId == id);
  }

  @override
  Future<void> cancelDue(String id) async {
    final index = _dues.indexWhere((d) => d.id == id);
    if (index != -1) {
      _dues[index] = _dues[index].copyWith(status: DueStatus.cancelled);
    }
  }

  @override
  Future<List<PaymentRecordEntity>> getPayments() async {
    return List.unmodifiable(_payments);
  }

  @override
  Future<PaymentRecordEntity> recordPayment({
    required String dueId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    final index = _dues.indexWhere((d) => d.id == dueId);
    if (index == -1) {
      throw Exception('Due not found with id: $dueId');
    }

    final targetDue = _dues[index];
    final newPaidAmount = targetDue.paidAmount + amount;
    final isFullyPaid = newPaidAmount >= targetDue.amount;
    final now = DateTime.now();

    final receiptNumber = 'REC-${now.year}-${(1000 + (now.millisecondsSinceEpoch % 9000))}';

    final record = PaymentRecordEntity(
      id: 'pay_${const Uuid().v4().substring(0, 8)}',
      dueId: dueId,
      customerId: targetDue.customerId,
      customerName: targetDue.customerName,
      amount: amount,
      paymentMethod: paymentMethod,
      paidAt: now.toIso8601String(),
      receiptNumber: receiptNumber,
      notes: notes,
    );

    _payments.insert(0, record);

    // Update target due
    _dues[index] = targetDue.copyWith(
      paidAmount: newPaidAmount,
      status: isFullyPaid ? DueStatus.paid : DueStatus.partiallyPaid,
      paidAt: isFullyPaid ? now.toIso8601String() : targetDue.paidAt,
      paymentMethod: paymentMethod.displayName,
    );

    // Auto-schedule recurrence if fully settled
    if (isFullyPaid && targetDue.recurrence != RecurrenceType.none) {
      DateTime currentDueDate = DateTime.parse(targetDue.dueDate);
      DateTime nextDueDate;

      if (targetDue.recurrence == RecurrenceType.weekly) {
        nextDueDate = currentDueDate.add(const Duration(days: 7));
      } else if (targetDue.recurrence == RecurrenceType.monthly) {
        nextDueDate = DateTime(currentDueDate.year, currentDueDate.month + 1, currentDueDate.day);
      } else {
        nextDueDate = DateTime(currentDueDate.year + 1, currentDueDate.month, currentDueDate.day);
      }

      final nextDateStr =
          '${nextDueDate.year}-${nextDueDate.month.toString().padLeft(2, '0')}-${nextDueDate.day.toString().padLeft(2, '0')}';

      final recurringInstance = DueEntity(
        id: 'due_${const Uuid().v4().substring(0, 8)}',
        customerId: targetDue.customerId,
        customerName: targetDue.customerName,
        amount: targetDue.amount,
        paidAmount: 0,
        description: targetDue.description,
        dueDate: nextDateStr,
        status: nextDateStr == _todayStr() ? DueStatus.due : DueStatus.upcoming,
        reminderType: targetDue.reminderType,
        reminderEnabled: targetDue.reminderEnabled,
        recurrence: targetDue.recurrence,
        recurringCycle: targetDue.recurringCycle + 1,
      );

      _dues.insert(0, recurringInstance);
    }

    return record;
  }
}
