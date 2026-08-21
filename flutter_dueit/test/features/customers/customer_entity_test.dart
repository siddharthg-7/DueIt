import 'package:flutter_test/flutter_test.dart';
import 'package:dueit/features/customers/domain/entities/customer_entity.dart';

void main() {
  group('CustomerEntity Tests', () {
    test('1. CustomerEntity serialization to and from Map', () {
      final now = DateTime(2026, 8, 20, 10, 30);
      final customer = CustomerEntity(
        id: 'cust_101',
        ownerId: 'uid_test',
        businessId: 'biz_test',
        name: 'Rahul Kumar',
        phone: '+91 98765 43210',
        email: 'rahul@example.com',
        notes: 'Evening Karate Batch',
        createdAt: now,
        updatedAt: now,
      );

      final map = customer.toMap();
      expect(map['id'], 'cust_101');
      expect(map['ownerId'], 'uid_test');
      expect(map['businessId'], 'biz_test');
      expect(map['name'], 'Rahul Kumar');
      expect(map['phone'], '+91 98765 43210');
      expect(map['email'], 'rahul@example.com');
      expect(map['notes'], 'Evening Karate Batch');

      final deserialized = CustomerEntity.fromMap(map, docId: 'cust_101');
      expect(deserialized.id, 'cust_101');
      expect(deserialized.ownerId, 'uid_test');
      expect(deserialized.name, 'Rahul Kumar');
      expect(deserialized.phone, '+91 98765 43210');
      expect(deserialized.email, 'rahul@example.com');
      expect(deserialized.notes, 'Evening Karate Batch');
      expect(deserialized.createdAt.year, 2026);
    });

    test('2. calculatedInitials formats correctly', () {
      final multiWord = CustomerEntity(
        id: '1',
        name: 'Rahul Kumar',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(multiWord.calculatedInitials, 'RK');

      final singleWord = CustomerEntity(
        id: '2',
        name: 'Cheryl',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(singleWord.calculatedInitials, 'C');

      final explicitInitials = CustomerEntity(
        id: '3',
        name: 'Sensei Alex Rivera',
        initials: 'AR',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(explicitInitials.calculatedInitials, 'AR');
    });

    test('3. clientSince formats month and year correctly', () {
      final customer = CustomerEntity(
        id: '1',
        name: 'Arjun Sharma',
        createdAt: DateTime(2024, 3, 15),
        updatedAt: DateTime(2024, 3, 15),
      );
      expect(customer.clientSince, 'Mar 2024');
    });

    test('4. copyWith updates fields without mutating original', () {
      final original = CustomerEntity(
        id: '1',
        ownerId: 'owner_1',
        name: 'Sneha Reddy',
        phone: '12345',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final updated = original.copyWith(
        name: 'Sneha Reddy (Updated)',
        phone: '99999',
      );

      expect(updated.id, '1');
      expect(updated.ownerId, 'owner_1');
      expect(updated.name, 'Sneha Reddy (Updated)');
      expect(updated.phone, '99999');
      expect(original.name, 'Sneha Reddy');
    });
  });
}
