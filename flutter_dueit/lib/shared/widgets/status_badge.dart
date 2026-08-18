import 'package:flutter/material.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';

class StatusBadge extends StatelessWidget {
  final DueStatus status;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String label = status.displayName;

    switch (status) {
      case DueStatus.paid:
        bg = AppColors.secondaryContainer;
        fg = AppColors.onSecondaryContainer;
        icon = Icons.check_circle;
        break;
      case DueStatus.overdue:
        bg = AppColors.errorContainer;
        fg = AppColors.error;
        icon = Icons.warning_rounded;
        break;
      case DueStatus.partiallyPaid:
        bg = AppColors.tertiaryFixed;
        fg = AppColors.onTertiaryFixed;
        icon = Icons.timelapse;
        break;
      case DueStatus.cancelled:
        bg = AppColors.surfaceVariant;
        fg = AppColors.onSurfaceVariant;
        icon = Icons.cancel;
        break;
      case DueStatus.upcoming:
        bg = AppColors.tertiaryFixed.withValues(alpha: 0.5);
        fg = AppColors.tertiary;
        icon = Icons.calendar_month;
        break;
      case DueStatus.due:
        bg = AppColors.primaryContainer.withValues(alpha: 0.15);
        fg = AppColors.primary;
        icon = Icons.schedule;
        break;
    }

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: fg,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
