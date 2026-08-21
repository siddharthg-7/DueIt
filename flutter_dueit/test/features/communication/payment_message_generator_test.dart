import 'package:flutter_test/flutter_test.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';
import 'package:dueit/features/communication/domain/services/payment_message_generator.dart';

void main() {
  group('PaymentMessageGenerator Domain Unit Tests', () {
    test(
        '1. Upcoming due reminder generates friendly reminder with formatted date and amount',
        () {
      final msg = PaymentMessageGenerator.generateDueReminderMessage(
        customerName: 'Rahul Sharma',
        amount: 1500,
        dueDate: '2026-08-25',
        remainingAmount: 1500,
        status: DueStatus.upcoming,
      );

      expect(msg, contains('Hi Rahul Sharma'));
      expect(msg, contains('₹1,500 is due on August 25'));
      expect(msg, contains('Please let me know once the payment is completed'));
    });

    test('2. Due today reminder generates quick reminder for today', () {
      final msg = PaymentMessageGenerator.generateDueReminderMessage(
        customerName: 'Pooja Verma',
        amount: 2500,
        dueDate: '2026-08-21',
        remainingAmount: 2500,
        status: DueStatus.due,
      );

      expect(msg, contains('Hi Pooja Verma'));
      expect(msg, contains('₹2,500 is due today'));
    });

    test(
        '3. Overdue reminder uses actual remaining amount rather than original amount',
        () {
      final msg = PaymentMessageGenerator.generateDueReminderMessage(
        customerName: 'Amit Patel',
        amount: 5000,
        dueDate: '2026-08-10',
        remainingAmount: 3000, // Partially paid, ₹3000 remaining
        status: DueStatus.overdue,
      );

      expect(msg, contains('Hi Amit Patel'));
      expect(msg, contains('₹3,000 is currently overdue'));
      expect(msg, isNot(contains('₹5,000')));
    });

    test('4. Partially paid reminder emphasizes remaining balance', () {
      final msg = PaymentMessageGenerator.generateDueReminderMessage(
        customerName: 'Sneha Rao',
        amount: 4000,
        dueDate: '2026-08-28',
        remainingAmount: 1500,
        status: DueStatus.partiallyPaid,
      );

      expect(msg, contains('Hi Sneha Rao'));
      expect(msg, contains('remaining balance of ₹1,500'));
    });

    test(
        '5. Payment received message for partial payment shows received and remaining balance',
        () {
      final msg = PaymentMessageGenerator.generatePaymentReceivedMessage(
        customerName: 'Rahul',
        paidAmount: 500,
        remainingAmount: 1000,
        isFullyPaid: false,
      );

      expect(msg, contains('Hi Rahul'));
      expect(msg, contains('we received your payment of ₹500'));
      expect(msg, contains('remaining balance is ₹1,000'));
    });

    test(
        '6. Payment received message for full settlement shows fully settled confirmation',
        () {
      final msg = PaymentMessageGenerator.generatePaymentReceivedMessage(
        customerName: 'Rahul',
        paidAmount: 1500,
        remainingAmount: 0,
        isFullyPaid: true,
      );

      expect(msg, contains('Hi Rahul'));
      expect(msg, contains('we received your payment of ₹1,500'));
      expect(msg, contains('balance is now fully settled'));
    });

    test('7. Business name is included in message signature when provided', () {
      final msg = PaymentMessageGenerator.generateDueReminderMessage(
        customerName: 'Vikas',
        amount: 1000,
        dueDate: '2026-08-25',
        remainingAmount: 1000,
        status: DueStatus.upcoming,
        businessName: 'Apex Karate Academy',
      );

      expect(msg, contains('— Apex Karate Academy'));
    });

    test('8. Missing or empty customer name falls back gracefully to Customer',
        () {
      final msg = PaymentMessageGenerator.generateDueReminderMessage(
        customerName: '  ',
        amount: 1200,
        dueDate: '2026-08-22',
        remainingAmount: 1200,
        status: DueStatus.due,
      );

      expect(msg,
          contains('Hi Customer, a quick reminder that ₹1,200 is due today'));
    });

    test(
        '9. Customer statement message aggregates multiple dues with UPI details',
        () {
      final dues = [
        DueEntity(
          id: 'due_1',
          ownerId: 'u1',
          customerId: 'c1',
          customerName: 'Karan',
          amount: 2000,
          paidAmount: 500,
          description: 'Gym Fee - July',
          dueDate: '2026-07-01',
          status: DueStatus.overdue,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        DueEntity(
          id: 'due_2',
          ownerId: 'u1',
          customerId: 'c1',
          customerName: 'Karan',
          amount: 2000,
          paidAmount: 0,
          description: 'Gym Fee - August',
          dueDate: '2026-08-01',
          status: DueStatus.due,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final statement =
          PaymentMessageGenerator.generateCustomerStatementMessage(
        customerName: 'Karan',
        outstandingDues: dues,
        upiId: 'apex@upi',
        businessName: 'Apex Fitness',
      );

      expect(statement, contains('Payment Summary from Apex Fitness'));
      expect(statement, contains('1. Gym Fee - July: ₹1,500'));
      expect(statement, contains('2. Gym Fee - August: ₹2,000'));
      expect(statement, contains('Total Outstanding: ₹3,500'));
      expect(statement, contains('pay via UPI to: apex@upi'));
    });
  });
}
