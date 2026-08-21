import 'package:intl/intl.dart';
import 'package:dueit/core/utils/currency_formatter.dart';
import 'package:dueit/core/utils/date_formatter.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';

/// Pure domain service that dynamically generates personalized payment reminder
/// and payment received messages for customer communication.
class PaymentMessageGenerator {
  /// Generates a customized due reminder message based on the status and date.
  static String generateDueReminderMessage({
    required String customerName,
    required double amount,
    required String dueDate,
    required double remainingAmount,
    required DueStatus status,
    String? businessName,
  }) {
    final cleanName =
        customerName.trim().isNotEmpty ? customerName.trim() : 'Customer';
    final formattedRemaining = CurrencyFormatter.format(remainingAmount);
    final formattedDate = _formatDisplayDate(dueDate);
    final senderSuffix =
        (businessName != null && businessName.trim().isNotEmpty)
            ? ' — ${businessName.trim()}'
            : '';

    switch (status) {
      case DueStatus.overdue:
        return 'Hi $cleanName, just a reminder that $formattedRemaining is currently overdue. Please make the payment when possible. Thank you.$senderSuffix';

      case DueStatus.due:
        return 'Hi $cleanName, a quick reminder that $formattedRemaining is due today. Please let me know once the payment is completed. Thank you.$senderSuffix';

      case DueStatus.partiallyPaid:
        return 'Hi $cleanName, this is a reminder regarding your remaining balance of $formattedRemaining. Please complete the payment when possible. Thank you.$senderSuffix';

      case DueStatus.upcoming:
      default:
        return 'Hi $cleanName, this is a friendly reminder that $formattedRemaining is due on $formattedDate. Please let me know once the payment is completed. Thank you.$senderSuffix';
    }
  }

  /// Generates a payment confirmation / receipt message.
  static String generatePaymentReceivedMessage({
    required String customerName,
    required double paidAmount,
    required double remainingAmount,
    required bool isFullyPaid,
    String? businessName,
  }) {
    final cleanName =
        customerName.trim().isNotEmpty ? customerName.trim() : 'Customer';
    final formattedPaid = CurrencyFormatter.format(paidAmount);
    final formattedRemaining = CurrencyFormatter.format(remainingAmount);
    final senderSuffix =
        (businessName != null && businessName.trim().isNotEmpty)
            ? ' — ${businessName.trim()}'
            : '';

    if (isFullyPaid || remainingAmount <= 0) {
      return 'Hi $cleanName, we received your payment of $formattedPaid. Your balance is now fully settled. Thank you.$senderSuffix';
    } else {
      return 'Hi $cleanName, we received your payment of $formattedPaid. Your remaining balance is $formattedRemaining. Thank you.$senderSuffix';
    }
  }

  /// Generates a comprehensive customer statement message summarizing multiple dues.
  static String generateCustomerStatementMessage({
    required String customerName,
    required List<DueEntity> outstandingDues,
    String? upiId,
    String? businessName,
  }) {
    final cleanName =
        customerName.trim().isNotEmpty ? customerName.trim() : 'Customer';
    final totalOutstanding = outstandingDues.fold<double>(
      0.0,
      (sum, d) => sum + d.remainingAmount,
    );
    final formattedTotal = CurrencyFormatter.format(totalOutstanding);
    final businessTitle =
        (businessName != null && businessName.trim().isNotEmpty)
            ? businessName.trim()
            : 'DueIt';

    final buffer = StringBuffer();
    buffer.writeln('Payment Summary from $businessTitle');
    buffer.writeln(
        'Hi $cleanName, here is your current outstanding balance summary:');
    buffer.writeln('');

    for (int i = 0; i < outstandingDues.length; i++) {
      final due = outstandingDues[i];
      final formattedDueDate = _formatDisplayDate(due.dueDate);
      final formattedAmount = CurrencyFormatter.format(due.remainingAmount);
      buffer.writeln(
          '${i + 1}. ${due.description}: $formattedAmount (Due: $formattedDueDate)');
    }

    buffer.writeln('');
    buffer.writeln('Total Outstanding: $formattedTotal');

    if (upiId != null && upiId.trim().isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('You can pay via UPI to: ${upiId.trim()}');
    }

    buffer.writeln('');
    buffer
        .write('Please let us know once the payment is completed. Thank you.');
    return buffer.toString();
  }

  static String _formatDisplayDate(String isoDate) {
    try {
      final parsed = DateFormatter.parseLocalDate(isoDate);
      final currentYear = DateTime.now().year;
      if (parsed.year == currentYear) {
        return DateFormat('MMMM d').format(parsed);
      }
      return DateFormat('MMMM d, yyyy').format(parsed);
    } catch (_) {
      return isoDate;
    }
  }
}
