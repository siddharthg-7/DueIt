import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/routing/route_names.dart';
import 'package:dueit/core/utils/currency_formatter.dart';
import 'package:dueit/shared/widgets/app_top_bar.dart';
import 'package:dueit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dueit/features/customers/presentation/controllers/customer_controller.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';
import 'package:dueit/features/dues/presentation/controllers/dues_controller.dart';
import 'package:dueit/features/reminders/presentation/controllers/reminder_controller.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  int _selectedMonthOffset = 0;

  @override
  Widget build(BuildContext context) {
    final duesState = ref.watch(duesControllerProvider);
    final customerState = ref.watch(customerControllerProvider);
    final user = ref.watch(authControllerProvider).user;
    final unreadCount = ref.watch(reminderControllerProvider).unreadCount;

    final now = DateTime.now();
    final targetDate = DateTime(now.year, now.month - _selectedMonthOffset, 1);
    final monthLabel = DateFormat('MMMM yyyy').format(targetDate);
    final yearMonthStr = DateFormat('yyyy-MM').format(targetDate);

    // Filter dues for target month
    final monthDues = duesState.dues.where((d) {
      return d.dueDate.startsWith(yearMonthStr) ||
          (d.paidAt != null && d.paidAt!.startsWith(yearMonthStr));
    }).toList();

    final collected = monthDues.fold<double>(0, (sum, d) => sum + d.paidAmount);
    final pending = monthDues
        .where((d) =>
            d.status != DueStatus.paid && d.status != DueStatus.cancelled)
        .fold<double>(0, (sum, d) => sum + d.remainingAmount);
    final totalExpected = collected + pending;
    final rate =
        totalExpected > 0 ? ((collected / totalExpected) * 100).round() : 0;
    final paidCount = monthDues.where((d) => d.status == DueStatus.paid).length;
    final pendingCount = monthDues
        .where((d) =>
            d.status != DueStatus.paid && d.status != DueStatus.cancelled)
        .length;

    // Real Batch breakdown
    final Map<String, Map<String, double>> batchMap = {};
    for (final cust in customerState.customers) {
      final batchName = cust.notes?.split('(').first.trim() ?? 'General Client';
      if (!batchMap.containsKey(batchName)) {
        batchMap[batchName] = {'collected': 0, 'pending': 0};
      }
      final clientDues = monthDues.where((d) => d.customerId == cust.id);
      for (final d in clientDues) {
        batchMap[batchName]!['collected'] =
            batchMap[batchName]!['collected']! + d.paidAmount;
        if (d.status != DueStatus.paid && d.status != DueStatus.cancelled) {
          batchMap[batchName]!['pending'] =
              batchMap[batchName]!['pending']! + d.remainingAmount;
        }
      }
    }

    final batchList = batchMap.entries
        .where((e) => e.value['collected']! > 0 || e.value['pending']! > 0)
        .map((e) {
      final bCol = e.value['collected']!;
      final bPen = e.value['pending']!;
      final bTot = bCol + bPen;
      final bRate = bTot > 0 ? ((bCol / bTot) * 100).round() : 0;
      return {'name': e.key, 'collected': bCol, 'pending': bPen, 'rate': bRate};
    }).toList()
      ..sort((a, b) =>
          (b['collected'] as double).compareTo(a['collected'] as double));

    return Scaffold(
      appBar: AppTopBar(
        title: 'Insights',
        onProfile: () => context.push(RouteNames.settings),
        onNotifications: () => context.push(RouteNames.notifications),
        unreadNotificationsCount: unreadCount,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Month Selector Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Performance Analytics',
                      style: AppTypography.headlineMedium
                          .copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user?.businessName ?? 'DueIt',
                      style: AppTypography.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      visualDensity: VisualDensity.compact,
                      onPressed: _selectedMonthOffset < 5
                          ? () => setState(() => _selectedMonthOffset++)
                          : null,
                    ),
                    Text(
                      DateFormat('MMM yy').format(targetDate),
                      style: AppTypography.labelSmall
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      visualDensity: VisualDensity.compact,
                      onPressed: _selectedMonthOffset > 0
                          ? () => setState(() => _selectedMonthOffset--)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Efficiency Rate Card
          Card(
            color: AppColors.surfaceContainerLowest,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: AppColors.surfaceVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Collection Efficiency',
                          style: AppTypography.labelSmall),
                      const SizedBox(height: 4),
                      Text(
                        '$rate%',
                        style: AppTypography.displayLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('$paidCount dues collected in $monthLabel',
                          style: AppTypography.bodySmall),
                    ],
                  ),
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: rate / 100,
                          strokeWidth: 6,
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary),
                        ),
                        const Icon(Icons.trending_up,
                            color: AppColors.primary, size: 28),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Collected vs Pending Bento Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.surfaceVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance_wallet,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text('Collected', style: AppTypography.labelSmall),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        CurrencyFormatter.format(collected),
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('$paidCount settlements',
                          style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.surfaceVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_rounded,
                              size: 16, color: AppColors.error),
                          const SizedBox(width: 6),
                          Text('Pending Due', style: AppTypography.labelSmall),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        CurrencyFormatter.format(pending),
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('$pendingCount pending items',
                          style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category / Batch Breakdown
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Batch / Category Breakdown',
                        style: AppTypography.titleMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text('${batchList.length} groups',
                        style: AppTypography.bodySmall),
                  ],
                ),
                const SizedBox(height: 16),
                if (batchList.isEmpty)
                  Center(
                      child: Text('No active batches for $monthLabel.',
                          style: AppTypography.bodySmall))
                else
                  ...batchList.map((batch) {
                    final bRate = batch['rate'] as int;
                    final bCol = batch['collected'] as double;
                    final bPen = batch['pending'] as double;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(batch['name'] as String,
                                  style: AppTypography.labelLarge),
                              Text('$bRate%',
                                  style: AppTypography.labelLarge
                                      .copyWith(color: AppColors.primary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: bRate / 100,
                              minHeight: 6,
                              backgroundColor: AppColors.surfaceVariant,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  'Collected: ${CurrencyFormatter.format(bCol)}',
                                  style: AppTypography.bodySmall
                                      .copyWith(fontSize: 11)),
                              Text('Pending: ${CurrencyFormatter.format(bPen)}',
                                  style: AppTypography.bodySmall
                                      .copyWith(fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),

          const SizedBox(height: 90),
        ],
      ),
    );
  }
}
