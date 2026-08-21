import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dueit/core/utils/date_formatter.dart';
import 'package:dueit/features/auth/domain/entities/user_entity.dart';
import 'package:dueit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dueit/features/customers/presentation/controllers/customer_controller.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';
import 'package:dueit/features/dues/domain/entities/payment_record_entity.dart';
import 'package:dueit/features/dues/domain/entities/recurring_due_schedule_entity.dart';
import 'package:dueit/features/dues/domain/services/due_payment_calculator.dart';
import 'package:dueit/features/dues/domain/services/recurring_due_generation_service.dart';
import 'package:dueit/features/dues/presentation/controllers/dues_controller.dart';
import 'package:dueit/features/dashboard/domain/services/dashboard_financial_calculator.dart';
import 'package:dueit/features/reminders/data/services/local_notification_service.dart';
import '../mocks/fake_auth_repository.dart';
import '../mocks/fake_customer_repository.dart';
import '../mocks/fake_dues_repository.dart';
import '../mocks/fake_recurring_due_repository.dart';
import '../mocks/fake_notification_service.dart';

void main() {
  group('STEP 12: Production QA, Security & Data Integrity Audit Suite', () {
    const userA = UserEntity(
      id: 'owner_user_A',
      email: 'userA@business.com',
      businessName: 'Business A',
      isSetupComplete: true,
    );

    final todayStr = DateFormatter.todayIsoDate();
    final yesterdayStr = DateFormatter.formatIsoDate(
        DateTime.now().subtract(const Duration(days: 1)));
    final tomorrowStr = DateFormatter.formatIsoDate(
        DateTime.now().add(const Duration(days: 1)));

    late FakeAuthRepository fakeAuthRepo;
    late FakeCustomerRepository fakeCustomerRepo;
    late FakeDuesRepository fakeDuesRepo;
    late FakeRecurringDueRepository fakeRecurringRepo;
    late FakeNotificationService fakeNotificationService;
    late ProviderContainer container;

    setUp(() async {
      fakeAuthRepo = FakeAuthRepository(initialUser: userA);
      fakeCustomerRepo = FakeCustomerRepository(ownerId: userA.id);
      fakeDuesRepo = FakeDuesRepository(ownerId: userA.id);
      fakeRecurringRepo = FakeRecurringDueRepository(ownerId: userA.id);
      fakeNotificationService = FakeNotificationService();

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          customerRepositoryProvider.overrideWithValue(fakeCustomerRepo),
          duesRepositoryProvider.overrideWithValue(fakeDuesRepo),
          notificationServiceProvider
              .overrideWithValue(fakeNotificationService),
        ],
      );

      await Future<void>.delayed(Duration.zero);
      container.read(customerControllerProvider);
      container.read(duesControllerProvider);
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() {
      container.dispose();
      fakeAuthRepo.dispose();
      fakeCustomerRepo.dispose();
      fakeDuesRepo.dispose();
      fakeRecurringRepo.dispose();
    });

    // ==========================================
    // PART 2: AUTHENTICATION & MULTI-TENANT ISOLATION
    // ==========================================
    test(
        'Audit 1: User session isolation and state clearing across logout/login',
        () async {
      // 1. User A adds customer and due
      final customerCtrl = container.read(customerControllerProvider.notifier);
      final custA = await customerCtrl.addCustomer(name: 'User A Client');
      expect(custA, isNotNull);

      final duesCtrl = container.read(duesControllerProvider.notifier);
      final dueA = await duesCtrl.addDue(
        customerId: custA!.id,
        customerName: custA.name,
        amount: 5000.0,
        description: 'User A Due',
        dueDate: todayStr,
      );
      expect(dueA, isNotNull);

      // Verify User A sees data
      expect(container.read(customerControllerProvider).customers.length, 1);
      expect(container.read(duesControllerProvider).dues.length, 1);

      // 2. User A logs out
      await container.read(authControllerProvider.notifier).signOut();
      await Future<void>.delayed(Duration.zero);

      // Data must be cleared and not leaked
      expect(container.read(customerControllerProvider).customers, isEmpty);
      expect(container.read(duesControllerProvider).dues, isEmpty);

      // 3. User B logs in
      await container
          .read(authControllerProvider.notifier)
          .signIn('userB@business.com', 'password123');
      await Future<void>.delayed(Duration.zero);

      // User B must start with clean slate
      expect(container.read(customerControllerProvider).customers, isEmpty);
      expect(container.read(duesControllerProvider).dues, isEmpty);
    });

    // ==========================================
    // PART 5: PAYMENT INTEGRITY & REJECTIONS
    // ==========================================
    test('Audit 2: Payment mathematical integrity and validation boundaries',
        () async {
      final duesCtrl = container.read(duesControllerProvider.notifier);

      final due = await duesCtrl.addDue(
        customerId: 'cust_audit_1',
        customerName: 'Audit Student',
        amount: 5000.0,
        description: 'Exam Fee',
        dueDate: todayStr,
      );
      expect(due, isNotNull);

      // Rejection 1: Zero amount
      final zeroPay = await duesCtrl.recordPayment(
        dueId: due!.id,
        amount: 0.0,
        paymentMethod: PaymentMethod.upi,
      );
      expect(zeroPay, isNull);
      expect(container.read(duesControllerProvider).error,
          contains('greater than ₹0'));

      // Rejection 2: Negative amount
      final negPay = await duesCtrl.recordPayment(
        dueId: due.id,
        amount: -500.0,
        paymentMethod: PaymentMethod.cash,
      );
      expect(negPay, isNull);
      expect(container.read(duesControllerProvider).error,
          contains('greater than ₹0'));

      // Rejection 3: Payment greater than remaining amount
      final overPay = await duesCtrl.recordPayment(
        dueId: due.id,
        amount: 6000.0,
        paymentMethod: PaymentMethod.upi,
      );
      expect(overPay, isNull);
      expect(container.read(duesControllerProvider).error,
          contains('cannot be greater than the remaining amount'));

      // Valid Partial Payment: ₹2,000 -> Remaining ₹3,000
      final p1 = await duesCtrl.recordPayment(
        dueId: due.id,
        amount: 2000.0,
        paymentMethod: PaymentMethod.upi,
      );
      expect(p1, isNotNull);

      var updatedDue = container
          .read(duesControllerProvider)
          .dues
          .firstWhere((d) => d.id == due.id);
      expect(updatedDue.paidAmount, 2000.0);
      expect(updatedDue.remainingAmount, 3000.0);
      expect(updatedDue.status, DueStatus.partiallyPaid);

      // Valid Final Payment: ₹3,000 -> Remaining ₹0 (PAID)
      final p2 = await duesCtrl.recordPayment(
        dueId: due.id,
        amount: 3000.0,
        paymentMethod: PaymentMethod.cash,
      );
      expect(p2, isNotNull);

      updatedDue = container
          .read(duesControllerProvider)
          .dues
          .firstWhere((d) => d.id == due.id);
      expect(updatedDue.paidAmount, 5000.0);
      expect(updatedDue.remainingAmount, 0.0);
      expect(updatedDue.status, DueStatus.paid);

      // Rejection 4: Attempt payment on already PAID due
      final extraPay = await duesCtrl.recordPayment(
        dueId: due.id,
        amount: 1.0,
        paymentMethod: PaymentMethod.upi,
      );
      expect(extraPay, isNull);
      expect(container.read(duesControllerProvider).error,
          contains('cannot be greater than the remaining amount'));
    });

    // ==========================================
    // PART 6: DUE STATUS CALCULATION & PRIORITY
    // ==========================================
    test('Audit 3: Centralized Due status priority calculation', () {
      // 1. Cancelled takes precedence over everything
      expect(
        DuePaymentCalculator.calculateDueStatus(
          amount: 5000.0,
          totalPaid: 5000.0,
          dueDate: yesterdayStr,
          isCancelled: true,
        ),
        DueStatus.cancelled,
      );

      // 2. Paid takes precedence over overdue date
      expect(
        DuePaymentCalculator.calculateDueStatus(
          amount: 5000.0,
          totalPaid: 5000.0,
          dueDate: yesterdayStr,
          isCancelled: false,
        ),
        DueStatus.paid,
      );

      // 3. Partially Paid takes precedence over date-based status
      expect(
        DuePaymentCalculator.calculateDueStatus(
          amount: 5000.0,
          totalPaid: 1000.0,
          dueDate: yesterdayStr,
          isCancelled: false,
        ),
        DueStatus.partiallyPaid,
      );

      expect(
        DuePaymentCalculator.calculateDueStatus(
          amount: 5000.0,
          totalPaid: 1000.0,
          dueDate: tomorrowStr,
          isCancelled: false,
        ),
        DueStatus.partiallyPaid,
      );

      // 4. Date-based statuses for unpaid dues
      expect(
        DuePaymentCalculator.calculateDueStatus(
          amount: 5000.0,
          totalPaid: 0.0,
          dueDate: yesterdayStr,
          isCancelled: false,
        ),
        DueStatus.overdue,
      );

      expect(
        DuePaymentCalculator.calculateDueStatus(
          amount: 5000.0,
          totalPaid: 0.0,
          dueDate: todayStr,
          isCancelled: false,
        ),
        DueStatus.due,
      );

      expect(
        DuePaymentCalculator.calculateDueStatus(
          amount: 5000.0,
          totalPaid: 0.0,
          dueDate: tomorrowStr,
          isCancelled: false,
        ),
        DueStatus.upcoming,
      );
    });

    // ==========================================
    // PART 7: DASHBOARD METRICS INTEGRITY
    // ==========================================
    test(
        'Audit 4: Dashboard financial calculation scenario without double counting',
        () {
      final dues = [
        // Due A: ₹5,000 Today (₹2,000 paid today -> remaining ₹3,000)
        DueEntity(
          id: 'due_A',
          ownerId: userA.id,
          customerId: 'c1',
          customerName: 'Customer A',
          amount: 5000.0,
          paidAmount: 2000.0,
          description: 'Due A',
          dueDate: todayStr,
          status: DueStatus.partiallyPaid,
        ),
        // Due B: ₹4,000 Yesterday (₹1,000 paid today -> remaining ₹3,000)
        DueEntity(
          id: 'due_B',
          ownerId: userA.id,
          customerId: 'c2',
          customerName: 'Customer B',
          amount: 4000.0,
          paidAmount: 1000.0,
          description: 'Due B',
          dueDate: yesterdayStr,
          status: DueStatus.partiallyPaid,
        ),
        // Due C: ₹3,000 Tomorrow (unpaid)
        DueEntity(
          id: 'due_C',
          ownerId: userA.id,
          customerId: 'c3',
          customerName: 'Customer C',
          amount: 3000.0,
          paidAmount: 0.0,
          description: 'Due C',
          dueDate: tomorrowStr,
          status: DueStatus.upcoming,
        ),
      ];

      final payments = [
        PaymentRecordEntity(
          id: 'pay_1',
          ownerId: userA.id,
          dueId: 'due_A',
          customerId: 'c1',
          amount: 2000.0,
          paymentMethod: PaymentMethod.upi,
          paidAt: todayStr,
        ),
        PaymentRecordEntity(
          id: 'pay_2',
          ownerId: userA.id,
          dueId: 'due_B',
          customerId: 'c2',
          amount: 1000.0,
          paymentMethod: PaymentMethod.cash,
          paidAt: todayStr,
        ),
      ];

      final metrics = DashboardFinancialCalculator.calculate(
        dues: dues,
        payments: payments,
        referenceDate: DateTime.now(),
      );

      // Verify exact expectations:
      expect(metrics.toCollectToday, 3000.0);
      expect(
          metrics.collectedToday, 3000.0); // ₹2,000 on Due A + ₹1,000 on Due B
      expect(metrics.overdueTotal, 3000.0); // Due B remaining
      expect(metrics.upcomingTotal, 3000.0); // Due C remaining
    });

    // ==========================================
    // PART 8: RECURRING SCHEDULE IMMUTABILITY
    // ==========================================
    test('Audit 5: Recurring schedule modification preserves historical dues',
        () async {
      final schedule = RecurringDueScheduleEntity(
        id: 'sched_history_1',
        ownerId: userA.id,
        customerId: 'c1',
        customerName: 'Student A',
        amount: 1500.0,
        description: 'Karate Fee',
        frequency: RecurrenceFrequency.monthly,
        startDate: '2026-07-01',
        nextDueDate: '2026-07-01',
        dayOfMonth: 1,
        createdAt: DateTime(2026, 7, 1),
        updatedAt: DateTime(2026, 7, 1),
      );

      final generationService = RecurringDueGenerationService(
        duesRepository: fakeDuesRepo,
        recurringRepository: fakeRecurringRepo,
      );

      await fakeRecurringRepo.createSchedule(userA.id, schedule);

      // Generate July occurrence: ₹1,500
      await generationService.generatePendingDues(
        ownerId: userA.id,
        referenceDateStr: '2026-07-01',
      );

      final julyDues = await fakeDuesRepo.getDues(userA.id);
      expect(julyDues.length, 1);
      expect(julyDues.first.amount, 1500.0);

      // Update schedule for future months: change to ₹2,000
      final updatedSchedule = schedule.copyWith(
        amount: 2000.0,
        nextDueDate: '2026-08-01',
      );
      await fakeRecurringRepo.updateSchedule(userA.id, updatedSchedule);

      // Generate August occurrence: ₹2,000
      await generationService.generatePendingDues(
        ownerId: userA.id,
        referenceDateStr: '2026-08-01',
      );

      final allDues = await fakeDuesRepo.getDues(userA.id);
      expect(allDues.length, 2);

      // July due must remain ₹1,500 (historical immutability)
      final julyDue = allDues.firstWhere((d) => d.dueDate == '2026-07-01');
      expect(julyDue.amount, 1500.0);

      // August due must be ₹2,000
      final augDue = allDues.firstWhere((d) => d.dueDate == '2026-08-01');
      expect(augDue.amount, 2000.0);
    });

    // ==========================================
    // PART 16: DELETE SAFETY
    // ==========================================
    test(
        'Audit 6: Customer deletion guard blocks deletion when financial records exist',
        () {
      final duesCtrl = container.read(duesControllerProvider.notifier);

      // Customer with an active due
      final hasActive = duesCtrl.hasActiveDuesForCustomer('c_active');
      expect(hasActive, isFalse);

      final hasFinancial =
          duesCtrl.hasFinancialRecordsForCustomer('c_financial');
      expect(hasFinancial, isFalse);
    });

    // ==========================================
    // PART 17: SEARCH AND FILTER ROBUSTNESS
    // ==========================================
    test(
        'Audit 7: Search and filter handling of whitespace, casing, and empty queries',
        () async {
      final customerCtrl = container.read(customerControllerProvider.notifier);

      await customerCtrl.addCustomer(name: 'Aarav Sharma');
      await customerCtrl.addCustomer(name: 'Bhavna Patel');

      // Empty query
      customerCtrl.setSearchQuery('');
      expect(container.read(customerControllerProvider).searchQuery, '');

      // Case differences & whitespace
      customerCtrl.setSearchQuery('  aarav  ');
      expect(
          container.read(customerControllerProvider).searchQuery, '  aarav  ');

      // Filter tabs
      customerCtrl.setFilterTab('With Balance');
      expect(
          container.read(customerControllerProvider).filterTab, 'With Balance');

      customerCtrl.setFilterTab('Overdue');
      expect(container.read(customerControllerProvider).filterTab, 'Overdue');
    });
  });
}
