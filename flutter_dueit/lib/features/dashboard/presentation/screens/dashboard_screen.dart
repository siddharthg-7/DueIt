import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/routing/route_names.dart';
import 'package:dueit/core/utils/currency_formatter.dart';
import 'package:dueit/shared/widgets/app_top_bar.dart';
import 'package:dueit/shared/widgets/collection_summary.dart';
import 'package:dueit/shared/widgets/due_card.dart';
import 'package:dueit/shared/widgets/empty_state.dart';
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
          await ref.read(reminderControllerProvider.notifier).loadNotifications();
        },
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Greeting
            Text(
              _getGreeting(),
              style: AppTypography.headlineLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Here\'s what needs your attention today.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 20),

            // Primary Metric: To Collect Today Card
            Card(
              color: AppColors.surfaceContainerLowest,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppColors.surfaceVariant, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.today, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'To collect today',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatter.format(metrics.todayTotal),
                        style: AppTypography.displayLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Across ${metrics.todayDues.length} pending ${metrics.todayDues.length == 1 ? 'payment' : 'payments'}',
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: () {
                          ref.read(duesControllerProvider.notifier).setFilter('Today');
                          context.go(RouteNames.dues);
                        },
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: Text('View Today\'s Dues (${metrics.todayDues.length})'),
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

            // Secondary Urgency Grid (Bento Style)
            Row(
              children: [
                // Overdue Bento Card
                Expanded(
                  child: InkWell(
                    onTap: () {
                      ref.read(duesControllerProvider.notifier).setFilter('Overdue');
                      context.go(RouteNames.dues);
                    },
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.errorContainer),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_rounded, size: 16, color: AppColors.error),
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
                            '${metrics.overdueDues.length} payments',
                            style: AppTypography.bodySmall,
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
                      ref.read(duesControllerProvider.notifier).setFilter('Upcoming');
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
                              const Icon(Icons.calendar_month, size: 16, color: AppColors.primary),
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
                            'Next 7 days',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Due Today Section Header
            SectionHeader(
              title: 'Due Today',
              count: metrics.todayDues.length,
              actionText: metrics.todayDues.isNotEmpty ? 'See all' : null,
              onAction: () {
                ref.read(duesControllerProvider.notifier).setFilter('Today');
                context.go(RouteNames.dues);
              },
            ),
            const SizedBox(height: 8),

            // Due Today List / Empty State
            if (metrics.todayDues.isEmpty)
              EmptyState(
                icon: Icons.task_alt,
                title: 'All caught up for today!',
                description: 'No pending collections due today. You can create a new payment due anytime.',
                actionText: '+ Create Due',
                onAction: () => context.push(RouteNames.addDue),
              )
            else
              ...metrics.todayDues.take(4).map(
                    (due) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: DueCard(
                        due: due,
                        onTap: () => context.push('/due/${due.id}'),
                      ),
                    ),
                  ),

            const SizedBox(height: 20),

            // Monthly Summary Card
            CollectionSummary(
              expectedTotal: metrics.expectedMonthTotal,
              collectedTotal: metrics.collectedMonthTotal,
              pendingTotal: metrics.pendingMonthTotal,
            ),
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
