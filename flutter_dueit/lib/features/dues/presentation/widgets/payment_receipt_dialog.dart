import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/utils/currency_formatter.dart';
import 'package:dueit/core/utils/date_formatter.dart';
import 'package:dueit/features/auth/domain/entities/user_entity.dart';
import '../../domain/entities/payment_record_entity.dart';

class PaymentReceiptDialog extends StatelessWidget {
  final PaymentRecordEntity payment;
  final UserEntity? businessProfile;
  final String? customerPhone;

  const PaymentReceiptDialog({
    super.key,
    required this.payment,
    this.businessProfile,
    this.customerPhone,
  });

  static void show(
    BuildContext context, {
    required PaymentRecordEntity payment,
    UserEntity? businessProfile,
    String? customerPhone,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => PaymentReceiptDialog(
        payment: payment,
        businessProfile: businessProfile,
        customerPhone: customerPhone,
      ),
    );
  }

  void _shareViaWhatsApp(BuildContext context) async {
    final phone = customerPhone?.replaceAll(RegExp(r'\D'), '') ?? '';
    final bName = businessProfile?.businessName ?? 'DueIt';
    final dateFormatted = DateFormatter.formatDateTime(DateTime.parse(payment.paidAt));

    final text = '*OFFICIAL PAYMENT RECEIPT*\n\n'
        '*$bName*\n'
        'Receipt No: *${payment.receiptNumber}*\n\n'
        'Dear *${payment.customerName}*,\n'
        'We have received your payment of *₹${payment.amount.toInt()}* via *${payment.paymentMethod.displayName}* on $dateFormatted.\n\n'
        'Thank you for your timely payment!';

    final uri = Uri.parse('https://api.whatsapp.com/send?phone=$phone&text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyReceipt(BuildContext context) {
    final bName = businessProfile?.businessName ?? 'DueIt';
    final dateFormatted = DateFormatter.formatDateTime(DateTime.parse(payment.paidAt));

    final text = 'PAYMENT RECEIPT\n'
        'Receipt No: ${payment.receiptNumber}\n'
        'Issued by: $bName\n'
        'Customer: ${payment.customerName}\n'
        'Amount Paid: ₹${payment.amount.toInt()}\n'
        'Method: ${payment.paymentMethod.displayName}\n'
        'Date: $dateFormatted\n'
        'Status: Settled & Verified';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt details copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bName = businessProfile?.businessName ?? 'DueIt Business';
    final dateFormatted = DateFormatter.formatDateTime(DateTime.parse(payment.paidAt));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: AppColors.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Teal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: AppColors.primary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: AppColors.onPrimary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Payment Receipt',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.onPrimary, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Business Name Banner
                  Text(
                    bName,
                    style: AppTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Official Payment Receipt',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Payment Settled & Verified',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.surfaceVariant),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'AMOUNT RECEIVED',
                          style: AppTypography.labelSmall.copyWith(
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(payment.amount),
                          style: AppTypography.displayLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'via ${payment.paymentMethod.displayName} • $dateFormatted',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Receipt Meta Key-Values
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.surfaceVariant),
                    ),
                    child: Column(
                      children: [
                        _buildRow('Receipt No.', payment.receiptNumber),
                        const Divider(height: 12, thickness: 0.5),
                        _buildRow('Client Name', payment.customerName),
                        if (payment.notes != null) ...[
                          const Divider(height: 12, thickness: 0.5),
                          _buildRow('Notes', payment.notes!),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // WhatsApp Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: () => _shareViaWhatsApp(context),
                      icon: const Icon(Icons.chat, size: 20),
                      label: const Text('Share Receipt on WhatsApp'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.whatsAppGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Copy Details Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => _copyReceipt(context),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy Details'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySmall),
        Text(
          value,
          style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
