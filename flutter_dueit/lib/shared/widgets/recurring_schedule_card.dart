import 'package:flutter/material.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/utils/currency_formatter.dart';
import 'package:dueit/core/utils/date_formatter.dart';
import 'package:dueit/features/dues/domain/entities/recurring_due_schedule_entity.dart';

/// Clean card displaying a recurring schedule with status, frequency, next due date, and actions
class RecurringScheduleCard extends StatelessWidget {
  final RecurringDueScheduleEntity schedule;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const RecurringScheduleCard({
    super.key,
    required this.schedule,
    this.onPause,
    this.onResume,
    this.onStop,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    Color statusBgColor;
    String statusText = schedule.status.displayName;

    switch (schedule.status) {
      case RecurringScheduleStatus.active:
        statusColor = AppColors.primary;
        statusBgColor = AppColors.primaryContainer;
        break;
      case RecurringScheduleStatus.paused:
        statusColor = Colors.orange.shade800;
        statusBgColor = Colors.orange.shade50;
        break;
      case RecurringScheduleStatus.ended:
        statusColor = AppColors.onSurfaceVariant;
        statusBgColor = AppColors.surfaceContainerLowest;
        break;
    }

    final parsedNext = DateFormatter.parseLocalDate(schedule.nextDueDate);
    final formattedNext = DateFormatter.formatDisplayDate(parsedNext);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: schedule.isActive
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Client & Frequency badge
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.repeat,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            schedule.frequency.displayName,
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Popup Menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (val) {
                  switch (val) {
                    case 'pause':
                      onPause?.call();
                      break;
                    case 'resume':
                      onResume?.call();
                      break;
                    case 'stop':
                      onStop?.call();
                      break;
                    case 'edit':
                      onEdit?.call();
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (schedule.isActive)
                    const PopupMenuItem(
                      value: 'pause',
                      child: Row(
                        children: [
                          Icon(Icons.pause, size: 18, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Pause Schedule'),
                        ],
                      ),
                    ),
                  if (schedule.isPaused)
                    const PopupMenuItem(
                      value: 'resume',
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow,
                              size: 18, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('Resume Schedule'),
                        ],
                      ),
                    ),
                  if (!schedule.isEnded)
                    const PopupMenuItem(
                      value: 'stop',
                      child: Row(
                        children: [
                          Icon(Icons.stop, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Stop Schedule'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit Amount / Details'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Delete Schedule',
                            style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Client Name
          Text(
            schedule.customerName.isNotEmpty
                ? schedule.customerName
                : 'Customer',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),

          // Description & Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  schedule.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                CurrencyFormatter.format(schedule.amount),
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Next occurrence date info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.event,
                      size: 16, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    schedule.isEnded
                        ? 'Schedule Ended'
                        : 'Next: $formattedNext',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (schedule.reminderEnabled)
                Row(
                  children: [
                    const Icon(Icons.notifications_active,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      schedule.reminderType.displayName,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
