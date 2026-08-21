import 'package:flutter/material.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

/// Modern, elevated Monthly Collection Planning frontend component for DueIt.
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
    final currentMonthName = DateFormat('MMMM yyyy').format(DateTime.now());
    final hasData = collectionRate != null && expectedTotal > 0;
    final rate = (collectionRate ?? 0.0).clamp(0.0, 1.0);
    final ratePercentage = (rate * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.surfaceVariant.withValues(alpha: 0.8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryContainer
                                  .withValues(alpha: 0.25),
                              AppColors.primary.withValues(alpha: 0.15),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              periodTitle,
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              currentMonthName,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Rate Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: hasData
                        ? (rate >= 0.75
                            ? AppColors.successContainer.withValues(alpha: 0.5)
                            : AppColors.primaryFixedDim.withValues(alpha: 0.35))
                        : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: hasData
                          ? (rate >= 0.75
                              ? AppColors.success.withValues(alpha: 0.3)
                              : AppColors.primary.withValues(alpha: 0.25))
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasData ? Icons.trending_up : Icons.info_outline,
                        size: 14,
                        color: hasData
                            ? (rate >= 0.75
                                ? AppColors.success
                                : AppColors.primary)
                            : AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasData ? '$ratePercentage% Collected' : 'No dues yet',
                        style: AppTypography.labelSmall.copyWith(
                          color: hasData
                              ? (rate >= 0.75
                                  ? AppColors.success
                                  : AppColors.primary)
                              : AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bento 3-Column Metrics Row
            Row(
              children: [
                // Expected Card
                Expanded(
                  child: _buildMetricCard(
                    context: context,
                    label: 'Expected',
                    amount: expectedTotal,
                    accentColor: AppColors.onSurfaceVariant,
                    icon: Icons.flag_outlined,
                    bgColor: AppColors.surfaceContainerLow,
                  ),
                ),
                const SizedBox(width: 8),

                // Collected Card (Highlighted)
                Expanded(
                  child: _buildMetricCard(
                    context: context,
                    label: 'Collected',
                    amount: collectedTotal,
                    accentColor: AppColors.primary,
                    icon: Icons.check_circle_outline,
                    bgColor: AppColors.primaryFixedDim.withValues(alpha: 0.22),
                    isHighlighted: true,
                  ),
                ),
                const SizedBox(width: 8),

                // Outstanding Card
                Expanded(
                  child: _buildMetricCard(
                    context: context,
                    label: 'Outstanding',
                    amount: outstandingTotal,
                    accentColor: AppColors.tertiary,
                    icon: Icons.pending_actions_outlined,
                    bgColor: AppColors.tertiaryFixedDim.withValues(alpha: 0.25),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Progress Bar Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monthly Target Progress',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${CurrencyFormatter.format(collectedTotal)} / ${CurrencyFormatter.format(expectedTotal)}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final fillWidth = constraints.maxWidth * rate;
                      return Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            width: fillWidth,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  Color(0xFF00A896),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: rate > 0
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String label,
    required double amount,
    required Color accentColor,
    required IconData icon,
    required Color bgColor,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: isHighlighted
            ? Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.2)
            : Border.all(color: Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: accentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.format(amount),
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: isHighlighted ? accentColor : AppColors.onSurface,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
