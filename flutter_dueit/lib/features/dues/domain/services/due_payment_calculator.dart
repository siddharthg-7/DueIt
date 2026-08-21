import 'dart:math' as math;
import 'package:dueit/core/utils/date_formatter.dart';
import '../entities/due_entity.dart';
import '../entities/payment_record_entity.dart';

class CustomerFinancials {
  final double outstanding;
  final double collected;

  const CustomerFinancials({
    this.outstanding = 0.0,
    this.collected = 0.0,
  });
}

abstract class DuePaymentCalculator {
  /// Sums all payment records associated with a given dueId
  static double calculateTotalPaid(
    String dueId,
    List<PaymentRecordEntity> payments,
  ) {
    return payments
        .where((p) => p.dueId == dueId)
        .fold<double>(0.0, (sum, p) => sum + p.amount);
  }

  /// Calculates remaining balance given total due and total paid
  static double calculateRemaining(double totalDue, double totalPaid) {
    return math.max(0.0, totalDue - totalPaid);
  }

  /// Deterministic single-source-of-truth status derivation
  /// Hierarchy: CANCELLED -> PAID -> PARTIALLY_PAID -> OVERDUE -> DUE -> UPCOMING
  static DueStatus calculateDueStatus({
    required double amount,
    required double totalPaid,
    required String dueDate,
    bool isCancelled = false,
  }) {
    if (isCancelled) {
      return DueStatus.cancelled;
    }
    final remaining = calculateRemaining(amount, totalPaid);
    if (remaining <= 0.0 && amount > 0.0) {
      return DueStatus.paid;
    }
    if (totalPaid > 0.0) {
      return DueStatus.partiallyPaid;
    }
    if (DateFormatter.isBeforeToday(dueDate)) {
      return DueStatus.overdue;
    }
    if (DateFormatter.isToday(dueDate)) {
      return DueStatus.due;
    }
    return DueStatus.upcoming;
  }

  /// Enriches a DueEntity with aggregated payments
  static DueEntity enrichDue(
    DueEntity due,
    List<PaymentRecordEntity> payments,
  ) {
    final totalPaid = calculateTotalPaid(due.id, payments);
    final status = calculateDueStatus(
      amount: due.amount,
      totalPaid: totalPaid,
      dueDate: due.dueDate,
      isCancelled: due.isCancelled,
    );

    String? paidAtDate;
    if (status == DueStatus.paid) {
      final duePayments = payments.where((p) => p.dueId == due.id).toList();
      if (duePayments.isNotEmpty) {
        paidAtDate = duePayments.last.paidAt;
      }
    }

    return due.copyWith(
      paidAmount: totalPaid,
      status: status,
      paidAt: paidAtDate,
    );
  }

  /// Computes customer outstanding balance and total collected
  static CustomerFinancials calculateCustomerFinancials(
    String customerId,
    List<DueEntity> dues,
    List<PaymentRecordEntity> payments,
  ) {
    final customerDues = dues.where((d) => d.customerId == customerId);
    final customerPayments = payments.where((p) => p.customerId == customerId);

    final collected =
        customerPayments.fold<double>(0.0, (sum, p) => sum + p.amount);

    final outstanding = customerDues
        .where((d) => !d.isCancelled && !d.isFullyPaid)
        .fold<double>(0.0, (sum, d) => sum + d.remainingAmount);

    return CustomerFinancials(
      outstanding: outstanding,
      collected: collected,
    );
  }
}
