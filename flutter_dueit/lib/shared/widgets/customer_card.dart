import 'package:flutter/material.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/utils/currency_formatter.dart';
import 'package:dueit/features/customers/domain/entities/customer_entity.dart';

class CustomerCard extends StatelessWidget {
  final CustomerEntity customer;
  final double totalBalance;
  final bool isOverdue;
  final VoidCallback? onTap;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.totalBalance,
    this.isOverdue = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasBalance = totalBalance > 0;

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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isOverdue
                      ? AppColors.errorContainer
                      : hasBalance
                          ? AppColors.tertiaryFixed
                          : AppColors.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  customer.calculatedInitials,
                  style: AppTypography.titleMedium.copyWith(
                    color: isOverdue
                        ? AppColors.error
                        : hasBalance
                            ? AppColors.onTertiaryFixed
                            : AppColors.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Name, Phone & Batch
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOverdue
                                ? AppColors.error
                                : hasBalance
                                    ? AppColors.tertiary
                                    : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOverdue
                              ? 'Overdue'
                              : hasBalance
                                  ? 'Due Soon'
                                  : 'Settled',
                          style: AppTypography.labelSmall.copyWith(
                            color: isOverdue
                                ? AppColors.error
                                : hasBalance
                                    ? AppColors.tertiary
                                    : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (customer.notes != null) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '• ${customer.notes}',
                              style: AppTypography.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Outstanding Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(totalBalance),
                    style: AppTypography.titleMedium.copyWith(
                      color: isOverdue
                          ? AppColors.error
                          : hasBalance
                              ? AppColors.onSurface
                              : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasBalance ? 'Outstanding' : 'All Settled',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
