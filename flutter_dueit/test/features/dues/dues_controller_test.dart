import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dueit/core/utils/date_formatter.dart';
import 'package:dueit/features/auth/domain/entities/user_entity.dart';
import 'package:dueit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';
import 'package:dueit/features/dues/domain/entities/payment_record_entity.dart';
import 'package:dueit/features/dues/presentation/controllers/dues_controller.dart';
import 'package:dueit/features/reminders/data/services/local_notification_service.dart';
import '../../mocks/fake_auth_repository.dart';
import '../../mocks/fake_dues_repository.dart';
import '../../mocks/fake_notification_service.dart';

void main() {
  group('DuesController Unit Tests with Payments', () {
    late FakeAuthRepository fakeAuthRepo;
    late FakeDuesRepository fakeDuesRepo;
    late FakeNotificationService fakeNotificationService;
    late ProviderContainer container;

    final todayStr = DateFormatter.todayIsoDate();
    final yesterdayStr = DateFormatter.formatIsoDate(
        DateTime.now().subtract(const Duration(days: 1)));
    final tomorrowStr = DateFormatter.formatIsoDate(
        DateTime.now().add(const Duration(days: 1)));

    setUp(() async {
      const testUser = UserEntity(
        id: 'owner_123',
        email: 'owner@dueit.com',
        businessName: 'Apex Martial Arts',
        isSetupComplete: true,
      );

      fakeAuthRepo = FakeAuthRepository(initialUser: testUser);
      fakeDuesRepo = FakeDuesRepository(
        ownerId: 'owner_123',
        initialDues: [
          DueEntity(
            id: 'due_1',
            ownerId: 'owner_123',
            businessId: 'owner_123',
            customerId: 'cust_1',
            customerName: 'Rahul Kumar',
            amount: 5000.0,
            description: 'August Karate Fee',
            dueDate: todayStr,
            status: DueStatus.due,
          ),
          DueEntity(
            id: 'due_2',
            ownerId: 'owner_123',
            businessId: 'owner_123',
            customerId: 'cust_2',
            customerName: 'Arjun Sharma',
            amount: 2000.0,
            description: 'Gym Membership',
            dueDate: yesterdayStr,
            status: DueStatus.overdue,
          ),
        ],
      );
      fakeNotificationService = FakeNotificationService();

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          duesRepositoryProvider.overrideWithValue(fakeDuesRepo),
          notificationServiceProvider
              .overrideWithValue(fakeNotificationService),
        ],
      );

      await Future<void>.delayed(Duration.zero);
      container.read(duesControllerProvider);
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() {
      container.dispose();
      fakeAuthRepo.dispose();
      fakeDuesRepo.dispose();
    });

    test('1. Loads and subscribes to initial dues', () async {
      final ctrl = container.read(duesControllerProvider.notifier);
      await ctrl.loadDues();

      final state = container.read(duesControllerProvider);
      expect(state.dues.length, 2);
      expect(state.dues.any((d) => d.id == 'due_1'), isTrue);
    });

    test(
        '2. addDue creates a new due with authenticated ownerId and valid status',
        () async {
      final ctrl = container.read(duesControllerProvider.notifier);

      final created = await ctrl.addDue(
        customerId: 'cust_3',
        customerName: 'Sneha Reddy',
        amount: 3000.0,
        description: 'Tuition Fee',
        dueDate: tomorrowStr,
      );

      expect(created, isNotNull);
      expect(created!.ownerId, 'owner_123');
      expect(created.amount, 3000.0);
      expect(created.status, DueStatus.upcoming);

      final state = container.read(duesControllerProvider);
      expect(state.dues.any((d) => d.description == 'Tuition Fee'), isTrue);
    });

    test(
        '3. recordPayment records partial payment and updates remaining amount and status',
        () async {
      final ctrl = container.read(duesControllerProvider.notifier);
      await ctrl.loadDues();

      // Record partial payment of ₹2,000 against ₹5,000 due
      final payment = await ctrl.recordPayment(
        dueId: 'due_1',
        amount: 2000.0,
        paymentMethod: PaymentMethod.cash,
        notes: 'Partial cash payment',
      );

      expect(payment, isNotNull);
      expect(payment!.amount, 2000.0);

      final state = container.read(duesControllerProvider);
      final enrichedDue = state.dues.firstWhere((d) => d.id == 'due_1');
      expect(enrichedDue.paidAmount, 2000.0);
      expect(enrichedDue.remainingAmount, 3000.0);
      expect(enrichedDue.status, DueStatus.partiallyPaid);
    });

    test('4. recordPayment records remaining payment and marks due as PAID',
        () async {
      final ctrl = container.read(duesControllerProvider.notifier);
      await ctrl.loadDues();

      // 1st Payment ₹2,000
      await ctrl.recordPayment(
        dueId: 'due_1',
        amount: 2000.0,
        paymentMethod: PaymentMethod.cash,
      );

      // 2nd Payment ₹3,000 (Remaining full amount)
      final fullPayment = await ctrl.recordPayment(
        dueId: 'due_1',
        amount: 3000.0,
        paymentMethod: PaymentMethod.upi,
      );

      expect(fullPayment, isNotNull);

      final state = container.read(duesControllerProvider);
      final enrichedDue = state.dues.firstWhere((d) => d.id == 'due_1');
      expect(enrichedDue.paidAmount, 5000.0);
      expect(enrichedDue.remainingAmount, 0.0);
      expect(enrichedDue.status, DueStatus.paid);
      expect(enrichedDue.isFullyPaid, isTrue);
    });

    test('5. recordPayment rejects payment exceeding remaining amount or <= 0',
        () async {
      final ctrl = container.read(duesControllerProvider.notifier);
      await ctrl.loadDues();

      // Attempt payment of ₹6,000 against ₹5,000 due
      final overPayment = await ctrl.recordPayment(
        dueId: 'due_1',
        amount: 6000.0,
        paymentMethod: PaymentMethod.cash,
      );
      expect(overPayment, isNull);
      expect(container.read(duesControllerProvider).error,
          'Payment cannot be greater than the remaining amount.');

      // Attempt payment of ₹0
      final zeroPayment = await ctrl.recordPayment(
        dueId: 'due_1',
        amount: 0,
        paymentMethod: PaymentMethod.cash,
      );
      expect(zeroPayment, isNull);
    });

    test('6. deletePayment recalculates due paid amount and status immediately',
        () async {
      final ctrl = container.read(duesControllerProvider.notifier);
      await ctrl.loadDues();

      // Record payment of ₹5,000 -> PAID
      final payment = await ctrl.recordPayment(
        dueId: 'due_1',
        amount: 5000.0,
        paymentMethod: PaymentMethod.upi,
      );
      expect(payment, isNotNull);

      var state = container.read(duesControllerProvider);
      expect(
          state.dues.firstWhere((d) => d.id == 'due_1').status, DueStatus.paid);

      // Delete payment
      final deleted = await ctrl.deletePayment(payment!.id);
      expect(deleted, isTrue);

      state = container.read(duesControllerProvider);
      final revertedDue = state.dues.firstWhere((d) => d.id == 'due_1');
      expect(revertedDue.paidAmount, 0.0);
      expect(revertedDue.remainingAmount, 5000.0);
      expect(revertedDue.status, DueStatus.due);
    });

    test(
        '7. hasFinancialRecordsForCustomer returns true for active, paid dues, or payments',
        () async {
      final ctrl = container.read(duesControllerProvider.notifier);
      await ctrl.loadDues();

      expect(ctrl.hasFinancialRecordsForCustomer('cust_1'), isTrue);
      expect(ctrl.hasFinancialRecordsForCustomer('unknown_customer'), isFalse);
    });
  });
}
