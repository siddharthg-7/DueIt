import 'package:flutter_test/flutter_test.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';
import 'package:dueit/features/dues/domain/entities/payment_record_entity.dart';
import 'package:dueit/features/dues/domain/entities/recurring_due_schedule_entity.dart';
import 'package:dueit/features/dues/domain/services/recurrence_calculator.dart';
import 'package:dueit/features/dues/domain/services/recurring_due_generation_service.dart';
import '../../mocks/fake_dues_repository.dart';
import '../../mocks/fake_notification_service.dart';
import '../../mocks/fake_recurring_due_repository.dart';

void main() {
  group('Recurring Due Generation Service & Lifecycle Integration Tests', () {
    late FakeDuesRepository fakeDuesRepo;
    late FakeRecurringDueRepository fakeRecurringRepo;
    late FakeNotificationService fakeNotifService;
    late RecurringDueGenerationService generationService;

    const ownerId = 'owner_100';

    setUp(() {
      fakeDuesRepo = FakeDuesRepository(ownerId: ownerId);
      fakeRecurringRepo = FakeRecurringDueRepository(ownerId: ownerId);
      fakeNotifService = FakeNotificationService();

      generationService = RecurringDueGenerationService(
        duesRepository: fakeDuesRepo,
        recurringRepository: fakeRecurringRepo,
        notificationService: fakeNotifService,
      );
    });

    tearDown(() {
      fakeDuesRepo.dispose();
      fakeRecurringRepo.dispose();
    });

    test(
        '1. Due generation creates proper DueEntity with recurring link and reminder',
        () async {
      final schedule = RecurringDueScheduleEntity(
        id: 'sched_1',
        ownerId: ownerId,
        customerId: 'cust_1',
        customerName: 'Rahul Kumar',
        amount: 1500.0,
        description: 'Karate Fee',
        frequency: RecurrenceFrequency.monthly,
        dayOfMonth: 25,
        startDate: '2026-08-25',
        nextDueDate: '2026-08-25',
        reminderType: ReminderType.oneDayBefore,
        reminderEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await fakeRecurringRepo.createSchedule(ownerId, schedule);

      // Trigger generation for Aug 25
      final count = await generationService.generatePendingDues(
        ownerId: ownerId,
        referenceDateStr: '2026-08-25',
      );

      expect(count, 1);

      // Verify generated Due
      final dues = await fakeDuesRepo.getDues(ownerId);
      expect(dues.length, 1);
      final generatedDue = dues.first;

      expect(generatedDue.id, 'due_sched_1_2026-08-25');
      expect(generatedDue.amount, 1500.0);
      expect(generatedDue.customerName, 'Rahul Kumar');
      expect(generatedDue.dueDate, '2026-08-25');
      expect(generatedDue.recurringScheduleId, 'sched_1');
      expect(generatedDue.occurrenceDate, '2026-08-25');
      expect(generatedDue.isRecurring, isTrue);

      // Verify schedule nextDueDate advanced to Sep 25
      final updatedSchedule =
          await fakeRecurringRepo.getSchedule(ownerId, 'sched_1');
      expect(updatedSchedule!.nextDueDate, '2026-09-25');
    });

    test(
        '2. Idempotency: Multiple generation runs create exactly 1 Due (0 duplicates)',
        () async {
      final schedule = RecurringDueScheduleEntity(
        id: 'sched_2',
        ownerId: ownerId,
        customerId: 'cust_2',
        customerName: 'Arjun Sharma',
        amount: 2000.0,
        description: 'Gym Membership',
        frequency: RecurrenceFrequency.monthly,
        dayOfMonth: 10,
        startDate: '2026-08-10',
        nextDueDate: '2026-08-10',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await fakeRecurringRepo.createSchedule(ownerId, schedule);

      // Run 1
      final count1 = await generationService.generatePendingDues(
        ownerId: ownerId,
        referenceDateStr: '2026-08-10',
      );
      expect(count1, 1);

      // Run 2 (Immediately again on same day)
      final count2 = await generationService.generatePendingDues(
        ownerId: ownerId,
        referenceDateStr: '2026-08-10',
      );
      expect(count2, 0);

      // Run 3
      final count3 = await generationService.generatePendingDues(
        ownerId: ownerId,
        referenceDateStr: '2026-08-10',
      );
      expect(count3, 0);

      // Exactly 1 due in repository
      final dues = await fakeDuesRepo.getDues(ownerId);
      expect(dues.length, 1);
    });

    test('3. Pausing a schedule halts generation', () async {
      final schedule = RecurringDueScheduleEntity(
        id: 'sched_3',
        ownerId: ownerId,
        customerId: 'cust_3',
        customerName: 'Sneha Reddy',
        amount: 3000.0,
        description: 'Tuition Fee',
        frequency: RecurrenceFrequency.monthly,
        dayOfMonth: 1,
        startDate: '2026-08-01',
        nextDueDate: '2026-08-01',
        status: RecurringScheduleStatus.paused,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await fakeRecurringRepo.createSchedule(ownerId, schedule);

      final count = await generationService.generatePendingDues(
        ownerId: ownerId,
        referenceDateStr: '2026-08-01',
      );
      expect(count, 0);

      final dues = await fakeDuesRepo.getDues(ownerId);
      expect(dues.isEmpty, isTrue);
    });

    test('4. Resuming a schedule generates the next required occurrence',
        () async {
      final schedule = RecurringDueScheduleEntity(
        id: 'sched_4',
        ownerId: ownerId,
        customerId: 'cust_4',
        customerName: 'Vikram Singh',
        amount: 4000.0,
        description: 'Martial Arts',
        frequency: RecurrenceFrequency.monthly,
        dayOfMonth: 15,
        startDate: '2026-08-15',
        nextDueDate: '2026-08-15',
        status: RecurringScheduleStatus.paused,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await fakeRecurringRepo.createSchedule(ownerId, schedule);

      // Resume schedule
      await fakeRecurringRepo.resumeSchedule(ownerId, 'sched_4');

      final count = await generationService.generatePendingDues(
        ownerId: ownerId,
        referenceDateStr: '2026-08-15',
      );
      expect(count, 1);

      final dues = await fakeDuesRepo.getDues(ownerId);
      expect(dues.length, 1);
      expect(dues.first.dueDate, '2026-08-15');
    });

    test(
        '5. Stopping a schedule halts future generation while preserving historical dues',
        () async {
      // 1. Generate August Due
      final schedule = RecurringDueScheduleEntity(
        id: 'sched_5',
        ownerId: ownerId,
        customerId: 'cust_5',
        customerName: 'Ananya Gupta',
        amount: 2500.0,
        description: 'Art Class',
        frequency: RecurrenceFrequency.monthly,
        dayOfMonth: 5,
        startDate: '2026-08-05',
        nextDueDate: '2026-08-05',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await fakeRecurringRepo.createSchedule(ownerId, schedule);
      await generationService.generatePendingDues(
        ownerId: ownerId,
        referenceDateStr: '2026-08-05',
      );

      var dues = await fakeDuesRepo.getDues(ownerId);
      expect(dues.length, 1);
      expect(dues.first.dueDate, '2026-08-05');

      // 2. Stop schedule before September
      await fakeRecurringRepo.stopSchedule(ownerId, 'sched_5');

      // 3. Try to generate September
      await generationService.generatePendingDues(
        ownerId: ownerId,
        referenceDateStr: '2026-09-05',
      );

      // August due is still preserved, but no September due created
      dues = await fakeDuesRepo.getDues(ownerId);
      expect(dues.length, 1);
      expect(dues.first.dueDate, '2026-08-05');
    });

    test(
        '6. Modifying future schedule amount does not alter existing historical dues',
        () async {
      // 1. Generate August Due with ₹1,500
      final schedule = RecurringDueScheduleEntity(
        id: 'sched_6',
        ownerId: ownerId,
        customerId: 'cust_6',
        customerName: 'Karan Mehra',
        amount: 1500.0,
        description: 'Swimming Pool Membership',
        frequency: RecurrenceFrequency.monthly,
        dayOfMonth: 1,
        startDate: '2026-08-01',
        nextDueDate: '2026-08-01',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await fakeRecurringRepo.createSchedule(ownerId, schedule);
      await generationService.generatePendingDues(
        ownerId: ownerId,
        referenceDateStr: '2026-08-01',
      );

      // 2. Owner updates schedule amount from ₹1,500 to ₹2,000
      final updatedSchedule = schedule.copyWith(
        amount: 2000.0,
        nextDueDate: '2026-09-01',
      );
      await fakeRecurringRepo.updateSchedule(ownerId, updatedSchedule);

      // 3. Generate September Due
      await generationService.generatePendingDues(
        ownerId: ownerId,
        referenceDateStr: '2026-09-01',
      );

      final dues = await fakeDuesRepo.getDues(ownerId);
      expect(dues.length, 2);

      final augDue = dues.firstWhere((d) => d.occurrenceDate == '2026-08-01');
      final sepDue = dues.firstWhere((d) => d.occurrenceDate == '2026-09-01');

      expect(augDue.amount, 1500.0); // Historical unchanged!
      expect(sepDue.amount, 2000.0); // Future uses new amount!
    });

    test(
        '7. Payment independence: Paying current due has no effect on schedule or future dues',
        () async {
      final schedule = RecurringDueScheduleEntity(
        id: 'sched_7',
        ownerId: ownerId,
        customerId: 'cust_7',
        customerName: 'Pooja Roy',
        amount: 5000.0,
        description: 'Yoga Classes',
        frequency: RecurrenceFrequency.monthly,
        dayOfMonth: 20,
        startDate: '2026-08-20',
        nextDueDate: '2026-08-20',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await fakeRecurringRepo.createSchedule(ownerId, schedule);
      await generationService.generatePendingDues(
        ownerId: ownerId,
        referenceDateStr: '2026-08-20',
      );

      // Record full payment on August Due
      final initialDue = await fakeDuesRepo.getDue(
        ownerId: ownerId,
        dueId: 'due_sched_7_2026-08-20',
      );
      expect(initialDue, isNotNull);

      await fakeDuesRepo.recordPayment(PaymentRecordEntity(
        id: 'pay_1',
        ownerId: ownerId,
        dueId: 'due_sched_7_2026-08-20',
        customerId: 'cust_7',
        amount: 5000.0,
        paymentMethod: PaymentMethod.upi,
        paidAt: '2026-08-20',
      ));

      await fakeDuesRepo.updateDue(initialDue!.copyWith(
        paidAmount: 5000.0,
        status: DueStatus.paid,
      ));

      final augDue = await fakeDuesRepo.getDue(
        ownerId: ownerId,
        dueId: 'due_sched_7_2026-08-20',
      );
      expect(augDue!.isFullyPaid, isTrue);

      // Schedule remains active
      final currentSched =
          await fakeRecurringRepo.getSchedule(ownerId, 'sched_7');
      expect(currentSched!.isActive, isTrue);
      expect(currentSched.nextDueDate, '2026-09-20');
    });

    test('8. Catch-up safety limit: Missed periods capped at maxCatchUpCycles',
        () async {
      // Schedule started 10 months ago, but user never opened app
      final schedule = RecurringDueScheduleEntity(
        id: 'sched_8',
        ownerId: ownerId,
        customerId: 'cust_8',
        customerName: 'Dormant Client',
        amount: 1000.0,
        description: 'Monthly Retainer',
        frequency: RecurrenceFrequency.monthly,
        dayOfMonth: 1,
        startDate: '2025-10-01',
        nextDueDate: '2025-10-01',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await fakeRecurringRepo.createSchedule(ownerId, schedule);

      // Generate up to today (2026-08-21)
      final generated = await generationService.generatePendingDues(
        ownerId: ownerId,
        referenceDateStr: '2026-08-21',
      );

      // Must be capped at maxCatchUpCycles = 6
      expect(generated, RecurrenceCalculator.maxCatchUpCycles);

      final dues = await fakeDuesRepo.getDues(ownerId);
      expect(dues.length, 6);
    });

    test(
        '9. Weekly recurrence schedule generation across cross-month transition',
        () async {
      // Weekly schedule on Fridays (2026-08-28 is Friday)
      final schedule = RecurringDueScheduleEntity(
        id: 'sched_9_weekly',
        ownerId: ownerId,
        customerId: 'cust_9',
        customerName: 'Weekly Client',
        amount: 500.0,
        description: 'Weekly Yoga Class',
        frequency: RecurrenceFrequency.weekly,
        dayOfMonth: 28,
        dayOfWeek: DateTime.friday,
        startDate: '2026-08-28',
        nextDueDate: '2026-08-28',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await fakeRecurringRepo.createSchedule(ownerId, schedule);

      // Generate for Aug 28
      final count1 = await generationService.generatePendingDues(
        ownerId: ownerId,
        referenceDateStr: '2026-08-28',
      );
      expect(count1, 1);

      final updatedSched =
          await fakeRecurringRepo.getSchedule(ownerId, 'sched_9_weekly');
      expect(
          updatedSched!.nextDueDate, '2026-09-04'); // Crosses from Aug to Sep!

      // Generate for Sep 04
      final count2 = await generationService.generatePendingDues(
        ownerId: ownerId,
        referenceDateStr: '2026-09-04',
      );
      expect(count2, 1);

      final dues = await fakeDuesRepo.getDues(ownerId);
      expect(dues.length, 2);
      expect(dues.any((d) => d.occurrenceDate == '2026-08-28'), isTrue);
      expect(dues.any((d) => d.occurrenceDate == '2026-09-04'), isTrue);
    });
  });
}
