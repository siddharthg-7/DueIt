import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/routing/route_names.dart';
import 'package:dueit/core/utils/currency_formatter.dart';
import 'package:dueit/core/utils/date_formatter.dart';
import 'package:dueit/shared/widgets/app_top_bar.dart';
import 'package:dueit/shared/widgets/due_card.dart';
import 'package:dueit/shared/widgets/empty_state.dart';
import 'package:dueit/shared/widgets/search_field.dart';
import 'package:dueit/shared/widgets/recurring_schedule_card.dart';
import 'package:dueit/features/customers/presentation/controllers/customer_controller.dart';
import 'package:dueit/features/reminders/presentation/controllers/reminder_controller.dart';
import '../../domain/entities/due_entity.dart';
import '../../domain/entities/recurring_due_schedule_entity.dart';
import '../controllers/dues_controller.dart';
import '../controllers/recurring_dues_controller.dart';

class DuesScreen extends ConsumerStatefulWidget {
  const DuesScreen({super.key});

  @override
  ConsumerState<DuesScreen> createState() => _DuesScreenState();
}

class _DuesScreenState extends ConsumerState<DuesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _urgencyWeight(DueEntity due) {
    if (due.status == DueStatus.overdue ||
        (DateFormatter.isBeforeToday(due.dueDate) &&
            due.status != DueStatus.paid)) {
      return 0; // Most urgent
    }
    if (due.status == DueStatus.due ||
        (DateFormatter.isToday(due.dueDate) && due.status != DueStatus.paid)) {
      return 1;
    }
    if (due.status == DueStatus.partiallyPaid) {
      return 2;
    }
    if (due.status == DueStatus.upcoming) {
      return 3;
    }
    return 4; // Paid / settled
  }

  void _showEditScheduleDialog(
      BuildContext context, RecurringDueScheduleEntity schedule) {
    final amountCtrl =
        TextEditingController(text: schedule.amount.toInt().toString());
    final descCtrl = TextEditingController(text: schedule.description);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(bottomContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Edit Recurring Schedule',
                    style: AppTypography.titleMedium
                        .copyWith(fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(bottomContext),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Changes will apply to future generated dues. Existing historical dues will not be altered.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () async {
                  final newAmount = double.tryParse(amountCtrl.text.trim());
                  if (newAmount == null || newAmount <= 0) return;
                  final newDesc = descCtrl.text.trim();
                  if (newDesc.isEmpty) return;

                  final updated = schedule.copyWith(
                    amount: newAmount,
                    description: newDesc,
                  );

                  await ref
                      .read(recurringDuesControllerProvider.notifier)
                      .updateSchedule(updated);

                  if (bottomContext.mounted) {
                    Navigator.pop(bottomContext);
                  }
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duesState = ref.watch(duesControllerProvider);
    final recurringState = ref.watch(recurringDuesControllerProvider);
    final customerState = ref.watch(customerControllerProvider);
    final unreadCount = ref.watch(reminderControllerProvider).unreadCount;

    // Build customer map for instant O(1) customer name resolution
    final customerMap = {for (var c in customerState.customers) c.id: c.name};

    final isRecurringTab = duesState.duesFilter == 'Recurring';

    // Filter recurring schedules if on recurring tab
    final filteredSchedules = recurringState.schedules.where((s) {
      final custName = customerMap[s.customerId] ?? s.customerName;
      final q = _searchController.text.toLowerCase().trim();
      return q.isEmpty ||
          custName.toLowerCase().contains(q) ||
          s.description.toLowerCase().contains(q);
    }).toList();

    // Filter out cancelled dues from active lists
    final activeDues =
        duesState.dues.where((d) => d.status != DueStatus.cancelled).toList();

    final filteredDues = activeDues.where((d) {
      final custName = customerMap[d.customerId] ?? d.customerName;
      final q = _searchController.text.toLowerCase().trim();
      final matchesQuery = q.isEmpty ||
          custName.toLowerCase().contains(q) ||
          d.description.toLowerCase().contains(q);

      if (!matchesQuery) {
        return false;
      }

      if (duesState.duesFilter == 'Paid') {
        return d.status == DueStatus.paid;
      }

      // Active filters exclude fully settled dues
      if (d.status == DueStatus.paid) {
        return false;
      }

      if (duesState.duesFilter == 'Today') {
        return DateFormatter.isToday(d.dueDate);
      }
      if (duesState.duesFilter == 'Overdue') {
        return DateFormatter.isBeforeToday(d.dueDate);
      }
      if (duesState.duesFilter == 'Upcoming') {
        return DateFormatter.isAfterToday(d.dueDate);
      }
      return true;
    }).toList();

    // Urgency sorting
    filteredDues.sort((a, b) {
      final weightA = _urgencyWeight(a);
      final weightB = _urgencyWeight(b);
      if (weightA != weightB) {
        return weightA.compareTo(weightB);
      }
      return a.dueDate.compareTo(b.dueDate);
    });

    final totalFiltered = filteredDues.fold<double>(0, (sum, d) {
      return sum +
          (d.status == DueStatus.paid ? d.paidAmount : d.remainingAmount);
    });

    final totalRecurring =
        filteredSchedules.fold<double>(0, (sum, s) => sum + s.amount);

    final filterTabs = [
      'All',
      'Today',
      'Upcoming',
      'Overdue',
      'Paid',
      'Recurring'
    ];

    String emptyTitle() {
      if (_searchController.text.isNotEmpty) return 'No matching dues';
      switch (duesState.duesFilter) {
        case 'Today':
          return 'No dues today';
        case 'Overdue':
          return 'No overdue payments';
        case 'Upcoming':
          return 'No upcoming dues';
        case 'Paid':
          return 'No settled dues';
        case 'Recurring':
          return 'No recurring dues yet';
        default:
          return 'No payments tracked yet';
      }
    }

    String emptyDescription() {
      if (_searchController.text.isNotEmpty) {
        return 'No payment dues match your search query.';
      }
      switch (duesState.duesFilter) {
        case 'Today':
          return 'You\'re all caught up for today!';
        case 'Overdue':
          return 'No overdue payments. Great job!';
        case 'Upcoming':
          return 'No upcoming payments scheduled.';
        case 'Paid':
          return 'Settled dues will appear here.';
        case 'Recurring':
          return 'Create a recurring schedule to automatically track repeated collections.';
        default:
          return 'Create your first due to start tracking collections.';
      }
    }

    return Scaffold(
      appBar: AppTopBar(
        title: 'Dues',
        onProfile: () => context.push(RouteNames.settings),
        onNotifications: () => context.push(RouteNames.notifications),
        unreadNotificationsCount: unreadCount,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(duesControllerProvider.notifier).loadDues();
          await ref
              .read(recurringDuesControllerProvider.notifier)
              .triggerGeneration();
        },
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Search Bar
            SearchField(
              controller: _searchController,
              hintText: isRecurringTab
                  ? 'Search recurring schedules...'
                  : 'Search dues by client or description...',
              onChanged: (_) => setState(() {}),
              onClear: () => setState(() {}),
            ),
            const SizedBox(height: 12),

            // Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filterTabs.map((tab) {
                  final isSelected = duesState.duesFilter == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(tab),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: AppTypography.labelSmall.copyWith(
                        color: isSelected
                            ? AppColors.onPrimary
                            : AppColors.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      onSelected: (_) {
                        ref
                            .read(duesControllerProvider.notifier)
                            .setFilter(tab);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Filter Summary Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isRecurringTab
                      ? '${filteredSchedules.length} Schedules'
                      : '${filteredDues.length} Records',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isRecurringTab
                      ? 'Total: ${CurrencyFormatter.format(totalRecurring)}/cycle'
                      : 'Total: ${CurrencyFormatter.format(totalFiltered)}',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Recurring Tab Content
            if (isRecurringTab) ...[
              if (recurringState.isLoading && recurringState.schedules.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (filteredSchedules.isEmpty)
                EmptyState(
                  icon: Icons.repeat,
                  title: emptyTitle(),
                  description: emptyDescription(),
                  actionText: '+ Create Recurring Due',
                  onAction: () => context.push(RouteNames.addDue),
                )
              else
                ...filteredSchedules.map((schedule) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: RecurringScheduleCard(
                      schedule: schedule,
                      onPause: () => ref
                          .read(recurringDuesControllerProvider.notifier)
                          .pauseSchedule(schedule.id),
                      onResume: () => ref
                          .read(recurringDuesControllerProvider.notifier)
                          .resumeSchedule(schedule.id),
                      onStop: () => ref
                          .read(recurringDuesControllerProvider.notifier)
                          .stopSchedule(schedule.id),
                      onDelete: () => ref
                          .read(recurringDuesControllerProvider.notifier)
                          .deleteSchedule(schedule.id),
                      onEdit: () => _showEditScheduleDialog(context, schedule),
                    ),
                  );
                }),
            ]
            // Standard Dues Content
            else ...[
              if (duesState.isLoading && duesState.dues.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (filteredDues.isEmpty)
                EmptyState(
                  icon: Icons.receipt_long,
                  title: emptyTitle(),
                  description: emptyDescription(),
                  actionText:
                      duesState.duesFilter == 'Paid' ? null : '+ Create Due',
                  onAction: duesState.duesFilter == 'Paid'
                      ? null
                      : () => context.push(RouteNames.addDue),
                )
              else
                ...filteredDues.map(
                  (due) {
                    final resolvedCustomerName =
                        customerMap[due.customerId] ?? due.customerName;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: DueCard(
                        due: due,
                        customerName: resolvedCustomerName,
                        onTap: () => context.push('/due/${due.id}'),
                      ),
                    );
                  },
                ),
            ],

            const SizedBox(height: 90),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'dues_fab',
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
