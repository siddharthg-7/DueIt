import 'package:flutter/material.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/features/dashboard/domain/entities/dashboard_financial_metrics.dart';

/// Card showing actionable attention items based on genuine real-time data
class NeedsAttentionCard extends StatelessWidget {
  final List<AttentionItem> items;
  final Function(String filterRoute) onAction;

  const NeedsAttentionCard({
    super.key,
    required this.items,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You\'re all caught up!',
                    style: AppTypography.titleMedium
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'No urgent collections or overdue payments.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: items.map((item) {
        final isUrgent = item.isUrgent;
        final bgColor = isUrgent
            ? AppColors.errorContainer.withValues(alpha: 0.25)
            : AppColors.surfaceContainerLowest;
        final borderColor =
            isUrgent ? AppColors.errorContainer : AppColors.surfaceVariant;
        final iconColor = isUrgent ? AppColors.error : AppColors.primary;
        final iconData =
            isUrgent ? Icons.warning_amber_rounded : Icons.schedule;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => onAction(item.filterRoute),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUrgent
                          ? AppColors.error.withValues(alpha: 0.1)
                          : AppColors.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(iconData, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isUrgent
                                ? AppColors.error
                                : AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.description,
                          style: AppTypography.bodySmall.copyWith(
                            color: isUrgent
                                ? AppColors.error.withValues(alpha: 0.8)
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 20, color: AppColors.onSurfaceVariant),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
