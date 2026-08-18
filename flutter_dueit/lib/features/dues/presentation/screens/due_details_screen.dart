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
import 'package:dueit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dueit/features/customers/presentation/controllers/customer_controller.dart';
import 'package:dueit/features/reminders/presentation/controllers/reminder_controller.dart';
import '../../domain/entities/due_entity.dart';
import '../../domain/entities/payment_record_entity.dart';
import '../controllers/dues_controller.dart';
import '../widgets/payment_receipt_dialog.dart';
import '../widgets/record_payment_dialog.dart';

class DueDetailsScreen extends ConsumerWidget {
  final String dueId;

  const DueDetailsScreen({super.key, required this.dueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duesState = ref.watch(duesControllerProvider);
    final user = ref.watch(authControllerProvider).user;
    final customerState = ref.watch(customerControllerProvider);
    final reminderRepo = ref.watch(reminderRepositoryProvider);

    final due = duesState.dues.where((d) => d.id == dueId).firstOrNull;

    if (due == null) {
      return Scaffold(
        appBar: const AppTopBar(title: 'Due Details', showBack: true),
        body: const Center(child: Text('Due record not found.')),
      );
    }

    final customer = customerState.customers
        .where((c) => c.id == due.customerId)
        .firstOrNull;
    final duePayments =
        duesState.payments.where((p) => p.dueId == due.id).toList();

    final isPaid = due.status == DueStatus.paid;
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
                  StatusBadge(status: due.status),
                  const SizedBox(height: 12),
                  Text(
                    CurrencyFormatter.format(due.amount),
                    style: AppTypography.displayLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (due.paidAmount > 0 && !isPaid) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.tertiaryFixed.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Paid: ${CurrencyFormatter.format(due.paidAmount)}  •  Balance: ${CurrencyFormatter.format(due.remainingAmount)}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.onTertiaryFixed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    due.description,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Client Pill Tile
                  InkWell(
                    onTap: () {
                      if (customer != null) {
                        context.push('/customer/${customer.id}');
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.surfaceVariant),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              due.customerName.isNotEmpty
                                  ? due.customerName[0].toUpperCase()
                                  : 'C',
                              style: const TextStyle(
                                color: AppColors.onPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            due.customerName,
                            style: AppTypography.titleMedium
                                .copyWith(fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right,
                              size: 16, color: AppColors.outlineVariant),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Due Date & Recurrence Row
          Row(
            children: [
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
                          const Icon(Icons.calendar_today,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text('Due Date', style: AppTypography.labelSmall),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormatter.formatDisplayDate(
                            DateFormatter.parseLocalDate(due.dueDate)),
                        style: AppTypography.titleMedium.copyWith(fontSize: 15),
                      ),
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
                          const Icon(Icons.autorenew,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text('Recurrence', style: AppTypography.labelSmall),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        due.recurrence.displayName,
                        style: AppTypography.titleMedium.copyWith(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // WhatsApp Nudge Banner
          if (!isPaid && !isCancelled) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.surfaceVariant),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.whatsAppGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.chat,
                        color: AppColors.whatsAppDarkGreen, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WhatsApp Reminder',
                            style: AppTypography.titleMedium
                                .copyWith(fontSize: 14)),
                        Text('One-tap prefilled reminder message',
                            style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: sendWhatsAppReminder,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.whatsAppGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      minimumSize: const Size(60, 36),
                    ),
                    child: const Text('Send', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Payment Transaction History
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Payment Transactions',
                        style:
                            AppTypography.titleMedium.copyWith(fontSize: 15)),
                    Text('${duePayments.length} recorded',
                        style: AppTypography.bodySmall),
                  ],
                ),
                const SizedBox(height: 12),
                if (duePayments.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: Text('No payments recorded for this due yet.',
                        style: AppTypography.bodySmall),
                  )
                else
                  ...duePayments.map((p) {
                    final dateFormatted =
                        DateFormatter.formatDateTime(DateTime.parse(p.paidAt));
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.surfaceVariant),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    CurrencyFormatter.format(p.amount),
                                    style: AppTypography.titleMedium.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      p.paymentMethod.displayName,
                                      style: AppTypography.labelSmall
                                          .copyWith(fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text('$dateFormatted • ${p.receiptNumber}',
                                  style: AppTypography.bodySmall
                                      .copyWith(fontSize: 11)),
                              if (p.notes != null)
                                Text(p.notes!,
                                    style: AppTypography.bodySmall.copyWith(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 11)),
                            ],
                          ),
                          OutlinedButton(
                            onPressed: () {
                              PaymentReceiptDialog.show(
                                context,
                                payment: p,
                                businessProfile: user,
                                customerPhone: customer?.phone,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(64, 32),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: const Text('Receipt',
                                style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),

          const SizedBox(height: 120),
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
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isPaid && !isCancelled) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () async {
                    final payment = await ref
                        .read(duesControllerProvider.notifier)
                        .recordPayment(
                          dueId: due.id,
                          amount: due.remainingAmount,
                          paymentMethod: PaymentMethod.upi,
                          notes: 'Full settlement',
                        );
                    if (context.mounted) {
                      PaymentReceiptDialog.show(
                        context,
                        payment: payment,
                        businessProfile: user,
                        customerPhone: customer?.phone,
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle, size: 20),
                  label: Text(
                      'Mark as Paid (${CurrencyFormatter.format(due.remainingAmount)})'),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          RecordPaymentDialog.show(context, due: due),
                      icon: const Icon(Icons.receipt_long, size: 16),
                      label: const Text('Record Partial'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                width: double.infinity,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified,
                        color: AppColors.onSecondaryContainer),
                    const SizedBox(width: 8),
                    Text(
                      isCancelled
                          ? 'Due is Cancelled'
                          : 'Payment Fully Settled',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
