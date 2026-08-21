import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dueit/features/customers/domain/entities/customer_entity.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';
import 'package:dueit/features/communication/presentation/widgets/whatsapp_message_preview_sheet.dart';
import 'package:dueit/features/communication/presentation/widgets/choose_due_for_reminder_sheet.dart';

void main() {
  final testCustomer = CustomerEntity(
    id: 'cust_1',
    ownerId: 'user_1',
    businessId: 'user_1',
    name: 'Rahul Sharma',
    phone: '9876543210',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testDue = DueEntity(
    id: 'due_1',
    ownerId: 'user_1',
    customerId: 'cust_1',
    customerName: 'Rahul Sharma',
    amount: 1500,
    paidAmount: 500,
    description: 'August Karate Fee',
    dueDate: '2026-08-25',
    status: DueStatus.upcoming,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Widget createWidgetUnderTest(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('WhatsApp Collection Flow Widget Tests', () {
    testWidgets(
        '1. WhatsAppMessagePreviewSheet displays customer info, due amount, and editable message',
        (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          WhatsAppMessagePreviewSheet(
            customer: testCustomer,
            due: testDue,
            businessName: 'Apex Martial Arts',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('WhatsApp Message'), findsOneWidget);
      expect(find.text('Rahul Sharma'), findsOneWidget);
      expect(find.text('+91 98765 43210'), findsOneWidget);
      expect(find.text('₹1,000'), findsOneWidget); // Remaining amount
      expect(find.text('Open WhatsApp'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);

      // Verify text field has default message
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextFormField &&
              (widget.controller?.text.contains('Hi Rahul Sharma') ?? false) &&
              (widget.controller?.text.contains('₹1,000 is due on') ?? false),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        '2. Template switching toggles between Reminder and Payment Receipt',
        (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          WhatsAppMessagePreviewSheet(
            customer: testCustomer,
            due: testDue,
            lastPaidAmount: 500,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Payment Receipt' chip
      await tester.tap(find.text('Payment Receipt'));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextFormField &&
              (widget.controller?.text
                      .contains('we received your payment of ₹500') ??
                  false),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        '3. Empty message validation prevents opening WhatsApp and shows error',
        (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          WhatsAppMessagePreviewSheet(
            customer: testCustomer,
            due: testDue,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clear the text field
      final textFieldFinder = find.byType(TextFormField);
      await tester.enterText(textFieldFinder, '   ');
      await tester.pumpAndSettle();

      // Tap Open WhatsApp
      await tester.tap(find.text('Open WhatsApp'));
      await tester.pumpAndSettle();

      expect(find.text('Message cannot be empty.'), findsOneWidget);
    });

    testWidgets(
        '4. Missing or invalid phone number disables Open WhatsApp and shows warning',
        (tester) async {
      final invalidCustomer = testCustomer.copyWith(phone: 'invalid_number');

      await tester.pumpWidget(
        createWidgetUnderTest(
          WhatsAppMessagePreviewSheet(
            customer: invalidCustomer,
            due: testDue,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Please check this customer's phone number."),
          findsOneWidget);

      // Open WhatsApp button should be disabled (onPressed == null)
      final openButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Open WhatsApp'),
      );
      expect(openButton.onPressed, isNull);

      // Copy button should still be available
      final copyButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Copy'),
      );
      expect(copyButton.onPressed, isNotNull);
    });

    testWidgets(
        '5. ChooseDueForReminderSheet renders all active dues and handles selection',
        (tester) async {
      final multipleDues = [
        testDue,
        testDue.copyWith(
          id: 'due_2',
          description: 'Tournament Registration',
          amount: 2000,
          paidAmount: 0,
          status: DueStatus.due,
        ),
      ];

      await tester.pumpWidget(
        createWidgetUnderTest(
          ChooseDueForReminderSheet(
            customer: testCustomer,
            activeDues: multipleDues,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Choose a Due'), findsOneWidget);
      expect(find.text('August Karate Fee'), findsOneWidget);
      expect(find.text('Tournament Registration'), findsOneWidget);
      expect(find.text('₹1,000'), findsOneWidget);
      expect(find.text('₹2,000'), findsOneWidget);
    });
  });
}
