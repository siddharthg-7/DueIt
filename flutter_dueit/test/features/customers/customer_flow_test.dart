import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dueit/features/auth/domain/entities/user_entity.dart';
import 'package:dueit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dueit/features/customers/domain/entities/customer_entity.dart';
import 'package:dueit/features/customers/presentation/controllers/customer_controller.dart';
import 'package:dueit/features/customers/presentation/screens/customers_screen.dart';
import 'package:dueit/features/customers/presentation/screens/customer_details_screen.dart';
import '../../mocks/fake_auth_repository.dart';
import '../../mocks/fake_customer_repository.dart';

void main() {
  group('Customer Flow UI & Widget Tests', () {
    late FakeAuthRepository fakeAuthRepo;
    late FakeCustomerRepository fakeCustomerRepo;

    setUp(() {
      const testUser = UserEntity(
        id: 'owner_1',
        email: 'owner@dueit.com',
        businessName: 'Apex Dojo',
        isSetupComplete: true,
      );

      fakeAuthRepo = FakeAuthRepository(initialUser: testUser);
      fakeCustomerRepo = FakeCustomerRepository(
        ownerId: 'owner_1',
        initialCustomers: [
          CustomerEntity(
            id: 'c1',
            ownerId: 'owner_1',
            businessId: 'owner_1',
            name: 'Rahul Kumar',
            phone: '+91 98765 43210',
            email: 'rahul@example.com',
            notes: 'Evening Karate Batch',
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
          CustomerEntity(
            id: 'c2',
            ownerId: 'owner_1',
            businessId: 'owner_1',
            name: 'Arjun Sharma',
            phone: '+91 98222 33445',
            email: 'arjun@example.com',
            notes: 'Gym Session',
            createdAt: DateTime(2026, 2, 1),
            updatedAt: DateTime(2026, 2, 1),
          ),
        ],
      );
    });

    tearDown(() {
      fakeAuthRepo.dispose();
      fakeCustomerRepo.dispose();
    });

    testWidgets('1. CustomersScreen displays customer list and search field',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
            customerRepositoryProvider.overrideWithValue(fakeCustomerRepo),
          ],
          child: const MaterialApp(
            home: CustomersScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header and items
      expect(find.text('People'), findsOneWidget);
      expect(find.text('Rahul Kumar'), findsOneWidget);
      expect(find.text('Arjun Sharma'), findsOneWidget);

      // Search for Arjun
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Arjun');
      await tester.pumpAndSettle();

      // Only Arjun should be visible
      expect(find.text('Arjun Sharma'), findsOneWidget);
      expect(find.text('Rahul Kumar'), findsNothing);

      // Clear search
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();
      expect(find.text('Rahul Kumar'), findsOneWidget);
    });

    testWidgets('2. Add Client bottom sheet validates required name',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
            customerRepositoryProvider.overrideWithValue(fakeCustomerRepo),
          ],
          child: const MaterialApp(
            home: CustomersScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap FAB to open Add Client
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.text('Add New Client'), findsOneWidget);

      // Tap Save Client with empty name
      final saveBtn = find.widgetWithText(FilledButton, 'Save Client');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Client name is required'), findsOneWidget);
    });

    testWidgets('3. CustomerDetailsScreen renders details and shows popup menu',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
            customerRepositoryProvider.overrideWithValue(fakeCustomerRepo),
          ],
          child: const MaterialApp(
            home: CustomerDetailsScreen(customerId: 'c1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify details
      expect(find.text('Rahul Kumar'), findsOneWidget);
      expect(find.text('+91 98765 43210'), findsOneWidget);
      expect(find.text('Evening Karate Batch'), findsOneWidget);

      // Open popup menu
      final popupMenu = find.byType(PopupMenuButton<String>);
      expect(popupMenu, findsOneWidget);
      await tester.tap(popupMenu);
      await tester.pumpAndSettle();

      expect(find.text('Edit Client'), findsOneWidget);
      expect(find.text('Delete Client'), findsOneWidget);
    });
  });
}
