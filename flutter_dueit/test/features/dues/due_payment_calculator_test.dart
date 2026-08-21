import 'package:flutter_test/flutter_test.dart';
import 'package:dueit/core/utils/date_formatter.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';
import 'package:dueit/features/dues/domain/entities/payment_record_entity.dart';
import 'package:dueit/features/dues/domain/services/due_payment_calculator.dart';

void main() {
  group('DuePaymentCalculator & Payment Domain Comprehensive Tests', () {
    final todayStr = DateFormatter.todayIsoDate();
    final yesterdayStr = DateFormatter.formatIsoDate(
        DateTime.now().subtract(const Duration(days: 1)));
    final tomorrowStr = DateFormatter.formatIsoDate(
        DateTime.now().add(const Duration(days: 1)));

    test('1. Payment serialization to Map', () {
      final payment = PaymentRecordEntity(
        id: 'pay_1',
        ownerId: 'user_1',
        businessId: 'user_1',
        dueId: 'due_100',
        customerId: 'cust_1',
        customerName: 'Rahul Kumar',
        amount: 1500.0,
        paymentMethod: PaymentMethod.upi,
        paidAt: todayStr,
        receiptNumber: 'REC-001',
        notes: 'GPay payment',
        createdAt: DateTime(2026, 8, 21),
      );

      final map = payment.toMap();
      expect(map['id'], 'pay_1');
      expect(map['ownerId'], 'user_1');
      expect(map['dueId'], 'due_100');
      expect(map['amount'], 1500.0);
      expect(map['paymentMethod'], 'upi');
      expect(map['paidAt'], todayStr);
      expect(map['receiptNumber'], 'REC-001');
      expect(map['notes'], 'GPay payment');
    });

    test('2. Payment deserialization from Map', () {
      final map = {
        'id': 'pay_2',
        'ownerId': 'user_1',
        'dueId': 'due_200',
        'customerId': 'cust_2',
        'amount': 2500.0,
        'paymentMethod': 'bankTransfer',
        'paidAt': '2026-08-20',
        'receiptNumber': 'REC-002',
        'notes': 'NEFT transfer',
        'createdAt': '2026-08-20T10:00:00.000Z',
      };

      final payment = PaymentRecordEntity.fromMap(map, docId: 'pay_2');
      expect(payment.id, 'pay_2');
      expect(payment.amount, 2500.0);
      expect(payment.paymentMethod, PaymentMethod.bankTransfer);
      expect(payment.paidAt, '2026-08-20');
      expect(payment.notes, 'NEFT transfer');
    });

    test('3. Total paid calculation for multiple payments on one due', () {
      final payments = [
        PaymentRecordEntity(
          id: 'p1',
          dueId: 'due_1',
          customerId: 'c1',
          amount: 2000.0,
          paymentMethod: PaymentMethod.cash,
          paidAt: todayStr,
        ),
        PaymentRecordEntity(
          id: 'p2',
          dueId: 'due_1',
          customerId: 'c1',
          amount: 1000.0,
          paymentMethod: PaymentMethod.upi,
          paidAt: todayStr,
        ),
        PaymentRecordEntity(
          id: 'p3',
          dueId: 'due_other',
          customerId: 'c2',
          amount: 5000.0,
          paymentMethod: PaymentMethod.cash,
          paidAt: todayStr,
        ),
      ];

      final totalPaid =
          DuePaymentCalculator.calculateTotalPaid('due_1', payments);
      expect(totalPaid, 3000.0);
    });

    test('4. Remaining calculation', () {
      expect(DuePaymentCalculator.calculateRemaining(5000.0, 3000.0), 2000.0);
      expect(DuePaymentCalculator.calculateRemaining(5000.0, 5000.0), 0.0);
      expect(DuePaymentCalculator.calculateRemaining(5000.0, 6000.0), 0.0);
    });

    test('5. PAID status when totalPaid equals or exceeds amount', () {
      final status = DuePaymentCalculator.calculateDueStatus(
        amount: 5000.0,
        totalPaid: 5000.0,
        dueDate: todayStr,
      );
      expect(status, DueStatus.paid);
    });

    test('6. PARTIALLY_PAID status when totalPaid > 0 and remaining > 0', () {
      final status = DuePaymentCalculator.calculateDueStatus(
        amount: 5000.0,
        totalPaid: 2000.0,
        dueDate: todayStr,
      );
      expect(status, DueStatus.partiallyPaid);
    });

    test(
        '7. OVERDUE with partial payment still reflects partial payment status priority',
        () {
      // Prompt specification: "PARTIALLY_PAID applies when paid > 0 and remaining > 0"
      final status = DuePaymentCalculator.calculateDueStatus(
        amount: 5000.0,
        totalPaid: 2000.0,
        dueDate: yesterdayStr,
      );
      expect(status, DueStatus.partiallyPaid);

      // Unpaid yesterday due is OVERDUE
      final unpaidOverdue = DuePaymentCalculator.calculateDueStatus(
        amount: 5000.0,
        totalPaid: 0.0,
        dueDate: yesterdayStr,
      );
      expect(unpaidOverdue, DueStatus.overdue);
    });

    test('8. DUE with partial payment reflects partial payment', () {
      final status = DuePaymentCalculator.calculateDueStatus(
        amount: 5000.0,
        totalPaid: 1000.0,
        dueDate: todayStr,
      );
      expect(status, DueStatus.partiallyPaid);

      // Unpaid today due is DUE
      final unpaidDue = DuePaymentCalculator.calculateDueStatus(
        amount: 5000.0,
        totalPaid: 0.0,
        dueDate: todayStr,
      );
      expect(unpaidDue, DueStatus.due);
    });

    test('9. UPCOMING with no payment is UPCOMING', () {
      final status = DuePaymentCalculator.calculateDueStatus(
        amount: 5000.0,
        totalPaid: 0.0,
        dueDate: tomorrowStr,
      );
      expect(status, DueStatus.upcoming);
    });

    test('10. CANCELLED always wins regardless of payment or dates', () {
      expect(
        DuePaymentCalculator.calculateDueStatus(
          amount: 5000.0,
          totalPaid: 5000.0,
          dueDate: yesterdayStr,
          isCancelled: true,
        ),
        DueStatus.cancelled,
      );
      expect(
        DuePaymentCalculator.calculateDueStatus(
          amount: 5000.0,
          totalPaid: 2000.0,
          dueDate: todayStr,
          isCancelled: true,
        ),
        DueStatus.cancelled,
      );
    });

    test(
        '11. Sequential payments on one due: Due ₹5,000 -> Pay ₹2,000 -> Pay ₹1,000 -> Pay ₹2,000',
        () {
      final due = DueEntity(
        id: 'due_seq',
        customerId: 'c1',
        amount: 5000.0,
        description: 'Coaching',
        dueDate: todayStr,
        status: DueStatus.due,
      );

      final p1 = PaymentRecordEntity(
          id: 'p1',
          dueId: 'due_seq',
          customerId: 'c1',
          amount: 2000.0,
          paymentMethod: PaymentMethod.cash,
          paidAt: todayStr);
      final p2 = PaymentRecordEntity(
          id: 'p2',
          dueId: 'due_seq',
          customerId: 'c1',
          amount: 1000.0,
          paymentMethod: PaymentMethod.upi,
          paidAt: todayStr);

      // After p1 & p2: Paid = 3000, Remaining = 2000, Status = partiallyPaid
      final enriched1 = DuePaymentCalculator.enrichDue(due, [p1, p2]);
      expect(enriched1.paidAmount, 3000.0);
      expect(enriched1.remainingAmount, 2000.0);
      expect(enriched1.status, DueStatus.partiallyPaid);

      // Add p3: 2000 -> Paid = 5000, Remaining = 0, Status = paid
      final p3 = PaymentRecordEntity(
          id: 'p3',
          dueId: 'due_seq',
          customerId: 'c1',
          amount: 2000.0,
          paymentMethod: PaymentMethod.bankTransfer,
          paidAt: todayStr);
      final enriched2 = DuePaymentCalculator.enrichDue(due, [p1, p2, p3]);
      expect(enriched2.paidAmount, 5000.0);
      expect(enriched2.remainingAmount, 0.0);
      expect(enriched2.status, DueStatus.paid);
    });

    test(
        '12. Payment deletion recalculation reverts due from PAID back to PARTIALLY_PAID',
        () {
      final due = DueEntity(
        id: 'due_del',
        customerId: 'c1',
        amount: 5000.0,
        description: 'Service',
        dueDate: todayStr,
        status: DueStatus.due,
      );

      final p1 = PaymentRecordEntity(
          id: 'p1',
          dueId: 'due_del',
          customerId: 'c1',
          amount: 3000.0,
          paymentMethod: PaymentMethod.cash,
          paidAt: todayStr);
      final p2 = PaymentRecordEntity(
          id: 'p2',
          dueId: 'due_del',
          customerId: 'c1',
          amount: 2000.0,
          paymentMethod: PaymentMethod.upi,
          paidAt: todayStr);

      // Initially paid
      final initial = DuePaymentCalculator.enrichDue(due, [p1, p2]);
      expect(initial.status, DueStatus.paid);

      // Remove p2 (deletion): only p1 remains
      final afterDeletion = DuePaymentCalculator.enrichDue(due, [p1]);
      expect(afterDeletion.paidAmount, 3000.0);
      expect(afterDeletion.remainingAmount, 2000.0);
      expect(afterDeletion.status, DueStatus.partiallyPaid);
    });

    test('13. Customer financial summary: Outstanding and Collected balances',
        () {
      final dues = [
        DueEntity(
            id: 'd1',
            customerId: 'c1',
            amount: 5000.0,
            paidAmount: 2000.0,
            description: 'Fee 1',
            dueDate: todayStr,
            status: DueStatus.partiallyPaid),
        DueEntity(
            id: 'd2',
            customerId: 'c1',
            amount: 3000.0,
            paidAmount: 3000.0,
            description: 'Fee 2',
            dueDate: yesterdayStr,
            status: DueStatus.paid),
        DueEntity(
            id: 'd3',
            customerId: 'c1',
            amount: 4000.0,
            paidAmount: 0.0,
            description: 'Cancelled',
            dueDate: todayStr,
            status: DueStatus.cancelled),
        DueEntity(
            id: 'd4',
            customerId: 'c2',
            amount: 8000.0,
            paidAmount: 0.0,
            description: 'Other customer',
            dueDate: todayStr,
            status: DueStatus.due),
      ];

      final payments = [
        PaymentRecordEntity(
            id: 'p1',
            dueId: 'd1',
            customerId: 'c1',
            amount: 2000.0,
            paymentMethod: PaymentMethod.cash,
            paidAt: todayStr),
        PaymentRecordEntity(
            id: 'p2',
            dueId: 'd2',
            customerId: 'c1',
            amount: 3000.0,
            paymentMethod: PaymentMethod.upi,
            paidAt: yesterdayStr),
        PaymentRecordEntity(
            id: 'p3',
            dueId: 'd4',
            customerId: 'c2',
            amount: 1000.0,
            paymentMethod: PaymentMethod.cash,
            paidAt: todayStr),
      ];

      final financials = DuePaymentCalculator.calculateCustomerFinancials(
          'c1', dues, payments);
      // c1 Collected: 2000 + 3000 = 5000
      expect(financials.collected, 5000.0);
      // c1 Outstanding: d1 remaining (3000); d2 is paid (0); d3 is cancelled (excluded)
      expect(financials.outstanding, 3000.0);
    });
  });
}
