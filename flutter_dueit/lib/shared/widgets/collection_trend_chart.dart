import 'dart:math';
import 'package:flutter/material.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/utils/currency_formatter.dart';
import 'package:dueit/features/dashboard/domain/entities/dashboard_financial_metrics.dart';

/// Interactive and visual daily collection trend chart for the current month.
class CollectionTrendChart extends StatelessWidget {
  final List<DailyCollectionPoint> dailyTrend;
  final double totalCollectedMonth;

  const CollectionTrendChart({
    super.key,
    required this.dailyTrend,
    required this.totalCollectedMonth,
  });

  @override
  Widget build(BuildContext context) {
    final hasCollections = totalCollectedMonth > 0;
    final maxAmount = dailyTrend.fold<double>(
      0.0,
      (maxVal, point) => max(maxVal, point.amount),
    );

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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            AppColors.primaryContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.insights,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Collection Trend',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Daily cash inflow this month',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  CurrencyFormatter.format(totalCollectedMonth),
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Content: Empty state or Bar chart
            if (!hasCollections)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.bar_chart,
                      size: 32,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No payments recorded this month yet',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  SizedBox(
                    height: 120,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: dailyTrend.map((point) {
                        final ratio =
                            maxAmount > 0 ? (point.amount / maxAmount) : 0.0;
                        final hasValue = point.amount > 0;

                        return Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 1.5),
                            child: Tooltip(
                              message:
                                  'Day ${point.dayOfMonth}: ${CurrencyFormatter.format(point.amount)}',
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    height: max(
                                        4.0, ratio * 96), // min 4px bar height
                                    decoration: BoxDecoration(
                                      color: hasValue
                                          ? AppColors.primary
                                          : AppColors.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (point.dayOfMonth == 1 ||
                                      point.dayOfMonth == 5 ||
                                      point.dayOfMonth == 10 ||
                                      point.dayOfMonth == 15 ||
                                      point.dayOfMonth == 20 ||
                                      point.dayOfMonth == 25 ||
                                      point.dayOfMonth == dailyTrend.length)
                                    Text(
                                      '${point.dayOfMonth}',
                                      style: AppTypography.labelSmall.copyWith(
                                        fontSize: 9,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    )
                                  else
                                    const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
