import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/utils/currency_formatter.dart';
import 'package:dueit/core/utils/date_formatter.dart';
import 'package:dueit/shared/widgets/app_top_bar.dart';
import 'package:dueit/shared/widgets/status_badge.dart';
import 'package:dueit/shared/widgets/date_selector.dart';
import 'package:dueit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dueit/features/customers/presentation/controllers/customer_controller.dart';
import 'package:dueit/features/reminders/presentation/controllers/reminder_controller.dart';
import '../../domain/entities/due_entity.dart';
import '../controllers/dues_controller.dart';

class DueDetailsScreen extends ConsumerWidget {
  final String dueId;

  const DueDetailsScreen({super.key, required this.dueId});

  void _showEditDueBottomSheet(
    BuildContext context,
    WidgetRef ref,
    DueEntity due,
  ) {
    final amountCtrl =
        TextEditingController(text: due.amount.toInt().toString());
    final descCtrl = TextEditingController(text: due.description);
    DateTime selectedDate = DateFormatter.parseLocalDate(due.dueDate);
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Due',
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

                // Amount
                TextFormField(
                  controller: amountCtrl,
                  enabled: !isSaving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Due Amount (₹) *',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: descCtrl,
                  enabled: !isSaving,
                  decoration: const InputDecoration(
                    labelText: 'For (Description) *',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                // Due Date
                DateSelector(
                  selectedDate: selectedDate,
                  onDateSelected: (d) {
                    setModalState(() => selectedDate = d);
                  },
                ),
                const SizedBox(height: 20),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final amt = double.tryParse(amountCtrl.text.trim());
                            if (amt == null || amt <= 0) {
                              setModalState(() {
                                errorMessage =
                                    'Enter an amount greater than ₹0.';
                              });
                              return;
                            }

                            final desc = descCtrl.text.trim();
                            if (desc.isEmpty) {
                              setModalState(() {
                                errorMessage =
                                    'Enter what this payment is for.';
                              });
                              return;
                            }

                            setModalState(() {
                              isSaving = true;
                              errorMessage = null;
                            });

                            final updated = due.copyWith(
                              amount: amt,
                              description: desc,
                              dueDate:
                                  DateFormatter.formatIsoDate(selectedDate),
                            );

                            final success = await ref
                                .read(duesControllerProvider.notifier)
                                .updateDue(updated);

                            if (success) {
                              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                            } else {
                              setModalState(() {
                                isSaving = false;
                                errorMessage =
                                    ref.read(duesControllerProvider).error ??
                                        'Failed to update due.';
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
    );
  }

  void _confirmCancelDue(
    BuildContext context,
    WidgetRef ref,
    DueEntity due,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cancel this due?',
          style:
              AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This will mark the due as cancelled. It will be removed from your active collection totals.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Keep Active'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await ref
                  .read(duesControllerProvider.notifier)
                  .cancelDue(due.id);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Due marked as cancelled.')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ref.read(duesControllerProvider).error ??
                          'Failed to cancel due.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Cancel Due'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDue(
    BuildContext context,
    WidgetRef ref,
    DueEntity due,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete this record?',
          style:
              AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This will permanently delete this payment due record from your business.',
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
                  .read(duesControllerProvider.notifier)
                  .deleteDue(due.id);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Due deleted.')),
                  );
                  context.pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ref.read(duesControllerProvider).error ??
                          'Failed to delete due.'),
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
    final duesState = ref.watch(duesControllerProvider);
    final user = ref.watch(authControllerProvider).user;
    final customerState = ref.watch(customerControllerProvider);
    final reminderRepo = ref.watch(reminderRepositoryProvider);

    final due = duesState.dues.where((d) => d.id == dueId).firstOrNull;

    if (due == null) {
      return Scaffold(
        appBar: AppTopBar(
          title: 'Due Details',
          showBack: true,
          onBack: () => context.pop(),
        ),
        body: Center(
          child: duesState.isLoading
              ? const CircularProgressIndicator(color: AppColors.primary)
              : const Text('Due record not found.'),
        ),
      );
    }

    final customer = customerState.customers
        .where((c) => c.id == due.customerId)
        .firstOrNull;
    final displayName = customer?.name ??
        (due.customerName.isNotEmpty ? due.customerName : 'Client');

    final isCancelled = due.status == DueStatus.cancelled;

    void sendWhatsAppReminder() async {
      if (customer == null) return;
      final url = reminderRepo.generateWhatsAppReminderUrl(
        due: due,
        customer: customer,
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
        title: 'Due Details',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Main Status & Amount Card
          Card(
            color: AppColors.surfaceContainerLowest,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
              side: const BorderSide(color: AppColors.surfaceVariant, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      StatusBadge(status: due.status),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert,
                            color: AppColors.onSurfaceVariant),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        onSelected: (val) {
                          if (val == 'edit') {
                            _showEditDueBottomSheet(context, ref, due);
                          } else if (val == 'cancel') {
                            _confirmCancelDue(context, ref, due);
                          } else if (val == 'delete') {
                            _confirmDeleteDue(context, ref, due);
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
                                Text('Edit Due'),
                              ],
                            ),
                          ),
                          if (!isCancelled)
                            const PopupMenuItem(
                              value: 'cancel',
                              child: Row(
                                children: [
                                  Icon(Icons.cancel_outlined,
                                      size: 18, color: AppColors.error),
                                  SizedBox(width: 10),
                                  Text('Cancel Due',
                                      style: TextStyle(color: AppColors.error)),
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
                                Text('Delete Record',
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
                    CurrencyFormatter.format(due.amount),
                    style: AppTypography.displayLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    due.description,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // WhatsApp Action Button
                  if (customer != null && !isCancelled)
                    SizedBox(
                      height: 40,
                      child: FilledButton.icon(
                        onPressed: sendWhatsAppReminder,
                        icon: const Icon(Icons.chat, size: 16),
                        label: const Text('Send Reminder on WhatsApp',
                            style: TextStyle(fontSize: 13)),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.whatsAppGreen,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Client Info Card
          Card(
            color: AppColors.surfaceContainerLowest,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.surfaceVariant, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: AppTypography.titleMedium
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (customer != null && customer.phone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(customer.phone, style: AppTypography.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  if (customer != null && customer.phone.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.call, color: AppColors.primary),
                      onPressed: () async {
                        final uri = Uri.parse('tel:${customer.phone}');
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Due Timing Details Bento Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Due Date', style: AppTypography.bodyMedium),
                    Text(
                      DateFormatter.formatDisplayDate(
                          DateFormatter.parseLocalDate(due.dueDate)),
                      style: AppTypography.titleMedium
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const Divider(height: 24, color: AppColors.surfaceVariant),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recurrence', style: AppTypography.bodyMedium),
                    Text(
                      due.recurrence.displayName,
                      style: AppTypography.titleMedium
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const Divider(height: 24, color: AppColors.surfaceVariant),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Created Date', style: AppTypography.bodyMedium),
                    Text(
                      DateFormatter.formatShortDate(due.createdAt),
                      style: AppTypography.titleMedium
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
