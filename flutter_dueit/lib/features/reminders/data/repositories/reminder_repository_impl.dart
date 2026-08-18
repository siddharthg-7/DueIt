import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/reminder_repository.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';
import 'package:dueit/features/customers/domain/entities/customer_entity.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  final List<NotificationEntity> _notifications = [
    NotificationEntity(
      id: 'notif_1',
      title: 'Payment Overdue',
      message: 'Sneha Reddy\'s payment of ₹2,200 is 4 days overdue.',
      type: NotificationType.overdue,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      read: false,
      dueId: 'due_2',
      customerId: 'cust_2',
    ),
    NotificationEntity(
      id: 'notif_2',
      title: 'Due Today',
      message:
          'Rahul Kumar has ₹1,500 due today for August Advanced Karate Fee.',
      type: NotificationType.dueToday,
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      read: false,
      dueId: 'due_1',
      customerId: 'cust_1',
    ),
    NotificationEntity(
      id: 'notif_3',
      title: 'Payment Received',
      message: 'Received ₹2,000 partial payment from Vikram Malhotra via UPI.',
      type: NotificationType.paymentReceived,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      read: true,
      dueId: 'due_3',
      customerId: 'cust_3',
    ),
  ];

  @override
  Future<List<NotificationEntity>> getNotifications() async {
    return List.unmodifiable(_notifications);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(read: true);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(read: true);
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
  }

  @override
  String generateWhatsAppReminderUrl({
    required DueEntity due,
    required CustomerEntity customer,
    String? upiId,
    String? businessName,
  }) {
    final phone = customer.phone.replaceAll(RegExp(r'\D'), '');
    final bName = businessName ?? 'DueIt';
    final remaining = due.remainingAmount;

    final String text = '*PAYMENT REMINDER*\n\n'
        'Dear *${due.customerName}*,\n'
        'This is a friendly reminder from *$bName* regarding your pending payment for *${due.description}*.\n\n'
        '• Amount Due: *₹${remaining.toInt()}*\n'
        '• Due Date: *${due.dueDate}*\n'
        '${upiId != null && upiId.isNotEmpty ? '• Pay via UPI: *$upiId*\n' : ''}\n'
        'Please let us know once paid. Thank you!';

    return 'https://api.whatsapp.com/send?phone=$phone&text=${Uri.encodeComponent(text)}';
  }

  @override
  String generateCustomerStatementWhatsAppUrl({
    required CustomerEntity customer,
    required List<DueEntity> outstandingDues,
    String? upiId,
    String? businessName,
  }) {
    final phone = customer.phone.replaceAll(RegExp(r'\D'), '');
    final bName = businessName ?? 'DueIt';
    final total =
        outstandingDues.fold<double>(0, (sum, d) => sum + d.remainingAmount);

    final duesLines = outstandingDues
        .map((d) =>
            '• ${d.description}: ₹${d.remainingAmount.toInt()} (Due: ${d.dueDate})')
        .join('\n');

    final String text = '*ACCOUNT STATEMENT*\n\n'
        '*$bName*\n'
        'Client: *${customer.name}*\n\n'
        'Outstanding Items:\n'
        '$duesLines\n\n'
        '*Total Outstanding: ₹${total.toInt()}*\n'
        '${upiId != null && upiId.isNotEmpty ? 'Pay via UPI: *$upiId*\n' : ''}\n'
        'Thank you for your business!';

    return 'https://api.whatsapp.com/send?phone=$phone&text=${Uri.encodeComponent(text)}';
  }
}
