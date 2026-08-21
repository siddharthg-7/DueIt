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
import 'package:dueit/features/customers/domain/entities/customer_entity.dart';
import 'package:dueit/features/customers/presentation/controllers/customer_controller.dart';
import 'package:dueit/features/reminders/presentation/controllers/reminder_controller.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'recent'; // 'recent', 'name', 'balance'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddClientBottomSheet(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool isSaving = false;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
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
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
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
                        onPressed:
                            isSaving ? null : () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Error banner if any
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.errorContainer),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Client Name (Required)
                  TextFormField(
                    controller: nameCtrl,
                    enabled: !isSaving,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Client Name *',
                      hintText: 'e.g. Rahul Kumar',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Client name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Phone Number (Optional)
                  TextFormField(
                    controller: phoneCtrl,
                    enabled: !isSaving,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number (Optional)',
                      hintText: 'e.g. +91 98765 43210',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (val) {
                      if (val != null && val.trim().isNotEmpty) {
                        if (val.trim().length < 5) {
                          return 'Please enter a valid phone number';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Email Address (Optional)
                  TextFormField(
                    controller: emailCtrl,
                    enabled: !isSaving,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address (Optional)',
                      hintText: 'e.g. rahul@example.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (val) {
                      if (val != null && val.trim().isNotEmpty) {
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(val.trim())) {
                          return 'Please enter a valid email address';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Batch / Category Presets
                  Text('Batch / Category Presets',
                      style: AppTypography.labelSmall),
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
                        onSelected: isSaving
                            ? null
                            : (selected) {
                                setModalState(() {
                                  notesCtrl.text = selected ? preset : '';
                                });
                              },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),

                  // Custom Batch or Notes
                  TextFormField(
                    controller: notesCtrl,
                    enabled: !isSaving,
                    decoration: const InputDecoration(
                      labelText: 'Custom Batch or Notes (Optional)',
                      hintText: 'e.g. Karate Evening Batch',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!(formKey.currentState?.validate() ??
                                  false)) {
                                return;
                              }

                              setModalState(() {
                                isSaving = true;
                                errorMessage = null;
                              });

                              final created = await ref
                                  .read(customerControllerProvider.notifier)
                                  .addCustomer(
                                    name: nameCtrl.text.trim(),
                                    phone: phoneCtrl.text.trim(),
                                    email: emailCtrl.text.trim(),
                                    notes: notesCtrl.text.trim(),
                                  );

                              if (created != null) {
                                if (sheetCtx.mounted) {
                                  Navigator.pop(sheetCtx);
                                }
                              } else {
                                setModalState(() {
                                  isSaving = false;
                                  errorMessage = ref
                                          .read(customerControllerProvider)
                                          .error ??
                                      'Failed to save client. Please try again.';
                                });
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save Client',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
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
      final c = item['customer'] as CustomerEntity;
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
    } else if (_sortBy == 'name') {
      filtered.sort((a, b) => ((a['customer'] as CustomerEntity).name)
          .compareTo((b['customer'] as CustomerEntity).name));
    } else {
      // Default: Most recently created/updated first
      filtered.sort((a, b) => ((b['customer'] as CustomerEntity).updatedAt)
          .compareTo((a['customer'] as CustomerEntity).updatedAt));
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
                    DropdownMenuItem(value: 'recent', child: Text('Recent')),
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                    DropdownMenuItem(value: 'balance', child: Text('Balance')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _sortBy = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Loading state
            if (customerState.isLoading && customerState.customers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            // Customer List / Empty State
            else if (filtered.isEmpty)
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
                final customer = item['customer'] as CustomerEntity;
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
