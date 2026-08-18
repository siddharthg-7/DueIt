import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/utils/currency_formatter.dart';
import 'package:dueit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dueit/features/customers/presentation/controllers/customer_controller.dart';
import '../../domain/entities/due_entity.dart';
import '../../domain/entities/payment_record_entity.dart';
import '../controllers/dues_controller.dart';
import 'payment_receipt_dialog.dart';

class RecordPaymentDialog extends ConsumerStatefulWidget {
  final DueEntity due;

  const RecordPaymentDialog({super.key, required this.due});

  static void show(BuildContext context, {required DueEntity due}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RecordPaymentDialog(due: due),
    );
  }

  @override
  ConsumerState<RecordPaymentDialog> createState() =>
      _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends ConsumerState<RecordPaymentDialog> {
  late TextEditingController _amountController;
  final TextEditingController _notesController = TextEditingController();
  PaymentMethod _selectedMethod = PaymentMethod.upi;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.due.remainingAmount.toInt().toString(),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.due.remainingAmount;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long,
                      color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Record Payment',
                    style: AppTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Client & Due Info Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.due.customerName,
                      style: AppTypography.titleMedium
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      widget.due.description,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Remaining Due', style: AppTypography.labelSmall),
                    Text(
                      CurrencyFormatter.format(remaining),
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Amount Input with "Full Amount" button
          Text('Amount Received *', style: AppTypography.labelSmall),
          const SizedBox(height: 6),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style:
                AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              prefixText: '₹ ',
              suffixIcon: TextButton(
                onPressed: () {
                  _amountController.text = remaining.toInt().toString();
                },
                child: const Text('Full Amount'),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Payment Method Selector
          Text('Payment Method', style: AppTypography.labelSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: PaymentMethod.values.map((method) {
              final isSelected = _selectedMethod == method;
              return ChoiceChip(
                label: Text(method.displayName),
                selected: isSelected,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
                onSelected: (selected) {
                  if (selected) setState(() => _selectedMethod = method);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Notes
          Text('Notes / Ref (Optional)', style: AppTypography.labelSmall),
          const SizedBox(height: 6),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              hintText: 'e.g. UPI ref or cash receipt note...',
            ),
          ),
          const SizedBox(height: 24),

          // Confirm Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () async {
                final numAmount = double.tryParse(_amountController.text);
                if (numAmount == null || numAmount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid amount.')),
                  );
                  return;
                }

                final payment = await ref
                    .read(duesControllerProvider.notifier)
                    .recordPayment(
                      dueId: widget.due.id,
                      amount: numAmount,
                      paymentMethod: _selectedMethod,
                      notes: _notesController.text.trim().isEmpty
                          ? null
                          : _notesController.text.trim(),
                    );

                if (mounted && context.mounted) {
                  Navigator.pop(context);

                  // Show receipt dialog
                  final user = ref.read(authControllerProvider).user;
                  final customer = ref
                      .read(customerControllerProvider)
                      .customers
                      .where((c) => c.id == widget.due.customerId)
                      .firstOrNull;

                  if (context.mounted) {
                    PaymentReceiptDialog.show(
                      context,
                      payment: payment,
                      businessProfile: user,
                      customerPhone: customer?.phone,
                    );
                  }
                }
              },
              icon: const Icon(Icons.check_circle, size: 20),
              label: const Text('Confirm & Generate Receipt'),
            ),
          ),
        ],
      ),
    );
  }
}
