import '../entities/notification_entity.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';
import 'package:dueit/features/customers/domain/entities/customer_entity.dart';

abstract class ReminderRepository {
  Future<List<NotificationEntity>> getNotifications();
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String notificationId);
  String generateWhatsAppReminderUrl({
    required DueEntity due,
    required CustomerEntity customer,
    String? upiId,
    String? businessName,
  });
  String generateCustomerStatementWhatsAppUrl({
    required CustomerEntity customer,
    required List<DueEntity> outstandingDues,
    String? upiId,
    String? businessName,
  });
}
