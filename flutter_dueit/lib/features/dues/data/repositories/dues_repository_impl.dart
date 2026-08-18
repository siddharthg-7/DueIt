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
    // Today's Dues (5 payments = ₹8,500)
    DueEntity(
      id: 'due_1',
      customerId: 'cust_1',
      customerName: 'Rahul Kumar',
      amount: 1500,
      paidAmount: 0,
      description: 'August Karate Fee',
      dueDate: _todayStr(),
      status: DueStatus.due,
      recurrence: RecurrenceType.monthly,
    ),
    DueEntity(
      id: 'due_2',
      customerId: 'cust_2',
      customerName: 'Arjun Sharma',
      amount: 2000,
      paidAmount: 0,
      description: 'Monthly Membership',
      dueDate: _todayStr(),
      status: DueStatus.due,
      recurrence: RecurrenceType.monthly,
    ),
    DueEntity(
      id: 'due_3',
      customerId: 'cust_5',
      customerName: 'Pooja Sharma',
      amount: 1800,
      paidAmount: 0,
      description: 'Yoga Monthly Pass',
      dueDate: _todayStr(),
      status: DueStatus.due,
      recurrence: RecurrenceType.monthly,
    ),
    DueEntity(
      id: 'due_4',
      customerId: 'cust_6',
      customerName: 'Amitabh Sen',
      amount: 1700,
      paidAmount: 0,
      description: 'Karate Training',
      dueDate: _todayStr(),
      status: DueStatus.due,
      recurrence: RecurrenceType.monthly,
    ),
    DueEntity(
      id: 'due_5',
      customerId: 'cust_1',
      customerName: 'Ritu Verma',
      amount: 1500,
      paidAmount: 0,
      description: 'Music Class',
      dueDate: _todayStr(),
      status: DueStatus.due,
      recurrence: RecurrenceType.monthly,
    ),

    // Overdue Dues (₹4,000)
    DueEntity(
      id: 'due_6',
      customerId: 'cust_4',
      customerName: 'Vikram Rao',
      amount: 2500,
      paidAmount: 0,
      description: 'Monthly Training',
      dueDate: _offsetDateStr(-5),
      status: DueStatus.overdue,
      recurrence: RecurrenceType.monthly,
    ),
    DueEntity(
      id: 'due_7',
      customerId: 'cust_3',
      customerName: 'Sneha Reddy',
      amount: 1500,
      paidAmount: 0,
      description: 'Karate Uniform & Gear',
      dueDate: _offsetDateStr(-8),
      status: DueStatus.overdue,
      recurrence: RecurrenceType.none,
    ),

    // Upcoming Dues (₹18,500)
    DueEntity(
      id: 'due_8',
      customerId: 'cust_1',
      customerName: 'Rahul Kumar',
      amount: 1500,
      paidAmount: 0,
      description: 'September Karate Fee',
      dueDate: _offsetDateStr(5),
      status: DueStatus.upcoming,
      recurrence: RecurrenceType.monthly,
    ),
    DueEntity(
      id: 'due_9',
      customerId: 'cust_2',
      customerName: 'Amit Shah',
      amount: 5000,
      paidAmount: 0,
      description: 'Quarterly Coaching',
      dueDate: _offsetDateStr(10),
      status: DueStatus.upcoming,
      recurrence: RecurrenceType.monthly,
    ),
    DueEntity(
      id: 'due_10',
      customerId: 'cust_4',
      customerName: 'Priya Nair',
      amount: 4500,
      paidAmount: 0,
      description: '3-Month Gym Membership',
      dueDate: _offsetDateStr(14),
      status: DueStatus.upcoming,
      recurrence: RecurrenceType.monthly,
    ),
    DueEntity(
      id: 'due_11',
      customerId: 'cust_5',
      customerName: 'Deepak Joshi',
      amount: 7500,
      paidAmount: 0,
      description: 'Annual Access Pass',
      dueDate: _offsetDateStr(20),
      status: DueStatus.upcoming,
      recurrence: RecurrenceType.monthly,
    ),

    // Paid Dues
    DueEntity(
      id: 'due_12',
      customerId: 'cust_3',
      customerName: 'Sneha Reddy',
      amount: 1500,
      paidAmount: 1500,
      description: 'August Tuition',
      dueDate: _offsetDateStr(-10),
      status: DueStatus.paid,
      paidAt: _offsetDateStr(-9),
      paymentMethod: 'UPI',
    ),
  ];

  final List<PaymentRecordEntity> _payments = [
    PaymentRecordEntity(
      id: 'pay_init_1',
      dueId: 'due_12',
      customerId: 'cust_3',
      customerName: 'Sneha Reddy',
      amount: 1500,
      paymentMethod: PaymentMethod.upi,
      paidAt:
          DateTime.now().subtract(const Duration(days: 9)).toIso8601String(),
      receiptNumber: 'REC-2026-0012',
      notes: 'Settled via UPI',
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

    final receiptNumber =
        'REC-${now.year}-${(1000 + (now.millisecondsSinceEpoch % 9000))}';

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

    return record;
  }
}
