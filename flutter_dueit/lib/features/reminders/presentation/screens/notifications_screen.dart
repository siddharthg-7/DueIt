import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/utils/date_formatter.dart';
import 'package:dueit/shared/widgets/app_top_bar.dart';
import 'package:dueit/shared/widgets/empty_state.dart';
import '../../domain/entities/notification_entity.dart';
import '../controllers/reminder_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderState = ref.watch(reminderControllerProvider);
    final notifications = reminderState.notifications;

    return Scaffold(
      appBar: AppTopBar(
        title: 'Notifications',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          if (notifications.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${reminderState.unreadCount} unread',
                  style: AppTypography.bodySmall
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () {
                    ref
                        .read(reminderControllerProvider.notifier)
                        .markAllAsRead();
                  },
                  child: const Text('Mark all read'),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (notifications.isEmpty)
            const EmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'No notifications',
              description:
                  'You\'re all caught up! Dues alerts and payment receipts will appear here.',
            )
          else
            ...notifications.map((n) {
              IconData icon;
              Color iconBg;
              Color iconColor;

              switch (n.type) {
                case NotificationType.overdue:
                  icon = Icons.warning_rounded;
                  iconBg = AppColors.errorContainer;
                  iconColor = AppColors.error;
                  break;
                case NotificationType.dueToday:
                  icon = Icons.today;
                  iconBg = AppColors.primaryContainer.withValues(alpha: 0.2);
                  iconColor = AppColors.primary;
                  break;
                case NotificationType.paymentReceived:
                  icon = Icons.verified;
                  iconBg = AppColors.secondaryContainer;
                  iconColor = AppColors.onSecondaryContainer;
                  break;
                case NotificationType.upcoming:
                  icon = Icons.calendar_month;
                  iconBg = AppColors.tertiaryFixed;
                  iconColor = AppColors.onTertiaryFixed;
                  break;
                case NotificationType.system:
                  icon = Icons.info_outline;
                  iconBg = AppColors.surfaceContainerHigh;
                  iconColor = AppColors.onSurfaceVariant;
                  break;
              }

              return Dismissible(
                key: Key(n.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  ref
                      .read(reminderControllerProvider.notifier)
                      .deleteNotification(n.id);
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: AppColors.error,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: n.read
                        ? AppColors.surfaceContainerLow
                        : AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: n.read
                          ? AppColors.surfaceVariant
                          : AppColors.primary.withValues(alpha: 0.3),
                      width: n.read ? 1 : 1.5,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      ref
                          .read(reminderControllerProvider.notifier)
                          .markAsRead(n.id);
                      if (n.dueId != null) {
                        context.push('/due/${n.dueId}');
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: iconBg,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(icon, color: iconColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    n.title,
                                    style: AppTypography.titleMedium.copyWith(
                                      fontWeight: n.read
                                          ? FontWeight.w500
                                          : FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    DateFormatter.formatRelativeTime(
                                        n.timestamp),
                                    style: AppTypography.bodySmall
                                        .copyWith(fontSize: 10.5),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(n.message, style: AppTypography.bodySmall),
                              if (n.dueId != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      'Open Due Details',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward,
                                        size: 12, color: AppColors.primary),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!n.read)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4, left: 4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
