import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dueit/core/utils/date_formatter.dart';
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

  // Active dues exclude cancelled dues
  final activeDues =
      dues.where((d) => d.status != DueStatus.cancelled).toList();

  // 1. Today's Dues: dueDate == today
  final todayDues = activeDues.where((d) {
    return DateFormatter.isToday(d.dueDate) && d.status != DueStatus.paid;
  }).toList();
  final todaySum =
      todayDues.fold<double>(0, (sum, d) => sum + d.remainingAmount);

  // 2. Overdue Dues: dueDate < today
  final overdueDues = activeDues.where((d) {
    return DateFormatter.isBeforeToday(d.dueDate) && d.status != DueStatus.paid;
  }).toList();
  final overdueSum =
      overdueDues.fold<double>(0, (sum, d) => sum + d.remainingAmount);

  // 3. Upcoming Dues: dueDate > today
  final upcomingDues = activeDues.where((d) {
    return DateFormatter.isAfterToday(d.dueDate) && d.status != DueStatus.paid;
  }).toList();
  final upcomingSum =
      upcomingDues.fold<double>(0, (sum, d) => sum + d.remainingAmount);

  // 4. Month Breakdown (Calculated from active dues)
  final now = DateTime.now();
  final currentYearMonth =
      '${now.year}-${now.month.toString().padLeft(2, '0')}';

  final monthDues = activeDues.where((d) {
    return d.dueDate.startsWith(currentYearMonth) ||
        (d.paidAt != null && d.paidAt!.startsWith(currentYearMonth));
  }).toList();

  final collectedMonth =
      monthDues.fold<double>(0, (sum, d) => sum + d.paidAmount);
  final pendingMonth = monthDues
      .where((d) => d.status != DueStatus.paid)
      .fold<double>(0, (sum, d) => sum + d.remainingAmount);
  final expectedMonth = collectedMonth + pendingMonth;
  final rate =
      expectedMonth > 0 ? ((collectedMonth / expectedMonth) * 100).round() : 0;

  return DashboardMetrics(
    todayTotal: todaySum,
    todayDues: todayDues,
    overdueTotal: overdueSum,
    overdueDues: overdueDues,
    upcomingTotal: upcomingSum,
    upcomingDues: upcomingDues,
    expectedMonthTotal: expectedMonth,
    collectedMonthTotal: collectedMonth,
    pendingMonthTotal: pendingMonth,
    collectionRate: rate,
  );
});
