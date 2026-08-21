import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dueit/features/auth/domain/entities/user_entity.dart';
import 'package:dueit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dueit/features/customers/domain/entities/customer_entity.dart';
import 'package:dueit/features/customers/presentation/controllers/customer_controller.dart';
import '../../mocks/fake_auth_repository.dart';
import '../../mocks/fake_customer_repository.dart';

void main() {
  group('CustomerController Unit Tests', () {
    late FakeAuthRepository fakeAuthRepo;
    late FakeCustomerRepository fakeCustomerRepo;
    late ProviderContainer container;

    setUp(() async {
      const testUser = UserEntity(
        id: 'owner_123',
        email: 'sensei@dueit.com',
        businessName: 'Apex Martial Arts',
        isSetupComplete: true,
      );

      fakeAuthRepo = FakeAuthRepository(initialUser: testUser);
      fakeCustomerRepo = FakeCustomerRepository(
        ownerId: 'owner_123',
        initialCustomers: [
          CustomerEntity(
            id: 'c1',
            ownerId: 'owner_123',
            businessId: 'owner_123',
            name: 'Rahul Kumar',
            phone: '+91 98765 43210',
            email: 'rahul@example.com',
            notes: 'Karate Advanced Batch',
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
          CustomerEntity(
            id: 'c2',
            ownerId: 'owner_123',
            businessId: 'owner_123',
            name: 'Arjun Sharma',
            phone: '+91 98222 33445',
            email: 'arjun@example.com',
            notes: 'Gym Membership',
            createdAt: DateTime(2026, 2, 1),
            updatedAt: DateTime(2026, 2, 1),
          ),
        ],
      );

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          customerRepositoryProvider.overrideWithValue(fakeCustomerRepo),
        ],
      );

      // Allow auth stream and customer controller to establish subscriptions
      await Future<void>.delayed(Duration.zero);
      container.read(customerControllerProvider);
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() {
      container.dispose();
      fakeAuthRepo.dispose();
      fakeCustomerRepo.dispose();
    });

    test('1. Subscribes to customers and loads initial list', () async {
      final ctrl = container.read(customerControllerProvider.notifier);
      await ctrl.loadCustomers();

      final state = container.read(customerControllerProvider);
      expect(state.customers.length, 2);
      expect(state.customers.first.name, 'Rahul Kumar');
    });

    test('2. addCustomer successfully adds customer with authenticated ownerId',
        () async {
      final ctrl = container.read(customerControllerProvider.notifier);

      final created = await ctrl.addCustomer(
        name: 'Sneha Reddy',
        phone: '+91 98111 22334',
        email: 'sneha@example.com',
        notes: 'Yoga Batch',
      );

      expect(created, isNotNull);
      expect(created!.name, 'Sneha Reddy');
      expect(created.ownerId, 'owner_123');
      expect(created.businessId, 'owner_123');

      final state = container.read(customerControllerProvider);
      expect(state.customers.any((c) => c.name == 'Sneha Reddy'), isTrue);
    });

    test('3. addCustomer fails when name is empty', () async {
      final ctrl = container.read(customerControllerProvider.notifier);

      final created = await ctrl.addCustomer(
        name: '   ',
        phone: '+91 98111 22334',
      );

      expect(created, isNull);
      final state = container.read(customerControllerProvider);
      expect(state.error, 'Client name is required.');
    });

    test('4. updateCustomer updates fields and persists', () async {
      final ctrl = container.read(customerControllerProvider.notifier);
      await ctrl.loadCustomers();

      final existing = container
          .read(customerControllerProvider)
          .customers
          .firstWhere((c) => c.id == 'c1');

      final updated = existing.copyWith(
        name: 'Rahul Kumar (Sensei)',
        phone: '+91 99999 00000',
      );

      final success = await ctrl.updateCustomer(updated);
      expect(success, isTrue);

      final state = container.read(customerControllerProvider);
      final refreshed = state.customers.firstWhere((c) => c.id == 'c1');
      expect(refreshed.name, 'Rahul Kumar (Sensei)');
      expect(refreshed.phone, '+91 99999 00000');
    });

    test('5. deleteCustomer removes customer', () async {
      final ctrl = container.read(customerControllerProvider.notifier);
      await ctrl.loadCustomers();

      expect(container.read(customerControllerProvider).customers.length, 2);

      final success = await ctrl.deleteCustomer('c1');
      expect(success, isTrue);

      final state = container.read(customerControllerProvider);
      expect(state.customers.length, 1);
      expect(state.customers.any((c) => c.id == 'c1'), isFalse);
    });

    test('6. setSearchQuery and setFilterTab update state', () {
      final ctrl = container.read(customerControllerProvider.notifier);

      ctrl.setSearchQuery('Rahul');
      expect(container.read(customerControllerProvider).searchQuery, 'Rahul');

      ctrl.setFilterTab('With Balance');
      expect(
          container.read(customerControllerProvider).filterTab, 'With Balance');
    });

    test('7. Database error handling sets human-readable error state',
        () async {
      fakeCustomerRepo.shouldFail = true;
      final ctrl = container.read(customerControllerProvider.notifier);

      final result = await ctrl.addCustomer(name: 'Fail Test');
      expect(result, isNull);

      final state = container.read(customerControllerProvider);
      expect(state.error, contains('Failed to create customer'));
    });
  });
}
