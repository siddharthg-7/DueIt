import 'package:dueit/features/dues/domain/entities/due_entity.dart';

/// Single point representing collection on a specific day of the month
class DailyCollectionPoint {
  final String dateIso; // 'YYYY-MM-DD'
  final int dayOfMonth; // 1..31
  final double amount;

  const DailyCollectionPoint({
    required this.dateIso,
    required this.dayOfMonth,
    required this.amount,
  });
}

/// Actionable attention item for the business owner
class AttentionItem {
  final String id;
  final String title;
  final String description;
  final double? amount;
  final String filterRoute; // e.g. 'Overdue', 'Today', 'Upcoming'
  final bool isUrgent;

  const AttentionItem({
    required this.id,
    required this.title,
    required this.description,
    this.amount,
    required this.filterRoute,
    this.isUrgent = false,
  });
}

/// Financial summary for a specific customer
class CustomerCollectionSummary {
  final String customerId;
  final String customerName;
  final double outstandingAmount;
  final double collectedAmount;
  final int activeDuesCount;

  const CustomerCollectionSummary({
    required this.customerId,
    required this.customerName,
    required this.outstandingAmount,
    required this.collectedAmount,
    required this.activeDuesCount,
  });
}

/// Pure domain model containing all calculated financial planning metrics
class DashboardFinancialMetrics {
  // Today's Metrics
  final double
      toCollectToday; // Remaining balance of active dues where dueDate == today
  final int todayDuesCount; // Count of active dues where dueDate == today
  final double collectedToday; // Payments recorded where paidAt == today
  final List<DueEntity> todayDues;

  // Overdue Metrics
  final double
      overdueTotal; // Remaining balance of active dues where dueDate < today
  final int overdueDuesCount;
  final int overdueCustomersCount;
  final List<DueEntity> overdueDues;

  // Upcoming Metrics (30-day planning horizon)
  final double
      upcomingTotal; // Remaining balance of active dues where today < dueDate <= today + 30
  final int upcomingDuesCount;
  final List<DueEntity> upcomingDues;

  // Monthly Collection Planning (Current Calendar Month)
  final double
      expectedMonthTotal; // Original amount of non-cancelled dues with dueDate in month
  final double collectedMonthTotal; // Total payments recorded in month
  final double
      outstandingMonthTotal; // Remaining balances for dues with dueDate in month
  final double?
      collectionRate; // % (0.0 to 1.0) or null if no current-month dues

  // Trend & Attention
  final List<DailyCollectionPoint>
      dailyTrend; // Actual payments by day of current month
  final List<AttentionItem> attentionItems; // Actionable alerts
  final List<CustomerCollectionSummary> topCustomers; // Summaries by customer

  const DashboardFinancialMetrics({
    this.toCollectToday = 0.0,
    this.todayDuesCount = 0,
    this.collectedToday = 0.0,
    this.todayDues = const [],
    this.overdueTotal = 0.0,
    this.overdueDuesCount = 0,
    this.overdueCustomersCount = 0,
    this.overdueDues = const [],
    this.upcomingTotal = 0.0,
    this.upcomingDuesCount = 0,
    this.upcomingDues = const [],
    this.expectedMonthTotal = 0.0,
    this.collectedMonthTotal = 0.0,
    this.outstandingMonthTotal = 0.0,
    this.collectionRate,
    this.dailyTrend = const [],
    this.attentionItems = const [],
    this.topCustomers = const [],
  });

  /// Check if the dashboard has any business data
  bool get hasAnyData =>
      todayDuesCount > 0 ||
      overdueDuesCount > 0 ||
      upcomingDuesCount > 0 ||
      expectedMonthTotal > 0 ||
      collectedMonthTotal > 0;
}
