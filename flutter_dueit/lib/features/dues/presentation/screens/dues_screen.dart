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
import 'package:dueit/features/customers/presentation/controllers/customer_controller.dart';
import 'package:dueit/features/reminders/presentation/controllers/reminder_controller.dart';
import '../../domain/entities/due_entity.dart';
import '../controllers/dues_controller.dart';

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

  @override
  Widget build(BuildContext context) {
    final duesState = ref.watch(duesControllerProvider);
    final customerState = ref.watch(customerControllerProvider);
    final unreadCount = ref.watch(reminderControllerProvider).unreadCount;

    // Build customer map for instant O(1) customer name resolution
    final customerMap = {for (var c in customerState.customers) c.id: c.name};

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

    final filterTabs = ['All', 'Today', 'Upcoming', 'Overdue', 'Paid'];

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
        },
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Search Bar
            SearchField(
              controller: _searchController,
              hintText: 'Search dues by client or description...',
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
                  '${filteredDues.length} Records',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Total: ${CurrencyFormatter.format(totalFiltered)}',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Loading state
            if (duesState.isLoading && duesState.dues.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            // Dues List / Empty State
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
