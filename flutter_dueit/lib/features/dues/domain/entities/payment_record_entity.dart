enum PaymentMethod {
  cash,
  upi,
  bankTransfer,
  card,
  cheque,
  other;

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.cheque:
        return 'Cheque';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  static PaymentMethod fromString(String? val) {
    if (val == null) return PaymentMethod.cash;
    switch (val.toLowerCase()) {
      case 'cash':
        return PaymentMethod.cash;
      case 'upi':
        return PaymentMethod.upi;
      case 'banktransfer':
      case 'bank_transfer':
      case 'bank transfer':
        return PaymentMethod.bankTransfer;
      case 'card':
        return PaymentMethod.card;
      case 'cheque':
        return PaymentMethod.cheque;
      case 'other':
        return PaymentMethod.other;
      default:
        return PaymentMethod.cash;
    }
  }
}

class PaymentRecordEntity {
  final String id;
  final String ownerId;
  final String businessId;
  final String dueId;
  final String customerId;
  final String customerName;
  final double amount;
  final PaymentMethod paymentMethod;
  final String paidAt; // ISO format date or datetime string
  final String receiptNumber;
  final String? notes;
  final DateTime createdAt;

  const PaymentRecordEntity({
    required this.id,
    this.ownerId = '',
    this.businessId = '',
    required this.dueId,
    required this.customerId,
    this.customerName = '',
    required this.amount,
    required this.paymentMethod,
    required this.paidAt,
    this.receiptNumber = '',
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? const _DefaultDateTime();

  PaymentRecordEntity copyWith({
    String? id,
    String? ownerId,
    String? businessId,
    String? dueId,
    String? customerId,
    String? customerName,
    double? amount,
    PaymentMethod? paymentMethod,
    String? paidAt,
    String? receiptNumber,
    String? notes,
    DateTime? createdAt,
  }) {
    return PaymentRecordEntity(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      businessId: businessId ?? this.businessId,
      dueId: dueId ?? this.dueId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAt: paidAt ?? this.paidAt,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'businessId': businessId,
      'dueId': dueId,
      'customerId': customerId,
      'customerName': customerName,
      'amount': amount,
      'paymentMethod': paymentMethod.name,
      'paidAt': paidAt,
      'receiptNumber': receiptNumber,
      'notes': notes?.trim(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PaymentRecordEntity.fromMap(Map<String, dynamic> map,
      {String? docId}) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    return PaymentRecordEntity(
      id: docId ?? map['id'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      businessId: map['businessId'] as String? ?? '',
      dueId: map['dueId'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: PaymentMethod.fromString(map['paymentMethod'] as String?),
      paidAt: map['paidAt'] as String? ?? DateTime.now().toIso8601String(),
      receiptNumber: map['receiptNumber'] as String? ?? '',
      notes: map['notes'] as String?,
      createdAt: parseDate(map['createdAt']),
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
