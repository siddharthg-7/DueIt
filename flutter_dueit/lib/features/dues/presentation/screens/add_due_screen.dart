import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/utils/date_formatter.dart';
import 'package:dueit/core/routing/route_names.dart';
import 'package:dueit/shared/widgets/app_top_bar.dart';
import 'package:dueit/shared/widgets/app_text_field.dart';
import 'package:dueit/shared/widgets/date_selector.dart';
import 'package:dueit/shared/widgets/reminder_selector.dart';
import 'package:dueit/shared/widgets/recurrence_selector.dart';
import 'package:dueit/shared/widgets/empty_state.dart';
import 'package:dueit/features/customers/presentation/controllers/customer_controller.dart';
import '../../domain/entities/due_entity.dart';
import '../../domain/entities/recurring_due_schedule_entity.dart';
import '../controllers/dues_controller.dart';
import '../controllers/recurring_dues_controller.dart';

class AddDueScreen extends ConsumerStatefulWidget {
  final String? preselectedCustomerId;

  const AddDueScreen({super.key, this.preselectedCustomerId});

  @override
  ConsumerState<AddDueScreen> createState() => _AddDueScreenState();
}

class _AddDueScreenState extends ConsumerState<AddDueScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String? _selectedCustomerId;
  DateTime _selectedDate = DateTime.now();
  String _selectedRecurrence = 'One-time';
  String _selectedReminder = '1 day before';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.preselectedCustomerId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _addQuickAmount(int val) {
    final current = double.tryParse(_amountController.text) ?? 0;
    _amountController.text = (current + val).toInt().toString();
  }

  RecurrenceFrequency _getRecurrenceFrequency(String val) {
    switch (val.toLowerCase()) {
      case 'weekly':
        return RecurrenceFrequency.weekly;
      case 'quarterly':
        return RecurrenceFrequency.quarterly;
      case 'annually':
      case 'yearly':
        return RecurrenceFrequency.yearly;
      case 'monthly':
      default:
        return RecurrenceFrequency.monthly;
    }
  }

  ReminderType _getReminderType(String val) {
    return ReminderType.fromString(val);
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerControllerProvider);
    final customers = customerState.customers;

    if (_selectedCustomerId == null && customers.isNotEmpty) {
      _selectedCustomerId = customers.first.id;
    }

    final selectedCustomer =
        customers.where((c) => c.id == _selectedCustomerId).firstOrNull;

    if (customers.isEmpty && !customerState.isLoading) {
      return Scaffold(
        appBar: AppTopBar(
          title: 'Add Due',
          showBack: true,
          onBack: () => context.pop(),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: EmptyState(
              icon: Icons.person_add_disabled_outlined,
              title: 'No Customers Found',
              description: 'Add a customer before creating a payment due.',
              actionText: '+ Go to People',
              onAction: () => context.push(RouteNames.customers),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppTopBar(
        title: 'Add Due',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Amount Card (Bento Hero)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.surfaceVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'DUE AMOUNT',
                  style: AppTypography.labelSmall.copyWith(
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '₹',
                      style: AppTypography.displayLarge.copyWith(
                        color: AppColors.primary,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IntrinsicWidth(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        style: AppTypography.displayLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 40,
                        ),
                        decoration: InputDecoration(
                          hintText: '1,500',
                          hintStyle: AppTypography.displayLarge.copyWith(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            fontSize: 40,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [500, 1000, 1500, 2000, 5000].map((val) {
                    return ActionChip(
                      label: Text('+$val'),
                      onPressed: () => _addQuickAmount(val),
                      backgroundColor: AppColors.surfaceContainerLow,
                      labelStyle: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: AppColors.surfaceVariant),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Client Dropdown Box
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Who? (Client)',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ' *',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCustomerId,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceContainerLowest,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.outlineVariant, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.outlineVariant, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  items: customers.map((c) {
                    final displayPhone =
                        c.phone.isNotEmpty ? ' (${c.phone})' : '';
                    return DropdownMenuItem<String>(
                      value: c.id,
                      child: Text(
                        '${c.name}$displayPhone',
                        style: AppTypography.bodyLarge
                            .copyWith(color: AppColors.onSurface),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCustomerId = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Description Field
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: AppTextField(
              controller: _descController,
              label: 'For (Description / Reason) *',
              hintText: 'e.g. August Karate Fee, Monthly Retainer',
              prefixIcon: Icons.description_outlined,
            ),
          ),
          const SizedBox(height: 16),

          // Date Selector
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: DateSelector(
              selectedDate: _selectedDate,
              onDateSelected: (d) => setState(() => _selectedDate = d),
            ),
          ),
          const SizedBox(height: 16),

          // Reminder Selector
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: ReminderSelector(
              selectedValue: _selectedReminder,
              onChanged: (val) => setState(() => _selectedReminder = val),
            ),
          ),
          const SizedBox(height: 16),

          // Recurrence Selector
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: RecurrenceSelector(
              selectedValue: _selectedRecurrence,
              onChanged: (val) => setState(() => _selectedRecurrence = val),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border:
              const Border(top: BorderSide(color: AppColors.surfaceVariant)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            onPressed: _isSubmitting
                ? null
                : () async {
                    final amountText = _amountController.text.trim();
                    final amount = double.tryParse(amountText);

                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Enter an amount greater than ₹0.')),
                      );
                      return;
                    }

                    if (selectedCustomer == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Select a customer.')),
                      );
                      return;
                    }

                    final description = _descController.text.trim();
                    if (description.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Enter what this payment is for.')),
                      );
                      return;
                    }

                    setState(() => _isSubmitting = true);

                    final dueDateStr =
                        DateFormatter.formatIsoDate(_selectedDate);
                    final isRecurring =
                        _selectedRecurrence.toLowerCase() != 'one-time' &&
                            _selectedRecurrence.toLowerCase() != 'none';

                    if (isRecurring) {
                      final freq = _getRecurrenceFrequency(_selectedRecurrence);
                      final schedule = await ref
                          .read(recurringDuesControllerProvider.notifier)
                          .createSchedule(
                            customerId: selectedCustomer.id,
                            customerName: selectedCustomer.name,
                            amount: amount,
                            description: description,
                            frequency: freq,
                            dayOfMonth: _selectedDate.day,
                            dayOfWeek: _selectedDate.weekday,
                            startDate: dueDateStr,
                            reminderEnabled:
                                _selectedReminder.toLowerCase() != 'none',
                            reminderType: _getReminderType(_selectedReminder),
                          );

                      if (!mounted) return;
                      setState(() => _isSubmitting = false);

                      if (schedule != null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Recurring ${freq.displayName} due schedule created.'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          context.pop();
                        }
                      } else {
                        final err =
                            ref.read(recurringDuesControllerProvider).error ??
                                'Failed to create recurring schedule.';
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(err),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    } else {
                      final created = await ref
                          .read(duesControllerProvider.notifier)
                          .addDue(
                            customerId: selectedCustomer.id,
                            customerName: selectedCustomer.name,
                            amount: amount,
                            description: description,
                            dueDate: dueDateStr,
                            recurrence: RecurrenceType.none,
                            reminderEnabled:
                                _selectedReminder.toLowerCase() != 'none',
                            reminderType: _getReminderType(_selectedReminder),
                          );

                      if (!mounted) return;
                      setState(() => _isSubmitting = false);
                      if (created != null) {
                        if (context.mounted) {
                          final hasReminder = created.reminderEnabled &&
                              created.reminderType != ReminderType.none;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(hasReminder
                                  ? 'Due added. Reminder scheduled.'
                                  : 'Due added successfully.'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          context.pop();
                        }
                      } else {
                        final err = ref.read(duesControllerProvider).error ??
                            'Failed to create due.';
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(err),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    }
                  },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: _isSubmitting
                ? const SizedBox.shrink()
                : const Icon(Icons.check_circle, size: 22),
            label: _isSubmitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Create Due',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
