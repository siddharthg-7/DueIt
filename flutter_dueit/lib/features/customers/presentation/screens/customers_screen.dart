import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/routing/route_names.dart';
import 'package:dueit/core/constants/app_constants.dart';
import 'package:dueit/shared/widgets/app_top_bar.dart';
import 'package:dueit/shared/widgets/customer_card.dart';
import 'package:dueit/shared/widgets/empty_state.dart';
import 'package:dueit/shared/widgets/search_field.dart';
import 'package:dueit/features/dues/presentation/controllers/dues_controller.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';
import 'package:dueit/features/customers/presentation/controllers/customer_controller.dart';
import 'package:dueit/features/reminders/presentation/controllers/reminder_controller.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'balance'; // 'balance', 'name'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddClientBottomSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add New Client',
                    style: AppTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Client Name *',
                  hintText: 'e.g. Rahul Kumar',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: 'e.g. +91 98765 43210',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address (Optional)',
                  hintText: 'e.g. rahul@example.com',
                ),
              ),
              const SizedBox(height: 12),
              Text('Batch / Category Presets', style: AppTypography.labelSmall),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: AppConstants.batchPresets.map((preset) {
                  final isSelected = notesCtrl.text == preset;
                  return ChoiceChip(
                    label: Text(preset),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.onPrimary
                          : AppColors.onSurface,
                      fontSize: 11,
                    ),
                    onSelected: (selected) {
                      setModalState(() {
                        notesCtrl.text = selected ? preset : '';
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Custom Batch or Notes',
                  hintText: 'e.g. Karate Evening Batch',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty ||
                        phoneCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Name and phone are required.')),
                      );
                      return;
                    }
                    await ref
                        .read(customerControllerProvider.notifier)
                        .addCustomer(
                          name: nameCtrl.text,
                          phone: phoneCtrl.text,
                          email: emailCtrl.text,
                          notes: notesCtrl.text,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Client'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerControllerProvider);
    final duesState = ref.watch(duesControllerProvider);
    final unreadCount = ref.watch(reminderControllerProvider).unreadCount;

    final customerListWithStats = customerState.customers.map((c) {
      final clientDues =
          duesState.dues.where((d) => d.customerId == c.id).toList();
      final pendingDues = clientDues
          .where(
            (d) =>
                d.status != DueStatus.paid && d.status != DueStatus.cancelled,
          )
          .toList();
      final totalBalance =
          pendingDues.fold<double>(0, (sum, d) => sum + d.remainingAmount);
      final isOverdue = pendingDues.any((d) => d.status == DueStatus.overdue);

      return {
        'customer': c,
        'balance': totalBalance,
        'isOverdue': isOverdue,
      };
    }).toList();

    // Filter by query and tab
    var filtered = customerListWithStats.where((item) {
      final c = item['customer'] as dynamic;
      final q = _searchController.text.toLowerCase().trim();
      final matchesQuery = q.isEmpty ||
          c.name.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q) ||
          (c.notes != null && c.notes!.toLowerCase().contains(q));

      if (!matchesQuery) return false;

      if (customerState.filterTab == 'With Balance') {
        return (item['balance'] as double) > 0;
      }
      if (customerState.filterTab == 'Overdue') {
        return (item['isOverdue'] as bool) == true;
      }
      return true;
    }).toList();

    // Sort
    if (_sortBy == 'balance') {
      filtered.sort(
          (a, b) => (b['balance'] as double).compareTo(a['balance'] as double));
    } else {
      filtered.sort((a, b) => ((a['customer'] as dynamic).name as String)
          .compareTo((b['customer'] as dynamic).name));
    }

    final tabs = ['All', 'With Balance', 'Overdue'];

    return Scaffold(
      appBar: AppTopBar(
        title: 'People',
        onProfile: () => context.push(RouteNames.settings),
        onNotifications: () => context.push(RouteNames.notifications),
        unreadNotificationsCount: unreadCount,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(customerControllerProvider.notifier).loadCustomers();
          await ref.read(duesControllerProvider.notifier).loadDues();
        },
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Search Field
            SearchField(
              controller: _searchController,
              hintText: 'Search by name, phone, or batch...',
              onChanged: (val) => setState(() {}),
              onClear: () => setState(() {}),
            ),
            const SizedBox(height: 12),

            // Filter Tabs & Sort Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: tabs.map((tab) {
                    final isSelected = customerState.filterTab == tab;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(tab),
                        selected: isSelected,
                        selectedColor: AppColors.secondaryContainer,
                        labelStyle: AppTypography.labelSmall.copyWith(
                          color: isSelected
                              ? AppColors.onSecondaryContainer
                              : AppColors.onSurfaceVariant,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        onSelected: (_) {
                          ref
                              .read(customerControllerProvider.notifier)
                              .setFilterTab(tab);
                        },
                      ),
                    );
                  }).toList(),
                ),
                DropdownButton<String>(
                  value: _sortBy,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.sort,
                      size: 18, color: AppColors.primary),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'balance', child: Text('Balance')),
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _sortBy = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Customer List / Empty State
            if (filtered.isEmpty)
              EmptyState(
                icon: Icons.person_off,
                title: 'No clients found',
                description: _searchController.text.isNotEmpty
                    ? 'No client matched your search criteria.'
                    : 'Add your first client to start tracking dues.',
                actionText: '+ Add Client',
                onAction: () => _showAddClientBottomSheet(context),
              )
            else
              ...filtered.map((item) {
                final customer = item['customer'] as dynamic;
                final balance = item['balance'] as double;
                final isOverdue = item['isOverdue'] as bool;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CustomerCard(
                    customer: customer,
                    totalBalance: balance,
                    isOverdue: isOverdue,
                    onTap: () => context.push('/customer/${customer.id}'),
                  ),
                );
              }),

            const SizedBox(height: 90),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'customers_fab',
        onPressed: () => _showAddClientBottomSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.person_add, size: 26),
      ),
    );
  }
}
