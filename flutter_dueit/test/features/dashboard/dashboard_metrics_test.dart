import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dueit/core/utils/date_formatter.dart';
import 'package:dueit/features/auth/domain/entities/user_entity.dart';
import 'package:dueit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';
import 'package:dueit/features/dues/presentation/controllers/dues_controller.dart';
import 'package:dueit/features/dashboard/presentation/controllers/dashboard_controller.dart';
import '../../mocks/fake_auth_repository.dart';
import '../../mocks/fake_dues_repository.dart';

void main() {
  group('DashboardMetrics Financial Invariant Tests', () {
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
          // Today: ₹1,500 + ₹2,000 = ₹3,500
          DueEntity(
            id: 'due_today_1',
            ownerId: 'owner_1',
            customerId: 'cust_1',
            amount: 1500.0,
            description: 'Today Due 1',
            dueDate: todayStr,
            status: DueStatus.due,
          ),
          DueEntity(
            id: 'due_today_2',
            ownerId: 'owner_1',
            customerId: 'cust_2',
            amount: 2000.0,
            description: 'Today Due 2',
            dueDate: todayStr,
            status: DueStatus.due,
          ),
          // Overdue: ₹2,500
          DueEntity(
            id: 'due_overdue',
            ownerId: 'owner_1',
            customerId: 'cust_3',
            amount: 2500.0,
            description: 'Overdue Due',
            dueDate: yesterdayStr,
            status: DueStatus.overdue,
          ),
          // Upcoming: ₹1,800
          DueEntity(
            id: 'due_upcoming',
            ownerId: 'owner_1',
            customerId: 'cust_4',
            amount: 1800.0,
            description: 'Upcoming Due',
            dueDate: tomorrowStr,
            status: DueStatus.upcoming,
          ),
          // Cancelled today due: ₹5,000 (MUST BE EXCLUDED)
          DueEntity(
            id: 'due_cancelled',
            ownerId: 'owner_1',
            customerId: 'cust_5',
            amount: 5000.0,
            description: 'Cancelled Due',
            dueDate: todayStr,
            status: DueStatus.cancelled,
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

    test(
        '1. Today\'s collection correctly sums today active dues and excludes cancelled',
        () {
      final metrics = container.read(dashboardMetricsProvider);

      expect(metrics.todayTotal, 3500.0);
      expect(metrics.todayDues.length, 2);
      expect(metrics.todayDues.any((d) => d.id == 'due_cancelled'), isFalse);
    });

    test(
        '2. Overdue total correctly sums past active dues and excludes today/upcoming/cancelled',
        () {
      final metrics = container.read(dashboardMetricsProvider);

      expect(metrics.overdueTotal, 2500.0);
      expect(metrics.overdueDues.length, 1);
      expect(metrics.overdueDues.first.id, 'due_overdue');
    });

    test('3. Upcoming total correctly sums future active dues', () {
      final metrics = container.read(dashboardMetricsProvider);

      expect(metrics.upcomingTotal, 1800.0);
      expect(metrics.upcomingDues.length, 1);
      expect(metrics.upcomingDues.first.id, 'due_upcoming');
    });

    test('4. Cancelling a due dynamically updates today metrics', () async {
      final ctrl = container.read(duesControllerProvider.notifier);
      await ctrl.cancelDue('due_today_1');

      final metrics = container.read(dashboardMetricsProvider);
      expect(metrics.todayTotal, 2000.0);
      expect(metrics.todayDues.length, 1);
    });
  });
}
