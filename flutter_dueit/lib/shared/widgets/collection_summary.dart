import 'package:flutter/material.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/utils/currency_formatter.dart';

class CollectionSummary extends StatelessWidget {
  final double expectedTotal;
  final double collectedTotal;
  final double outstandingTotal;
  final double? collectionRate;
  final String periodTitle;

  const CollectionSummary({
    super.key,
    required this.expectedTotal,
    required this.collectedTotal,
    required this.outstandingTotal,
    this.collectionRate,
    this.periodTitle = 'Monthly Collection Planning',
  });

  @override
  Widget build(BuildContext context) {
    final hasData = collectionRate != null;
    final ratePercentage =
        hasData ? (collectionRate! * 100).clamp(0, 100).round() : null;

    return Card(
      color: AppColors.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.surfaceVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primaryContainer.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.calendar_month,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        periodTitle,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasData
                        ? AppColors.primaryContainer.withValues(alpha: 0.2)
                        : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hasData
                        ? '$ratePercentage% Collected'
                        : 'No collection data yet',
                    style: AppTypography.labelSmall.copyWith(
                      color: hasData
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Expected Total (Current month original dues)
            _buildStatRow(
              color: AppColors.outlineVariant,
              label: 'Expected Collections',
              amount: expectedTotal,
              subtitle: 'Original amount of current-month dues',
            ),
            const Divider(
                height: 16, thickness: 0.6, color: AppColors.surfaceVariant),

            // Collected Total (Payments recorded in current month)
            _buildStatRow(
              color: AppColors.primary,
              label: 'Actual Collected',
              amount: collectedTotal,
              subtitle: 'Payments recorded this month',
              isHighlighted: true,
            ),
            const Divider(
                height: 16, thickness: 0.6, color: AppColors.surfaceVariant),

            // Outstanding Balance (Remaining current-month dues)
            _buildStatRow(
              color: AppColors.tertiary,
              label: 'Current Month Outstanding',
              amount: outstandingTotal,
              subtitle: 'Remaining unpaid for this month',
            ),
            const SizedBox(height: 16),

            // Progress Bar
            if (hasData)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: collectionRate,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 8,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required Color color,
    required String label,
    required double amount,
    String? subtitle,
    bool isHighlighted = false,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                  color: isHighlighted
                      ? AppColors.onSurface
                      : AppColors.onSurfaceVariant,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 10,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: AppTypography.titleMedium.copyWith(
            fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
            color: isHighlighted ? AppColors.primary : AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
