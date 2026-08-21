import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/constants/app_constants.dart';
import 'package:dueit/core/utils/currency_formatter.dart';
import 'package:dueit/core/utils/date_formatter.dart';
import 'package:dueit/shared/widgets/app_top_bar.dart';
import 'package:dueit/shared/widgets/due_card.dart';
import 'package:dueit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dueit/features/customers/domain/entities/customer_entity.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';
import 'package:dueit/features/dues/presentation/controllers/dues_controller.dart';
import 'package:dueit/features/dues/presentation/widgets/payment_receipt_dialog.dart';
import 'package:dueit/features/dues/presentation/widgets/record_payment_dialog.dart';
import 'package:dueit/features/reminders/presentation/controllers/reminder_controller.dart';
import '../controllers/customer_controller.dart';

class CustomerDetailsScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailsScreen({super.key, required this.customerId});

  void _showEditCustomerBottomSheet(
      BuildContext context, WidgetRef ref, CustomerEntity customer) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: customer.name);
    final phoneCtrl = TextEditingController(text: customer.phone);
    final emailCtrl = TextEditingController(text: customer.email ?? '');
    final notesCtrl = TextEditingController(text: customer.notes ?? '');
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
                        'Edit Client',
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
                  TextFormField(
                    controller: nameCtrl,
                    enabled: !isSaving,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Client Name *',
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
                  TextFormField(
                    controller: phoneCtrl,
                    enabled: !isSaving,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number (Optional)',
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
                  TextFormField(
                    controller: emailCtrl,
                    enabled: !isSaving,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address (Optional)',
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
                  TextFormField(
                    controller: notesCtrl,
                    enabled: !isSaving,
                    decoration: const InputDecoration(
                      labelText: 'Custom Batch or Notes (Optional)',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
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

                              final updated = customer.copyWith(
                                name: nameCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                                email: emailCtrl.text.trim().isEmpty
                                    ? null
                                    : emailCtrl.text.trim(),
                                notes: notesCtrl.text.trim().isEmpty
                                    ? null
                                    : notesCtrl.text.trim(),
                              );

                              final success = await ref
                                  .read(customerControllerProvider.notifier)
                                  .updateCustomer(updated);

                              if (success) {
                                if (sheetCtx.mounted) {
                                  Navigator.pop(sheetCtx);
                                }
                              } else {
                                setModalState(() {
                                  isSaving = false;
                                  errorMessage = ref
                                          .read(customerControllerProvider)
                                          .error ??
                                      'Failed to update client.';
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
                              'Save Changes',
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

  void _confirmDeleteCustomer(
      BuildContext context, WidgetRef ref, CustomerEntity customer) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete ${customer.name}?',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will permanently remove this customer from your business records.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await ref
                  .read(customerControllerProvider.notifier)
                  .deleteCustomer(customer.id);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${customer.name} removed.')),
                  );
                  context.pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          ref.read(customerControllerProvider).error ??
                              'Failed to delete client.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerState = ref.watch(customerControllerProvider);
    final duesState = ref.watch(duesControllerProvider);
    final user = ref.watch(authControllerProvider).user;
    final reminderRepo = ref.watch(reminderRepositoryProvider);

    final customer =
        customerState.customers.where((c) => c.id == customerId).firstOrNull;

    if (customer == null) {
      return Scaffold(
        appBar: AppTopBar(
          title: 'Client Details',
          showBack: true,
          onBack: () => context.pop(),
        ),
        body: Center(
          child: customerState.isLoading
              ? const CircularProgressIndicator(color: AppColors.primary)
              : const Text('Client not found.'),
        ),
      );
    }

    final clientDues =
        duesState.dues.where((d) => d.customerId == customer.id).toList();
    final clientPayments =
        duesState.payments.where((p) => p.customerId == customer.id).toList();

    final outstandingDues = clientDues
        .where(
          (d) => d.status != DueStatus.paid && d.status != DueStatus.cancelled,
        )
        .toList();

    final totalOutstanding =
        outstandingDues.fold<double>(0, (sum, d) => sum + d.remainingAmount);
    final totalCollected =
        clientPayments.fold<double>(0, (sum, p) => sum + p.amount);

    void sendWhatsAppStatement() async {
      final url = reminderRepo.generateCustomerStatementWhatsAppUrl(
        customer: customer,
        outstandingDues: outstandingDues,
        upiId: user?.upiId,
        businessName: user?.businessName,
      );
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    return Scaffold(
      appBar: AppTopBar(
        title: 'Client Details',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Header Card
          Card(
            color: AppColors.surfaceContainerLowest,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
              side: const BorderSide(color: AppColors.surfaceVariant, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          customer.calculatedInitials,
                          style: const TextStyle(
                            color: AppColors.onPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert,
                            color: AppColors.onSurfaceVariant),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        onSelected: (val) {
                          if (val == 'edit') {
                            _showEditCustomerBottomSheet(
                                context, ref, customer);
                          } else if (val == 'delete') {
                            _confirmDeleteCustomer(context, ref, customer);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined,
                                    size: 18, color: AppColors.primary),
                                SizedBox(width: 10),
                                Text('Edit Client'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 18, color: AppColors.error),
                                SizedBox(width: 10),
                                Text('Delete Client',
                                    style: TextStyle(color: AppColors.error)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    customer.name,
                    style: AppTypography.headlineMedium
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Client since ${customer.clientSince}',
                    style: AppTypography.bodySmall,
                  ),
                  if (customer.email != null && customer.email!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      customer.email!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (customer.notes != null && customer.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        customer.notes!,
                        style: AppTypography.labelSmall
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // WhatsApp Statement & Call Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (customer.phone.isNotEmpty) ...[
                        OutlinedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse('tel:${customer.phone}');
                            if (await canLaunchUrl(uri)) await launchUrl(uri);
                          },
                          icon: const Icon(Icons.call, size: 16),
                          label: Text(customer.phone,
                              style: const TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(120, 36),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      FilledButton.icon(
                        onPressed: sendWhatsAppStatement,
                        icon: const Icon(Icons.chat, size: 16),
                        label: const Text('Statement',
                            style: TextStyle(fontSize: 12)),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.whatsAppGreen,
                          minimumSize: const Size(100, 36),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Financial Summary Bento Grid
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.errorContainer),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_rounded,
                              size: 15, color: AppColors.error),
                          const SizedBox(width: 4),
                          Text('Outstanding',
                              style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        CurrencyFormatter.format(totalOutstanding),
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('${outstandingDues.length} pending dues',
                          style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.surfaceVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance_wallet,
                              size: 15, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('Total Collected',
                              style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        CurrencyFormatter.format(totalCollected),
                        style: AppTypography.headlineMedium
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text('${clientPayments.length} payments',
                          style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons: + Add Due & Record Payment
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () =>
                        context.push('/add-due?customerId=${customer.id}'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Due'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (outstandingDues.isNotEmpty)
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => RecordPaymentDialog.show(context,
                          due: outstandingDues.first),
                      icon: const Icon(Icons.receipt_long, size: 18),
                      label: const Text('Record Payment'),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Dues List Section
          Text('Dues & History',
              style: AppTypography.titleMedium.copyWith(fontSize: 16)),
          const SizedBox(height: 10),
          if (clientDues.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceVariant),
              ),
              child: const Center(
                  child: Text('No dues created for this client yet.')),
            )
          else
            ...clientDues.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DueCard(
                    due: d,
                    onTap: () => context.push('/due/${d.id}'),
                  ),
                )),

          const SizedBox(height: 20),

          // Issued Receipts Section
          if (clientPayments.isNotEmpty) ...[
            Text('Issued Receipts (${clientPayments.length})',
                style: AppTypography.titleMedium.copyWith(fontSize: 16)),
            const SizedBox(height: 10),
            ...clientPayments.map((p) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceVariant),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.receiptNumber,
                              style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700)),
                          Text(
                            '${DateFormatter.formatDisplayDate(DateTime.parse(p.paidAt))} • ${p.paymentMethod.displayName}',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(CurrencyFormatter.format(p.amount),
                              style: AppTypography.titleMedium
                                  .copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.chevron_right,
                                size: 20, color: AppColors.outlineVariant),
                            onPressed: () {
                              PaymentReceiptDialog.show(
                                context,
                                payment: p,
                                businessProfile: user,
                                customerPhone: customer.phone,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
