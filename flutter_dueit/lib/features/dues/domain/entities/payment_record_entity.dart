enum PaymentMethod {
  upi,
  cash,
  card,
  bankTransfer,
  cheque;

  String get displayName {
    switch (this) {
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.cheque:
        return 'Cheque';
    }
  }
}

class PaymentRecordEntity {
  final String id;
  final String dueId;
  final String customerId;
  final String customerName;
  final double amount;
  final PaymentMethod paymentMethod;
  final String paidAt;
  final String receiptNumber;
  final String? notes;

  const PaymentRecordEntity({
    required this.id,
    required this.dueId,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.paymentMethod,
    required this.paidAt,
    required this.receiptNumber,
    this.notes,
  });
}
