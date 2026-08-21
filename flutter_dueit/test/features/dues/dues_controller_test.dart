import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dueit/core/utils/date_formatter.dart';
import 'package:dueit/features/auth/domain/entities/user_entity.dart';
import 'package:dueit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';
import 'package:dueit/features/dues/presentation/controllers/dues_controller.dart';
import '../../mocks/fake_auth_repository.dart';
import '../../mocks/fake_dues_repository.dart';

void main() {
  group('DuesController Unit Tests', () {
    late FakeAuthRepository fakeAuthRepo;
    late FakeDuesRepository fakeDuesRepo;
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
            amount: 1500.0,
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

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          duesRepositoryProvider.overrideWithValue(fakeDuesRepo),
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

    test('3. addDue fails when amount <= 0 or customer is empty', () async {
      final ctrl = container.read(duesControllerProvider.notifier);

      final zeroAmount = await ctrl.addDue(
        customerId: 'cust_1',
        amount: 0,
        description: 'Free Training',
        dueDate: todayStr,
      );
      expect(zeroAmount, isNull);

      final emptyCust = await ctrl.addDue(
        customerId: '',
        amount: 500,
        description: 'Fee',
        dueDate: todayStr,
      );
      expect(emptyCust, isNull);
    });

    test('4. updateDue updates amount and description', () async {
      final ctrl = container.read(duesControllerProvider.notifier);
      await ctrl.loadDues();

      final existing = container
          .read(duesControllerProvider)
          .dues
          .firstWhere((d) => d.id == 'due_1');

      final updated = existing.copyWith(
        amount: 1800.0,
        description: 'August Karate Fee (Advanced)',
      );

      final success = await ctrl.updateDue(updated);
      expect(success, isTrue);

      final state = container.read(duesControllerProvider);
      final refreshed = state.dues.firstWhere((d) => d.id == 'due_1');
      expect(refreshed.amount, 1800.0);
      expect(refreshed.description, 'August Karate Fee (Advanced)');
    });

    test('5. cancelDue sets status to cancelled', () async {
      final ctrl = container.read(duesControllerProvider.notifier);
      await ctrl.loadDues();

      final success = await ctrl.cancelDue('due_1');
      expect(success, isTrue);

      final state = container.read(duesControllerProvider);
      final cancelled = state.dues.firstWhere((d) => d.id == 'due_1');
      expect(cancelled.status, DueStatus.cancelled);
    });

    test('6. deleteDue removes due record', () async {
      final ctrl = container.read(duesControllerProvider.notifier);
      await ctrl.loadDues();

      expect(container.read(duesControllerProvider).dues.length, 2);

      final success = await ctrl.deleteDue('due_2');
      expect(success, isTrue);

      final state = container.read(duesControllerProvider);
      expect(state.dues.length, 1);
      expect(state.dues.any((d) => d.id == 'due_2'), isFalse);
    });

    test(
        '7. hasActiveDuesForCustomer returns true for active dues and false when cancelled',
        () async {
      final ctrl = container.read(duesControllerProvider.notifier);
      await ctrl.loadDues();

      expect(ctrl.hasActiveDuesForCustomer('cust_1'), isTrue);
      expect(ctrl.hasActiveDuesForCustomer('non_existent_cust'), isFalse);

      await ctrl.cancelDue('due_1');
      expect(ctrl.hasActiveDuesForCustomer('cust_1'), isFalse);
    });
  });
}
