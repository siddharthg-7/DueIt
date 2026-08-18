import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';
import 'package:dueit/features/dues/presentation/controllers/dues_controller.dart';

class DashboardMetrics {
  final double todayTotal;
  final List<DueEntity> todayDues;
  final double overdueTotal;
  final List<DueEntity> overdueDues;
  final double upcomingTotal;
  final List<DueEntity> upcomingDues;
  final double expectedMonthTotal;
  final double collectedMonthTotal;
  final double pendingMonthTotal;
  final int collectionRate;

  const DashboardMetrics({
    this.todayTotal = 0,
    this.todayDues = const [],
    this.overdueTotal = 0,
    this.overdueDues = const [],
    this.upcomingTotal = 0,
    this.upcomingDues = const [],
    this.expectedMonthTotal = 0,
    this.collectedMonthTotal = 0,
    this.pendingMonthTotal = 0,
    this.collectionRate = 0,
  });
}

final dashboardMetricsProvider = Provider<DashboardMetrics>((ref) {
  final duesState = ref.watch(duesControllerProvider);
  final dues = duesState.dues;

  final now = DateTime.now();
  final todayStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final currentYearMonth =
      '${now.year}-${now.month.toString().padLeft(2, '0')}';

  // Today
  final todayPending = dues.where((d) {
    final isToday = d.dueDate == todayStr;
    final isNotSettled =
        d.status != DueStatus.paid && d.status != DueStatus.cancelled;
    return isToday && isNotSettled;
  }).toList();
  final todaySum =
      todayPending.fold<double>(0, (sum, d) => sum + d.remainingAmount);

  // Overdue
  final overdueList = dues.where((d) {
    final isOverdue = d.status == DueStatus.overdue ||
        (d.dueDate.compareTo(todayStr) < 0 &&
            !d.isFullyPaid &&
            d.status != DueStatus.cancelled);
    return isOverdue;
  }).toList();
  final overdueSum =
      overdueList.fold<double>(0, (sum, d) => sum + d.remainingAmount);

  // Upcoming
  final upcomingList = dues.where((d) {
    final isUpcoming = d.dueDate.compareTo(todayStr) > 0 &&
        !d.isFullyPaid &&
        d.status != DueStatus.cancelled;
    return isUpcoming;
  }).toList();
  final upcomingSum =
      upcomingList.fold<double>(0, (sum, d) => sum + d.remainingAmount);

  // Monthly breakdown
  final monthDues = dues.where((d) {
    return d.dueDate.startsWith(currentYearMonth) ||
        (d.paidAt != null && d.paidAt!.startsWith(currentYearMonth));
  }).toList();

  final collectedMonth =
      monthDues.fold<double>(0, (sum, d) => sum + d.paidAmount);
  final pendingMonth = monthDues
      .where(
          (d) => d.status != DueStatus.paid && d.status != DueStatus.cancelled)
      .fold<double>(0, (sum, d) => sum + d.remainingAmount);
  final expectedMonth = collectedMonth + pendingMonth;
  final rate =
      expectedMonth > 0 ? ((collectedMonth / expectedMonth) * 100).round() : 0;

  return DashboardMetrics(
    todayTotal: todaySum,
    todayDues: todayPending,
    overdueTotal: overdueSum,
    overdueDues: overdueList,
    upcomingTotal: upcomingSum,
    upcomingDues: upcomingList,
    expectedMonthTotal: expectedMonth,
    collectedMonthTotal: collectedMonth,
    pendingMonthTotal: pendingMonth,
    collectionRate: rate,
  );
});
