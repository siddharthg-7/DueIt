import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dueit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dueit/features/auth/presentation/screens/login_screen.dart';
import 'package:dueit/features/auth/presentation/screens/business_setup_screen.dart';
import '../../mocks/fake_auth_repository.dart';

void main() {
  group('Auth Flow UI & Form Validation Tests', () {
    testWidgets(
        'LoginScreen displays sign in fields and validates empty inputs',
        (tester) async {
      final fakeRepo = FakeAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: LoginScreen(initialIsSignUp: false),
          ),
        ),
      );

      // Verify branding and title
      expect(find.text('DueIt'), findsOneWidget);
      expect(find.text('Sign In'), findsWidgets);

      // Attempt to tap Sign In button with empty fields
      final submitButton = find.widgetWithText(FilledButton, 'Sign In');
      expect(submitButton, findsOneWidget);

      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Expect validation error
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);
    });

    testWidgets(
        'LoginScreen validates invalid email format and password min length',
        (tester) async {
      final fakeRepo = FakeAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: LoginScreen(initialIsSignUp: false),
          ),
        ),
      );

      // Enter invalid email and short password
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'invalidemail');
      await tester.enterText(textFields.at(1), '123');

      final submitButton = find.widgetWithText(FilledButton, 'Sign In');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
      expect(
          find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('Create Account tab validates password confirmation match',
        (tester) async {
      final fakeRepo = FakeAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: LoginScreen(initialIsSignUp: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show Email, Password, Confirm Password fields
      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(3));

      // Enter email, password, and mismatching confirm password
      await tester.enterText(textFields.at(0), 'test@domain.com');
      await tester.enterText(textFields.at(1), 'securepass123');
      await tester.enterText(textFields.at(2), 'mismatchpass456');

      final createAccountBtn =
          find.widgetWithText(FilledButton, 'Create Account');
      await tester.tap(createAccountBtn);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('BusinessSetupScreen validates required business name',
        (tester) async {
      final fakeRepo = FakeAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: BusinessSetupScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("Let's set up your business profile."), findsOneWidget);

      // Tap Save & Continue with empty name
      final continueBtn = find.text('Save & Continue');
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your business name'), findsOneWidget);
    });
  });
}
