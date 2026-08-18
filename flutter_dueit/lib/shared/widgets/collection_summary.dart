import 'package:flutter/material.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/utils/currency_formatter.dart';

class CollectionSummary extends StatelessWidget {
  final double expectedTotal;
  final double collectedTotal;
  final double pendingTotal;
  final String periodTitle;

  const CollectionSummary({
    super.key,
    required this.expectedTotal,
    required this.collectedTotal,
    required this.pendingTotal,
    this.periodTitle = 'This Month\'s Summary',
  });

  @override
  Widget build(BuildContext context) {
    final double rate = expectedTotal > 0
        ? ((collectedTotal / expectedTotal) * 100).clamp(0, 100)
        : 0;

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
                  child: Text(
                    periodTitle,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${rate.round()}% Collected',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Expected Total
            _buildStatRow(
              color: AppColors.outlineVariant,
              label: 'Expected Total',
              amount: expectedTotal,
            ),
            const Divider(height: 16, thickness: 0.6, color: AppColors.surfaceVariant),

            // Collected Total
            _buildStatRow(
              color: AppColors.primary,
              label: 'Collected',
              amount: collectedTotal,
              isHighlighted: true,
            ),
            const Divider(height: 16, thickness: 0.6, color: AppColors.surfaceVariant),

            // Pending & Overdue
            _buildStatRow(
              color: AppColors.tertiary,
              label: 'Pending & Overdue',
              amount: pendingTotal,
            ),
            const SizedBox(height: 16),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 8,
                child: LinearProgressIndicator(
                  value: rate / 100,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
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
    bool isHighlighted = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          CurrencyFormatter.format(amount),
          style: AppTypography.labelLarge.copyWith(
            color: isHighlighted ? AppColors.primary : AppColors.onSurface,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
