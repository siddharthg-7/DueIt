enum NotificationType {
  dueToday,
  overdue,
  upcoming,
  paymentReceived,
  system;
}

class NotificationEntity {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool read;
  final String? dueId;
  final String? customerId;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.read = false,
    this.dueId,
    this.customerId,
  });

  NotificationEntity copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? read,
    String? dueId,
    String? customerId,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
      dueId: dueId ?? this.dueId,
      customerId: customerId ?? this.customerId,
    );
  }
}
