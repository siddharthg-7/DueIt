import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/routing/route_names.dart';
import 'package:dueit/core/utils/currency_formatter.dart';
import 'package:dueit/shared/widgets/app_top_bar.dart';
import 'package:dueit/shared/widgets/due_card.dart';
import 'package:dueit/shared/widgets/empty_state.dart';
import 'package:dueit/shared/widgets/search_field.dart';
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

  @override
  Widget build(BuildContext context) {
    final duesState = ref.watch(duesControllerProvider);
    final unreadCount = ref.watch(reminderControllerProvider).unreadCount;

    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final filteredDues = duesState.dues.where((d) {
      final q = _searchController.text.toLowerCase().trim();
      final matchesQuery = q.isEmpty ||
          d.customerName.toLowerCase().contains(q) ||
          d.description.toLowerCase().contains(q);

      if (!matchesQuery) return false;

      if (duesState.duesFilter == 'Today') return d.dueDate == todayStr;
      if (duesState.duesFilter == 'Overdue') return d.status == DueStatus.overdue;
      if (duesState.duesFilter == 'Upcoming') return d.dueDate.compareTo(todayStr) > 0 && !d.isFullyPaid;
      if (duesState.duesFilter == 'Paid') return d.status == DueStatus.paid;
      return true;
    }).toList();

    final totalFiltered = filteredDues.fold<double>(0, (sum, d) {
      return sum + (d.status == DueStatus.paid ? d.amount : d.remainingAmount);
    });

    final filterTabs = ['All', 'Today', 'Upcoming', 'Overdue', 'Paid'];

    return Scaffold(
      appBar: AppTopBar(
        title: 'Payment History',
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
                        color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      onSelected: (_) {
                        ref.read(duesControllerProvider.notifier).setFilter(tab);
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

            // Dues List / Empty State
            if (filteredDues.isEmpty)
              EmptyState(
                icon: Icons.receipt_long,
                title: 'No dues found',
                description: 'No payment dues match the current filter "${duesState.duesFilter}".',
                actionText: '+ Create Due',
                onAction: () => context.push(RouteNames.addDue),
              )
            else
              ...filteredDues.map(
                (due) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DueCard(
                    due: due,
                    onTap: () => context.push('/due/${due.id}'),
                  ),
                ),
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
