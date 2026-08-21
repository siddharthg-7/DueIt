import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/routing/route_names.dart';
import 'package:dueit/core/utils/currency_formatter.dart';
import 'package:dueit/shared/widgets/app_top_bar.dart';
import 'package:dueit/shared/widgets/collection_summary.dart';
import 'package:dueit/shared/widgets/collection_trend_chart.dart';
import 'package:dueit/shared/widgets/due_card.dart';
import 'package:dueit/shared/widgets/empty_state.dart';
import 'package:dueit/shared/widgets/needs_attention_card.dart';
import 'package:dueit/shared/widgets/section_header.dart';
import 'package:dueit/features/reminders/presentation/controllers/reminder_controller.dart';
import 'package:dueit/features/dues/presentation/controllers/dues_controller.dart';
import 'package:dueit/features/dashboard/presentation/controllers/dashboard_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardMetricsProvider);
    final unreadCount = ref.watch(reminderControllerProvider).unreadCount;

    return Scaffold(
      appBar: AppTopBar(
        title: 'DueIt',
        onProfile: () => context.push(RouteNames.settings),
        onNotifications: () => context.push(RouteNames.notifications),
        unreadNotificationsCount: unreadCount,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(duesControllerProvider.notifier).loadDues();
          await ref
              .read(reminderControllerProvider.notifier)
              .loadNotifications();
        },
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // 1. Greeting Header
            Text(
              _getGreeting(),
              style: AppTypography.headlineLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Here is your financial collection plan.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 20),

            // Onboarding State when new business has no data
            if (!metrics.hasAnyData)
              Card(
                color: AppColors.surfaceContainerLowest,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(
                      color: AppColors.surfaceVariant, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primaryContainer.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.rocket_launch,
                            size: 36, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome to DueIt!',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start tracking who owes you money and when to collect. Create your first payment due to populate your collection dashboard.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: () => context.push(RouteNames.addDue),
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Add First Due'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // 2. Primary Metric: To Collect Today Card
              Card(
                color: AppColors.surfaceContainerLowest,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(
                      color: AppColors.surfaceVariant, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.today,
                                  size: 20, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'To collect today',
                                style: AppTypography.titleMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          if (metrics.collectedToday > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Collected today: ${CurrencyFormatter.format(metrics.collectedToday)}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          CurrencyFormatter.format(metrics.toCollectToday),
                          style: AppTypography.displayLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Across ${metrics.todayDuesCount} pending ${metrics.todayDuesCount == 1 ? 'payment' : 'payments'} due today',
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: () {
                            ref
                                .read(duesControllerProvider.notifier)
                                .setFilter('Today');
                            context.go(RouteNames.dues);
                          },
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: Text(
                              'View Today\'s Dues (${metrics.todayDuesCount})'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Secondary Urgency Grid (Bento Style)
              Row(
                children: [
                  // Overdue Bento Card
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        ref
                            .read(duesControllerProvider.notifier)
                            .setFilter('Overdue');
                        context.go(RouteNames.dues);
                      },
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              AppColors.errorContainer.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.errorContainer),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_rounded,
                                    size: 16, color: AppColors.error),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'OVERDUE',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                      fontSize: 10.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                CurrencyFormatter.format(metrics.overdueTotal),
                                style: AppTypography.headlineMedium.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${metrics.overdueDuesCount} dues (${metrics.overdueCustomersCount} cust)',
                              style: AppTypography.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Upcoming Bento Card
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        ref
                            .read(duesControllerProvider.notifier)
                            .setFilter('Upcoming');
                        context.go(RouteNames.dues);
                      },
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.surfaceVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_month,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'UPCOMING',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                      fontSize: 10.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                CurrencyFormatter.format(metrics.upcomingTotal),
                                style: AppTypography.headlineMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${metrics.upcomingDuesCount} dues (Next 30d)',
                              style: AppTypography.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 4. Needs Attention Section
              if (metrics.attentionItems.isNotEmpty) ...[
                Text(
                  'Needs Attention',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                NeedsAttentionCard(
                  items: metrics.attentionItems,
                  onAction: (filterRoute) {
                    ref
                        .read(duesControllerProvider.notifier)
                        .setFilter(filterRoute);
                    context.go(RouteNames.dues);
                  },
                ),
                const SizedBox(height: 20),
              ],

              // 5. Due Today Section Header & List
              SectionHeader(
                title: 'Due Today',
                count: metrics.todayDuesCount,
                actionText: metrics.todayDuesCount > 0 ? 'See all' : null,
                onAction: () {
                  ref.read(duesControllerProvider.notifier).setFilter('Today');
                  context.go(RouteNames.dues);
                },
              ),
              const SizedBox(height: 8),

              if (metrics.todayDues.isEmpty)
                EmptyState(
                  icon: Icons.task_alt,
                  title: 'All caught up for today!',
                  description:
                      'No pending collections due today. You can create a new payment due anytime.',
                  actionText: '+ Create Due',
                  onAction: () => context.push(RouteNames.addDue),
                )
              else
                ...metrics.todayDues.take(3).map(
                      (due) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: DueCard(
                          due: due,
                          onTap: () => context.push('/due/${due.id}'),
                        ),
                      ),
                    ),

              const SizedBox(height: 20),

              // 6. Monthly Collection Planning Card
              CollectionSummary(
                expectedTotal: metrics.expectedMonthTotal,
                collectedTotal: metrics.collectedMonthTotal,
                outstandingTotal: metrics.outstandingMonthTotal,
                collectionRate: metrics.collectionRate,
              ),
              const SizedBox(height: 20),

              // 7. Collection Trend Chart
              CollectionTrendChart(
                dailyTrend: metrics.dailyTrend,
                totalCollectedMonth: metrics.collectedMonthTotal,
              ),
            ],

            const SizedBox(height: 90),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'dashboard_fab',
        onPressed: () => context.push(RouteNames.addDue),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
