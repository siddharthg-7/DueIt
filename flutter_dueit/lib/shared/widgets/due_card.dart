import 'package:flutter/material.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/utils/currency_formatter.dart';
import 'package:dueit/core/utils/date_formatter.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';
import 'status_badge.dart';

class DueCard extends StatelessWidget {
  final DueEntity due;
  final VoidCallback? onTap;
  final VoidCallback? onQuickPay;
  final VoidCallback? onQuickWhatsApp;

  const DueCard({
    super.key,
    required this.due,
    this.onTap,
    this.onQuickPay,
    this.onQuickWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = due.status == DueStatus.paid;
    final isOverdue = due.status == DueStatus.overdue;

    return Card(
      color: AppColors.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.surfaceVariant, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isPaid
                      ? AppColors.secondaryContainer
                      : isOverdue
                          ? AppColors.errorContainer
                          : AppColors.primaryContainer.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  due.customerName.isNotEmpty
                      ? due.customerName[0].toUpperCase()
                      : 'D',
                  style: AppTypography.titleMedium.copyWith(
                    color: isPaid
                        ? AppColors.onSecondaryContainer
                        : isOverdue
                            ? AppColors.error
                            : AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Description & Due Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      due.customerName,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      due.description,
                      style: AppTypography.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        StatusBadge(status: due.status, compact: true),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '•  Due ${DateFormatter.formatShortDate(DateFormatter.parseLocalDate(due.dueDate))}',
                            style: AppTypography.bodySmall.copyWith(
                              color: isOverdue
                                  ? AppColors.error
                                  : AppColors.onSurfaceVariant,
                              fontWeight:
                                  isOverdue ? FontWeight.w600 : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Amount & Chevron / Quick Actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(due.remainingAmount),
                    style: AppTypography.titleMedium.copyWith(
                      color: isPaid
                          ? AppColors.onSurfaceVariant.withValues(alpha: 0.6)
                          : isOverdue
                              ? AppColors.error
                              : AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                      decoration: isPaid ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (onQuickWhatsApp != null || onQuickPay != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onQuickWhatsApp != null && !isPaid)
                          IconButton(
                            onPressed: onQuickWhatsApp,
                            icon: const Icon(Icons.chat,
                                size: 18, color: AppColors.whatsAppDarkGreen),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                          ),
                        if (onQuickPay != null && !isPaid)
                          IconButton(
                            onPressed: onQuickPay,
                            icon: const Icon(Icons.check_circle_outline,
                                size: 20, color: AppColors.primary),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                          ),
                      ],
                    ),
                  ] else ...[
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.outlineVariant,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
