import 'package:flutter_test/flutter_test.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';
import 'package:dueit/features/dues/domain/entities/payment_record_entity.dart';
import 'package:dueit/features/dashboard/domain/services/dashboard_financial_calculator.dart';

void main() {
  group('DashboardFinancialCalculator Unit & Invariant Tests', () {
    final refDate = DateTime(2026, 8, 20); // Reference: 2026-08-20

    test('1. Today\'s due amount and count calculations', () {
      final dues = [
        DueEntity(
          id: 'd1',
          ownerId: 'u1',
          customerId: 'c1',
          customerName: 'Alice',
          amount: 5000.0,
          paidAmount: 1000.0,
          description: 'Fee 1',
          dueDate: '2026-08-20', // Today
          status: DueStatus.partiallyPaid,
        ),
        DueEntity(
          id: 'd2',
          ownerId: 'u1',
          customerId: 'c2',
          customerName: 'Bob',
          amount: 3000.0,
          paidAmount: 0.0,
          description: 'Fee 2',
          dueDate: '2026-08-20', // Today
          status: DueStatus.due,
        ),
        DueEntity(
          id: 'd3',
          ownerId: 'u1',
          customerId: 'c3',
          customerName: 'Charlie',
          amount: 2000.0,
          paidAmount: 2000.0,
          description: 'Fee 3',
          dueDate: '2026-08-20', // Today but fully paid
          status: DueStatus.paid,
        ),
      ];

      final metrics = DashboardFinancialCalculator.calculate(
        dues: dues,
        payments: [],
        referenceDate: refDate,
      );

      // (5000 - 1000) + 3000 = 7000
      expect(metrics.toCollectToday, 7000.0);
      expect(metrics.todayDuesCount, 2);
      expect(metrics.todayDues.length, 2);
    });

    test('2. Collected today calculation from payments recorded today', () {
      final payments = [
        PaymentRecordEntity(
          id: 'p1',
          ownerId: 'u1',
          dueId: 'd1',
          customerId: 'c1',
          amount: 1500.0,
          paymentMethod: PaymentMethod.upi,
          paidAt: '2026-08-20T10:30:00.000',
        ),
        PaymentRecordEntity(
          id: 'p2',
          ownerId: 'u1',
          dueId: 'd2',
          customerId: 'c2',
          amount: 2500.0,
          paymentMethod: PaymentMethod.cash,
          paidAt: '2026-08-20',
        ),
        PaymentRecordEntity(
          id: 'p3',
          ownerId: 'u1',
          dueId: 'd3',
          customerId: 'c3',
          amount: 1000.0,
          paymentMethod: PaymentMethod.bankTransfer,
          paidAt: '2026-08-19', // Yesterday
        ),
      ];

      final metrics = DashboardFinancialCalculator.calculate(
        dues: [],
        payments: payments,
        referenceDate: refDate,
      );

      expect(metrics.collectedToday, 4000.0);
    });

    test('3. Overdue amount and count across unique customers', () {
      final dues = [
        DueEntity(
          id: 'd1',
          ownerId: 'u1',
          customerId: 'c1',
          customerName: 'Alice',
          amount: 4000.0,
          paidAmount: 1000.0, // Remaining: 3000
          description: 'Overdue 1',
          dueDate: '2026-08-10',
          status: DueStatus.overdue,
        ),
        DueEntity(
          id: 'd2',
          ownerId: 'u1',
          customerId: 'c1', // Same customer
          customerName: 'Alice',
          amount: 2000.0,
          paidAmount: 0.0, // Remaining: 2000
          description: 'Overdue 2',
          dueDate: '2026-08-15',
          status: DueStatus.overdue,
        ),
        DueEntity(
          id: 'd3',
          ownerId: 'u1',
          customerId: 'c2', // Second customer
          customerName: 'Bob',
          amount: 1500.0,
          paidAmount: 0.0, // Remaining: 1500
          description: 'Overdue 3',
          dueDate: '2026-08-18',
          status: DueStatus.overdue,
        ),
      ];

      final metrics = DashboardFinancialCalculator.calculate(
        dues: dues,
        payments: [],
        referenceDate: refDate,
      );

      expect(metrics.overdueTotal, 6500.0);
      expect(metrics.overdueDuesCount, 3);
      expect(metrics.overdueCustomersCount, 2); // Alice & Bob
    });

    test('4. Upcoming amount within 30-day horizon', () {
      final dues = [
        DueEntity(
          id: 'd1',
          ownerId: 'u1',
          customerId: 'c1',
          amount: 3000.0,
          description: 'Next week',
          dueDate: '2026-08-25', // +5 days
          status: DueStatus.upcoming,
        ),
        DueEntity(
          id: 'd2',
          ownerId: 'u1',
          customerId: 'c2',
          amount: 5000.0,
          description: 'Next month inside horizon',
          dueDate: '2026-09-10', // +21 days
          status: DueStatus.upcoming,
        ),
        DueEntity(
          id: 'd3',
          ownerId: 'u1',
          customerId: 'c3',
          amount: 10000.0,
          description: 'Far future outside horizon',
          dueDate: '2026-11-20', // +92 days
          status: DueStatus.upcoming,
        ),
      ];

      final metrics = DashboardFinancialCalculator.calculate(
        dues: dues,
        payments: [],
        referenceDate: refDate,
      );

      // 3000 + 5000 = 8000 (10000 excluded by 30-day horizon)
      expect(metrics.upcomingTotal, 8000.0);
      expect(metrics.upcomingDuesCount, 2);
    });

    test(
        '5. Monthly collection planning metrics (Expected, Collected, Outstanding)',
        () {
      final dues = [
        DueEntity(
          id: 'd1',
          ownerId: 'u1',
          customerId: 'c1',
          amount: 6000.0,
          paidAmount: 2000.0, // Remaining: 4000
          description: 'August Due 1',
          dueDate: '2026-08-05',
          status: DueStatus.partiallyPaid,
        ),
        DueEntity(
          id: 'd2',
          ownerId: 'u1',
          customerId: 'c2',
          amount: 4000.0,
          paidAmount: 4000.0, // Remaining: 0
          description: 'August Due 2',
          dueDate: '2026-08-15',
          status: DueStatus.paid,
        ),
        DueEntity(
          id: 'd3',
          ownerId: 'u1',
          customerId: 'c3',
          amount: 8000.0,
          paidAmount: 0.0, // Remaining: 8000
          description: 'September Due',
          dueDate: '2026-09-01',
          status: DueStatus.upcoming,
        ),
      ];

      final payments = [
        PaymentRecordEntity(
          id: 'p1',
          ownerId: 'u1',
          dueId: 'd1',
          customerId: 'c1',
          amount: 2000.0,
          paymentMethod: PaymentMethod.upi,
          paidAt: '2026-08-06',
        ),
        PaymentRecordEntity(
          id: 'p2',
          ownerId: 'u1',
          dueId: 'd2',
          customerId: 'c2',
          amount: 4000.0,
          paymentMethod: PaymentMethod.cash,
          paidAt: '2026-08-15',
        ),
      ];

      final metrics = DashboardFinancialCalculator.calculate(
        dues: dues,
        payments: payments,
        referenceDate: refDate,
      );

      // Expected for August: 6000 + 4000 = 10000
      expect(metrics.expectedMonthTotal, 10000.0);

      // Collected in August: 2000 + 4000 = 6000
      expect(metrics.collectedMonthTotal, 6000.0);

      // Outstanding in August: 4000 + 0 = 4000
      expect(metrics.outstandingMonthTotal, 4000.0);

      // Collection Rate: 6000 / 10000 = 0.60 (60%)
      expect(metrics.collectionRate, 0.60);
    });

    test('6. Collection rate returns null when no current month dues exist',
        () {
      final metrics = DashboardFinancialCalculator.calculate(
        dues: [],
        payments: [],
        referenceDate: refDate,
      );

      expect(metrics.collectionRate, isNull);
    });

    test('7. Daily collection trend grouping', () {
      final payments = [
        PaymentRecordEntity(
          id: 'p1',
          ownerId: 'u1',
          dueId: 'd1',
          customerId: 'c1',
          amount: 2000.0,
          paymentMethod: PaymentMethod.upi,
          paidAt: '2026-08-01',
        ),
        PaymentRecordEntity(
          id: 'p2',
          ownerId: 'u1',
          dueId: 'd1',
          customerId: 'c1',
          amount: 1500.0,
          paymentMethod: PaymentMethod.cash,
          paidAt: '2026-08-03',
        ),
        PaymentRecordEntity(
          id: 'p3',
          ownerId: 'u1',
          dueId: 'd2',
          customerId: 'c2',
          amount: 2000.0,
          paymentMethod: PaymentMethod.upi,
          paidAt: '2026-08-03',
        ),
      ];

      final metrics = DashboardFinancialCalculator.calculate(
        dues: [],
        payments: payments,
        referenceDate: refDate,
      );

      expect(metrics.dailyTrend.length, 31); // August has 31 days

      final day1 = metrics.dailyTrend.firstWhere((p) => p.dayOfMonth == 1);
      final day2 = metrics.dailyTrend.firstWhere((p) => p.dayOfMonth == 2);
      final day3 = metrics.dailyTrend.firstWhere((p) => p.dayOfMonth == 3);

      expect(day1.amount, 2000.0);
      expect(day2.amount, 0.0);
      expect(day3.amount, 3500.0); // 1500 + 2000
    });

    test('8. Cancelled dues are excluded from all financial metrics', () {
      final dues = [
        DueEntity(
          id: 'd1',
          ownerId: 'u1',
          customerId: 'c1',
          amount: 5000.0,
          description: 'Cancelled Today Due',
          dueDate: '2026-08-20',
          status: DueStatus.cancelled,
        ),
        DueEntity(
          id: 'd2',
          ownerId: 'u1',
          customerId: 'c2',
          amount: 4000.0,
          description: 'Cancelled Overdue Due',
          dueDate: '2026-08-10',
          status: DueStatus.cancelled,
        ),
      ];

      final metrics = DashboardFinancialCalculator.calculate(
        dues: dues,
        payments: [],
        referenceDate: refDate,
      );

      expect(metrics.toCollectToday, 0.0);
      expect(metrics.overdueTotal, 0.0);
      expect(metrics.expectedMonthTotal, 0.0);
      expect(metrics.outstandingMonthTotal, 0.0);
    });

    test('9. Paid dues excluded from toCollectToday, overdue, and upcoming',
        () {
      final dues = [
        DueEntity(
          id: 'd1',
          ownerId: 'u1',
          customerId: 'c1',
          amount: 5000.0,
          paidAmount: 5000.0,
          description: 'Paid Today',
          dueDate: '2026-08-20',
          status: DueStatus.paid,
        ),
        DueEntity(
          id: 'd2',
          ownerId: 'u1',
          customerId: 'c2',
          amount: 4000.0,
          paidAmount: 4000.0,
          description: 'Paid Overdue',
          dueDate: '2026-08-10',
          status: DueStatus.paid,
        ),
      ];

      final metrics = DashboardFinancialCalculator.calculate(
        dues: dues,
        payments: [],
        referenceDate: refDate,
      );

      expect(metrics.toCollectToday, 0.0);
      expect(metrics.todayDuesCount, 0);
      expect(metrics.overdueTotal, 0.0);
      expect(metrics.overdueDuesCount, 0);
    });

    test(
        '10. Payment on old overdue due increases Collected Today without reducing Today\'s Due',
        () {
      final dues = [
        DueEntity(
          id: 'd_today',
          ownerId: 'u1',
          customerId: 'c1',
          amount: 5000.0,
          paidAmount: 0.0,
          description: 'Today Due',
          dueDate: '2026-08-20',
          status: DueStatus.due,
        ),
        DueEntity(
          id: 'd_old',
          ownerId: 'u1',
          customerId: 'c2',
          amount: 4000.0,
          paidAmount: 1500.0, // Partial payment recorded today
          description: 'Old Overdue Due',
          dueDate: '2026-08-01',
          status: DueStatus.partiallyPaid,
        ),
      ];

      final payments = [
        PaymentRecordEntity(
          id: 'p1',
          ownerId: 'u1',
          dueId: 'd_old', // Payment on old overdue due!
          customerId: 'c2',
          amount: 1500.0,
          paymentMethod: PaymentMethod.upi,
          paidAt: '2026-08-20T14:00:00', // Made today
        ),
      ];

      final metrics = DashboardFinancialCalculator.calculate(
        dues: dues,
        payments: payments,
        referenceDate: refDate,
      );

      // Today's due must remain exactly ₹5,000
      expect(metrics.toCollectToday, 5000.0);
      expect(metrics.todayDuesCount, 1);

      // Collected today captures the ₹1,500
      expect(metrics.collectedToday, 1500.0);

      // Overdue reflects 4000 - 1500 = 2500
      expect(metrics.overdueTotal, 2500.0);
    });

    test('11. Month boundary transition (e.g. Aug 31 -> Sep 1)', () {
      final aug31 = DateTime(2026, 8, 31);
      final dues = [
        DueEntity(
          id: 'd1',
          ownerId: 'u1',
          customerId: 'c1',
          amount: 5000.0,
          description: 'End of August',
          dueDate: '2026-08-31',
          status: DueStatus.due,
        ),
        DueEntity(
          id: 'd2',
          ownerId: 'u1',
          customerId: 'c2',
          amount: 3000.0,
          description: 'Start of September',
          dueDate: '2026-09-01',
          status: DueStatus.upcoming,
        ),
      ];

      // On Aug 31
      final metricsAug31 = DashboardFinancialCalculator.calculate(
        dues: dues,
        payments: [],
        referenceDate: aug31,
      );
      expect(metricsAug31.toCollectToday, 5000.0);
      expect(metricsAug31.upcomingTotal, 3000.0);
      expect(metricsAug31.expectedMonthTotal, 5000.0);

      // On Sep 01
      final sep01 = DateTime(2026, 9, 1);
      final metricsSep01 = DashboardFinancialCalculator.calculate(
        dues: [
          dues[0].copyWith(status: DueStatus.overdue),
          dues[1].copyWith(status: DueStatus.due),
        ],
        payments: [],
        referenceDate: sep01,
      );
      expect(metricsSep01.overdueTotal, 5000.0); // Aug 31 is now overdue
      expect(metricsSep01.toCollectToday, 3000.0); // Sep 1 is now today
      expect(metricsSep01.expectedMonthTotal, 3000.0); // September expected
    });

    test('12. Year boundary transition (e.g. Dec 31 -> Jan 1)', () {
      final dec31 = DateTime(2026, 12, 31);
      final dues = [
        DueEntity(
          id: 'd1',
          ownerId: 'u1',
          customerId: 'c1',
          amount: 10000.0,
          description: 'Year End Due',
          dueDate: '2026-12-31',
          status: DueStatus.due,
        ),
        DueEntity(
          id: 'd2',
          ownerId: 'u1',
          customerId: 'c2',
          amount: 8000.0,
          description: 'New Year Due',
          dueDate: '2027-01-01',
          status: DueStatus.upcoming,
        ),
      ];

      // On Dec 31
      final metricsDec31 = DashboardFinancialCalculator.calculate(
        dues: dues,
        payments: [],
        referenceDate: dec31,
      );
      expect(metricsDec31.toCollectToday, 10000.0);
      expect(metricsDec31.expectedMonthTotal, 10000.0);

      // On Jan 1
      final jan01 = DateTime(2027, 1, 1);
      final metricsJan01 = DashboardFinancialCalculator.calculate(
        dues: [
          dues[0].copyWith(status: DueStatus.overdue),
          dues[1].copyWith(status: DueStatus.due),
        ],
        payments: [],
        referenceDate: jan01,
      );
      expect(metricsJan01.overdueTotal, 10000.0);
      expect(metricsJan01.toCollectToday, 8000.0);
      expect(metricsJan01.expectedMonthTotal, 8000.0);
    });

    test(
        '13. Prompt verification scenario (Due A, B, C and multi-payment updates)',
        () {
      // Setup:
      // Due A: ₹5,000 Today (2026-08-20)
      // Due B: ₹3,000 Tomorrow (2026-08-21)
      // Due C: ₹4,000 Yesterday (2026-08-19)
      final dueA = DueEntity(
        id: 'due_A',
        ownerId: 'u1',
        customerId: 'cust_A',
        customerName: 'Customer A',
        amount: 5000.0,
        paidAmount: 2000.0, // ₹2,000 paid against Due A today
        description: 'Due A',
        dueDate: '2026-08-20', // Today
        status: DueStatus.partiallyPaid,
      );

      final dueB = DueEntity(
        id: 'due_B',
        ownerId: 'u1',
        customerId: 'cust_B',
        customerName: 'Customer B',
        amount: 3000.0,
        paidAmount: 0.0,
        description: 'Due B',
        dueDate: '2026-08-21', // Tomorrow
        status: DueStatus.upcoming,
      );

      final dueC = DueEntity(
        id: 'due_C',
        ownerId: 'u1',
        customerId: 'cust_C',
        customerName: 'Customer C',
        amount: 4000.0,
        paidAmount: 0.0,
        description: 'Due C',
        dueDate: '2026-08-19', // Yesterday
        status: DueStatus.overdue,
      );

      final paymentA = PaymentRecordEntity(
        id: 'pay_A',
        ownerId: 'u1',
        dueId: 'due_A',
        customerId: 'cust_A',
        amount: 2000.0,
        paymentMethod: PaymentMethod.upi,
        paidAt: '2026-08-20',
      );

      // Check Step 1:
      final m1 = DashboardFinancialCalculator.calculate(
        dues: [dueA, dueB, dueC],
        payments: [paymentA],
        referenceDate: refDate,
      );

      expect(m1.toCollectToday, 3000.0);
      expect(m1.collectedToday, 2000.0);
      expect(m1.overdueTotal, 4000.0);
      expect(m1.upcomingTotal, 3000.0);

      // Step 2: Then pay ₹1,000 against Due C today
      final updatedDueC = dueC.copyWith(
        paidAmount: 1000.0,
        status: DueStatus.partiallyPaid,
      );

      final paymentC = PaymentRecordEntity(
        id: 'pay_C',
        ownerId: 'u1',
        dueId: 'due_C',
        customerId: 'cust_C',
        amount: 1000.0,
        paymentMethod: PaymentMethod.cash,
        paidAt: '2026-08-20',
      );

      final m2 = DashboardFinancialCalculator.calculate(
        dues: [dueA, dueB, updatedDueC],
        payments: [paymentA, paymentC],
        referenceDate: refDate,
      );

      expect(m2.overdueTotal, 3000.0); // 4000 - 1000 = 3000
      expect(m2.collectedToday, 3000.0); // 2000 + 1000 = 3000
      expect(m2.toCollectToday, 3000.0); // Today's due remains 3000!
      expect(m2.upcomingTotal, 3000.0);
    });

    test('14. Needs Attention items generated correctly', () {
      final dues = [
        DueEntity(
          id: 'd1',
          ownerId: 'u1',
          customerId: 'c1',
          amount: 5000.0,
          description: 'Overdue Due',
          dueDate: '2026-08-10',
          status: DueStatus.overdue,
        ),
        DueEntity(
          id: 'd2',
          ownerId: 'u1',
          customerId: 'c2',
          amount: 3000.0,
          description: 'Today Due',
          dueDate: '2026-08-20',
          status: DueStatus.due,
        ),
      ];

      final metrics = DashboardFinancialCalculator.calculate(
        dues: dues,
        payments: [],
        referenceDate: refDate,
      );

      expect(metrics.attentionItems.length, 2);

      final overdueItem =
          metrics.attentionItems.firstWhere((i) => i.id == 'attention_overdue');
      expect(overdueItem.isUrgent, isTrue);
      expect(overdueItem.amount, 5000.0);
      expect(overdueItem.filterRoute, 'Overdue');

      final todayItem =
          metrics.attentionItems.firstWhere((i) => i.id == 'attention_today');
      expect(todayItem.isUrgent, isFalse);
      expect(todayItem.amount, 3000.0);
      expect(todayItem.filterRoute, 'Today');
    });

    test('15. Customer collection summaries ranked by outstanding balance', () {
      final dues = [
        DueEntity(
          id: 'd1',
          ownerId: 'u1',
          customerId: 'c1',
          customerName: 'Low Debtor',
          amount: 2000.0,
          description: 'Due 1',
          dueDate: '2026-08-20',
          status: DueStatus.due,
        ),
        DueEntity(
          id: 'd2',
          ownerId: 'u1',
          customerId: 'c2',
          customerName: 'High Debtor',
          amount: 10000.0,
          description: 'Due 2',
          dueDate: '2026-08-20',
          status: DueStatus.due,
        ),
      ];

      final metrics = DashboardFinancialCalculator.calculate(
        dues: dues,
        payments: [],
        referenceDate: refDate,
      );

      expect(metrics.topCustomers.length, 2);
      expect(metrics.topCustomers.first.customerName, 'High Debtor');
      expect(metrics.topCustomers.first.outstandingAmount, 10000.0);
    });
  });
}
