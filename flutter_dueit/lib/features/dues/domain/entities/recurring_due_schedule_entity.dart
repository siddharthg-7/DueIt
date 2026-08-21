import 'package:dueit/core/utils/date_formatter.dart';
import 'due_entity.dart';

/// Recurrence frequencies supported by DueIt
enum RecurrenceFrequency {
  monthly,
  quarterly,
  yearly,
  weekly;

  String get displayName {
    switch (this) {
      case RecurrenceFrequency.monthly:
        return 'Monthly';
      case RecurrenceFrequency.quarterly:
        return 'Quarterly';
      case RecurrenceFrequency.yearly:
        return 'Yearly';
      case RecurrenceFrequency.weekly:
        return 'Weekly';
    }
  }

  static RecurrenceFrequency fromString(String? val) {
    if (val == null) return RecurrenceFrequency.monthly;
    switch (val.toLowerCase().trim()) {
      case 'quarterly':
        return RecurrenceFrequency.quarterly;
      case 'yearly':
      case 'annually':
        return RecurrenceFrequency.yearly;
      case 'weekly':
        return RecurrenceFrequency.weekly;
      case 'monthly':
      default:
        return RecurrenceFrequency.monthly;
    }
  }
}

/// Lifecycle status of a Recurring Schedule
enum RecurringScheduleStatus {
  active,
  paused,
  ended;

  String get displayName {
    switch (this) {
      case RecurringScheduleStatus.active:
        return 'Active';
      case RecurringScheduleStatus.paused:
        return 'Paused';
      case RecurringScheduleStatus.ended:
        return 'Ended';
    }
  }

  static RecurringScheduleStatus fromString(String? val) {
    if (val == null) return RecurringScheduleStatus.active;
    switch (val.toLowerCase().trim()) {
      case 'paused':
        return RecurringScheduleStatus.paused;
      case 'ended':
      case 'stopped':
        return RecurringScheduleStatus.ended;
      case 'active':
      default:
        return RecurringScheduleStatus.active;
    }
  }
}

/// Human-readable representation of standard days of week
enum AppDayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  int get weekdayNumber => index + 1;

  String get displayName {
    switch (this) {
      case AppDayOfWeek.monday:
        return 'Monday';
      case AppDayOfWeek.tuesday:
        return 'Tuesday';
      case AppDayOfWeek.wednesday:
        return 'Wednesday';
      case AppDayOfWeek.thursday:
        return 'Thursday';
      case AppDayOfWeek.friday:
        return 'Friday';
      case AppDayOfWeek.saturday:
        return 'Saturday';
      case AppDayOfWeek.sunday:
        return 'Sunday';
    }
  }

  static AppDayOfWeek fromDateTimeWeekday(int weekday) {
    return AppDayOfWeek.values[(weekday - 1).clamp(0, 6)];
  }

  static AppDayOfWeek? fromString(String? val) {
    if (val == null) return null;
    switch (val.toLowerCase().trim()) {
      case 'monday':
      case 'mon':
        return AppDayOfWeek.monday;
      case 'tuesday':
      case 'tue':
        return AppDayOfWeek.tuesday;
      case 'wednesday':
      case 'wed':
        return AppDayOfWeek.wednesday;
      case 'thursday':
      case 'thu':
        return AppDayOfWeek.thursday;
      case 'friday':
      case 'fri':
        return AppDayOfWeek.friday;
      case 'saturday':
      case 'sat':
        return AppDayOfWeek.saturday;
      case 'sunday':
      case 'sun':
        return AppDayOfWeek.sunday;
      default:
        return null;
    }
  }
}

/// Domain entity representing a template for generating recurring dues
class RecurringDueScheduleEntity {
  final String id;
  final String ownerId;
  final String businessId;
  final String customerId;
  final String customerName;
  final double amount;
  final String description;
  final RecurrenceFrequency frequency;
  final int dayOfMonth; // 1-31 (used for Monthly, Quarterly, Yearly)
  final int? dayOfWeek; // 1-7 (1=Monday..7=Sunday, used for Weekly)
  final String startDate; // ISO format 'YYYY-MM-DD'
  final String? endDate; // Optional ISO format 'YYYY-MM-DD'
  final RecurringScheduleStatus status;
  final String nextDueDate; // ISO format 'YYYY-MM-DD'
  final ReminderType reminderType;
  final bool reminderEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecurringDueScheduleEntity({
    required this.id,
    this.ownerId = '',
    this.businessId = '',
    required this.customerId,
    this.customerName = '',
    required this.amount,
    required this.description,
    this.frequency = RecurrenceFrequency.monthly,
    required this.dayOfMonth,
    this.dayOfWeek,
    required this.startDate,
    this.endDate,
    this.status = RecurringScheduleStatus.active,
    required this.nextDueDate,
    this.reminderType = ReminderType.oneDayBefore,
    this.reminderEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == RecurringScheduleStatus.active;
  bool get isPaused => status == RecurringScheduleStatus.paused;
  bool get isEnded => status == RecurringScheduleStatus.ended;

  /// Effective day of week (1=Monday, 7=Sunday)
  int get effectiveDayOfWeek =>
      dayOfWeek ?? DateFormatter.parseLocalDate(startDate).weekday;

  /// Weekday enum representation
  AppDayOfWeek get weekday =>
      AppDayOfWeek.fromDateTimeWeekday(effectiveDayOfWeek);

  RecurringDueScheduleEntity copyWith({
    String? id,
    String? ownerId,
    String? businessId,
    String? customerId,
    String? customerName,
    double? amount,
    String? description,
    RecurrenceFrequency? frequency,
    int? dayOfMonth,
    int? dayOfWeek,
    String? startDate,
    String? endDate,
    RecurringScheduleStatus? status,
    String? nextDueDate,
    ReminderType? reminderType,
    bool? reminderEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurringDueScheduleEntity(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      businessId: businessId ?? this.businessId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      reminderType: reminderType ?? this.reminderType,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
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
      'description': description.trim(),
      'frequency': frequency.name,
      'dayOfMonth': dayOfMonth,
      'dayOfWeek': dayOfWeek ?? effectiveDayOfWeek,
      'startDate': startDate,
      'endDate': endDate,
      'status': status.name,
      'nextDueDate': nextDueDate,
      'reminderType': reminderType.name,
      'reminderEnabled': reminderEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RecurringDueScheduleEntity.fromMap(
    Map<String, dynamic> map, {
    String? docId,
  }) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    final sDate = map['startDate'] as String? ?? DateFormatter.todayIsoDate();

    return RecurringDueScheduleEntity(
      id: docId ?? map['id'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      businessId: map['businessId'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] as String? ?? '',
      frequency: RecurrenceFrequency.fromString(map['frequency'] as String?),
      dayOfMonth: (map['dayOfMonth'] as num?)?.toInt() ?? 1,
      dayOfWeek: (map['dayOfWeek'] as num?)?.toInt() ??
          DateFormatter.parseLocalDate(sDate).weekday,
      startDate: sDate,
      endDate: map['endDate'] as String?,
      status: RecurringScheduleStatus.fromString(map['status'] as String?),
      nextDueDate:
          map['nextDueDate'] as String? ?? DateFormatter.todayIsoDate(),
      reminderType: ReminderType.fromString(map['reminderType'] as String?),
      reminderEnabled: map['reminderEnabled'] as bool? ?? true,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}
