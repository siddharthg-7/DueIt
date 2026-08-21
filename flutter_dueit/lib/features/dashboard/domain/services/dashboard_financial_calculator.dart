import 'package:dueit/core/utils/date_formatter.dart';
import 'package:dueit/core/utils/currency_formatter.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';
import 'package:dueit/features/dues/domain/entities/payment_record_entity.dart';
import '../entities/dashboard_financial_metrics.dart';

/// Pure domain calculation engine for DueIt's collection planning & dashboard metrics.
abstract class DashboardFinancialCalculator {
  /// Default planning horizon in days for upcoming dues
  static const int upcomingHorizonDays = 30;

  /// Calculates comprehensive financial planning metrics from raw dues and payments state.
  static DashboardFinancialMetrics calculate({
    required List<DueEntity> dues,
    required List<PaymentRecordEntity> payments,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final todayIso = DateFormatter.formatIsoDate(now);
    final horizonDate = now.add(const Duration(days: upcomingHorizonDays));
    final horizonIso = DateFormatter.formatIsoDate(horizonDate);

    final currentYearMonth =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    // 1. Filter active non-cancelled dues
    final activeDues =
        dues.where((d) => d.status != DueStatus.cancelled).toList();

    // 2. Today's Due Metrics
    // Active dues where dueDate == today and remaining balance > 0
    final todayDues = activeDues.where((d) {
      return d.dueDate == todayIso &&
          d.status != DueStatus.paid &&
          d.remainingAmount > 0;
    }).toList();

    final toCollectToday =
        todayDues.fold<double>(0.0, (sum, d) => sum + d.remainingAmount);

    // 3. Collected Today Metrics
    // Payments recorded today (based on local calendar date)
    final collectedToday = payments.where((p) {
      final pDateIso = _extractLocalDateIso(p.paidAt);
      return pDateIso == todayIso;
    }).fold<double>(0.0, (sum, p) => sum + p.amount);

    // 4. Overdue Metrics
    // Active dues where dueDate < today and remaining balance > 0
    final overdueDues = activeDues.where((d) {
      return d.dueDate.compareTo(todayIso) < 0 &&
          d.status != DueStatus.paid &&
          d.remainingAmount > 0;
    }).toList();

    final overdueTotal =
        overdueDues.fold<double>(0.0, (sum, d) => sum + d.remainingAmount);
    final overdueCustomersCount =
        overdueDues.map((d) => d.customerId).toSet().length;

    // 5. Upcoming Metrics (Within 30-day horizon)
    // Active dues where today < dueDate <= today + 30 days and remaining balance > 0
    final upcomingDues = activeDues.where((d) {
      return d.dueDate.compareTo(todayIso) > 0 &&
          d.dueDate.compareTo(horizonIso) <= 0 &&
          d.status != DueStatus.paid &&
          d.remainingAmount > 0;
    }).toList();

    final upcomingTotal =
        upcomingDues.fold<double>(0.0, (sum, d) => sum + d.remainingAmount);

    // 6. Monthly Collection Planning (Current Calendar Month)
    // Dues originating in this month
    final currentMonthDues = activeDues.where((d) {
      return d.dueDate.startsWith(currentYearMonth);
    }).toList();

    final expectedMonthTotal =
        currentMonthDues.fold<double>(0.0, (sum, d) => sum + d.amount);

    final outstandingMonthTotal =
        currentMonthDues.fold<double>(0.0, (sum, d) => sum + d.remainingAmount);

    // Payments recorded in this month
    final currentMonthPayments = payments.where((p) {
      final pDateIso = _extractLocalDateIso(p.paidAt);
      return pDateIso.startsWith(currentYearMonth);
    }).toList();

    final collectedMonthTotal =
        currentMonthPayments.fold<double>(0.0, (sum, p) => sum + p.amount);

    // Collection Rate:
    // Amount collected against current-month dues / original amount of current-month dues
    double? collectionRate;
    if (expectedMonthTotal > 0) {
      final collectedAgainstCurrentMonthDues = currentMonthDues.fold<double>(
        0.0,
        (sum, d) => sum + d.paidAmount.clamp(0.0, d.amount),
      );
      collectionRate = (collectedAgainstCurrentMonthDues / expectedMonthTotal)
          .clamp(0.0, 1.0);
    } else {
      collectionRate = null; // No current-month dues to measure
    }

    // 7. Daily Collection Trend for Current Month
    final daysInCurrentMonth = DateTime(now.year, now.month + 1, 0).day;
    final List<DailyCollectionPoint> dailyTrend = [];

    // Map payments to day of month
    final Map<int, double> dailySums = {};
    for (final p in currentMonthPayments) {
      final pDate = DateFormatter.parseLocalDate(p.paidAt);
      if (pDate.year == now.year && pDate.month == now.month) {
        dailySums[pDate.day] = (dailySums[pDate.day] ?? 0.0) + p.amount;
      }
    }

    for (int day = 1; day <= daysInCurrentMonth; day++) {
      final dateIso =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      dailyTrend.add(DailyCollectionPoint(
        dateIso: dateIso,
        dayOfMonth: day,
        amount: dailySums[day] ?? 0.0,
      ));
    }

    // 8. Needs Attention Actionable Items
    final List<AttentionItem> attentionItems = [];

    if (overdueDues.isNotEmpty) {
      attentionItems.add(AttentionItem(
        id: 'attention_overdue',
        title:
            '${overdueDues.length} Overdue ${overdueDues.length == 1 ? 'Payment' : 'Payments'}',
        description:
            '${CurrencyFormatter.format(overdueTotal)} pending across $overdueCustomersCount ${overdueCustomersCount == 1 ? 'customer' : 'customers'}',
        amount: overdueTotal,
        filterRoute: 'Overdue',
        isUrgent: true,
      ));
    }

    if (todayDues.isNotEmpty) {
      attentionItems.add(AttentionItem(
        id: 'attention_today',
        title:
            '${todayDues.length} ${todayDues.length == 1 ? 'Payment' : 'Payments'} Due Today',
        description:
            '${CurrencyFormatter.format(toCollectToday)} scheduled for collection today',
        amount: toCollectToday,
        filterRoute: 'Today',
        isUrgent: false,
      ));
    }

    if (upcomingDues.isNotEmpty) {
      attentionItems.add(AttentionItem(
        id: 'attention_upcoming',
        title:
            '${upcomingDues.length} Upcoming ${upcomingDues.length == 1 ? 'Payment' : 'Payments'}',
        description:
            '${CurrencyFormatter.format(upcomingTotal)} expected in next 30 days',
        amount: upcomingTotal,
        filterRoute: 'Upcoming',
        isUrgent: false,
      ));
    }

    // 9. Customer Collection Summaries
    final Map<String, _CustomerAggregator> customerMap = {};
    for (final d in activeDues) {
      final agg = customerMap.putIfAbsent(
        d.customerId,
        () => _CustomerAggregator(
          customerId: d.customerId,
          customerName: d.customerName,
        ),
      );
      agg.outstanding += d.remainingAmount;
      agg.collected += d.paidAmount;
      if (d.status != DueStatus.paid) {
        agg.activeCount++;
      }
    }

    final topCustomers = customerMap.values
        .map((a) => CustomerCollectionSummary(
              customerId: a.customerId,
              customerName: a.customerName,
              outstandingAmount: a.outstanding,
              collectedAmount: a.collected,
              activeDuesCount: a.activeCount,
            ))
        .toList();

    // Sort by highest outstanding balance
    topCustomers
        .sort((a, b) => b.outstandingAmount.compareTo(a.outstandingAmount));

    return DashboardFinancialMetrics(
      toCollectToday: toCollectToday,
      todayDuesCount: todayDues.length,
      collectedToday: collectedToday,
      todayDues: todayDues,
      overdueTotal: overdueTotal,
      overdueDuesCount: overdueDues.length,
      overdueCustomersCount: overdueCustomersCount,
      overdueDues: overdueDues,
      upcomingTotal: upcomingTotal,
      upcomingDuesCount: upcomingDues.length,
      upcomingDues: upcomingDues,
      expectedMonthTotal: expectedMonthTotal,
      collectedMonthTotal: collectedMonthTotal,
      outstandingMonthTotal: outstandingMonthTotal,
      collectionRate: collectionRate,
      dailyTrend: dailyTrend,
      attentionItems: attentionItems,
      topCustomers: topCustomers,
    );
  }

  /// Extracts the local calendar date ISO string ('YYYY-MM-DD') from a timestamp or ISO string.
  static String _extractLocalDateIso(String dateStr) {
    if (dateStr.length >= 10) {
      final prefix = dateStr.substring(0, 10);
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(prefix)) {
        return prefix;
      }
    }
    final parsed = DateFormatter.parseLocalDate(dateStr);
    return DateFormatter.formatIsoDate(parsed);
  }
}

class _CustomerAggregator {
  final String customerId;
  final String customerName;
  double outstanding = 0.0;
  double collected = 0.0;
  int activeCount = 0;

  _CustomerAggregator({
    required this.customerId,
    required this.customerName,
  });
}
