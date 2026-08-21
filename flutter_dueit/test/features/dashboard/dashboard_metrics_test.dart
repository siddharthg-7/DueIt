import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dueit/core/utils/date_formatter.dart';
import 'package:dueit/features/auth/domain/entities/user_entity.dart';
import 'package:dueit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';
import 'package:dueit/features/dues/domain/entities/payment_record_entity.dart';
import 'package:dueit/features/dues/presentation/controllers/dues_controller.dart';
import 'package:dueit/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:dueit/features/reminders/data/services/local_notification_service.dart';
import '../../mocks/fake_auth_repository.dart';
import '../../mocks/fake_dues_repository.dart';
import '../../mocks/fake_notification_service.dart';

void main() {
  group('DashboardMetrics Reactive Provider & Financial Integration Tests', () {
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
        id: 'owner_1',
        email: 'owner@dueit.com',
        businessName: 'Apex Martial Arts',
        isSetupComplete: true,
      );

      fakeAuthRepo = FakeAuthRepository(initialUser: testUser);
      fakeDuesRepo = FakeDuesRepository(
        ownerId: 'owner_1',
        initialDues: [
          // Today: Due 1 = ₹1,500 (unpaid)
          DueEntity(
            id: 'due_today_1',
            ownerId: 'owner_1',
            customerId: 'cust_1',
            customerName: 'Rahul Kumar',
            amount: 1500.0,
            description: 'Today Due 1',
            dueDate: todayStr,
            status: DueStatus.due,
          ),
          // Today: Due 2 = ₹2,000 (partially paid ₹500, remaining ₹1,500)
          DueEntity(
            id: 'due_today_2',
            ownerId: 'owner_1',
            customerId: 'cust_2',
            customerName: 'Arjun Sharma',
            amount: 2000.0,
            paidAmount: 500.0,
            description: 'Today Due 2',
            dueDate: todayStr,
            status: DueStatus.partiallyPaid,
          ),
          // Overdue: ₹5,000 (partially paid ₹2,000, remaining ₹3,000)
          DueEntity(
            id: 'due_overdue',
            ownerId: 'owner_1',
            customerId: 'cust_3',
            customerName: 'Sneha Reddy',
            amount: 5000.0,
            paidAmount: 2000.0,
            description: 'Overdue Due',
            dueDate: yesterdayStr,
            status: DueStatus.overdue,
          ),
          // Upcoming: ₹1,800 (unpaid)
          DueEntity(
            id: 'due_upcoming',
            ownerId: 'owner_1',
            customerId: 'cust_4',
            customerName: 'Vikram Singh',
            amount: 1800.0,
            description: 'Upcoming Due',
            dueDate: tomorrowStr,
            status: DueStatus.upcoming,
          ),
        ],
        initialPayments: [
          // Partial payment on due_today_2: ₹500
          PaymentRecordEntity(
            id: 'p1',
            ownerId: 'owner_1',
            dueId: 'due_today_2',
            customerId: 'cust_2',
            amount: 500.0,
            paymentMethod: PaymentMethod.cash,
            paidAt: todayStr,
          ),
          // Partial payment on due_overdue: ₹2,000 (paid today)
          PaymentRecordEntity(
            id: 'p2',
            ownerId: 'owner_1',
            dueId: 'due_overdue',
            customerId: 'cust_3',
            amount: 2000.0,
            paymentMethod: PaymentMethod.upi,
            paidAt: todayStr,
          ),
        ],
      );

      final fakeNotificationService = FakeNotificationService();

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

    test(
        '1. Today\'s remaining collection correctly calculates remaining unpaid amounts',
        () {
      final metrics = container.read(dashboardMetricsProvider);

      // Today Due 1: 1500 remaining + Today Due 2: 1500 remaining = 3000
      expect(metrics.toCollectToday, 3000.0);
      expect(metrics.todayDuesCount, 2);
    });

    test('2. Collected Today correctly sums all payments recorded today', () {
      final metrics = container.read(dashboardMetricsProvider);

      // p1 (500) + p2 (2000) = 2500
      expect(metrics.collectedToday, 2500.0);
    });

    test(
        '3. Overdue total correctly reflects remaining balance (₹3,000, not ₹5,000)',
        () {
      final metrics = container.read(dashboardMetricsProvider);

      // Total ₹5,000 - Paid ₹2,000 = ₹3,000
      expect(metrics.overdueTotal, 3000.0);
      expect(metrics.overdueDuesCount, 1);
      expect(metrics.overdueDues.first.remainingAmount, 3000.0);
    });

    test('4. Upcoming total reflects within 30-day horizon', () {
      final metrics = container.read(dashboardMetricsProvider);

      expect(metrics.upcomingTotal, 1800.0);
      expect(metrics.upcomingDuesCount, 1);
    });

    test(
        '5. Needs attention items generated from active overdue and today dues',
        () {
      final metrics = container.read(dashboardMetricsProvider);

      expect(metrics.attentionItems.length, 3);
      expect(metrics.attentionItems.any((i) => i.id == 'attention_overdue'),
          isTrue);
      expect(
          metrics.attentionItems.any((i) => i.id == 'attention_today'), isTrue);
      expect(metrics.attentionItems.any((i) => i.id == 'attention_upcoming'),
          isTrue);
    });

    test(
        '6. Recording payment on today due dynamically updates remaining today and collected today',
        () async {
      final ctrl = container.read(duesControllerProvider.notifier);

      // Record full remaining on due_today_1: ₹1,500
      await ctrl.recordPayment(
        dueId: 'due_today_1',
        amount: 1500.0,
        paymentMethod: PaymentMethod.upi,
      );

      final metrics = container.read(dashboardMetricsProvider);
      // Today remaining was 3000 - 1500 = 1500
      expect(metrics.toCollectToday, 1500.0);
      // Collected today was 2500 + 1500 = 4000
      expect(metrics.collectedToday, 4000.0);
    });
  });
}
