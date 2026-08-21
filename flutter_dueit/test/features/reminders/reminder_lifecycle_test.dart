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
  group('Reminder & Notification Lifecycle Integration Tests', () {
    late FakeAuthRepository fakeAuthRepo;
    late FakeDuesRepository fakeDuesRepo;
    late FakeNotificationService fakeNotificationService;
    late ProviderContainer container;

    final futureDueDateStr = DateFormatter.formatIsoDate(
        DateTime.now().add(const Duration(days: 10)));

    setUp(() async {
      const testUser = UserEntity(
        id: 'owner_10',
        email: 'owner@dueit.com',
        businessName: 'Apex Dojo',
        isSetupComplete: true,
      );

      fakeAuthRepo = FakeAuthRepository(initialUser: testUser);
      fakeDuesRepo = FakeDuesRepository(ownerId: 'owner_10');
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

    test('1. Creating a Due with reminder schedules a local notification',
        () async {
      final ctrl = container.read(duesControllerProvider.notifier);

      final created = await ctrl.addDue(
        customerId: 'cust_1',
        customerName: 'Rahul Kumar',
        amount: 2500.0,
        description: 'Karate Uniform & Belt',
        dueDate: futureDueDateStr,
        reminderType: ReminderType.oneDayBefore,
        reminderEnabled: true,
      );

      expect(created, isNotNull);
      expect(fakeNotificationService.scheduledDues.length, 1);
      expect(fakeNotificationService.scheduledDues.first.id, created!.id);
      expect(fakeNotificationService.scheduledDues.first.reminderType,
          ReminderType.oneDayBefore);
    });

    test(
        '2. Creating a Due with ReminderType.none does NOT schedule a notification',
        () async {
      final ctrl = container.read(duesControllerProvider.notifier);

      final created = await ctrl.addDue(
        customerId: 'cust_2',
        customerName: 'Arjun Sharma',
        amount: 1000.0,
        description: 'Manual cash settlement',
        dueDate: futureDueDateStr,
        reminderType: ReminderType.none,
        reminderEnabled: false,
      );

      expect(created, isNotNull);
      expect(fakeNotificationService.scheduledDues.isEmpty, isTrue);
    });

    test('3. Editing a Due cancels old reminder and reschedules new reminder',
        () async {
      final ctrl = container.read(duesControllerProvider.notifier);

      final created = await ctrl.addDue(
        customerId: 'cust_3',
        customerName: 'Sneha Reddy',
        amount: 5000.0,
        description: 'Tuition Fee',
        dueDate: futureDueDateStr,
        reminderType: ReminderType.oneDayBefore,
        reminderEnabled: true,
      );
      expect(fakeNotificationService.scheduledDues.length, 1);

      // Edit: Change reminder to 3 days before
      final updatedDue = created!.copyWith(
        reminderType: ReminderType.threeDaysBefore,
      );

      final updated = await ctrl.updateDue(updatedDue);
      expect(updated, isTrue);

      expect(
          fakeNotificationService.cancelledDueIds.contains(created.id), isTrue);
      expect(fakeNotificationService.scheduledDues.length, 1);
      expect(fakeNotificationService.scheduledDues.first.reminderType,
          ReminderType.threeDaysBefore);
    });

    test('4. Marking Due as PAID (full payment) cancels pending reminder',
        () async {
      final ctrl = container.read(duesControllerProvider.notifier);

      final created = await ctrl.addDue(
        customerId: 'cust_4',
        customerName: 'Vikram Singh',
        amount: 3000.0,
        description: 'Full coaching payment',
        dueDate: futureDueDateStr,
        reminderType: ReminderType.oneDayBefore,
        reminderEnabled: true,
      );
      expect(fakeNotificationService.scheduledDues.length, 1);

      // Record full payment of ₹3,000
      await ctrl.recordPayment(
        dueId: created!.id,
        amount: 3000.0,
        paymentMethod: PaymentMethod.upi,
      );

      // Verify reminder cancellation
      expect(
          fakeNotificationService.cancelledDueIds.contains(created.id), isTrue);
      expect(fakeNotificationService.scheduledDues.isEmpty, isTrue);
    });

    test(
        '5. Partially paying Due keeps reminder scheduled for remaining balance',
        () async {
      final ctrl = container.read(duesControllerProvider.notifier);

      final created = await ctrl.addDue(
        customerId: 'cust_5',
        customerName: 'Ananya Gupta',
        amount: 5000.0,
        description: 'Semester Tuition',
        dueDate: futureDueDateStr,
        reminderType: ReminderType.oneDayBefore,
        reminderEnabled: true,
      );
      expect(fakeNotificationService.scheduledDues.length, 1);

      // Record partial payment of ₹2,000 (Remaining = ₹3,000)
      await ctrl.recordPayment(
        dueId: created!.id,
        amount: 2000.0,
        paymentMethod: PaymentMethod.cash,
      );

      // Reminder remains scheduled with updated remaining balance
      expect(fakeNotificationService.scheduledDues.length, 1);
      expect(fakeNotificationService.scheduledDues.first.id, created.id);
      expect(fakeNotificationService.scheduledDues.first.status,
          DueStatus.partiallyPaid);
      expect(
          fakeNotificationService.scheduledDues.first.remainingAmount, 3000.0);
    });

    test('6. Cancelling a Due cancels its pending reminder', () async {
      final ctrl = container.read(duesControllerProvider.notifier);

      final created = await ctrl.addDue(
        customerId: 'cust_6',
        customerName: 'Karan Mehra',
        amount: 4000.0,
        description: 'Event pass',
        dueDate: futureDueDateStr,
        reminderType: ReminderType.oneDayBefore,
        reminderEnabled: true,
      );
      expect(fakeNotificationService.scheduledDues.length, 1);

      // Cancel due
      final cancelled = await ctrl.cancelDue(created!.id);
      expect(cancelled, isTrue);

      expect(
          fakeNotificationService.cancelledDueIds.contains(created.id), isTrue);
      expect(fakeNotificationService.scheduledDues.isEmpty, isTrue);
    });

    test('7. Deleting a Due cancels its pending reminder', () async {
      final ctrl = container.read(duesControllerProvider.notifier);

      final created = await ctrl.addDue(
        customerId: 'cust_7',
        customerName: 'Pooja Roy',
        amount: 1500.0,
        description: 'Book fee',
        dueDate: futureDueDateStr,
        reminderType: ReminderType.oneDayBefore,
        reminderEnabled: true,
      );
      expect(fakeNotificationService.scheduledDues.length, 1);

      // Delete due
      final deleted = await ctrl.deleteDue(created!.id);
      expect(deleted, isTrue);

      expect(
          fakeNotificationService.cancelledDueIds.contains(created.id), isTrue);
      expect(fakeNotificationService.scheduledDues.isEmpty, isTrue);
    });

    test('8. Notification tap invokes callback with dueId payload', () async {
      String? tappedPayload;
      await fakeNotificationService.initialize(
        onNotificationTap: (payload) {
          tappedPayload = payload;
        },
      );

      fakeNotificationService.triggerNotificationTap('due_999');
      expect(tappedPayload, 'due_999');
    });
  });
}
