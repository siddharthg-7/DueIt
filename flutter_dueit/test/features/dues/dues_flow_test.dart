import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dueit/core/utils/date_formatter.dart';
import 'package:dueit/features/auth/domain/entities/user_entity.dart';
import 'package:dueit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dueit/features/customers/domain/entities/customer_entity.dart';
import 'package:dueit/features/customers/presentation/controllers/customer_controller.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';
import 'package:dueit/features/dues/domain/entities/payment_record_entity.dart';
import 'package:dueit/features/dues/domain/entities/recurring_due_schedule_entity.dart';
import 'package:dueit/features/dues/domain/repositories/recurring_due_repository.dart';
import 'package:dueit/features/dues/presentation/controllers/dues_controller.dart';
import 'package:dueit/features/dues/presentation/screens/add_due_screen.dart';
import 'package:dueit/features/dues/presentation/screens/dues_screen.dart';
import 'package:dueit/features/dues/presentation/screens/due_details_screen.dart';
import 'package:dueit/features/reminders/data/services/local_notification_service.dart';
import '../../mocks/fake_auth_repository.dart';
import '../../mocks/fake_customer_repository.dart';
import '../../mocks/fake_dues_repository.dart';
import '../../mocks/fake_notification_service.dart';
import '../../mocks/fake_recurring_due_repository.dart';

void main() {
  group('Dues UI Flow & Widget Tests with Payments & Recurring', () {
    late FakeAuthRepository fakeAuthRepo;
    late FakeCustomerRepository fakeCustomerRepo;
    late FakeDuesRepository fakeDuesRepo;
    late FakeRecurringDueRepository fakeRecurringRepo;
    late FakeNotificationService fakeNotificationService;

    final todayStr = DateFormatter.todayIsoDate();
    final yesterdayStr = DateFormatter.formatIsoDate(
        DateTime.now().subtract(const Duration(days: 1)));

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
            name: 'Rahul Kumar',
            phone: '+91 98765 43210',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          CustomerEntity(
            id: 'c2',
            ownerId: 'owner_1',
            name: 'Arjun Sharma',
            phone: '+91 98222 33445',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      );

      fakeDuesRepo = FakeDuesRepository(
        ownerId: 'owner_1',
        initialDues: [
          DueEntity(
            id: 'd1',
            ownerId: 'owner_1',
            customerId: 'c1',
            customerName: 'Rahul Kumar',
            amount: 1500.0,
            description: 'August Karate Fee',
            dueDate: todayStr,
            status: DueStatus.due,
          ),
          DueEntity(
            id: 'd2',
            ownerId: 'owner_1',
            customerId: 'c2',
            customerName: 'Arjun Sharma',
            amount: 2000.0,
            description: 'Monthly Membership',
            dueDate: yesterdayStr,
            status: DueStatus.overdue,
          ),
        ],
      );

      fakeRecurringRepo = FakeRecurringDueRepository(
        ownerId: 'owner_1',
        initialSchedules: [
          RecurringDueScheduleEntity(
            id: 'rec_1',
            ownerId: 'owner_1',
            customerId: 'c1',
            customerName: 'Rahul Kumar',
            amount: 1500.0,
            description: 'Monthly Karate Coaching',
            frequency: RecurrenceFrequency.monthly,
            dayOfMonth: 25,
            startDate: '2026-08-25',
            nextDueDate: '2026-09-25',
            status: RecurringScheduleStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      );

      fakeNotificationService = FakeNotificationService();
    });

    tearDown(() {
      fakeAuthRepo.dispose();
      fakeCustomerRepo.dispose();
      fakeDuesRepo.dispose();
      fakeRecurringRepo.dispose();
    });

    testWidgets('1. DuesScreen displays dues list and filter tabs',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
            customerRepositoryProvider.overrideWithValue(fakeCustomerRepo),
            duesRepositoryProvider.overrideWithValue(fakeDuesRepo),
            recurringDueRepositoryProvider.overrideWithValue(fakeRecurringRepo),
            notificationServiceProvider
                .overrideWithValue(fakeNotificationService),
          ],
          child: const MaterialApp(
            home: DuesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dues'), findsOneWidget);
      expect(find.text('August Karate Fee'), findsOneWidget);
      expect(find.text('Monthly Membership'), findsOneWidget);

      // Tap Today filter
      final todayFilter = find.widgetWithText(ChoiceChip, 'Today');
      expect(todayFilter, findsOneWidget);
      await tester.tap(todayFilter);
      await tester.pumpAndSettle();

      expect(find.text('August Karate Fee'), findsOneWidget);
      expect(find.text('Monthly Membership'), findsNothing);

      // Tap Recurring filter
      final recurringFilter = find.widgetWithText(ChoiceChip, 'Recurring');
      expect(recurringFilter, findsOneWidget);
      await tester.tap(recurringFilter);
      await tester.pumpAndSettle();

      expect(find.text('Monthly Karate Coaching'), findsOneWidget);
      expect(find.text('1 Schedules'), findsOneWidget);
    });

    testWidgets('2. AddDueScreen shows customer dropdown and creates due',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
            customerRepositoryProvider.overrideWithValue(fakeCustomerRepo),
            duesRepositoryProvider.overrideWithValue(fakeDuesRepo),
            recurringDueRepositoryProvider.overrideWithValue(fakeRecurringRepo),
            notificationServiceProvider
                .overrideWithValue(fakeNotificationService),
          ],
          child: const MaterialApp(
            home: AddDueScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Add Due'), findsOneWidget);
      expect(find.text('Who? (Client)'), findsOneWidget);
      expect(find.text('Create Due'), findsOneWidget);
    });

    testWidgets(
        '3. DueDetailsScreen shows due information, Mark as Paid, and popup menu',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
            customerRepositoryProvider.overrideWithValue(fakeCustomerRepo),
            duesRepositoryProvider.overrideWithValue(fakeDuesRepo),
            recurringDueRepositoryProvider.overrideWithValue(fakeRecurringRepo),
            notificationServiceProvider
                .overrideWithValue(fakeNotificationService),
          ],
          child: const MaterialApp(
            home: DueDetailsScreen(dueId: 'd1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Due Details'), findsOneWidget);
      expect(find.text('August Karate Fee'), findsOneWidget);
      expect(find.text('Rahul Kumar'), findsOneWidget);
      expect(find.text('Mark as Paid'), findsOneWidget);
      expect(find.text('Payment History'), findsOneWidget);

      // Check popup menu
      final popupMenu = find.byType(PopupMenuButton<String>);
      expect(popupMenu, findsOneWidget);
      await tester.tap(popupMenu);
      await tester.pumpAndSettle();

      expect(find.text('Edit Due'), findsOneWidget);
      expect(find.text('Cancel Due'), findsOneWidget);
      expect(find.text('Delete Record'), findsOneWidget);
    });

    testWidgets(
        '4. DueDetailsScreen with payment history shows payment records',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      fakeDuesRepo = FakeDuesRepository(
        ownerId: 'owner_1',
        initialDues: [
          DueEntity(
            id: 'd1',
            ownerId: 'owner_1',
            customerId: 'c1',
            customerName: 'Rahul Kumar',
            amount: 1500.0,
            description: 'August Karate Fee',
            dueDate: todayStr,
            status: DueStatus.partiallyPaid,
          ),
        ],
        initialPayments: [
          PaymentRecordEntity(
            id: 'p1',
            dueId: 'd1',
            customerId: 'c1',
            customerName: 'Rahul Kumar',
            amount: 500.0,
            paymentMethod: PaymentMethod.cash,
            paidAt: todayStr,
            notes: 'Advance installment',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
            customerRepositoryProvider.overrideWithValue(fakeCustomerRepo),
            duesRepositoryProvider.overrideWithValue(fakeDuesRepo),
            recurringDueRepositoryProvider.overrideWithValue(fakeRecurringRepo),
            notificationServiceProvider
                .overrideWithValue(fakeNotificationService),
          ],
          child: const MaterialApp(
            home: DueDetailsScreen(dueId: 'd1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Record Payment'), findsOneWidget);
      expect(find.text('Advance installment'), findsOneWidget);
      expect(find.text('1 Payments'), findsOneWidget);
    });
  });
}
