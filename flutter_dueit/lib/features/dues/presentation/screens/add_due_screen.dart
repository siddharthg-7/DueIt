import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/utils/date_formatter.dart';
import 'package:dueit/shared/widgets/app_top_bar.dart';
import 'package:dueit/shared/widgets/date_selector.dart';
import 'package:dueit/features/customers/presentation/controllers/customer_controller.dart';
import '../../domain/entities/due_entity.dart';
import '../controllers/dues_controller.dart';

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
  RecurrenceType _recurrence = RecurrenceType.none;
  bool _reminderEnabled = true;
  ReminderType _reminderType = ReminderType.oneDayBefore;

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

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerControllerProvider);
    final customers = customerState.customers;

    if (_selectedCustomerId == null && customers.isNotEmpty) {
      _selectedCustomerId = customers.first.id;
    }

    final selectedCustomer = customers.where((c) => c.id == _selectedCustomerId).firstOrNull;

    return Scaffold(
      appBar: AppTopBar(
        title: 'Add Due',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Amount Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Column(
              children: [
                Text(
                  'DUE AMOUNT',
                  style: AppTypography.labelSmall.copyWith(
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '₹',
                      style: AppTypography.displayLarge.copyWith(
                        color: AppColors.primary,
                        fontSize: 32,
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
                          fontSize: 38,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0',
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
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Client *', style: AppTypography.labelSmall),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCustomerId,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: customers.map((c) {
                    return DropdownMenuItem<String>(
                      value: c.id,
                      child: Text(
                        '${c.name} (${c.phone})',
                        style: AppTypography.bodyLarge,
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
          const SizedBox(height: 14),

          // Description Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('For (Description)', style: AppTypography.labelSmall),
                const SizedBox(height: 6),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. August Karate Fee, Retainer...',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Scheduling Grid: Due Date & Recurrence
          Row(
            children: [
              Expanded(
                child: DateSelector(
                  selectedDate: _selectedDate,
                  onDateSelected: (d) => setState(() => _selectedDate = d),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Repeat', style: AppTypography.labelSmall.copyWith(fontSize: 11)),
                      DropdownButton<RecurrenceType>(
                        value: _recurrence,
                        isExpanded: true,
                        underline: const SizedBox(),
                        style: AppTypography.titleMedium.copyWith(fontSize: 14),
                        items: RecurrenceType.values.map((r) {
                          return DropdownMenuItem(
                            value: r,
                            child: Text(r.displayName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _recurrence = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Reminders Switch Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notifications_active, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text('Reminders', style: AppTypography.titleMedium.copyWith(fontSize: 15)),
                      ],
                    ),
                    Switch(
                      value: _reminderEnabled,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) => setState(() => _reminderEnabled = val),
                    ),
                  ],
                ),
                if (_reminderEnabled) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: ReminderType.values.map((type) {
                      final isSelected = _reminderType == type;
                      return ChoiceChip(
                        label: Text(type.displayName),
                        selected: isSelected,
                        selectedColor: AppColors.primaryContainer.withValues(alpha: 0.2),
                        labelStyle: AppTypography.labelSmall.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 11,
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => _reminderType = type);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: const Border(top: BorderSide(color: AppColors.surfaceVariant)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            onPressed: () async {
              final amount = double.tryParse(_amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount.')),
                );
                return;
              }
              if (selectedCustomer == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a customer.')),
                );
                return;
              }

              final dueDateStr = DateFormatter.formatIsoDate(_selectedDate);

              await ref.read(duesControllerProvider.notifier).addDue(
                    customerId: selectedCustomer.id,
                    customerName: selectedCustomer.name,
                    amount: amount,
                    description: _descController.text.trim(),
                    dueDate: dueDateStr,
                    recurrence: _recurrence,
                    reminderEnabled: _reminderEnabled,
                    reminderType: _reminderType,
                  );

              if (context.mounted) {
                context.pop();
              }
            },
            icon: const Icon(Icons.check_circle, size: 22),
            label: const Text('Create Due'),
          ),
        ),
      ),
    );
  }
}
