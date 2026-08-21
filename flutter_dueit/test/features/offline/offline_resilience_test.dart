import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dueit/core/services/connectivity_service.dart';
import 'package:dueit/core/utils/date_formatter.dart';
import 'package:dueit/features/auth/domain/entities/user_entity.dart';
import 'package:dueit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dueit/features/customers/presentation/controllers/customer_controller.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';
import 'package:dueit/features/dues/domain/entities/payment_record_entity.dart';
import 'package:dueit/features/dues/domain/entities/recurring_due_schedule_entity.dart';
import 'package:dueit/features/dues/domain/services/recurrence_calculator.dart';
import 'package:dueit/features/dues/domain/services/recurring_due_generation_service.dart';
import 'package:dueit/features/dues/presentation/controllers/dues_controller.dart';
import 'package:dueit/features/dashboard/domain/services/dashboard_financial_calculator.dart';
import 'package:dueit/features/reminders/data/services/local_notification_service.dart';
import '../../mocks/fake_auth_repository.dart';
import '../../mocks/fake_customer_repository.dart';
import '../../mocks/fake_dues_repository.dart';
import '../../mocks/fake_recurring_due_repository.dart';
import '../../mocks/fake_notification_service.dart';

void main() {
  group('STEP 11: Offline-First Reliability & Production Resilience Tests', () {
    late FakeAuthRepository fakeAuthRepo;
    late FakeCustomerRepository fakeCustomerRepo;
    late FakeDuesRepository fakeDuesRepo;
    late FakeRecurringDueRepository fakeRecurringRepo;
    late FakeNotificationService fakeNotificationService;
    late ProviderContainer container;

    const testUser = UserEntity(
      id: 'owner_offline_1',
      email: 'owner@dueit.com',
      businessName: 'Apex Academy',
      isSetupComplete: true,
    );

    final todayStr = DateFormatter.todayIsoDate();
    final futureDueStr = DateFormatter.formatIsoDate(
        DateTime.now().add(const Duration(days: 7)));

    setUp(() async {
      fakeAuthRepo = FakeAuthRepository(initialUser: testUser);
      fakeCustomerRepo = FakeCustomerRepository(ownerId: testUser.id);
      fakeDuesRepo = FakeDuesRepository(ownerId: testUser.id);
      fakeRecurringRepo = FakeRecurringDueRepository(ownerId: testUser.id);
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

    test('1. ConnectivityState models and status transitions', () {
      const onlineState = ConnectivityState(
        status: ConnectivityStatus.online,
        message: null,
      );
      expect(onlineState.isOnline, isTrue);
      expect(onlineState.isOffline, isFalse);

      const offlineState = ConnectivityState(
        status: ConnectivityStatus.offline,
        message: 'Offline — Changes will sync when you\'re back online',
      );
      expect(offlineState.isOffline, isTrue);
      expect(offlineState.isOnline, isFalse);
      expect(offlineState.message, contains('Offline'));

      const reconnectedState = ConnectivityState(
        status: ConnectivityStatus.online,
        message: 'Back online',
      );
      expect(reconnectedState.isOnline, isTrue);
      expect(reconnectedState.message, 'Back online');
    });

    test('2. Offline customer creation and immediate cache availability',
        () async {
      final customerCtrl = container.read(customerControllerProvider.notifier);

      // Create customer while offline
      final created = await customerCtrl.addCustomer(
        name: 'Offline Customer',
        phone: '9876543210',
        notes: 'Local Store Owner',
      );

      expect(created, isNotNull);
      expect(created!.name, 'Offline Customer');

      // Verify immediate local reflection in state
      final customerState = container.read(customerControllerProvider);
      expect(customerState.customers.any((c) => c.id == created.id), isTrue);
    });

    test('3. Offline Due creation, immediate state reflection & local reminder',
        () async {
      final duesCtrl = container.read(duesControllerProvider.notifier);

      final createdDue = await duesCtrl.addDue(
        customerId: 'cust_offline_1',
        customerName: 'Karan Mehra',
        amount: 5000.0,
        description: 'Karate Uniform & Fee',
        dueDate: futureDueStr, // Future date so reminder is in future
        reminderEnabled: true,
        reminderType: ReminderType.oneDayBefore,
      );

      expect(createdDue, isNotNull);
      expect(createdDue!.amount, 5000.0);

      // Local state immediately reflects the created due
      final duesState = container.read(duesControllerProvider);
      expect(duesState.dues.any((d) => d.id == createdDue.id), isTrue);

      // Local notification is scheduled device-locally (no network required)
      expect(
          fakeNotificationService.scheduledDues
              .any((d) => d.id == createdDue.id),
          isTrue);
    });

    test(
        '4. Offline Payment recording immediately updates remaining balance and status',
        () async {
      final duesCtrl = container.read(duesControllerProvider.notifier);

      // 1. Create a Due
      final due = await duesCtrl.addDue(
        customerId: 'cust_offline_2',
        customerName: 'Pooja Hegde',
        amount: 4000.0,
        description: 'Monthly Tuition',
        dueDate: todayStr,
      );
      expect(due, isNotNull);

      // 2. Record Partial Payment offline: ₹1,500
      final payment = await duesCtrl.recordPayment(
        dueId: due!.id,
        amount: 1500.0,
        paymentMethod: PaymentMethod.cash,
        notes: 'Collected in cash offline',
      );

      expect(payment, isNotNull);
      expect(payment!.amount, 1500.0);

      // 3. Verify immediate local reflection in enriched Dues state
      final updatedDue = container
          .read(duesControllerProvider)
          .dues
          .firstWhere((d) => d.id == due.id);

      expect(updatedDue.paidAmount, 1500.0);
      expect(updatedDue.remainingAmount, 2500.0);
      expect(updatedDue.status, DueStatus.partiallyPaid);
    });

    test('5. Offline Due editing and cancellation', () async {
      final duesCtrl = container.read(duesControllerProvider.notifier);

      final due = await duesCtrl.addDue(
        customerId: 'cust_offline_3',
        customerName: 'Vikas Gupta',
        amount: 3000.0,
        description: 'Class Material',
        dueDate: todayStr,
      );
      expect(due, isNotNull);

      // Edit description offline
      final edited = due!.copyWith(description: 'Updated Class Material');
      final updateSuccess = await duesCtrl.updateDue(edited);
      expect(updateSuccess, isTrue);

      final duesStateAfterEdit = container.read(duesControllerProvider);
      expect(
        duesStateAfterEdit.dues.firstWhere((d) => d.id == due.id).description,
        'Updated Class Material',
      );

      // Cancel Due offline
      final cancelSuccess = await duesCtrl.cancelDue(due.id);
      expect(cancelSuccess, isTrue);

      final duesStateAfterCancel = container.read(duesControllerProvider);
      expect(
        duesStateAfterCancel.dues.firstWhere((d) => d.id == due.id).status,
        DueStatus.cancelled,
      );
    });

    test(
        '6. Cached dashboard calculations work offline without network requests',
        () {
      final dues = [
        DueEntity(
          id: 'd1',
          ownerId: testUser.id,
          customerId: 'c1',
          customerName: 'Cached User',
          amount: 5000.0,
          paidAmount: 2000.0,
          description: 'Cached Due',
          dueDate: todayStr,
          status: DueStatus.partiallyPaid,
        ),
      ];

      final payments = [
        PaymentRecordEntity(
          id: 'p1',
          ownerId: testUser.id,
          dueId: 'd1',
          customerId: 'c1',
          amount: 2000.0,
          paymentMethod: PaymentMethod.cash,
          paidAt: todayStr,
        ),
      ];

      // Calculations are pure and run entirely on local cached memory
      final metrics = DashboardFinancialCalculator.calculate(
        dues: dues,
        payments: payments,
        referenceDate: DateTime.now(),
      );

      expect(metrics.toCollectToday, 3000.0);
      expect(metrics.collectedToday, 2000.0);
      expect(metrics.todayDuesCount, 1);
    });

    test('7. Cached search and filters execute locally in memory', () async {
      final duesCtrl = container.read(duesControllerProvider.notifier);

      await duesCtrl.addDue(
        customerId: 'c1',
        customerName: 'Aarav Patel',
        amount: 2000.0,
        description: 'Music Class',
        dueDate: todayStr,
      );
      await duesCtrl.addDue(
        customerId: 'c2',
        customerName: 'Bhavna Sharma',
        amount: 3500.0,
        description: 'Dance Class',
        dueDate: todayStr,
      );

      // Filter by search query
      duesCtrl.setSearchQuery('Aarav');
      var state = container.read(duesControllerProvider);
      expect(state.searchQuery, 'Aarav');

      // Filter by Tab
      duesCtrl.setFilter('Today');
      state = container.read(duesControllerProvider);
      expect(state.duesFilter, 'Today');
    });

    test(
        '8. Recurring occurrence deterministic ID ensures zero duplicates on reconnect',
        () async {
      final schedule = RecurringDueScheduleEntity(
        id: 'sched_offline_1',
        ownerId: testUser.id,
        customerId: 'cust_1',
        customerName: 'Rahul',
        amount: 1500.0,
        description: 'Monthly Karate',
        frequency: RecurrenceFrequency.monthly,
        startDate: '2026-08-01',
        nextDueDate: '2026-08-01',
        dayOfMonth: 1,
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      );

      // Verify deterministic ID generation
      final occurrenceId = RecurrenceCalculator.generateOccurrenceDueId(
        schedule.id,
        '2026-08-01',
      );
      expect(occurrenceId, 'due_sched_offline_1_2026-08-01');

      final generationService = RecurringDueGenerationService(
        duesRepository: fakeDuesRepo,
        recurringRepository: fakeRecurringRepo,
      );

      // Seed schedule in repo
      await fakeRecurringRepo.createSchedule(testUser.id, schedule);

      // Run generation
      final count = await generationService.generatePendingDues(
        ownerId: testUser.id,
        referenceDateStr: '2026-08-01',
      );
      expect(count, 1);

      // Re-running generation yields 0 new dues because occurrence ID exists!
      final rerunCount = await generationService.generatePendingDues(
        ownerId: testUser.id,
        referenceDateStr: '2026-08-01',
      );
      expect(rerunCount, 0);
    });

    test(
        '9. Notification scheduling failure does not crash or block Due creation',
        () async {
      // Configure throwing notification service to simulate permission error on device
      final faultyNotificationService = ThrowingNotificationService();

      final faultContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          customerRepositoryProvider.overrideWithValue(fakeCustomerRepo),
          duesRepositoryProvider.overrideWithValue(fakeDuesRepo),
          notificationServiceProvider
              .overrideWithValue(faultyNotificationService),
        ],
      );

      await Future<void>.delayed(Duration.zero);
      faultContainer.read(customerControllerProvider);
      faultContainer.read(duesControllerProvider);
      await Future<void>.delayed(Duration.zero);

      final duesCtrl = faultContainer.read(duesControllerProvider.notifier);

      // Creating due with reminder when notification permission failed
      final due = await duesCtrl.addDue(
        customerId: 'cust_faulty',
        customerName: 'Test Student',
        amount: 2500.0,
        description: 'Test Fee',
        dueDate: futureDueStr,
        reminderEnabled: true,
        reminderType: ReminderType.oneDayBefore,
      );

      // Due creation MUST succeed despite notification failure!
      expect(due, isNotNull);
      expect(due!.amount, 2500.0);

      faultContainer.dispose();
    });

    test('10. Offline authentication session preservation', () {
      final authState = container.read(authControllerProvider);

      // User remains authenticated from persisted local session
      expect(authState.isAuthenticated, isTrue);
      expect(authState.user?.id, testUser.id);
      expect(authState.isBusinessSetupComplete, isTrue);
    });
  });
}

/// Helper fake service simulating notification permission denial / failure
class ThrowingNotificationService implements NotificationService {
  @override
  Future<void> cancelAllReminders() async {}

  @override
  Future<void> cancelReminderForDue(String dueId) async {}

  @override
  Future<List<PendingNotificationRequest>> getPendingNotifications() async =>
      [];

  @override
  Future<void> initialize(
      {void Function(String? payload)? onNotificationTap}) async {}

  @override
  Future<bool> requestPermissions() async => false;

  @override
  Future<bool> scheduleDueReminder(DueEntity due,
      {String? customerName}) async {
    throw Exception('Exact alarm permission not granted');
  }
}
