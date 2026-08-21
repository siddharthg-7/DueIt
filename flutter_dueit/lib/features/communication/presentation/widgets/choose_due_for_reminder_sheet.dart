import 'package:flutter/material.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/utils/currency_formatter.dart';
import 'package:dueit/core/utils/date_formatter.dart';
import 'package:dueit/features/customers/domain/entities/customer_entity.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';
import 'package:dueit/shared/widgets/status_badge.dart';
import 'whatsapp_message_preview_sheet.dart';

/// Modal bottom sheet allowing the business owner to select which unpaid Due
/// to send a WhatsApp reminder for when a customer has multiple active dues.
class ChooseDueForReminderSheet extends StatelessWidget {
  final CustomerEntity customer;
  final List<DueEntity> activeDues;
  final String? businessName;

  const ChooseDueForReminderSheet({
    super.key,
    required this.customer,
    required this.activeDues,
    this.businessName,
  });

  static Future<void> show({
    required BuildContext context,
    required CustomerEntity customer,
    required List<DueEntity> activeDues,
    String? businessName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChooseDueForReminderSheet(
        customer: customer,
        activeDues: activeDues,
        businessName: businessName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose a Due',
                    style: AppTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Select which payment due to remind ${customer.name} about',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: activeDues.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, index) {
                final due = activeDues[index];
                final formattedDueDate = _formatDate(due.dueDate);

                return InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    WhatsAppMessagePreviewSheet.show(
                      context: context,
                      customer: customer,
                      due: due,
                      businessName: businessName,
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceVariant),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                due.description,
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Due: $formattedDueDate',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  if (due.paidAmount > 0) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '(Paid: ${CurrencyFormatter.format(due.paidAmount)})',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.format(due.remainingAmount),
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            StatusBadge(status: due.status),
                          ],
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.onSurfaceVariant,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final parsed = DateFormatter.parseLocalDate(isoDate);
      return DateFormatter.formatDisplayDate(parsed);
    } catch (_) {
      return isoDate;
    }
  }
}
