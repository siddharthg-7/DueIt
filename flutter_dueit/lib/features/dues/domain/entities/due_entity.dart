enum DueStatus {
  due,
  upcoming,
  overdue,
  partiallyPaid,
  paid,
  cancelled;

  String get displayName {
    switch (this) {
      case DueStatus.due:
        return 'Payment Due';
      case DueStatus.upcoming:
        return 'Upcoming';
      case DueStatus.overdue:
        return 'Overdue';
      case DueStatus.partiallyPaid:
        return 'Partially Paid';
      case DueStatus.paid:
        return 'Fully Settled';
      case DueStatus.cancelled:
        return 'Cancelled';
    }
  }
}

enum RecurrenceType {
  none,
  weekly,
  monthly,
  yearly;

  String get displayName {
    switch (this) {
      case RecurrenceType.none:
        return 'None';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
      case RecurrenceType.yearly:
        return 'Yearly';
    }
  }
}

enum ReminderType {
  onDueDate,
  oneDayBefore,
  threeDaysBefore,
  daily;

  String get displayName {
    switch (this) {
      case ReminderType.onDueDate:
        return 'On Due Date';
      case ReminderType.oneDayBefore:
        return '1 Day Before';
      case ReminderType.threeDaysBefore:
        return '3 Days Before';
      case ReminderType.daily:
        return 'Daily';
    }
  }
}

class DueEntity {
  final String id;
  final String customerId;
  final String customerName;
  final double amount;
  final double paidAmount;
  final String description;
  final String dueDate;
  final DueStatus status;
  final ReminderType reminderType;
  final bool reminderEnabled;
  final RecurrenceType recurrence;
  final int recurringCycle;
  final String? paidAt;
  final String? paymentMethod;

  const DueEntity({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.amount,
    this.paidAmount = 0.0,
    required this.description,
    required this.dueDate,
    required this.status,
    this.reminderType = ReminderType.oneDayBefore,
    this.reminderEnabled = true,
    this.recurrence = RecurrenceType.none,
    this.recurringCycle = 1,
    this.paidAt,
    this.paymentMethod,
  });

  double get remainingAmount => amount - paidAmount;
  bool get isFullyPaid => paidAmount >= amount || status == DueStatus.paid;

  DueEntity copyWith({
    String? id,
    String? customerId,
    String? customerName,
    double? amount,
    double? paidAmount,
    String? description,
    String? dueDate,
    DueStatus? status,
    ReminderType? reminderType,
    bool? reminderEnabled,
    RecurrenceType? recurrence,
    int? recurringCycle,
    String? paidAt,
    String? paymentMethod,
  }) {
    return DueEntity(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      reminderType: reminderType ?? this.reminderType,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      recurrence: recurrence ?? this.recurrence,
      recurringCycle: recurringCycle ?? this.recurringCycle,
      paidAt: paidAt ?? this.paidAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}
