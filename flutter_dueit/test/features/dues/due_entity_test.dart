import 'package:flutter_test/flutter_test.dart';
import 'package:dueit/core/utils/date_formatter.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';

void main() {
  group('DueEntity Domain Tests', () {
    final now = DateTime.now();
    final todayStr = DateFormatter.todayIsoDate();
    final yesterdayStr =
        DateFormatter.formatIsoDate(now.subtract(const Duration(days: 1)));
    final tomorrowStr =
        DateFormatter.formatIsoDate(now.add(const Duration(days: 1)));

    test('1. DueEntity serialization to and from Map', () {
      final due = DueEntity(
        id: 'due_101',
        ownerId: 'user_123',
        businessId: 'user_123',
        customerId: 'cust_01',
        customerName: 'Rahul Kumar',
        amount: 1500.0,
        description: 'August Karate Fee',
        dueDate: todayStr,
        status: DueStatus.due,
        createdAt: DateTime(2026, 8, 20),
        updatedAt: DateTime(2026, 8, 20),
      );

      final map = due.toMap();
      expect(map['id'], 'due_101');
      expect(map['ownerId'], 'user_123');
      expect(map['customerId'], 'cust_01');
      expect(map['amount'], 1500.0);
      expect(map['dueDate'], todayStr);
      expect(map['status'], 'due');

      final deserialized = DueEntity.fromMap(map, docId: 'due_101');
      expect(deserialized.id, 'due_101');
      expect(deserialized.ownerId, 'user_123');
      expect(deserialized.amount, 1500.0);
      expect(deserialized.description, 'August Karate Fee');
      expect(deserialized.status, DueStatus.due);
    });

    test(
        '2. Status derivation rules: yesterday is overdue, today is due, tomorrow is upcoming',
        () {
      expect(DueEntity.deriveStatus(dueDate: yesterdayStr), DueStatus.overdue);
      expect(DueEntity.deriveStatus(dueDate: todayStr), DueStatus.due);
      expect(DueEntity.deriveStatus(dueDate: tomorrowStr), DueStatus.upcoming);
    });

    test('3. Cancelled status derivation overrides date calculations', () {
      expect(DueEntity.deriveStatus(dueDate: yesterdayStr, isCancelled: true),
          DueStatus.cancelled);
      expect(DueEntity.deriveStatus(dueDate: todayStr, isCancelled: true),
          DueStatus.cancelled);
      expect(DueEntity.deriveStatus(dueDate: tomorrowStr, isCancelled: true),
          DueStatus.cancelled);
    });

    test('4. DateFormatter date-only helpers', () {
      expect(DateFormatter.isToday(todayStr), isTrue);
      expect(DateFormatter.isToday(yesterdayStr), isFalse);
      expect(DateFormatter.isBeforeToday(yesterdayStr), isTrue);
      expect(DateFormatter.isAfterToday(tomorrowStr), isTrue);
    });

    test('5. copyWith creates modified instance preserving immutability', () {
      final original = DueEntity(
        id: 'due_1',
        ownerId: 'user_1',
        customerId: 'cust_1',
        amount: 1000.0,
        description: 'Monthly Fee',
        dueDate: todayStr,
        status: DueStatus.due,
      );

      final updated =
          original.copyWith(amount: 2000.0, description: 'Updated Fee');
      expect(updated.amount, 2000.0);
      expect(updated.description, 'Updated Fee');
      expect(original.amount, 1000.0);
    });
  });
}
