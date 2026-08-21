import 'package:dueit/core/utils/date_formatter.dart';

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

  static DueStatus fromString(String? val) {
    if (val == null) return DueStatus.upcoming;
    switch (val.toLowerCase()) {
      case 'due':
        return DueStatus.due;
      case 'upcoming':
        return DueStatus.upcoming;
      case 'overdue':
        return DueStatus.overdue;
      case 'partiallypaid':
      case 'partially_paid':
        return DueStatus.partiallyPaid;
      case 'paid':
        return DueStatus.paid;
      case 'cancelled':
        return DueStatus.cancelled;
      default:
        return DueStatus.upcoming;
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

  static RecurrenceType fromString(String? val) {
    if (val == null) return RecurrenceType.none;
    switch (val.toLowerCase()) {
      case 'weekly':
        return RecurrenceType.weekly;
      case 'monthly':
        return RecurrenceType.monthly;
      case 'yearly':
      case 'annually':
        return RecurrenceType.yearly;
      default:
        return RecurrenceType.none;
    }
  }
}

enum ReminderType {
  none,
  onDueDate,
  oneDayBefore,
  twoDaysBefore,
  threeDaysBefore,
  sevenDaysBefore,
  daily;

  String get displayName {
    switch (this) {
      case ReminderType.none:
        return 'None';
      case ReminderType.onDueDate:
        return 'On Due Date';
      case ReminderType.oneDayBefore:
        return '1 Day Before';
      case ReminderType.twoDaysBefore:
        return '2 Days Before';
      case ReminderType.threeDaysBefore:
        return '3 Days Before';
      case ReminderType.sevenDaysBefore:
        return '1 Week Before';
      case ReminderType.daily:
        return 'Daily';
    }
  }

  static ReminderType fromString(String? val) {
    if (val == null) return ReminderType.oneDayBefore;
    switch (val.toLowerCase().trim()) {
      case 'none':
        return ReminderType.none;
      case 'on_due_date':
      case 'on due date':
        return ReminderType.onDueDate;
      case 'one_day_before':
      case '1 day before':
        return ReminderType.oneDayBefore;
      case 'two_days_before':
      case '2 days before':
        return ReminderType.twoDaysBefore;
      case 'three_days_before':
      case '3 days before':
        return ReminderType.threeDaysBefore;
      case 'seven_days_before':
      case '7 days before':
      case '1 week before':
      case 'one_week_before':
        return ReminderType.sevenDaysBefore;
      case 'daily':
        return ReminderType.daily;
      default:
        return ReminderType.oneDayBefore;
    }
  }
}

class DueEntity {
  final String id;
  final String ownerId;
  final String businessId;
  final String customerId;
  final String customerName;
  final double amount;
  final double paidAmount;
  final String description;
  final String dueDate; // ISO format 'YYYY-MM-DD'
  final DueStatus status;
  final ReminderType reminderType;
  final bool reminderEnabled;
  final RecurrenceType recurrence;
  final int recurringCycle;
  final String? paidAt;
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DueEntity({
    required this.id,
    this.ownerId = '',
    this.businessId = '',
    required this.customerId,
    this.customerName = '',
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
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? const _DefaultDateTime(),
        updatedAt = updatedAt ?? const _DefaultDateTime();

  double get remainingAmount => amount - paidAmount;
  bool get isFullyPaid => paidAmount >= amount || status == DueStatus.paid;
  bool get isCancelled => status == DueStatus.cancelled;

  /// Deterministic status derivation based on due date and cancellation state
  static DueStatus deriveStatus({
    required String dueDate,
    bool isCancelled = false,
  }) {
    if (isCancelled) {
      return DueStatus.cancelled;
    }
    if (DateFormatter.isBeforeToday(dueDate)) {
      return DueStatus.overdue;
    }
    if (DateFormatter.isToday(dueDate)) {
      return DueStatus.due;
    }
    return DueStatus.upcoming;
  }

  /// Evaluates the current effective status dynamically
  DueStatus get effectiveStatus {
    if (status == DueStatus.cancelled) return DueStatus.cancelled;
    if (status == DueStatus.paid) return DueStatus.paid;
    if (status == DueStatus.partiallyPaid) return DueStatus.partiallyPaid;
    return deriveStatus(dueDate: dueDate, isCancelled: false);
  }

  DueEntity copyWith({
    String? id,
    String? ownerId,
    String? businessId,
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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DueEntity(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      businessId: businessId ?? this.businessId,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'businessId': businessId,
      'customerId': customerId,
      'customerName': customerName,
      'amount': amount,
      'paidAmount': paidAmount,
      'description': description.trim(),
      'dueDate': dueDate,
      'status': status.name,
      'reminderType': reminderType.name,
      'reminderEnabled': reminderEnabled,
      'recurrence': recurrence.name,
      'recurringCycle': recurringCycle,
      'paidAt': paidAt,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DueEntity.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    final dueDateStr =
        map['dueDate'] as String? ?? DateFormatter.todayIsoDate();
    final rawStatus = DueStatus.fromString(map['status'] as String?);
    final status = rawStatus == DueStatus.cancelled
        ? DueStatus.cancelled
        : deriveStatus(dueDate: dueDateStr, isCancelled: false);

    return DueEntity(
      id: docId ?? map['id'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      businessId: map['businessId'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] as String? ?? '',
      dueDate: dueDateStr,
      status: status,
      reminderType: ReminderType.fromString(map['reminderType'] as String?),
      reminderEnabled: map['reminderEnabled'] as bool? ?? true,
      recurrence: RecurrenceType.fromString(map['recurrence'] as String?),
      recurringCycle: (map['recurringCycle'] as num?)?.toInt() ?? 1,
      paidAt: map['paidAt'] as String?,
      paymentMethod: map['paymentMethod'] as String?,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}

class _DefaultDateTime implements DateTime {
  const _DefaultDateTime();

  DateTime get _now => DateTime.now();

  @override
  DateTime add(Duration duration) => _now.add(duration);
  @override
  int compareTo(DateTime other) => _now.compareTo(other);
  @override
  int get day => _now.day;
  @override
  Duration difference(DateTime other) => _now.difference(other);
  @override
  int get hour => _now.hour;
  @override
  bool isAfter(DateTime other) => _now.isAfter(other);
  @override
  bool isAtSameMomentAs(DateTime other) => _now.isAtSameMomentAs(other);
  @override
  bool isBefore(DateTime other) => _now.isBefore(other);
  @override
  bool get isUtc => _now.isUtc;
  @override
  int get microsecond => _now.microsecond;
  @override
  int get microsecondsSinceEpoch => _now.microsecondsSinceEpoch;
  @override
  int get millisecond => _now.millisecond;
  @override
  int get millisecondsSinceEpoch => _now.millisecondsSinceEpoch;
  @override
  int get minute => _now.minute;
  @override
  int get month => _now.month;
  @override
  int get second => _now.second;
  @override
  DateTime subtract(Duration duration) => _now.subtract(duration);
  @override
  String get timeZoneName => _now.timeZoneName;
  @override
  Duration get timeZoneOffset => _now.timeZoneOffset;
  @override
  String toIso8601String() => _now.toIso8601String();
  @override
  DateTime toLocal() => _now.toLocal();
  @override
  DateTime toUtc() => _now.toUtc();
  @override
  int get weekday => _now.weekday;
  @override
  int get year => _now.year;
}
